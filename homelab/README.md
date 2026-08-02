## OpenTofu

Variables use the `TF_VAR_*` prefix and are defined in `tofu/variables.tf`. Run from the repository root:

```sh
mise run tofu:plan
mise run tofu -- plan
```

## Ansible

Run from `homelab/ansible` with the 1Password environment loaded:

```sh
mise run ansible:syntax
mise run ansible:ping
mise run ansible:check
mise run ansible:apply
```

Hosts use mDNS (`proxmox.local`, `homelab.local`, `shared.local`, `smb.local`, `sftpgo.local`, `kino.local`, and `qbittorrent.local`). During initial setup, override their DHCP addresses and request SSH password authentication if needed:

```sh
mise run playbook -- playbooks/site.yml --ask-pass -e proxmox_ansible_host=192.168.1.x -e homelab_ansible_host=192.168.1.y -e shared_ansible_host=192.168.1.z -e smb_ansible_host=192.168.1.w -e sftpgo_ansible_host=192.168.1.s -e qbittorrent_ansible_host=192.168.1.v
```

SSH host-key checking is required. Before the first connection to each IP or mDNS name, compare its Ed25519 fingerprint with the fingerprint shown on the host console, then add the verified key to `~/.ssh/known_hosts`:

```sh
# Run on the host console.
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub

# Run locally; compare this fingerprint before appending the key.
ssh-keyscan -t ed25519 <host-or-ip> 2>/dev/null | ssh-keygen -lf -
ssh-keyscan -H -t ed25519 <host-or-ip> >> ~/.ssh/known_hosts
```

Required secrets:

- `TF_VAR_ssh_public_key`: root SSH public key.
- `TF_VAR_friend_ssh_public_key`: SSH public key for the `shared` VM only.
- `TF_VAR_proxmox_password`: Proxmox `root@pam` password.
- `SAMBA_PASSWORD` or `TF_VAR_samba_password`: Samba password for `divaltor`.
- `QBITTORRENT_PASSWORD`: qBittorrent Web UI password for `admin`.
- `TAILSCALE_AUTH_KEY` or `TF_VAR_tailscale_auth_key`: one reusable, pre-approved key authorized for `tag:homelab` and `tag:shared`.
- `SFTPGO_INSTALLATION_CODE`: strong value of at least 20 characters required to claim the initial SFTPGo administrator.

### SFTPGo file server

The dedicated `sftpgo` LXC (ID 105) has 2 cores, 1 GiB RAM, and mounts
`/media/cold/shared` at `/mnt/share`. Deploy it with:

```sh
mise run tofu:apply
mise run playbook -- playbooks/site.yml
```

Use `https://sftpgo.local` for private administration and
`sftpgo.local:2022` for SFTP. The standard Funnel URL serves the public
WebClient, while port `8443` on the same URL serves WebDAV for Finder. Funnel
requires MagicDNS, tailnet HTTPS, and the `funnel` node attribute for
`tag:homelab`; it does not provide public native SFTP or SMB. The public
WebClient listener disables WebAdmin and the REST API.

### Shared NixOS VM

The `shared` VM (ID 104) runs NixOS 26.05 with 10 host CPU cores, 16 GiB RAM, a 160 GiB disk, and 4 GiB swap. OpenTofu boots the pinned installer ISO, then `nixos-anywhere` installs the configuration from `nixos/` with Disko.

```sh
mise run tofu:plan
mise run tofu:apply
mise run nixos:install-shared -- 192.168.1.x
mise run playbook -- playbooks/vm_shared.yml
```

Replace the IP with the VM's DHCP address, or set `SHARED_INSTALL_HOST` and omit it. The installer uses local Nix when available and otherwise uses the pinned official Docker image. Sources are locked in `nixos/flake.lock`.

> **Warning:** Re-running `nixos-anywhere` repartitions the disk and destroys its data. Use `nixos-rebuild` or a deployment tool for later updates.

Keep the two SSH keys in separate variables. The shared VM advertises only `tag:shared`; other hosts advertise `tag:homelab`. Do not make the shared VM ephemeral.

Tailscale policy is managed outside this repository. Add `tag:shared` to `tagOwners` and grant access only to the owner and friend:

```hujson
{
  groups: {
    "group:shared-users": ["owner@example.com", "friend@example.com"],
  },
  tagOwners: {
    "tag:shared": ["owner@example.com"],
  },
  grants: [
    {
      src: ["group:shared-users"],
      dst: ["tag:shared"],
      ip: ["tcp:22"],
    },
  ],
}
```

Replace the example identities and merge this into the existing policy. Keep the friend out of `tagOwners`; ownership permits assigning the tag, not connecting to the host.

### Plex first-run claim

Plex is available at <https://kino.local/web>. For first setup, get a short-lived token from <https://plex.tv/claim> and run:

```sh
PLEX_CLAIM_TOKEN=claim-xxxx mise run ansible:apply
```

### qBittorrent login

The Web UI is available at <https://qt.local> and <https://torrent.local>. Sign in as `admin` with `QBITTORRENT_PASSWORD`.

Downloads go to `/media/cold/downloads`. Files are preallocated, and completed torrents stop automatically.
