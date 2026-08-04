# Homelab

## Storage

- Samsung 970 EVO Plus 500 GB (`S4EVNX0T102553F`): Proxmox ext4/LVM system disk.
- WD_BLACK SN850X 4 TB (`252639802020`): single-disk ZFS `vmdata`, storage `fast-nvme`, all VM/LXC disks.
- 4× Seagate IronWolf 6 TB: RAIDZ1 `pool`, mounted at `/media/cold`.
- AirDisk 128 GB: retired; do not use for persistent data.

The Samsung has `pve/root` 430 GB, swap 8 GB, and about 26 GB unassigned.
Proxmox showing 94% “Assigned to LVs” is normal; check real usage with `df -h /`.
ISO and templates in `local` use `/var/lib/vz` on `pve/root`.

## Back up the old host

1. Stop all guests and confirm both pools are healthy:

   ```sh
   zpool status -x
   ```

2. Create `vzdump` archives on `/media/cold` and verify every `.zst` file:

   ```sh
   BUNDLE=/media/cold/pve-reinstall-$(date +%Y%m%d)
   mkdir -p "$BUNDLE/guest-backups"
   vzdump --all 1 --mode stop --compress zstd --dumpdir "$BUNDLE/guest-backups"
   zstd -t "$BUNDLE"/guest-backups/*.zst
   ```

3. Save `/etc/pve`, `/var/lib/pve-cluster/config.db`, and
   `homelab/tofu/terraform.tfstate`. Keep the state private (`0600`).

Do not delete the last verified guest backup. `vmdata` has no mirror, and no
scheduled Proxmox backup job is currently configured. The 2026 recovery bundle
is `/media/cold/pve-reinstall-ready-20260804`.

## Install a new Proxmox host

1. Disconnect the WD and HDDs. Install Proxmox on the Samsung only:
   - ext4/LVM: `swapsize=8`, `maxroot=430`, `minfree=16`, `maxvz=0`;
   - FQDN: `divaltor-dc.local`;
   - network: `192.168.1.19/24`, gateway `192.168.1.1`, bridge `vmbr0`.
2. Reconnect the data disks, verify the new SSH fingerprint, then run:

   ```sh
   mise run ansible:proxmox-host -- -e proxmox_ansible_host=192.168.1.19
   ```

3. Confirm `pool`, `vmdata`, and `fast-nvme` are online. The playbook imports
   existing pools but never creates a pool or wipes a disk.
4. `maxroot` is only an installer limit. If root is smaller than 430 GB:

   ```sh
   lvextend -L 430G -r /dev/pve/root
   ```

## Restore

If `vmdata` survived, copy the saved VM/LXC configs into `/etc/pve`, restore the
original OpenTofu state, and run:

```sh
mise run tofu:plan
mise run tofu:apply
mise run ansible:ping
mise run ansible:apply
```

Review the plan before apply. Without the original state, OpenTofu can try to
recreate existing VMIDs. If `vmdata` was lost, create the replacement storage
first, then restore each archive with `qmrestore` or `pct restore` to
`fast-nvme`.

## Routine commands

```sh
mise run tofu:plan
mise run tofu:apply
mise run ansible:syntax
mise run ansible:check
mise run ansible:apply
```

Hosts use mDNS: `proxmox.local`, `homelab.local`, `div.local`, `smb.local`,
`sftpgo.local`, `kino.local`, and `qbittorrent.local`. Tasks load secrets from
1Password. Always verify a changed SSH host key at the host console.

> **Shared VM warning:** The live `shared` VM (`div.local`, VMID 104) contains
> NixOS services and encrypted configuration missing from `nixos/shared.nix`.
> Do not run `nixos-anywhere` or `nixos-rebuild` from this checkout. Keep the
> working system generation until the complete live configuration is imported.
