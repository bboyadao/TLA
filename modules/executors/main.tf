resource "null_resource" "provision" {

  for_each = var.servers

  connection {
    timeout     = "10"
    type        = "ssh"
    user        = "root"
    host        = each.value.ip_address
    private_key = var.private_key
  }

  provisioner "local-exec" {

#    name = "Update: ${each.value.name}"
    command = "lxc exec ${each.value.name} -- apt-get update -qq"
  }

  provisioner "local-exec" {
#    name = "Install ssh, python: ${each.value.name}"
    command = "lxc exec ${each.value.name} -- apt-get install -y openssh-server python3"
  }

  provisioner "local-exec" {
#    name = "Disable login pass: ${each.value.name}"
    command = "lxc exec ${each.value.name} -- sed -i -E 's/#?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
  }

  provisioner "local-exec" {
#    name = "Reload ssh: ${each.value.name}"
    command = "lxc exec ${each.value.name} -- systemctl restart ssh"
  }

  provisioner "remote-exec" {
    inline = [
      "hostname",
    ]
  }
}
