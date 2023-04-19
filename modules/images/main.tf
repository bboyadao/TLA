terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

resource "lxd_cached_image" "debian11" {
  source_remote = "images"
  source_image  = "debian/11"
}
