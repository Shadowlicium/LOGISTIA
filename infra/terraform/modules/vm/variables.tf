variable "name" { type = string }
variable "target_node" { type = string }
variable "vmid" { type = number }
variable "cores" { type = number }
variable "memory" { type = number }
variable "scsihw" { type = string, default = "virtio-scsi-pci" }
variable "disk_size" { type = string }
variable "storage" { type = string }
variable "net_model" { type = string, default = "virtio" }
variable "bridge" { type = string }
variable "vlan" { type = number }
variable "cicustom" { type = any, default = null }
