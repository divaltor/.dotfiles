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

Hosts default to mDNS (`proxmox.local`, `homelab.local`, `shared.local`, `smb.local`, `kino.local`, `qbittorrent.local`). qBittorrent's Web UI is also published as `qt.local` and `torrent.local`. For first bootstrap before mDNS works, override DHCP IPs and use SSH password auth where needed:

```sh
mise run playbook -- playbooks/site.yml --ask-pass -e proxmox_ansible_host=192.168.1.x -e homelab_ansible_host=192.168.1.y -e shared_ansible_host=192.168.1.z -e smb_ansible_host=192.168.1.w -e qbittorrent_ansible_host=192.168.1.v
```

Required 1Password environment variables for Ansible:

- `TF_VAR_ssh_public_key` — public key installed into root `authorized_keys`.
- `TF_VAR_friend_ssh_public_key` — friend's public key, installed only on the `shared` VM.
- `TF_VAR_proxmox_password` — password for OpenTofu `root@pam` Proxmox authentication.
- `SAMBA_PASSWORD` or `TF_VAR_samba_password` — password for Samba user `divaltor`.
- `QBITTORRENT_PASSWORD` — password for the qBittorrent Web UI `admin` user.
- `TAILSCALE_AUTH_KEY` or `TF_VAR_tailscale_auth_key` — reusable auth key authorized for both `tag:homelab` and `tag:shared`, used only when a host is not already joined to Tailscale. Tagged devices have node-key expiry disabled by default. This is one key value, not a comma-separated list.

### Shared NixOS VM

The `shared` VM (ID 104) runs the current stable NixOS 26.05 release with 8 host CPU cores, 12 GiB RAM, a 160 GiB disk, and a declarative 4 GiB swapfile. OpenTofu boots the checksum-pinned `nixos-cloud-init-installer` v2.6.0 ISO and injects both SSH keys with cloud-init. Then `nixos-anywhere` partitions the empty disk with Disko and installs the configuration from `nixos/`. Debian is never installed.

```sh
mise run tofu:plan
mise run tofu:apply
mise run nixos:install-shared -- 192.168.1.x
mise run playbook -- playbooks/vm_shared.yml
```

Replace `192.168.1.x` with the VM's DHCP address, or set `SHARED_INSTALL_HOST` in the 1Password environment and omit the argument. The controller uses a local Nix installation when available; otherwise it runs `nixos-anywhere` through the checksum-pinned official `nixos/nix` Docker image. For Docker, the script authorizes a throwaway SSH key in the temporary installer because OrbStack cannot mount the 1Password agent socket; that key disappears when the VM reboots, and only the two configured keys are copied to the final system. The NixOS system itself is built on the installer VM, so the Apple Silicon controller does not build an x86_64 system. Re-running `nixos-anywhere` repartitions the disk and destroys its data; use `nixos-rebuild` or a deployment tool for later configuration updates. The installer ISO remains attached, but the installed `scsi0` disk has boot priority.

The NixOS, Disko, and nixos-anywhere sources are exact revisions recorded in `nixos/flake.lock` and fetched with Git smart HTTP rather than GitHub archive tarballs. The installer refuses to start unless it sees the NixOS installer running from tmpfs and the expected blank 160 GiB `scsi0` disk.

Create one Tailscale key as **reusable**, **pre-approved** (when device approval is enabled), and authorized for both `tag:homelab` and `tag:shared`; do not make this persistent VM ephemeral. The shared VM advertises only `tag:shared`, while existing hosts continue to advertise only `tag:homelab`. For stronger long-term automation, replace the reusable key with an OAuth client that can mint tagged auth keys.

Keep the two SSH public keys in separate variables: `TF_VAR_ssh_public_key` and `TF_VAR_friend_ssh_public_key`. OpenTofu passes them as two `authorized_keys` entries. Do not join SSH keys with commas; a comma-separated value is not a valid `authorized_keys` list and makes independent key removal harder.

Tailscale policy is managed outside this repository. Add `tag:shared` to `tagOwners`, then grant only the owner and friend access. A minimal policy fragment is:

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

Replace the example identities and merge these sections into the existing policy. Keep the friend out of `tagOwners`; tag ownership controls who may assign the server identity, not who may connect to it.

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
