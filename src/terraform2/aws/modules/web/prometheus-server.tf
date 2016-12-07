
# instance
resource "aws_instance" "prometheus" {
  count = "${signum(var.prometheus_is_required)}"
  depends_on = ["null_resource.init-inventory"]
  tags {
    Name = "mizuno-prometheus"
  }
  ami = "${var.amazon_linux_ami}"
  instance_type = "${var.micro_instance}"
  key_name = "${aws_key_pair.mizuno_key.key_name}"
  disable_api_termination = false
  instance_initiated_shutdown_behavior = "${var.shutdown_behavior}"
  monitoring = true
  iam_instance_profile = "${aws_iam_instance_profile.ec2_instance_iam_profile.name}"

  provisioner "file" {
    content = "${data.template_file.prometheus_log_conf_template.rendered}"
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
resource "aws_ebs_volume" "prometheus_volume" {
  count = "${var.raid_replication_factor}"
  tags {
    Name = "${format("mizuno-prometheus-volume%03d", count.index + 1)}"
  }
  availability_zone = "${var.tokyo_region}a"
  size = 10
  type = "${var.volume_gp2}"
}


resource "aws_volume_attachment" "prometheus_volume_attachment" {
  count = "${var.raid_replication_factor}"
  device_name = "${format("/dev/sd%s", element(var.device_alphabets, count.index))}"
  instance_id = "${aws_instance.prometheus.id}"
  volume_id = "${element(aws_ebs_volume.prometheus_volume.*.id, count.index)}"
  force_detach = "${var.volume_force_detach}"
}


resource "null_resource" "prometheus_raid" {
  depends_on = ["aws_volume_attachment.prometheus_volume_attachment"]
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
      host = "${aws_instance.prometheus.public_ip}"
      timeout = "1m"
      private_key = "${file(var.private_key)}"
    }
  }
}


# Logging
resource "aws_cloudwatch_log_group" "prometheus_log_group" {
  count = "${signum(var.prometheus_is_required)}"
  name = "mizuno-prometheus"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_stream" "prometheus_log_stream" {
  count = "${signum(var.prometheus_is_required)}"
  log_group_name = "${aws_cloudwatch_log_group.prometheus_log_group.name}"
  name = "mizuno-prometheus"
}

resource "aws_cloudwatch_log_stream" "prometheus_instance_log_stream" {
  count = "${signum(var.prometheus_is_required)}"
  log_group_name = "${aws_cloudwatch_log_group.prometheus_log_group.name}"
  name = "mizuno-prometheus-instance"
}


data "template_file" "prometheus_log_conf_template" {
  count = "${signum(var.prometheus_is_required)}"
  template = "${file("${path.module}/files/conf/prometheus-awslogs.cfg")}"
  vars {
    prometheus_log_path = "/var/log/prometheus"
    prometheus_log_group = "${aws_cloudwatch_log_group.prometheus_log_group.name}"
    prometheus_log_stream_instance = "${aws_cloudwatch_log_stream.prometheus_log_stream.name}"
    log_stream_instance = "${aws_cloudwatch_log_stream.prometheus_instance_log_stream.name}"
  }
}



# alert
resource "aws_cloudwatch_metric_alarm" "prometheus-cpu-alert" {
  count = "${signum(var.prometheus_is_required)}"
  alarm_name = "${aws_instance.prometheus.tags.Name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 10
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 60
  statistic = "Average"
  threshold = 80
  dimensions {
    InstanceId = "${aws_instance.prometheus.id}"
  }
}


# DNS name resolution
resource "aws_route53_record" "prometheus_dns_records" {
  count = "${signum(var.prometheus_is_required)}"
  name = "${aws_instance.prometheus.tags.Name}"
  type = "A"
  ttl = 300
  zone_id = "${aws_route53_zone.routing_to_zone.id}"
  records = ["${aws_instance.prometheus.public_ip}"]
}


# Create inventory
resource "null_resource" "prometheus_inventory" {
  count = "${signum(var.prometheus_is_required)}"
  depends_on = ["null_resource.init-inventory"]
  provisioner  "local-exec" {
    command = "echo \"\n[prometheus]\n${format("%s ansible_ssh_user=%s ansible_ssh_private_key_file=%s", aws_instance.prometheus.public_ip, var.ansible_ssh_user, var.private_key)}\" >> ${var.inventory_path}"
  }
}
