
// account
variable "account_id" { default = "670544139128"}

// ssh key
variable "public_key" { default = "~/.ssh/aws-kensyu.pub" }
variable "private_key" { default = "~/.ssh/aws-kensyu" }

// regions
variable "tokyo_region" { default = "ap-northeast-1" }
variable "california_region" { default = "us-west-1" }

// availability zones
variable "tokyo_zone_a" { default = "ap-northeast-1a" }
variable "tokyo_zone_c" { default = "ap-northeast-1c" }
variable "tokyo_azs" {
  type = "list"
  default = [
    "ap-northeast-1a",
    "ap-northeast-1c"
  ]
}

// instance_type
variable "micro_instance" { default = "t2.micro" }
variable "large_instance" { default = "c4.large" }

// volume_type
variable "volume_gp2" { default = "gp2"}
variable "volume_standard" { default = "standard" }
variable "volume_io1" { default = "io1" }
variable "volume_st1" { default = "st1" }

// os
variable "amazon_linux_ami" { default = "ami-0c11b26d" }
variable "redhat_ami" { default = "ami-5de0433c" }

// for ansible
variable "ansible_path" { default = "$PWD/../../ansible"}
variable "inventory_path" { default = "$PWD/../../ansible/aws/inventory"}
variable "ansible_ssh_user" { default = "ec2-user" }


variable "elb_principals" {
  type = "map"
  default = {
    ap-northeast-1 = "582318560864"
    us-west-1 = "027434742980"
  }
}

variable "bucket_force_destroy" { default = false }
variable "shutdown_behavior" { default = "stop" }
variable "volume_force_detach" { default = false }
variable "domain" { default = "saint.com"}
variable "log_bucket" { default = "saint11" }

variable "db_count" { default = 2 }
variable "db_port" { default = 27017 }

variable "db_access_log_bucket_prefix" { default = "logs/db"}
variable "raid_replication_factor" { default = 3 }
variable "raid_level" { default = 0 }
variable "raid_mount_dir" { default = "/mnt/ebs/1" }
variable "device_alphabets" {
  type = "list"
  default = [
    "b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"
  ]
}

variable "api_count" { default = 2 }
variable "api_port" { default = 80 }
variable "api_access_log_bucket_prefix" { default = "logs/api"}

variable "prometheus_is_required" { default = 1 }