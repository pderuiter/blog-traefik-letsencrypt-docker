provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure

  # Importing the cloud image as a VM disk is done over SSH on the node.
  ssh {
    agent    = true
    username = var.proxmox_ssh_username
  }
}
