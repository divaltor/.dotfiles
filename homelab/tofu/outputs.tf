# ============================================================
# Outputs — consumed by Ansible inventory
# ============================================================

output "vm_homelab_info" {
  description = "homelab VM details"
  value = {
    vmid = proxmox_virtual_environment_vm.homelab.vm_id
    name = proxmox_virtual_environment_vm.homelab.name
    node = proxmox_virtual_environment_vm.homelab.node_name
  }
}

output "ct_smb_info" {
  description = "Samba LXC details"
  value = {
    vmid     = proxmox_virtual_environment_container.smb.vm_id
    hostname = "smb"
    ip       = "192.168.1.50"
    node     = proxmox_virtual_environment_container.smb.node_name
  }
}

output "all_ips" {
  description = "All static IPs for inventory (DHCP VMs use mDNS hostnames)"
  value = {
    smb = "192.168.1.50"
  }
}
