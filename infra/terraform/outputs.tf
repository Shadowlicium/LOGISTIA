output "web_vmid" {
  value = proxmox_vm_qemu.web.vmid
  description = "VMID du serveur web"
}

# Ajouter outputs pour chaque VM créée
