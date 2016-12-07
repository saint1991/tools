
// ssh key
variable "public_key" { default = "~/.ssh/aws-kensyu.pub" }
variable "private_key" { default = "~/.ssh/aws-kensyu" }

// regions
variable "tokyo_region" { default = "ap-northeast-1" }
variable "california_region" { default = "us-west-1" }

// availability zones
variable "tokyo_zone_a" { default = "ap-northeast-1a" }
variable "tokyo_zone_c" { default = "ap-northeast-1c" }
variable "tokyo_zones" {
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

variable "rds_master_user" { default = "a14215" }
variable "rds_master_pass" { default = "hogehoge11" } // FIXME thus should be given via a Vault ora  tfvars file
variable "rds_snapshot_name" { default = "mizuno-rds-snapshot"}
variable "rds_backup_retension_days" { default = 7 }
variable "rds_cluster_size" { default = 3 }
variable "rds_instance_type" { default = "db.t2.medium" }