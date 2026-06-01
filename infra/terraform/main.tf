terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = true
}

# Exemple de module VM (simple) pour la Web (DMZ VLAN 10)
module "vm_web" {
  source = "./modules/vm"
  name = "web-apache"
  target_node = var.proxmox_node
  vmid = var.vmid_start + 10
  cores = 2
  memory = 2048
  disk_size = "20G"
  storage = var.proxmox_storage
  bridge = var.proxmox_bridge
  vlan = 10
  cicustom = {
    user = "local:snippets/cloudinit-userdata-web.yaml"
  }
}

module "vm_db" {
  source = "./modules/vm"
  name = "db-postgres"
  target_node = var.proxmox_node
  vmid = var.vmid_start + 20
  cores = 2
  memory = 4096
  disk_size = "40G"
  storage = var.proxmox_storage
  bridge = var.proxmox_bridge
  vlan = 20
}

module "vm_grafana" {
  source = "./modules/vm"
  name = "grafana"
  target_node = var.proxmox_node
  vmid = var.vmid_start + 11
  cores = 2
  memory = 2048
  disk_size = "20G"
  storage = var.proxmox_storage
  bridge = var.proxmox_bridge
  vlan = 10
}

module "vm_mailcow" {
  source = "./modules/vm"
  name = "mailcow"
  target_node = var.proxmox_node
  vmid = var.vmid_start + 12
  cores = 2
  memory = 4096
  disk_size = "50G"
  storage = var.proxmox_storage
  bridge = var.proxmox_bridge
  vlan = 10
}

module "vm_ollama" {
  source = "./modules/vm"
  name = "ollama-ia"
  target_node = var.proxmox_node
  vmid = var.vmid_start + 21
  cores = 4
  memory = 8192
  disk_size = "60G"
  storage = var.proxmox_storage
  bridge = var.proxmox_bridge
  vlan = 20
}

module "vm_runner" {
  source = "./modules/vm"
  name = "gh-runner"
  target_node = var.proxmox_node
  vmid = var.vmid_start + 31
  cores = 2
  memory = 4096
  disk_size = "30G"
  storage = var.proxmox_storage
  bridge = var.proxmox_bridge
  vlan = 30
}

module "vm_backup" {
  source = "./modules/vm"
  name = "backup"
  target_node = var.proxmox_node
  vmid = var.vmid_start + 99
  cores = 2
  memory = 2048
  disk_size = "50G"
  storage = var.proxmox_storage
  bridge = var.proxmox_bridge
  vlan = 99
}
