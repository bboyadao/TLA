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
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_private_key" "node_key" {
  algorithm = "ECDSA"
  rsa_bits  = 4096
}


resource "lxd_container" "servers" {
  for_each = toset(local.instances)
  name      = each.value
  image     = "images:debian/11"
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
  value = [for i, j in lxd_container.servers: "${i}: ${j.ip_address}"]
}

output "master_key" {
  value = tls_private_key.master_key.private_key_pem
  sensitive = true
}

resource "lxd_container_file" "files" {
  depends_on = [lxd_container.servers]
  for_each = lxd_container.servers
  container_name     = each.value.name
  target_file        = "/root/.ssh/authorized_keys"
  content = tls_private_key.master_key.public_key_openssh
  create_directories = true
}

resource "null_resource" "provision" {
  depends_on = [
    lxd_container_file.files,
    lxd_container.servers
  ]

  for_each = lxd_container.servers

  connection {
    type        = "ssh"
    user        = "root"
    host        = each.value.ip_address
    private_key = tls_private_key.master_key.private_key_pem
  }

  provisioner "local-exec" {
    command = "lxc exec ${each.value.name} -- apt-get update -qq"
  }

  provisioner "local-exec" {
    command = "lxc exec ${each.value.name} -- apt-get install -y openssh-server python3"
  }

  provisioner "local-exec" {
    command = "lxc exec ${each.value.name} -- sed -i -E 's/#?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
  }

  provisioner "local-exec" {
    command = "lxc exec ${each.value.name} -- systemctl restart ssh"
  }



  provisioner "remote-exec" {
    inline = [
      "hostname",
    ]
  }
}