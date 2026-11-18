variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint, for example https://pve.example.com:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox VE API token in the form user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification of the Proxmox API (self-signed lab certificates)"
  type        = bool
  default     = false
}

variable "proxmox_ssh_username" {
  description = "SSH user on the Proxmox node, used by the provider to import the cloud image"
  type        = string
  default     = "root"
}

variable "node_name" {
  description = "Proxmox node that hosts the VMs"
  type        = string
}

variable "datastore_id" {
  description = "Datastore for VM disks and the cloud-init drive"
  type        = string
  default     = "local-lvm"
}

variable "image_datastore_id" {
  description = "Datastore (with the iso content type) that stores the downloaded cloud image"
  type        = string
  default     = "local"
}

variable "image_url" {
  description = "Ubuntu 24.04 cloud image"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "bridge" {
  description = "Network bridge for the VMs"
  type        = string
  default     = "vmbr0"
}

variable "vlan_id" {
  description = "Optional VLAN tag for the VM network interface"
  type        = number
  default     = null
}

variable "gateway" {
  description = "IPv4 default gateway for the VMs"
  type        = string
}

variable "dns_servers" {
  description = "DNS servers the VMs use during provisioning"
  type        = list(string)
  default     = ["9.9.9.9", "1.1.1.1"]
}

variable "vm_username" {
  description = "User created by cloud-init; Ansible connects as this user"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key installed for vm_username"
  type        = string
}

variable "vms" {
  description = "VMs to create. Key is the VM name, group is the Ansible inventory group (traefik), ipv4_address is in CIDR notation."
  type = map(object({
    group        = string
    vm_id        = optional(number)
    ipv4_address = string
    cores        = optional(number, 2)
    memory_mb    = optional(number, 2048)
    disk_gb      = optional(number, 20)
  }))

  validation {
    condition     = alltrue([for vm in values(var.vms) : contains(["traefik"], vm.group)])
    error_message = "Each VM needs group = \"traefik\"."
  }
}
