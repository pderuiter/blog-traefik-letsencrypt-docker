output "vm_ipv4_addresses" {
  description = "IPv4 address of each VM"
  value       = { for name, vm in var.vms : name => split("/", vm.ipv4_address)[0] }
}

output "ansible_inventory" {
  description = "Ansible inventory for ansible/site.yml (terraform output -raw ansible_inventory > ../ansible/inventory.yml)"
  value = yamlencode({
    all = {
      vars = {
        ansible_user = var.vm_username
      }
      children = {
        for group in local.groups : group => {
          hosts = {
            for name, vm in var.vms : name => {
              ansible_host = split("/", vm.ipv4_address)[0]
            } if vm.group == group
          }
        }
      }
    }
  })
}
