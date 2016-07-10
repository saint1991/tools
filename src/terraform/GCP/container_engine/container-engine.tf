
variable "master_username" {}
variable "master_password" {}
variable "node_count" {}

resource "google_container_cluster" "api_cluster" {

  name = "api-servers"
  zone = "${var.zone}"

  initial_node_count = "${var.node_count}"
  node_config {
    machine_type = "${lookup(var.instance_type, "small")}"
    disk_size_gb = 20
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring"
    ]
  }
  logging_service = "logging.googleapis.com"
  monitoring_service = "monitoring.googleapis.com"

  master_auth {
    username = "${var.master_username}"
    password = "${var.master_password}"
  }
}

output "kubernetes_master" {
  value = "${google_container_cluster.api_cluster.endpoint}"
}