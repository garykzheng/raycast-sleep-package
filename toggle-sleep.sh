#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Toggle Sleep
# @raycast.mode compact

# Optional parameters:
# @raycast.icon 💤

# Documentation:
# @raycast.description Enable / Disable MacOS Sleep
# @raycast.author gary_zheng
# @raycast.authorURL https://raycast.com/gary_zheng

# The installer adds a sudoers rule so these pmset calls need no password.
conf=/usr/local/etc/sleep-guard.conf
threshold=$(grep -E '^THRESHOLD=' "$conf" 2>/dev/null | cut -d= -f2)
threshold=${threshold:-15}

if pmset -g | grep -Eq 'SleepDisabled[[:space:]]+1'; then
  echo "Enabling sleep..."
  sudo -n /usr/bin/pmset disablesleep 0
else
  # Don't disable sleep on low battery; sleep-guard would just re-enable it
  batt=$(pmset -g batt)
  pct=$(echo "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
  if [[ $batt == *"Battery Power"* && -n $pct ]] && (( pct <= threshold )); then
    echo "Battery at ${pct}%, not disabling sleep"
    exit 1
  fi

  echo "Disabling sleep..."
  sudo -n /usr/bin/pmset disablesleep 1
fi
