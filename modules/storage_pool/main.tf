terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}
resource "lxd_storage_pool" "k8s_storage_pool" {
  name   = "k8s_storage_pool"
  driver = "zfs"
  config = {
    "zfs.pool_name" = "k8s_storage_pool"
    source          = "/dev/sda1"
  }
}
