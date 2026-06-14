terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.90.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true

  ssh {
    username = "root"
    # Uses default SSH agent or ~/.ssh/id_*
    # Set PROXMOX_VE_SSH_USERNAME / PROXMOX_VE_SSH_PASSWORD env vars to override
  }
}
