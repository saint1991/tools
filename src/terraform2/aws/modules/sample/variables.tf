
// ssh key
variable "public_key" { default = "~/.ssh/aws-kensyu.pub" }
variable "private_key" { default = "~/.ssh/aws-kensyu" }

// regions
variable "tokyo_region" { default = "ap-northeast-1" }
variable "california_region" { default = "us-west-1" }

// instance_type
variable "micro_instance" { default = "t2.micro" }
variable "large_instance" { default = "c4.large" }

// volume_type
variable "volume_type" { default = "gp2"}

// os
variable "amazon_linux_ami" { default = "ami-0c11b26d" }
variable "redhat_ami" { default = "ami-5de0433c" }

// for ansible
variable "ansible_path" { default = "$PWD/../ansible"}
variable "inventory_path" { default = "$PWD/../ansible/aws/inventory"}
variable "ansible_ssh_user" { default = "ec2-user" }

variable "mongodb_count" { default = 2 }
variable "nodejs_count" { default = 2 }
