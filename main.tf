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
    "master" : 3,
    "worker" : 4
  }
}

locals {
  instances = flatten([
  for kind, scale in var.bootstrap:
    [for i in range(scale): "${kind}-${i}"]
  ])

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
