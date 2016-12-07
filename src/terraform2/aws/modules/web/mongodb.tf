
# instance
resource "aws_instance" "db" {
  depends_on = ["null_resource.init-inventory"]
  count = "${var.db_count}"
  tags {
    Name = "${format("mizuno-db%03d", count.index + 1)}"
  }
  ami = "${var.amazon_linux_ami}"
  instance_type = "${var.micro_instance}"
  key_name = "${aws_key_pair.mizuno_key.key_name}"
  disable_api_termination = false
  instance_initiated_shutdown_behavior = "${var.shutdown_behavior}"
  monitoring = true
  iam_instance_profile = "${aws_iam_instance_profile.ec2_instance_iam_profile.name}"

  provisioner "file" {
    content = "${element(data.template_file.db_log_conf_template.*.rendered, count.index)}"
    destination = "/tmp/awslogs.cfg"
    connection {
      type = "ssh"
      user = "${var.ansible_ssh_user}"
      timeout = "1m"
      private_key = "${file(var.private_key)}"
    }
  }
}


# volume
resource "aws_ebs_volume" "db_volume" {
  count = "${var.db_count * var.raid_replication_factor}"
  tags {
    Name = "${format("mizuno-volume%03d-%03d", count.index / var.raid_replication_factor + 1, count.index % var.raid_replication_factor + 1)}"
  }
  availability_zone = "${var.tokyo_region}a"
  size = 10
  type = "${var.volume_gp2}"
}


resource "aws_volume_attachment" "volume_attachment" {
  count = "${var.db_count * var.raid_replication_factor}"
  device_name = "${format("/dev/sd%s", element(var.device_alphabets, count.index % var.raid_replication_factor))}"
  instance_id = "${element(aws_instance.db.*.id, count.index / var.raid_replication_factor)}"
  volume_id = "${element(aws_ebs_volume.db_volume.*.id, count.index)}"
  force_detach = "${var.volume_force_detach}"
}


resource "null_resource" "raid" {
  depends_on = ["aws_volume_attachment.volume_attachment"]
  count = "${var.db_count}"
  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y mdadm",
      "DEVS=(`ls -l /dev | grep sd[b-z] | awk '{print $9}'`)",
      "DEVICES=()",
      "for dev in $${DEVS[@]}; do DEVICES+=( \"/dev/$$dev\" ); done",
      "sudo mdadm --create --verbose /dev/md/md0 --level=${var.raid_level} --name=0 --raid-devices $${#DEVICES[*]} $${DEVICES[@]}",
      "sudo mkfs .xfs -L MYRAID /dev/md/md0",
      "sudo mkdir -p ${var.raid_mount_dir}",
      "sudo mount LABEL=MYRAID ${var.raid_mount_dir}"
    ]
    connection {
      type = "ssh"
      user = "${var.ansible_ssh_user}"
      host = "${element(aws_instance.db.*.public_ip, count.index)}"
      timeout = "1m"
      private_key = "${file(var.private_key)}"
    }
  }
}


# Logging
resource "aws_cloudwatch_log_group" "db_log_group" {
  count = "${signum(var.db_count)}"
  name = "mizuno-db"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_stream" "mongo_log_stream" {
  count = "${var.db_count}"
  log_group_name = "${aws_cloudwatch_log_group.db_log_group.name}"
  name = "${format("mizuno-db-mongo%03d", count.index + 1)}"
}

resource "aws_cloudwatch_log_stream" "db_log_stream" {
  count = "${var.db_count}"
  log_group_name = "${aws_cloudwatch_log_group.db_log_group.name}"
  name = "${format("mizuno-db%03d", count.index + 1)}"
}


data "template_file" "db_log_conf_template" {
  count = "${var.db_count}"
  template = "${file("${path.module}/files/conf/db-awslogs.cfg")}"
  vars {
    mongo_log_path = "/var/log/mongodb"
    db_log_group = "${aws_cloudwatch_log_group.db_log_group.name}"
    mongo_log_stream_instance = "${element(aws_cloudwatch_log_stream.mongo_log_stream.*.name, count.index)}"
    log_stream_instance = "${element(aws_cloudwatch_log_stream.db_log_stream.*.name, count.index)}"
  }
}



# alert
resource "aws_cloudwatch_metric_alarm" "db-cpu-alert" {
  count = "${var.db_count}"
  alarm_name = "${element(aws_instance.db.*.tags.Name, count.index)}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 10
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 60
  statistic = "Average"
  threshold = 80
  dimensions {
    InstanceId = "${element(aws_instance.db.*.id, count.index)}"
  }
}


# DNS name resolution
resource "aws_route53_record" "db_dns_records" {
  count = "${var.db_count}"
  name = "${element(aws_instance.db.*.tags.Name, count.index)}"
  type = "A"
  ttl = 300
  zone_id = "${aws_route53_zone.routing_to_zone.id}"
  records = ["${element(aws_instance.db.*.public_ip, count.index)}"]
}


# Load Balancing
resource "aws_elb" "db_lb" {
  depends_on = ["aws_s3_bucket_policy.log_bucket_policy"]
  count = "${signum(var.db_count)}"
  name = "mizuno-db"
  availability_zones = ["${var.tokyo_azs}"]
  access_logs {
    bucket = "${aws_s3_bucket.private_bucket.bucket}"
    bucket_prefix = "${var.db_access_log_bucket_prefix}"
    interval = 5
  }
  listener {
    instance_port = 27017
    instance_protocol = "TCP"
    lb_port = "${var.db_port}"
    lb_protocol = "TCP"
  }
  health_check {
    healthy_threshold = 2
    interval = 20
    target = "TCP:27017"
    timeout = 5
    unhealthy_threshold = 2
  }
}


resource "aws_elb_attachment" "db_lb_attachment" {
  count = "${var.db_count}"
  elb = "${aws_elb.db_lb.0.id}"
  instance = "${element(aws_instance.db.*.id, count.index)}"
}

resource "aws_route53_record" "db_lb_record" {
  count = "${signum(var.db_count)}"
  name = "mizuno-db"
  type = "A"
  zone_id = "${aws_route53_zone.routing_to_zone.id}"
  alias {
    evaluate_target_health = true
    name = "${aws_elb.db_lb.dns_name}"
    zone_id = "${aws_elb.db_lb.zone_id}"
  }
}

# Create inventory
resource "null_resource" "db_inventory" {
  count = "${signum(var.db_count)}"
  depends_on = ["null_resource.init-inventory"]
  provisioner  "local-exec" {
    command = "echo \"\n[db]\n${join("\n", formatlist("%s ansible_ssh_user=%s ansible_ssh_private_key_file=%s", aws_instance.db.*.public_ip, var.ansible_ssh_user, var.private_key))}\" >> ${var.inventory_path}"
  }
}
