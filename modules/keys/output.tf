output "master_key" {
  value = tls_private_key.master_key
}

output "node_key" {
  value = tls_private_key.node_key
}