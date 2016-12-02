resource "aws_key_pair" "mizuno_key" {
  key_name = "aws_mizuno"
  public_key = "${file("${var.public_key}")}"
}