variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint"
  type        = string
  sensitive   = false
}

variable "proxmox_password" {
  description = "Password for root@pam Proxmox API authentication"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key installed into VM root authorized_keys"
  type        = string
  sensitive   = false
}
