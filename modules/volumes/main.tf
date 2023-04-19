terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

resource "lxd_volume" "k8s_volumes" {
  name = "k8s_volumes"
  pool = "k8s_storage_pool"
}
