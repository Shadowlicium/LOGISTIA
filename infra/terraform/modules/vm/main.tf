terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.108.0"
    }
  }
}

resource "proxmox_virtual_environment_container" "this" {
  description  = "Managed by Terraform"
  node_name    = var.target_node
  vm_id        = var.vmid
  unprivileged = true

  features {
    nesting = var.nesting
  }

  initialization {
    hostname = var.name

    ip_config {
      ipv4 {
        address = var.ip
        gateway = var.gateway
      }
    }

    user_account {
      password = var.root_password
      keys     = var.ssh_keys
    }
  }

  operating_system {
    template_file_id = var.ostemplate
    type             = "ubuntu"
  }

  network_interface {
    name    = "eth0"
    bridge  = var.bridge
    vlan_id = var.vlan
  }

  disk {
    datastore_id = var.storage
    size         = var.rootfs_size
  }

  memory {
    dedicated = var.memory
    swap      = var.swap
  }

  startup {
    order = 1
  }

  wait_for_ip {
    ipv4 = true
  }
}
