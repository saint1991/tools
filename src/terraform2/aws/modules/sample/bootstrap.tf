
resource "null_resource" "init-inventory" {
  provisioner "local-exec" {
    command = "rm -f $$PWD/../ansible/aws/inventory"
  }
}