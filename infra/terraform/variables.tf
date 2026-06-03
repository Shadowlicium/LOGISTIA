variable "proxmox_url" {
  description = "URL de l'API Proxmox (ex: https://proxmox.local:8006/). The provider strips a trailing /api2/json if present."
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
  default = "proxmox"
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
  description = "VLAN ID pour les services data"
  type        = number
  default     = 20
}

variable "vlan_security" {
  description = "VLAN ID pour la supervision et les services IA"
  type        = number
  default     = 40
}

variable "vlan_backup" {
  description = "VLAN ID pour le serveur de backup"
  type        = number
  default     = 99
}

variable "gateway_dmz" {
  description = "Passerelle pour le VLAN DMZ"
  type        = string
  default     = "10.10.10.254"
}

variable "gateway_db" {
  description = "Passerelle pour le VLAN DB"
  type        = string
  default     = "10.10.20.254"
}

variable "gateway_security" {
  description = "Passerelle pour le VLAN supervision/IA"
  type        = string
  default     = "10.10.40.254"
}

variable "gateway_backup" {
  description = "Passerelle pour le VLAN Backup"
  type        = string
  default     = "10.10.99.254"
}

variable "proxmox_ostemplate" {
  description = "Chemin du template LXC Proxmox pour les conteneurs"
  type        = string
  default     = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
}

variable "ssh_public_key" {
  description = "Clé SSH publique pour l'accès aux conteneurs"
  type        = string
  default     = ""
}

variable "vmid_start" {
  type    = number
  default = 100
}
