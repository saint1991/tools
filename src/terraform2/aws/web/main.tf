
provider "aws" {
  region = "ap-northeast-1"
}

module "web" {
  source = "../modules/web"

  api_count = 2

  db_count = 2
  shutdown_behavior = "terminate"

  raid_replication_factor = 2
  raid_level = 0

  volume_force_detach = true
  bucket_force_destroy = true
}