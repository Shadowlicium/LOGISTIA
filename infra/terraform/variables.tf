variable "proxmox_url" {
  description = "URL de l'API Proxmox (ex: https://proxmox.local:8006/api2/json)"
  type        = string
}

variable "proxmox_user" {
  type = string
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type    = string
  default = "pve"
}

variable "proxmox_storage" {
  type    = string
  default = "local-lvm"
}

variable "proxmox_bridge" {
  type    = string
  default = "vmbr0"
}

variable "vlan_dmz" {
  description = "VLAN ID pour la DMZ (web, Grafana, mail)"
  type        = number
  default     = 10
}

variable "vlan_db" {
  description = "VLAN ID pour la base de données et Ollama"
  type        = number
  default     = 20
}

variable "vlan_runner" {
  description = "VLAN ID pour le GitHub runner self-hosted"
  type        = number
  default     = 30
}

variable "vlan_backup" {
  description = "VLAN ID pour le serveur de backup"
  type        = number
  default     = 99
}

variable "gateway_dmz" {
  description = "Passerelle pour le VLAN DMZ"
  type        = string
  default     = "10.10.10.1"
}

variable "gateway_db" {
  description = "Passerelle pour le VLAN DB"
  type        = string
  default     = "10.10.20.1"
}

variable "gateway_runner" {
  description = "Passerelle pour le VLAN Runner"
  type        = string
  default     = "10.10.30.1"
}

variable "gateway_backup" {
  description = "Passerelle pour le VLAN Backup"
  type        = string
  default     = "10.10.99.1"
}

variable "proxmox_ostemplate" {
  description = "Chemin du template LXC Proxmox pour les conteneurs"
  type        = string
  default     = "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

variable "ssh_public_key" {
  description = "Clé SSH publique pour l'accès aux conteneurs"
  type        = string
  default     = ""
}

variable "root_password" {
  description = "Mot de passe root provisoire pour l'installation initiale"
  type        = string
  sensitive   = true
}

variable "vmid_start" {
  type    = number
  default = 100
}
