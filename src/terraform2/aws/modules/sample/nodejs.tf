
resource "aws_instance" "api" {

  tags {
    Name = "${format("mizuno-api%03d", count.index + 1)}"
  }

  ami = "${var.amazon_linux_ami}"
  instance_type = "${var.micro_instance}"
  count = "${var.nodejs_count}"
  disable_api_termination = false
  instance_initiated_shutdown_behavior = "terminate"
  key_name = "${aws_key_pair.mizuno_key.key_name}"

}

resource "null_resource" "api_inventory" {
  depends_on = ["null_resource.init-inventory"]
  provisioner  "local-exec" {
    command = "echo \"\n[api]\n${join("\n", formatlist("%s ansible_ssh_user=ec2-user ansible_ssh_private_key_file=%s", aws_instance.api.*.public_ip, var.private_key))}\" >> $$PWD/../ansible/aws/inventory"
  }
}
