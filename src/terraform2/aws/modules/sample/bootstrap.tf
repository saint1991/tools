
resource "null_resource" "init-inventory" {
  provisioner "local-exec" {
    command = "rm -f $$PWD/../ansible/aws/inventory"
  }
}

resource "null_resource" "ansible-provisioning" {
  depends_on = ["aws_instance.api", "aws_instance.db"]
  provisioner "local-exec" {
    command = "ansible-playbook -i ${var.inventory_path} ${var.ansible_path}/site.yml"
  }
}