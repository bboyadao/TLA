terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

resource "lxd_container_file" "files" {
  for_each           = var.servers
  container_name     = each.value.name
  target_file        = "/root/.ssh/authorized_keys"
#  content            = tls_private_key.master_key.public_key_openssh
  content            = var.master_key_public

  create_directories = true
}