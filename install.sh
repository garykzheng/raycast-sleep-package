#!/bin/bash

# Installs the Toggle Sleep Raycast command and the sleep guard LaunchDaemon.
# Run as your normal user (not with sudo); it asks for your password once.
# Re-run it any time to change the battery threshold or the Raycast folder.
#
# Usage: ./install.sh [threshold%] [raycast-scripts-folder]

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as your normal user, without sudo: ./install.sh" >&2
  exit 1
fi

dir=$(cd "$(dirname "$0")" && pwd)
label=local.sleep-guard
conf=/usr/local/etc/sleep-guard.conf
guard=/usr/local/libexec/sleep-guard.sh
plist=/Library/LaunchDaemons/$label.plist
sudoers=/etc/sudoers.d/sleep-guard
user=$(id -un)

# Defaults come from a previous install, if any
prev_threshold=$(grep -E '^THRESHOLD=' "$conf" 2>/dev/null | cut -d= -f2) || true
prev_dir=$(grep -E '^RAYCAST_DIR=' "$conf" 2>/dev/null | cut -d= -f2-) || true

threshold=${1:-}
if [[ -z $threshold ]]; then
  read -rp "Re-enable sleep when battery drops to what %? [${prev_threshold:-15}] " threshold
fi
threshold=${threshold:-${prev_threshold:-15}}
threshold=${threshold%\%}
if ! [[ $threshold =~ ^[0-9]+$ ]] || (( 10#$threshold < 1 || 10#$threshold > 99 )); then
  echo "Threshold must be a whole number from 1 to 99" >&2
  exit 1
fi
threshold=$((10#$threshold))

raycast_dir=${2:-}
if [[ -z $raycast_dir ]]; then
  read -rp "Folder for Raycast script commands? [${prev_dir:-$HOME/raycast-scripts}] " raycast_dir
fi
raycast_dir=${raycast_dir:-${prev_dir:-$HOME/raycast-scripts}}
raycast_dir=${raycast_dir/#\~/$HOME}

# Raycast command (user-owned, so no sudo)
mkdir -p "$raycast_dir"
raycast_dir=$(cd "$raycast_dir" && pwd)
install -m 755 "$dir/toggle-sleep.sh" "$raycast_dir/toggle-sleep.sh"

echo "Installing system files; you may be asked for your password."
sudo -v

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# Passwordless sudo for exactly the two pmset calls toggle-sleep.sh makes
printf '%s ALL=(root) NOPASSWD: /usr/bin/pmset disablesleep 0, /usr/bin/pmset disablesleep 1\n' \
  "$user" > "$tmp/sudoers"
sudo visudo -cqf "$tmp/sudoers"
sudo install -d -o root -g wheel -m 755 /etc/sudoers.d
sudo install -o root -g wheel -m 440 "$tmp/sudoers" "$sudoers"

printf 'THRESHOLD=%s\nRAYCAST_DIR=%s\n' "$threshold" "$raycast_dir" > "$tmp/conf"
sudo install -d -o root -g wheel -m 755 /usr/local/etc /usr/local/libexec
sudo install -o root -g wheel -m 644 "$tmp/conf" "$conf"

# The daemon runs a root-owned copy so it never executes a user-writable file
sudo launchctl bootout "system/$label" 2>/dev/null || true
sudo install -o root -g wheel -m 755 "$dir/sleep-guard.sh" "$guard"
sudo install -o root -g wheel -m 644 "$dir/$label.plist" "$plist"
sudo launchctl bootstrap system "$plist"

cat <<EOF

Installed.
  Sleep guard: re-enables sleep at ${threshold}% on battery (checks every 5 min)
  Raycast command: $raycast_dir/toggle-sleep.sh
  Log: /var/log/sleep-guard.log

If Raycast doesn't already use that folder, add it once:
  Raycast Settings > Extensions > + > Add Script Directory > $raycast_dir
Then search Raycast for "Toggle Sleep".
EOF
