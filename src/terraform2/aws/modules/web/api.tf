
# Instance Booting
resource "aws_instance" "api" {

  tags {
    Name = "${format("mizuno-api%03d", count.index + 1)}"
  }

  ami = "${var.amazon_linux_ami}"
  instance_type = "${var.micro_instance}"
  count = "${var.api_count}"
  disable_api_termination = false
  instance_initiated_shutdown_behavior = "${var.shutdown_behavior}"
  key_name = "${aws_key_pair.mizuno_key.key_name}"
  monitoring = true
  iam_instance_profile = "${aws_iam_instance_profile.ec2_instance_iam_profile.name}"

  provisioner "file" {
    content = "${element(data.template_file.api_log_conf_template.*.rendered, count.index)}"
    destination = "/tmp/awslogs.cfg"
    connection {
      type = "ssh"
      user = "${var.ansible_ssh_user}"
      timeout = "1m"
      private_key = "${file(var.private_key)}"
    }
  }
}


# Logging
resource "aws_cloudwatch_log_group" "api_log_group" {
  count = "${signum(var.api_count)}"
  name = "mizuno-api"
  retention_in_days = "7"
}

resource "aws_cloudwatch_log_stream" "nginx_access_log_stream" {
  count = "${var.api_count}"
  log_group_name = "${aws_cloudwatch_log_group.api_log_group.name}"
  name = "${format("mizuno-api-nginx-access%03d", count.index + 1)}"
}

resource "aws_cloudwatch_log_stream" "nginx_error_log_stream" {
  count = "${var.api_count}"
  log_group_name = "${aws_cloudwatch_log_group.api_log_group.name}"
  name = "${format("mizuno-api-nginx-error%03d", count.index + 1)}"
}

resource "aws_cloudwatch_log_stream" "api_log_stream" {
  count = "${var.api_count}"
  log_group_name = "${aws_cloudwatch_log_group.api_log_group.name}"
  name = "${format("mizuno-api%03d", count.index + 1)}"
}


data "template_file" "api_log_conf_template" {
  count = "${var.api_count}"
  template = "${file("${path.module}/files/conf/api-awslogs.cfg")}"
  vars {
    nginx_log_path = "/var/log/nginx"
    api_log_group = "${aws_cloudwatch_log_group.api_log_group.name}"
    nginx_access_log_stream_instance = "${element(aws_cloudwatch_log_stream.nginx_access_log_stream.*.name, count.index)}"
    nginx_error_log_stream_instance = "${element(aws_cloudwatch_log_stream.nginx_error_log_stream.*.name, count.index)}"
    log_stream_instance = "${element(aws_cloudwatch_log_stream.api_log_stream.*.name, count.index)}"
  }
}



# alert
resource "aws_cloudwatch_metric_alarm" "api-cpu-alert" {
  count = "${var.api_count}"
  alarm_name = "${element(aws_instance.api.*.tags.Name, count.index)}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 10
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = 60
  statistic = "Average"
  threshold = 80
  dimensions {
    InstanceId = "${element(aws_instance.api.*.id, count.index)}"
  }
}


# DNS name resolution
resource "aws_route53_record" "api_hosts_records" {
  count = "${var.api_count}"
  name = "${element(aws_instance.api.*.tags.Name, count.index)}"
  type = "A"
  ttl = 300
  zone_id = "${aws_route53_zone.routing_to_zone.id}"
  records = ["${element(aws_instance.api.*.public_ip, count.index)}"]
}


# Load Balancing
resource "aws_elb" "api_lb" {
  depends_on = ["aws_s3_bucket_policy.log_bucket_policy"]
  count = "${signum(var.api_count)}"
  name = "mizuno-api"
  availability_zones = ["${var.tokyo_azs}"]
  access_logs {
    bucket = "${aws_s3_bucket.private_bucket.bucket}"
    bucket_prefix = "${var.api_access_log_bucket_prefix}"
    interval = 5
  }
  listener {
    instance_port = 80
    instance_protocol = "HTTP"
    lb_port = "${var.api_port}"
    lb_protocol = "HTTP"
  }
  health_check {
    healthy_threshold = 2
    interval = 20
    target = "HTTP:80/"
    timeout = 5
    unhealthy_threshold = 2
  }
}

resource "aws_elb_attachment" "api_lb_attachment" {
  count = "${var.api_count}"
  elb = "${aws_elb.api_lb.id}"
  instance = "${element(aws_instance.api.*.id, count.index)}"
}



# Failover handling
resource "aws_route53_record" "api_lb_record" {
  count = "${signum(var.api_count)}"
  name = "mizuno-api"
  type = "A"
  zone_id = "${aws_route53_zone.routing_to_zone.id}"
  set_identifier = "failover_live"
  failover_routing_policy {
    type = "PRIMARY"
  }
  alias {
    evaluate_target_health = true
    name = "${aws_elb.api_lb.dns_name}"
    zone_id = "${aws_elb.api_lb.zone_id}"
  }
}

resource "aws_route53_record" "api_lb_record2" {
  depends_on = ["aws_s3_bucket_object.sorry_page"]
  count = "${signum(var.api_count)}"
  name = "mizuno-api"
  type = "A"
  zone_id = "${aws_route53_zone.routing_to_zone.id}"
  set_identifier = "failover_fail"
  failover_routing_policy {
    type = "SECONDARY"
  }
  alias {
    evaluate_target_health = true
    name = "${aws_s3_bucket.sorry_bucket.website_domain}"
    zone_id = "${aws_s3_bucket.sorry_bucket.hosted_zone_id}"
  }
}

resource "aws_s3_bucket" "sorry_bucket" {
  region = "${var.tokyo_region}"
  bucket = "${aws_route53_record.api_lb_record.name}.${aws_route53_zone.routing_to_zone.name}"
  acl = "public-read"
  force_destroy = "${var.bucket_force_destroy}"
  website {
    index_document = "sorry.html"
    error_document = "sorry.html"
  }
}

resource "aws_s3_bucket_object" "sorry_page" {
  acl = "public-read"
  bucket = "${aws_s3_bucket.sorry_bucket.bucket}"
  key = "sorry.html"
  source = "${path.module}/files/html/sorry.html"
}


# Ansible inventory for provisioning
resource "null_resource" "api_inventory" {
  count = "${signum(var.api_count)}"
  depends_on = ["null_resource.init-inventory"]
  provisioner  "local-exec" {
    command = "echo \"\n[api]\n${join("\n", formatlist("%s ansible_ssh_user=%s ansible_ssh_private_key_file=%s", aws_instance.api.*.public_ip, var.ansible_ssh_user, var.private_key))}\" >> ${var.inventory_path}"
  }
}