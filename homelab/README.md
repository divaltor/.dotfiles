# Homelab

## Storage

- Samsung 970 EVO Plus 500 GB (`S4EVNX0T102553F`): Proxmox ext4/LVM system disk.
- WD_BLACK SN850X 4 TB (`252639802020`): single-disk ZFS `vmdata`, storage `fast-nvme`, all VM/LXC disks.
  The `vmdata/qbittorrent` child dataset has a 1 TB quota, is shared with Samba,
  and is intentionally excluded from backup.
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
`sftpgo.local`, `kino.local`, `qbittorrent.local`, and `monitoring.local`.
Tasks load secrets from 1Password. Always verify a changed SSH host key at the
host console.

## Monitoring

`monitoring.local` runs Prometheus, Grafana, Loki, Tempo, Alloy, and
prometheus-pve-exporter in LXC 106. Grafana is available at
`https://monitoring.local`. Alloy accepts bearer-authenticated OTLP on ports
4317 and 4318, stores metrics in Prometheus, logs in Loki, and traces in Tempo,
and also forwards all signals to SigNoz. node_exporter runs on the Proxmox host
and every repository-managed Debian guest. LXC diskstats and ZFS collectors are
disabled
because Proxmox exposes host-wide values inside containers; pve_exporter
supplies each LXC's aggregate disk and network I/O.
The Proxmox node exporter also collects SMART and NVMe health data. pve_exporter
still supplies hypervisor-level CPU, memory, disk, and network metrics for the
`shared` VM, even though no agent is installed in that VM.
cAdvisor runs as a pinned Docker container on the `homelab` VM, the only VM
that hosts Docker workloads, and exposes container metrics to Prometheus on
port 8080. The `docker-logs` role runs a pinned Grafana Alloy container on the
same VM. It discovers containers through the Docker socket, labels stdout with
the container name as `service_name`, and writes directly to Loki on
`monitoring.local:3100`; this path bypasses the OTLP gateway and SigNoz. Loki's
HTTP port is exposed to the homelab network for this direct write path.
Containers whose names match `docker_logs_exclude_pattern` are skipped. Apps
that also push the same logs over OTLP should be added to that pattern to avoid
duplicate Loki entries.

The monitoring LXC copies `/etc/pve/pve-root-ca.pem` through Ansible and trusts
the Proxmox cluster CA. pve_exporter connects to `divaltor-dc.local:8006` with
certificate verification enabled.

Grafana provisions these pinned community dashboards in the `Homelab` folder:

- Node Exporter Full (1860, revision 45);
- Proxmox via Prometheus (10347, revision 1);
- ZFS Pool Performance and Health (24987, revision 2);
- Prometheus Self-Monitoring (25537, revision 1);
- cAdvisor exporter - Docker container Overview (21743, revision 1).

The downloaded JSON is checksum-pinned and its Prometheus datasource reference
is normalized to the provisioned `prometheus` datasource UID. Ansible removes
dashboard files that are no longer in this list.

The 1Password environment used by `mise` must provide:

- `GRAFANA_ADMIN_PASSWORD` for the initial Grafana admin account;
- `PVE_MONITORING_TOKEN` for `prometheus@pve!monitoring`;
- `OTLP_TOKEN` for Alloy ingress and SigNoz forwarding.

Create the API identity once on the Proxmox host, then save the printed token in
1Password:

```sh
pveum user add prometheus@pve
pveum aclmod / -user prometheus@pve -role PVEAuditor
pveum user token add prometheus@pve monitoring -privsep 0
```

The `shared` NixOS VM is intentionally not scraped by node_exporter. Its live
NixOS definition is outside this checkout. After that definition is imported,
enable `services.prometheus.exporters.node` there and add `div.local:9100` to
`monitoring_node_exporter_targets`.

> **Shared VM warning:** The live `shared` VM (`div.local`, VMID 104) contains
> NixOS services and encrypted configuration missing from `nixos/shared.nix`.
> Do not run `nixos-anywhere` or `nixos-rebuild` from this checkout. Keep the
> working system generation until the complete live configuration is imported.
