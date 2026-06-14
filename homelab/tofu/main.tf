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

resource "proxmox_download_file" "debian_13_netinst_iso" {
  content_type       = "iso"
  datastore_id       = "local"
  file_name          = "debian-13.5.0-amd64-netinst.iso"
  node_name          = "divaltor-dc"
  url                = "https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.5.0-amd64-netinst.iso"
  checksum           = "b2be60c555e328b4fa5ebb2d0e5c7ee6bc3eb4250c4dcfd3f78b8d9aec596efdf9f14f10a898c280eb252d50bbac91ea0a2bba29736df0d4985d50d4c8d77519"
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
    cores   = 16
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
    size         = 300
    iothread     = true
    discard      = "on"
  }

  efi_disk {
    datastore_id = "fast-nvme"
    type         = "4m"
  }

  cdrom {
    interface = "ide2"
    file_id   = proxmox_download_file.debian_13_netinst_iso.id
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  scsi_hardware = "virtio-scsi-single"

  boot_order = ["scsi0", "ide2", "net0"]

  lifecycle {
    ignore_changes = [
      cdrom,           # ISO may be ejected after install
      disk[0].file_id, # auto-assigned by Proxmox
    ]
  }
}

# ─── LXC: smb (101) — Samba NAS container ───────────────────

resource "proxmox_download_file" "debian_12_lxc_template" {
  content_type       = "vztmpl"
  datastore_id       = "local"
  file_name          = "debian-12-standard_12.12-1_amd64.tar.zst"
  node_name          = "divaltor-dc"
  url                = "http://download.proxmox.com/images/system/debian-12-standard_12.12-1_amd64.tar.zst"
  checksum           = "50c85eaaece677a3ebe01cc909b83872e9da2a22c29ae652838afce71e83222fdf40f6accecd7d52b180e912fc1f85ecdf7b3fc4d3027da4d865e509a9e76597"
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
    template_file_id = proxmox_download_file.debian_12_lxc_template.id
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
