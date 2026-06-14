variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint"
  type        = string
  sensitive   = false
}

variable "proxmox_api_token" {
  description = "Proxmox API token (format: user@realm!token=secret)"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key installed into VM root authorized_keys"
  type        = string
  sensitive   = false
}
