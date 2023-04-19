


resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/templates/hosts.tpl",
    {
      master-leader = [for host in var.servers: host if startswith(host.name, "master-leader") ]
      master = [for host in var.servers: host if startswith(host.name, "master-") ]
      others = {
        for node, _ in var.bootstrap: node => [ for host, data in var.servers: data.ip_address if startswith(host, node)]
      #{
      #  "master" = [
      #    "10.10.1.202",
      #    "10.10.1.89",
      #  ]
      #  "worker" = [
      #    "10.10.1.200",
      #  ]
      #}
      }

    }
  )
  filename = "${path.module}/./hosts.cfg"
}
