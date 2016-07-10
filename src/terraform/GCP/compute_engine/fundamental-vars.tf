
variable "instance_type" {
  type = "map"
  description = "Available Instance Type on GCP"
  default = {
    micro = "f1-micro"
    small = "g1-small"
    standard1 = "n1-standard-1"
    standard2 = "n1-standard-2"
    standard4 = "n1-standard-4"
    standard8 = "n1-standard-8"
    standard16 = "n1-standard-16"
    standard32 = "n1-standard-32"
    highmem2 = "n1-highmem-2"
    highmem4 = "n1-highmem-4"
    highmem8 = "n1-highmem-8"
    highmem16 = "n1-highmem-16"
    highmem32 = "n1-highmem-32"
    highcpu2 = "n1-highcpu-2"
    highcpu4 = "n1-highcpu-4"
    highcpu8 = "n1-highcpu-8"
    highcpu16 = "n1-highcpu-16"
    highcpu32 = "n1-highcpu-32"
  }
}

variable "os" {
    type = "map"
    description = "Available OS Image on GCP"
    default = {
        centos6 = "centos-6-v20160629"
        centos7 = "centos-7-v20160629"
        debian8 = "debian-8-jessie-v20160629"
        opensuse13 = "opensuse-13-2-v20160222"
        redhat6 = "rhel-6-v20160629"
        redhat7 = "rhel-7-v20160629"
        suse13 = "opensuse-13-2-v20160222"
        suse-enterprise11 = "sles-11-sp4-v20160301"
        suse-enterprise12 = "sles-12-sp4-v20160301"
        ubuntu12 = "ubuntu-1204-precise-v20160627"
        ubuntu14 = "ubuntu-1404-trusty-v20160627"
        ubuntu15 = "ubuntu-1510-wily-v20160627"
        ubuntu16 = "ubuntu-1604-xenial-v20160627"
    }
}