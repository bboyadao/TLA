terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

resource "lxd_profile" "k8s_profile" {
  name        = var.name
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
      network = var.network
    }
  }

  device {
    name = "root"
    type = "disk"

    properties = {
      pool = var.storage_pool
      path = "/"
    }
  }
}
