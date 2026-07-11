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

Hosts default to mDNS (`proxmox.local`, `homelab.local`, `smb.local`, `kino.local`, `qbittorrent.local`). qBittorrent's Web UI is also published as `qt.local` and `torrent.local`. For first bootstrap before Avahi works, override DHCP IPs and use SSH password auth:

```sh
mise run playbook -- playbooks/site.yml --ask-pass -e proxmox_ansible_host=192.168.1.x -e homelab_ansible_host=192.168.1.y -e smb_ansible_host=192.168.1.z -e qbittorrent_ansible_host=192.168.1.w
```

Required 1Password environment variables for Ansible:

- `TF_VAR_ssh_public_key` — public key installed into root `authorized_keys`.
- `TF_VAR_proxmox_password` — password for OpenTofu `root@pam` Proxmox authentication.
- `SAMBA_PASSWORD` or `TF_VAR_samba_password` — password for Samba user `divaltor`.
- `QBITTORRENT_PASSWORD` — password for the qBittorrent Web UI `admin` user.
- `TAILSCALE_AUTH_KEY` or `TF_VAR_tailscale_auth_key` — auth key used only when a host is not already joined to Tailscale.

### Plex first-run claim

The `kino` LXC installs Plex Media Server and serves it at `https://kino.local/web`.
For first setup, or if the server appears as only the generic Plex web UI, claim it with a fresh short-lived token from <https://plex.tv/claim>:

```sh
PLEX_CLAIM_TOKEN=claim-xxxx mise run ansible:apply
```

The claim token expires quickly, so generate it immediately before running Ansible.

### qBittorrent login

The qBittorrent Web UI is available at `https://qt.local` and `https://torrent.local`.
Sign in as `admin` using `QBITTORRENT_PASSWORD` from the 1Password environment.
Ansible stores only qBittorrent's salted PBKDF2 hash and updates it when the secret changes.

Downloads are written to `/media/cold/downloads`. qBittorrent preallocates files and
stops each torrent when its download completes (global share ratio `0`, action `Stop`).
