terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}
resource "lxd_network" "k8s_network" {
  name = "k8s_network"

  config = {
    "ipv4.address"  = var.ipv4
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
