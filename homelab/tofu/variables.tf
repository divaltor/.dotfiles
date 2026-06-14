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
