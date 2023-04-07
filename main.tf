terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

variable "pool" {
  type    = string
  default = "pool2"
}

variable "volume" {
  type    = string
  default = "volume1"
}

variable "network" {
  type    = string
  default = "global"
}
variable "profile" {
  type    = string
  default = "default"
}

variable "bootstrap" {
  type = map(string)
  default = {
    "master" : 1,
    "worker" : 1
  }
}

locals {
  instances = flatten([
  for kind, scale in var.bootstrap:
    [for i in range(scale): "${kind}-${i}"]
  ])
}

resource "tls_private_key" "master_key" {
  algorithm = "ECDSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "node_key" {
  algorithm = "ECDSA"
  rsa_bits  = 4096
}


resource "lxd_container" "server" {
  for_each = toset(local.instances)
  name      = each.value
  image     = "images:debian/10"
  ephemeral = false
  profiles  = ["default"]
  config = {
    "boot.autostart" = true
  }

  limits = {
    cpu = 2
  }
}
output "instances" {
  value = lxd_container.server[*]
}

output "master_key" {
  value = tls_private_key.master_key
  sensitive = true
}

resource "lxd_container_file" "file1" {
  depends_on = [lxd_container.server]
  for_each = lxd_container.server
  container_name     = each.value.name
  target_file        = "/foo/bar.txt"
  content = tls_private_key.master_key.private_key_pem
  create_directories = true
}