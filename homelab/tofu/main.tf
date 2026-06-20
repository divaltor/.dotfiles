# ============================================================
# Proxmox Infrastructure — main.tf
# ============================================================
# Resources match the current running state on node "divaltor-dc".
# After importing, run `tofu plan` to verify zero changes.
# ============================================================

# ─── VM: homelab (100) ──────────────────────────────────────

moved {
  from = proxmox_virtual_environment_vm.diva_lab
  to   = proxmox_virtual_environment_vm.homelab
}

import {
  to = proxmox_storage_directory.local
  id = "local"
}

resource "proxmox_storage_directory" "local" {
  id      = "local"
  path    = "/var/lib/vz"
  content = ["backup", "import", "iso", "snippets", "vztmpl"]
}

resource "proxmox_download_file" "debian_13_cloud_image" {
  content_type       = "import"
  datastore_id       = "local"
  file_name          = "debian-13-generic-amd64.qcow2"
  node_name          = "divaltor-dc"
  url                = "https://cloud.debian.org/images/cloud/trixie/20260601-2496/debian-13-generic-amd64-20260601-2496.qcow2"
  checksum           = "97675b27e69153002c4e13644e36200c8f9067f661dca00918c54f1cacbdb88d4bff8c0fbf5cf5d63a0397bdf0cc472d7a6372bae5281bf7ced756249c10f8a2"
  checksum_algorithm = "sha512"
}

resource "proxmox_virtual_environment_vm" "homelab" {
  node_name = "divaltor-dc"
  vm_id     = 100
  name      = "homelab"
  started   = true
  on_boot   = true

  bios    = "ovmf"
  machine = "q35"

  operating_system {
    type = "l26"
  }

  cpu {
    cores   = 24
    type    = "host"
    sockets = 1
  }

  memory {
    dedicated = 32678
    floating  = 24576
  }

  agent {
    enabled = true
  }

  disk {
    interface    = "scsi0"
    datastore_id = "fast-nvme"
    file_format  = "raw"
    import_from  = proxmox_download_file.debian_13_cloud_image.id
    size         = 300
    iothread     = true
    discard      = "on"
  }

  efi_disk {
    datastore_id = "fast-nvme"
    type         = "4m"
  }

  initialization {
    datastore_id = "fast-nvme"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "root"
      keys     = [trimspace(var.ssh_public_key)]
    }
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  scsi_hardware = "virtio-scsi-single"

  serial_device {}

  boot_order = ["scsi0", "net0"]

  lifecycle {
    ignore_changes = [
      disk[0].file_id, # auto-assigned by Proxmox
    ]
  }
}

# ─── LXC: smb (101) — Samba NAS container ───────────────────

resource "proxmox_download_file" "debian_13_lxc_template" {
  content_type       = "vztmpl"
  datastore_id       = "local"
  file_name          = "debian-13-standard_13.1-2_amd64.tar.zst"
  node_name          = "divaltor-dc"
  url                = "http://download.proxmox.com/images/system/debian-13-standard_13.1-2_amd64.tar.zst"
  checksum           = "5aec4ab2ac5c16c7c8ecb87bfeeb10213abe96db6b85e2463585cea492fc861d7c390b3f9c95629bf690b95e9dfe1037207fc69c0912429605f208d5cb2621f8"
  checksum_algorithm = "sha512"
}

resource "proxmox_virtual_environment_container" "smb" {
  node_name     = "divaltor-dc"
  vm_id         = 101
  started       = true
  start_on_boot = true
  unprivileged  = false

  description = "Samba file server — ZFS-backed storage via bind mount"

  operating_system {
    type             = "debian"
    template_file_id = proxmox_download_file.debian_13_lxc_template.id
  }

  cpu {
    architecture = "amd64"
    cores        = 1
  }

  console {
    enabled   = true
    tty_count = 2
    type      = "tty"
  }

  memory {
    dedicated = 512
    swap      = 256
  }

  disk {
    datastore_id = "fast-nvme"
    size         = 8
  }

  network_interface {
    name     = "eth0"
    bridge   = "vmbr0"
    firewall = false
  }

  initialization {
    hostname = "smb"

    dns {
      servers = ["1.1.1.1", "8.8.8.8"]
    }

  }

  features {
    nesting = true
  }

  # Required for Tailscale to create tailscale0 inside the LXC.
  device_passthrough {
    path = "/dev/net/tun"
  }

  # ZFS pool bind mount: /media/cold on host → /mnt/share in container
  mount_point {
    volume = "/media/cold"
    path   = "/mnt/share"
  }

  lifecycle {
    ignore_changes = [
      operating_system,  # template_file_id mismatch with state
      features[0].mount, # managed outside provider
      features[0].fuse,
      features[0].keyctl,
      features[0].mknod,
    ]
  }
}

# ─── Storage layout (managed at host level) ─────────────────
# Host disk (128 GB): ext4 root on pve/root, no LVM-Thin.
#   local-lvm was removed — all space given to root for host packages.
# VM disk (500 GB): LVM-Thin pool "fast-nvme" — all VM/CT disks here.
# HDD pool: 4× 6TB ZFS RAIDZ1 "pool" (~22TB) — bulk data.
# ────────────────────────────────────────────────────────────

# ─── ZFS Pool (documented, not managed by OpenTofu) ─────────
# ZFS pool "pool" across 4× 6TB HDDs (RAIDZ1), ~22TB total.
# ZFS datasets are managed via Ansible (see ansible/roles/zfs/).
# The Proxmox API exposes ZFS info but the bpg provider does not
# manage ZFS pools/datasets directly.
