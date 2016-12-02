
provider "aws" {
  region = "${var.tokyo_region}"
}

module "sample" {
  source = "modules/sample"


}
