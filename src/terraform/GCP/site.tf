
module "compute_engine" {
  source = "./compute_engine"
}

variable "master_password" {
  type = "string"
}

module "container_engine" {
  source = "./container_engine"
  master_username = "saint1991"
  master_password = "${var.master_password}"
}