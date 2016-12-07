
provider "aws" {
  region = "ap-northeast-1"
}

module "rds" {
  source = "../modules/rds"
}