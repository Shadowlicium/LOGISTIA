variable "proxmox_url" {
  description = "URL de l'API Proxmox (ex: https://proxmox.local:8006/api2/json)"
  type = string
}

variable "proxmox_user" {
  type = string
}

variable "proxmox_password" {
  type = string
  sensitive = true
}

variable "proxmox_node" {
  type = string
  default = "pve"
}

variable "proxmox_storage" {
  type = string
  default = "local-lvm"
}

variable "proxmox_bridge" {
  type = string
  default = "vmbr0"
}

variable "vmid_start" {
  type = number
  default = 100
}
