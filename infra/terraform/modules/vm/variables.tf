variable "name" {
  type = string
}

variable "target_node" {
  type = string
}

variable "vmid" {
  type = number
}

variable "ostemplate" {
  type = string
}

variable "root_password" {
  type      = string
  sensitive = true
}

variable "ssh_keys" {
  type    = list(string)
  default = []
}

variable "cores" {
  type = number
}

variable "memory" {
  type = number
}

variable "swap" {
  type = number
  default = 512
}

variable "rootfs_size" {
  type = string
}

variable "storage" {
  type = string
}

variable "bridge" {
  type = string
}

variable "vlan" {
  type = number
}

variable "ip" {
  description = "Adresse IP statique du conteneur avec masque CIDR"
  type        = string
}

variable "gateway" {
  description = "Passerelle pour le conteneur"
  type        = string
}

variable "nesting" {
  type    = bool
  default = true
}
