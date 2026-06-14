## Standarts

When edit any Opentofu or Ansible files ensure it is up to date with other part. Ansible and Terraform are coupled together into single setup layet. Terraform setup Proxmox and resources in it, Ansible setups VMs, LXC and other stuff Opentofu can't.

## Homelab specs

Hardware

- CPU: AMD Ryzen AI 9 HX PRO 370 (12C/24T, Zen 5/5c, AVX-512 VNNI)
- iGPU: Radeon 890M, 16 CU RDNA 3.5, ~5.3 TFLOPS FP16, shares system RAM
- NPU: XDNA 2, 50 TOPS
- RAM: 64 GB total (DDR5 4800 CL40)
- Disks:
- System: 128 GB AirDisk used by Proxmos host
- VMs storage: 500 GB Samsung 970 EVO Plus NVMe
- ZFS Pool (files, archives, media): 4 disks Seagate IronWolf 6 TB in ZFS Z1 raid

## OpenTofu

All variables are named like `TF_VAR_*` and used by `tofu/variables.tf`

Run from the repository root:

```sh
op run --environment 5hfpicsmni2xf56r2dv5gumz5e -- tofu -chdir=homelab/tofu plan
```

## Ansible

Run from `homelab/ansible` with 1Password environment loaded:

```sh
op run --environment 5hfpicsmni2xf56r2dv5gumz5e -- ansible-playbook playbooks/site.yml --syntax-check
op run --environment 5hfpicsmni2xf56r2dv5gumz5e -- ansible all -m ping
op run --environment 5hfpicsmni2xf56r2dv5gumz5e -- ansible-playbook playbooks/site.yml --check --diff
op run --environment 5hfpicsmni2xf56r2dv5gumz5e -- ansible-playbook playbooks/site.yml
```

Hosts default to mDNS (`proxmox.local`, `homelab.local`, `smb.local`). For first bootstrap before Avahi works, override DHCP IPs and use SSH password auth:

```sh
op run --environment 5hfpicsmni2xf56r2dv5gumz5e -- ansible-playbook playbooks/site.yml --ask-pass -e proxmox_ansible_host=192.168.1.x -e homelab_ansible_host=192.168.1.y -e smb_ansible_host=192.168.1.z
```

Required 1Password environment variables for Ansible:

- `TF_VAR_ssh_public_key` — public key installed into root `authorized_keys`.
- `SAMBA_PASSWORD` or `TF_VAR_samba_password` — password for Samba user `divaltor`.
