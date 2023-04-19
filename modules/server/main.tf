terraform {
  required_providers {
    lxd = {
      source = "terraform-lxd/lxd"
    }
  }
}

resource "lxd_container" "servers" {
  for_each  = var.servers_name
  name      = each.value
  image     = var.image
  ephemeral = false
  profiles  = var.profile

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
