
provider "google" {
    credentials = "${file("credentials/account.json")}"
    project = "${var.project}"
    region = "${var.region}"
}
