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

Hosts use mDNS (`proxmox.local`, `homelab.local`, `shared.local`, `smb.local`, `kino.local`, and `qbittorrent.local`). During initial setup, override their DHCP addresses and request SSH password authentication if needed:

```sh
mise run playbook -- playbooks/site.yml --ask-pass -e proxmox_ansible_host=192.168.1.x -e homelab_ansible_host=192.168.1.y -e shared_ansible_host=192.168.1.z -e smb_ansible_host=192.168.1.w -e qbittorrent_ansible_host=192.168.1.v
```

Required secrets:

- `TF_VAR_ssh_public_key`: root SSH public key.
- `TF_VAR_friend_ssh_public_key`: SSH public key for the `shared` VM only.
- `TF_VAR_proxmox_password`: Proxmox `root@pam` password.
- `SAMBA_PASSWORD` or `TF_VAR_samba_password`: Samba password for `divaltor`.
- `QBITTORRENT_PASSWORD`: qBittorrent Web UI password for `admin`.
- `TAILSCALE_AUTH_KEY` or `TF_VAR_tailscale_auth_key`: one reusable, pre-approved key authorized for `tag:homelab` and `tag:shared`.

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
