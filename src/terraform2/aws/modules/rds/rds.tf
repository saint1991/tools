
resource "aws_rds_cluster" "rds_cluster" {
  cluster_identifier = "rds-mizuno"
  master_username = "${var.rds_master_user}"
  master_password = "${var.rds_master_pass}"
  final_snapshot_identifier = "${var.rds_snapshot_name}"
  availability_zones = [
    "${var.tokyo_zone_a}",
    "${var.tokyo_zone_c}"
  ]
  backup_retention_period = "${var.rds_backup_retension_days}"
  port = 3306
}

resource "aws_rds_cluster_instance" "rds_instances" {
  cluster_identifier = "${aws_rds_cluster.rds_cluster.id}"
  count = "${var.rds_cluster_size}"
  identifier = "${format("mizuno-rds-%03d", count.index + 1)}"
  instance_class = "${var.rds_instance_type}"
}