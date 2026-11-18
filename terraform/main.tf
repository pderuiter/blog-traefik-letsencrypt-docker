resource "proxmox_download_file" "ubuntu_cloud_image" {
  content_type = "iso"
  datastore_id = var.image_datastore_id
  node_name    = var.node_name
  url          = var.image_url
  file_name    = "noble-server-cloudimg-amd64.img"
  overwrite    = false
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = var.vms

  name      = each.key
  node_name = var.node_name
  vm_id     = each.value.vm_id
  tags      = ["blog", local.project_tag, each.value.group]

  # The Ubuntu cloud image does not ship the QEMU guest agent.
  agent {
    enabled = false
  }

  cpu {
    cores = each.value.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = each.value.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    file_id      = proxmox_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    size         = each.value.disk_gb
    discard      = "on"
  }

  network_device {
    bridge  = var.bridge
    vlan_id = var.vlan_id
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  initialization {
    datastore_id = var.datastore_id

    dns {
      servers = var.dns_servers
    }

    ip_config {
      ipv4 {
        address = each.value.ipv4_address
        gateway = var.gateway
      }
    }

    user_account {
      username = var.vm_username
      keys     = [var.ssh_public_key]
    }
  }
}
