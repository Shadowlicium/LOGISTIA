resource "proxmox_vm_qemu" "this" {
  name        = var.name
  target_node = var.target_node
  vmid        = var.vmid
  cores       = var.cores
  memory      = var.memory
  scsihw      = var.scsihw

  disk {
    size    = var.disk_size
    type    = "scsi"
    storage = var.storage
  }

  network {
    model  = var.net_model
    bridge = var.bridge
    tag    = var.vlan
  }

  cicustom = var.cicustom
}
