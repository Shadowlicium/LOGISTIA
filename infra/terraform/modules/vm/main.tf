resource "proxmox_lxc" "this" {
  hostname    = var.name
  target_node = var.target_node
  vmid        = var.vmid
  ostemplate  = var.ostemplate
  password    = var.root_password
  cores       = var.cores
  memory      = var.memory
  swap        = var.swap
  rootfs      = "${var.storage}:${var.rootfs_size}"
  net0        = "name=eth0,bridge=${var.bridge},tag=${var.vlan},ip=${var.ip},gw=${var.gateway},firewall=1"
  features    = {
    nesting = var.nesting
  }
  onboot       = true
  unprivileged = true
  ssh_keys     = var.ssh_keys
}
