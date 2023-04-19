
module "keys" {
  source = "./modules/keys"
}

module "network" {
  source = "./modules/networks"
  ipv4 = "10.10.1.1/24"
}

module "storage_pool" {
  source = "./modules/storage_pool"
}

module "volumes" {
  source = "./modules/volumes"
  depends_on = [
    module.storage_pool
  ]
}

module "profile" {
  source           = "./modules/profile"
  name = "k8s"
  depends_on = [
    module.network,
    module.volumes
  ]
  storage_pool = module.storage_pool.storage_pool_name
  network   = module.network.network_name
}

module "images" {
  source = "./modules/images"
}

module "instance" {
  source = "./modules/server"
  servers_name = local.ins
  image = module.images.debian
  profile = [module.profile.profiles_name]
}

module "container_files" {
  source = "./modules/container_file"
  servers = module.instance.instances
  master_key_public =  module.keys.master_key.public_key_openssh
}

module "exec" {
  source = "./modules/executors"
  servers = module.instance.instances
  private_key = module.keys.master_key.private_key_pem

  depends_on = [
    module.instance.instances,
    module.container_files
  ]
}

module "ansible_inventory" {
  source = "./modules/templating"
  servers = module.instance.instances
  bootstrap = var.bootstrap
}
