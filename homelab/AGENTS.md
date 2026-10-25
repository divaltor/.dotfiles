## Standarts

When edit any Opentofu or Ansible files ensure it is up to date with other part. Ansible and Terraform are coupled together into single setup layet. Terraform setup Proxmox and resources in it, Ansible setups VMs, LXC and other stuff Opentofu can't.

## Homelab specs

Hardware

- CPU: AMD Ryzen AI 9 HX PRO 370 (12C/24T, Zen 5/5c, AVX-512 VNNI)
- iGPU: Radeon 890M, 16 CU RDNA 3.5, ~5.3 TFLOPS FP16, shares system RAM
- NPU: XDNA 2, 50 TOPS
- RAM: 64 GB total (DDR5 4800 CL40)
- Disks:
  - System: 500 GB Samsung 970 EVO Plus NVMe used by the Proxmox host
  - VM/LXC storage: 4 TB WD_BLACK SN850X, single-disk ZFS pool `vmdata`, Proxmox storage `fast-nvme`
  - Files, archives, and media: 4 disks Seagate IronWolf 6 TB in ZFS RAIDZ1 pool `pool`
  - Retired: 128 GB AirDisk; do not reuse it for persistent data

Any containers and VMs should provide host CPUs to get maximum performance from modern CPU instructions, not virtualized one.

## Secrets

Do not pass multiline private keys through the 1Password Environment tab; it
does not preserve line breaks. Read SSH keys directly from their 1Password item
with `op read` and the `?ssh-format=openssh` query parameter. Never print secret
field values while inspecting item metadata.

Use the 1Password Environments MCP server (`1password` in Amp) to list
Environments and variable names and to add or rotate variables. It never
returns secret values, so do not ask it for them and do not fall back to
`op environment read` or `printenv`. Execute tasks with the existing `mise`
tasks, which load the Environment through `op run`.

The homelab Environment belongs to the personal 1Password account; pass its
`account_id` from `op account list --format=json`. Do not update an existing
variable unless the task is explicitly a rotation, and do not mount the homelab
Environment as a local `.env` file. Deleting a variable requires the desktop
app. The MCP server is unavailable in orbs; do not attempt secret changes there.

## Other

For any additional info how to run Opentofu or Ansible read README.md
