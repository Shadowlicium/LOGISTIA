terraform {
  backend "local" {}

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.108.0"
    }
  }
}

provider "proxmox" {
  endpoint = replace(var.proxmox_url, "/api2/json$", "")
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = true
}

# Conteneurs LXC pour réduire la consommation mémoire et s'adapter aux 24 Go max
moved {
  from = module.vm_web
  to   = module.vm_web[0]
}

module "vm_web" {
  count       = var.deploy_web ? 1 : 0
  source      = "./modules/vm"
  name        = "web-apache"
  target_node = var.proxmox_node
  vmid        = var.vmid_start + 10
  cores       = 1
  memory      = 1024
  rootfs_size = "8"
  storage     = var.proxmox_storage
  bridge      = var.proxmox_bridge
  vlan        = var.vlan_dmz
  ip          = "10.10.10.10/24"
  gateway     = var.gateway_dmz
  ostemplate  = var.proxmox_ostemplate
  ssh_keys    = compact([var.ssh_public_key])
}

moved {
  from = module.vm_db
  to   = module.vm_db[0]
}

module "vm_db" {
  count       = var.deploy_db ? 1 : 0
  source      = "./modules/vm"
  name        = "db-postgres"
  target_node = var.proxmox_node
  vmid        = var.vmid_start + 20
  cores       = 2
  memory      = 2048
  rootfs_size = "12"
  storage     = var.proxmox_storage
  bridge      = var.proxmox_bridge
  vlan        = var.vlan_db
  ip          = "10.10.20.10/24"
  gateway     = var.gateway_db
  ostemplate  = var.proxmox_ostemplate
  ssh_keys    = compact([var.ssh_public_key])
}

moved {
  from = module.vm_mail_backend
  to   = module.vm_mail_backend[0]
}

module "vm_mail_backend" {
  count       = var.deploy_mail_data ? 1 : 0
  source      = "./modules/vm"
  name        = "mail-data"
  target_node = var.proxmox_node
  vmid        = var.vmid_start + 22
  cores       = 1
  memory      = 1024
  rootfs_size = "10"
  storage     = var.proxmox_storage
  bridge      = var.proxmox_bridge
  vlan        = var.vlan_db
  ip          = "10.10.20.12/24"
  gateway     = var.gateway_db
  ostemplate  = var.proxmox_ostemplate
  ssh_keys    = compact([var.ssh_public_key])
}

moved {
  from = module.vm_grafana
  to   = module.vm_grafana[0]
}

module "vm_grafana" {
  count       = var.deploy_grafana ? 1 : 0
  source      = "./modules/vm"
  name        = "grafana"
  target_node = var.proxmox_node
  vmid        = var.vmid_start + 40
  cores       = 1
  memory      = 1024
  rootfs_size = "8"
  storage     = var.proxmox_storage
  bridge      = var.proxmox_bridge
  vlan        = var.vlan_security
  ip          = "10.10.40.10/24"
  gateway     = var.gateway_security
  ostemplate  = var.proxmox_ostemplate
  ssh_keys    = compact([var.ssh_public_key])
}

moved {
  from = module.vm_postfix
  to   = module.vm_postfix[0]
}

module "vm_postfix" {
  count       = var.deploy_mail_relay ? 1 : 0
  source      = "./modules/vm"
  name        = "mail-relay"
  target_node = var.proxmox_node
  vmid        = var.vmid_start + 12
  cores       = 1
  memory      = 1024
  rootfs_size = "10"
  storage     = var.proxmox_storage
  bridge      = var.proxmox_bridge
  vlan        = var.vlan_dmz
  ip          = "10.10.10.12/24"
  gateway     = var.gateway_dmz
  ostemplate  = var.proxmox_ostemplate
  ssh_keys    = compact([var.ssh_public_key])
}

moved {
  from = module.vm_ollama
  to   = module.vm_ollama[0]
}

module "vm_ollama" {
  count       = var.deploy_ollama ? 1 : 0
  source      = "./modules/vm"
  name        = "ollama-ia"
  target_node = var.proxmox_node
  vmid        = var.vmid_start + 41
  cores       = 2
  memory      = 6144
  rootfs_size = "30"
  storage     = var.proxmox_storage
  bridge      = var.proxmox_bridge
  vlan        = var.vlan_security
  ip          = "10.10.40.11/24"
  gateway     = var.gateway_security
  ostemplate  = var.proxmox_ostemplate
  ssh_keys    = compact([var.ssh_public_key])
}

moved {
  from = module.vm_backup
  to   = module.vm_backup[0]
}

module "vm_backup" {
  count       = var.deploy_backup ? 1 : 0
  source      = "./modules/vm"
  name        = "backup"
  target_node = var.proxmox_node
  vmid        = var.vmid_start + 99
  cores       = 1
  memory      = 1024
  rootfs_size = "12"
  storage     = var.proxmox_storage
  bridge      = var.proxmox_bridge
  vlan        = var.vlan_backup
  ip          = "10.10.99.10/24"
  gateway     = var.gateway_backup
  ostemplate  = var.proxmox_ostemplate
  ssh_keys    = compact([var.ssh_public_key])
}
