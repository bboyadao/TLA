output "hosts" {
  value = local_file.hosts_cfg.content
  sensitive = false
}