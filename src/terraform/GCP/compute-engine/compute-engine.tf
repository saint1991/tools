
resource "google_compute_disk" "disk" {
    name = "disk"
    zone = "${var.zone}"
    size = 20
    type = "pd-ssd"
}

resource "google_compute_instance" "comupute" {

  name = "compute"
  zone = "${var.zone}"
  machine_type = "${lookup(var.instance_type, "small")}"

  disk {
      image = "${lookup(var.os, "centos7")}"
  }

  disk {
      disk = "${google_compute_disk.disk.name}"
      auto_delete = false
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = "${var.compute_ip}"
    }
  }
}

output "compute_endpoint" {
  value = "${google_compute_instance.comupute.network_interface.0.access_config.0.assigned_nat_ip}"
}
