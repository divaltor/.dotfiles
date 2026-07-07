## OpenTofu

All variables are named like `TF_VAR_*` and used by `tofu/variables.tf`

Run from the repository root:

```sh
mise run tofu:plan
mise run tofu -- plan
```

## Ansible

Run from `homelab/ansible` with 1Password environment loaded:

```sh
mise run ansible:syntax
mise run ansible:ping
mise run ansible:check
mise run ansible:apply
```

Hosts default to mDNS (`proxmox.local`, `homelab.local`, `smb.local`, `kino.local`). For first bootstrap before Avahi works, override DHCP IPs and use SSH password auth:

```sh
mise run playbook -- playbooks/site.yml --ask-pass -e proxmox_ansible_host=192.168.1.x -e homelab_ansible_host=192.168.1.y -e smb_ansible_host=192.168.1.z
```

Required 1Password environment variables for Ansible:

- `TF_VAR_ssh_public_key` — public key installed into root `authorized_keys`.
- `SAMBA_PASSWORD` or `TF_VAR_samba_password` — password for Samba user `divaltor`.
- `TAILSCALE_AUTH_KEY` or `TF_VAR_tailscale_auth_key` — auth key used only when a host is not already joined to Tailscale.
