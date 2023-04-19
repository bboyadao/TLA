output "instances" {
  value = [for i, j in module.instance.instances : "${i}: ${j.ip_address}"]
}

output "master_key" {
  value     = module.keys.master_key.private_key_pem
  sensitive = true
}
output "mode_key" {
  value     = module.keys.node_key.private_key_pem
  sensitive = true
}

output "network" {
  value = module.network.network_name
}

output "ansible_inventory" {
  value = module.ansible_inventory.hosts
  sensitive = false
}