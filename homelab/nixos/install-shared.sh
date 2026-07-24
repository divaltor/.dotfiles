#!/usr/bin/env bash
set -euo pipefail

for variable in TF_VAR_ssh_public_key TF_VAR_friend_ssh_public_key; do
  if [[ -z "${!variable:-}" ]]; then
    printf 'Required environment variable %s is not set\n' "$variable" >&2
    exit 1
  fi
done

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_host="${1:-${SHARED_INSTALL_HOST:-}}"
if [[ -z "$target_host" ]]; then
  printf 'Pass the VM DHCP address or set SHARED_INSTALL_HOST\n' >&2
  exit 1
fi

if ! ssh \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/dev/null \
  "root@$target_host" '
    set -eu
    . /etc/os-release
    disk=/dev/disk/by-id/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0
    test "$ID" = nixos
    test "${VARIANT_ID:-}" = installer
    test "$(findmnt -n -o FSTYPE /)" = tmpfs
    test -b "$disk"
    test "$(blockdev --getsize64 "$disk")" = 171798691840
    test -z "$(wipefs -n "$disk")"
  '; then
  printf 'Install preflight failed: expected the NixOS installer and a blank 160 GiB scsi0 disk\n' >&2
  exit 1
fi

runtime_dir="$(mktemp -d)"
extra_files="$runtime_dir/extra-files"
trap 'rm -rf "$runtime_dir"' EXIT

install -d -m 0755 "$extra_files/etc/ssh/authorized_keys.d"
printf '%s\n%s\n' "$TF_VAR_ssh_public_key" "$TF_VAR_friend_ssh_public_key" \
  > "$extra_files/etc/ssh/authorized_keys.d/root"
chmod 0600 "$extra_files/etc/ssh/authorized_keys.d/root"

if command -v nix >/dev/null 2>&1; then
  nix --extra-experimental-features "nix-command flakes" \
    run "path:$script_dir#nixos-anywhere" -- \
    --flake "path:$script_dir#shared" \
    --build-on remote \
    --extra-files "$extra_files" \
    --print-build-logs \
    "root@$target_host"
elif command -v docker >/dev/null 2>&1; then
  if ! docker info >/dev/null 2>&1; then
    printf 'Docker is installed but its daemon is not running\n' >&2
    exit 1
  fi

  # OrbStack cannot expose the 1Password SSH-agent socket to a container.
  # Authorize a throwaway key in the installer; it disappears on reboot.
  controller_key="$runtime_dir/nixos-anywhere"
  ssh-keygen -q -t ed25519 -N "" -f "$controller_key"
  ssh \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "root@$target_host" \
    'umask 077; mkdir -p /root/.ssh; tee -a /root/.ssh/authorized_keys >/dev/null' \
    < "$controller_key.pub"

  docker run --rm \
    --mount "type=volume,source=homelab-nix-store,target=/nix" \
    --mount "type=bind,source=$script_dir,target=/work,readonly" \
    --mount "type=bind,source=$extra_files,target=/extra-files,readonly" \
    --mount "type=bind,source=$controller_key,target=/root/.ssh/id_ed25519,readonly" \
    nixos/nix:2.35.1@sha256:377d4887aca98f0dfa12971c1ea6d6a625a435d8b610d4c95a436843da6fbfd1 \
    nix --extra-experimental-features "nix-command flakes" \
    run path:/work#nixos-anywhere -- \
    --flake path:/work#shared \
    --build-on remote \
    --extra-files /extra-files \
    --print-build-logs \
    -i /root/.ssh/id_ed25519 \
    "root@$target_host"
else
  printf 'Either Nix or Docker is required to run nixos-anywhere\n' >&2
  exit 1
fi
