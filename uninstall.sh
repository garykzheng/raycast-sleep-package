#!/bin/bash

# Removes everything install.sh set up. Run as your normal user.

set -uo pipefail

label=local.sleep-guard
conf=/usr/local/etc/sleep-guard.conf

raycast_dir=$(grep -E '^RAYCAST_DIR=' "$conf" 2>/dev/null | cut -d= -f2-)
if [[ -n $raycast_dir ]]; then
  rm -f "$raycast_dir/toggle-sleep.sh"
fi

sudo launchctl bootout "system/$label" 2>/dev/null
sudo rm -f "/Library/LaunchDaemons/$label.plist" /usr/local/libexec/sleep-guard.sh \
  "$conf" /etc/sudoers.d/sleep-guard

echo "Uninstalled. Sleep is left as it was; run 'sudo pmset disablesleep 0' to make sure it's on."
