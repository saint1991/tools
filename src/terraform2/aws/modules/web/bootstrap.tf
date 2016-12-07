
resource "null_resource" "init-inventory" {
  provisioner "local-exec" {
    command = "rm -f ${var.inventory_path}"
  }
}

resource "null_resource" "ansible-provisioning" {
  depends_on = [
    "aws_instance.api",
    "aws_instance.db",
    "null_resource.db_inventory",
    "null_resource.api_inventory"
  ]
  provisioner "local-exec" {
    command = "ansible-playbook -i ${var.inventory_path} ${var.ansible_path}/site.yml"
  }
}

resource "aws_s3_bucket" "private_bucket" {
  bucket = "${var.log_bucket}"
  force_destroy = "${var.bucket_force_destroy}"
}

resource "aws_s3_bucket_policy" "log_bucket_policy" {
  bucket = "${aws_s3_bucket.private_bucket.bucket}"
  policy = "${data.aws_iam_policy_document.log_bucket_policy_document.json}"
}

data "aws_iam_policy_document" "log_bucket_policy_document" {
  statement {
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.log_bucket}/${var.api_access_log_bucket_prefix}/AWSLogs/${var.account_id}/*",
      "arn:aws:s3:::${var.log_bucket}/${var.db_access_log_bucket_prefix}/AWSLogs/${var.account_id}/*"
    ]
    principals {
      identifiers = ["${lookup(var.elb_principals, var.tokyo_region)}"]
      type = "AWS"
    }
  }
}


resource "aws_iam_instance_profile" "ec2_instance_iam_profile" {
  name = "logging-instance-profile-mizuno"
  roles = ["${aws_iam_role.logging_enabled.name}"]
}

resource "aws_iam_role" "logging_enabled" {
  name = "logging-mizuno"
  assume_role_policy = "${data.aws_iam_policy_document.assume_policy_document.json}"
}

resource "aws_iam_role_policy" "logging_policy" {
  name = "logging-policy-mizuno"
  policy = "${data.aws_iam_policy_document.logging_policy.json}"
  role = "${aws_iam_role.logging_enabled.id}"
}

data "aws_iam_policy_document" "assume_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "logging_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}