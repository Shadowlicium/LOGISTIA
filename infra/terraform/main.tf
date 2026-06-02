terraform {
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
module "vm_web" {
  source        = "./modules/vm"
  name          = "web-apache"
  target_node   = var.proxmox_node
  vmid          = var.vmid_start + 10
  cores         = 1
  memory        = 1024
  rootfs_size   = "8"
  storage       = var.proxmox_storage
  bridge        = var.proxmox_bridge
  vlan          = var.vlan_dmz
  ip            = "10.10.10.10/24"
  gateway       = var.gateway_dmz
  ostemplate    = var.proxmox_ostemplate
  root_password = var.root_password
  ssh_keys      = compact([var.ssh_public_key])
}
module "vm_db" {
  source        = "./modules/vm"
  name          = "db-postgres"
  target_node   = var.proxmox_node
  vmid          = var.vmid_start + 20
  cores         = 2
  memory        = 2048
  rootfs_size   = "12"
  storage       = var.proxmox_storage
  bridge        = var.proxmox_bridge
  vlan          = var.vlan_db
  ip            = "10.10.20.10/24"
  gateway       = var.gateway_db
  ostemplate    = var.proxmox_ostemplate
  root_password = var.root_password
  ssh_keys      = compact([var.ssh_public_key])
}

module "vm_grafana" {
  source        = "./modules/vm"
  name          = "grafana"
  target_node   = var.proxmox_node
  vmid          = var.vmid_start + 11
  cores         = 1
  memory        = 1024
  rootfs_size   = "8"
  storage       = var.proxmox_storage
  bridge        = var.proxmox_bridge
  vlan          = var.vlan_dmz
  ip            = "10.10.10.11/24"
  gateway       = var.gateway_dmz
  ostemplate    = var.proxmox_ostemplate
  root_password = var.root_password
  ssh_keys      = compact([var.ssh_public_key])
}

module "vm_postfix" {
  source        = "./modules/vm"
  name          = "postfix-mail"
  target_node   = var.proxmox_node
  vmid          = var.vmid_start + 12
  cores         = 1
  memory        = 1024
  rootfs_size   = "10"
  storage       = var.proxmox_storage
  bridge        = var.proxmox_bridge
  vlan          = var.vlan_dmz
  ip            = "10.10.10.12/24"
  gateway       = var.gateway_dmz
  ostemplate    = var.proxmox_ostemplate
  root_password = var.root_password
  ssh_keys      = compact([var.ssh_public_key])
}

module "vm_ollama" {
  source        = "./modules/vm"
  name          = "ollama-ia"
  target_node   = var.proxmox_node
  vmid          = var.vmid_start + 21
  cores         = 2
  memory        = 4096
  rootfs_size   = "16"
  storage       = var.proxmox_storage
  bridge        = var.proxmox_bridge
  vlan          = var.vlan_db
  ip            = "10.10.20.11/24"
  gateway       = var.gateway_db
  ostemplate    = var.proxmox_ostemplate
  root_password = var.root_password
  ssh_keys      = compact([var.ssh_public_key])
}

module "vm_runner" {
  source        = "./modules/vm"
  name          = "gh-runner"
  target_node   = var.proxmox_node
  vmid          = var.vmid_start + 31
  cores         = 1
  memory        = 2048
  rootfs_size   = "10"
  storage       = var.proxmox_storage
  bridge        = var.proxmox_bridge
  vlan          = var.vlan_runner
  ip            = "10.10.30.10/24"
  gateway       = var.gateway_runner
  ostemplate    = var.proxmox_ostemplate
  root_password = var.root_password
  ssh_keys      = compact([var.ssh_public_key])
}

module "vm_backup" {
  source        = "./modules/vm"
  name          = "backup"
  target_node   = var.proxmox_node
  vmid          = var.vmid_start + 99
  cores         = 1
  memory        = 1024
  rootfs_size   = "12"
  storage       = var.proxmox_storage
  bridge        = var.proxmox_bridge
  vlan          = var.vlan_backup
  ip            = "10.10.99.10/24"
  gateway       = var.gateway_backup
  ostemplate    = var.proxmox_ostemplate
  root_password = var.root_password
  ssh_keys      = compact([var.ssh_public_key])
}
