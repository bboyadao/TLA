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
    for kind, scale in var.bootstrap :
    [for i in range(scale) : "${kind}-${i}"]
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

resource "lxd_storage_pool" "k8s_storage_pool" {
  name   = "k8s_storage_pool"
  driver = "zfs"
  config = {
    "zfs.pool_name" = "k8s_storage_pool"
    source          = "/dev/sda1"
  }
}


resource "lxd_volume" "k8s_volumes" {
  depends_on = [
    lxd_storage_pool.k8s_storage_pool
  ]
  name = "k8s_volumes"
  pool = "k8s_storage_pool"
}

resource "lxd_network" "k8s_network" {
  name = "k8s_network"

  config = {
    "ipv4.address"  = "10.10.1.1/24"
    "ipv6.address"  = ""
    "ipv4.nat"      = "true"
    "ipv6.nat"      = "true"
    "ipv4.firewall" = "false"
    "ipv6.firewall" : "false"

  }

  #  provisioner "local-exec" {
  #    command     = "sudo firewall-cmd --zone=trusted --change-interface=${lxd_network.k8s_network.name} --permanent"
  #    interpreter = ["/usr/bin/bash", "-c"]
  #  }
}

resource "lxd_profile" "k8s_profile" {
  depends_on = [
    lxd_network.k8s_network,
    lxd_volume.k8s_volumes
  ]
  name        = "k8s"
  description = "k8s profile"
  config = {
    "limits.cpu"         = 4
    "limits.memory"      = "4GB"
    "limits.memory.swap" = "false"
    #    "linux.kernel_modules" = "ip_tables,ip6_tables,nf_nat,overlay,br_netfilter"
    #    "raw.lxc" = <<EOF
    #lxc.apparmor.profile=unconfined
    #lxc.cap.drop=
    #lxc.cgroup.devices.allow=a
    #lxc.mount.auto=proc:rw sys:rw
    #lxc.mount.entry=/lib/modules lib/modules none bind 0 0
    #EOF
    #    "security.privileged" = "true"
    #    "security.nesting" = "true"
  }

  device {
    name = "eth0"
    type = "nic"

    properties = {
      name    = "eth0"
      network = lxd_network.k8s_network.name
    }
  }

  device {
    name = "root"
    type = "disk"

    properties = {
      pool = "k8s_storage_pool"
      path = "/"
    }
  }
}

resource "lxd_cached_image" "debian11" {
  source_remote = "images"
  source_image  = "debian/11"
}

resource "lxd_container" "servers" {
  for_each  = toset(local.instances)
  name      = each.value
  image     = lxd_cached_image.debian11.fingerprint
  ephemeral = false
  profiles  = [lxd_profile.k8s_profile.name]

  config = {
    "linux.kernel_modules"                 = "br_netfilter,overlay"
    "security.syscalls.intercept.mknod"    = true
    "security.syscalls.intercept.setxattr" = true
    "security.privileged"                  = true
    "security.nesting"                     = true
    "raw.lxc"                              = <<EOF
lxc.apparmor.profile=unconfined
lxc.cap.drop=
lxc.cgroup.devices.allow=a
lxc.mount.auto=proc:rw sys:rw
EOF
  }

}

resource "lxd_container_file" "files" {
  depends_on         = [lxd_container.servers]
  for_each           = lxd_container.servers
  container_name     = each.value.name
  target_file        = "/root/.ssh/authorized_keys"
  content            = tls_private_key.master_key.public_key_openssh
  create_directories = true
}

resource "null_resource" "provision" {
  depends_on = [
    lxd_container_file.files,
    lxd_container.servers
  ]

  for_each = lxd_container.servers

  connection {
    timeout     = "10"
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

resource "local_file" "hosts_cfg" {

  content = templatefile("${path.module}/templates/hosts.tpl",
    #Todo: map nodes from var.bootstrap to inventory for ansible!
    {
      master = lxd_container.servers
      worker = lxd_container.servers
    }
  )
  filename = "./ansible/inventory/hosts.cfg"
}

output "instances" {
  value = [for i, j in lxd_container.servers : "${i}: ${j.ip_address}"]
}

output "master_key" {
  value     = tls_private_key.master_key.private_key_pem
  sensitive = true
}

output "network" {
  value = lxd_network.k8s_network.name
}
