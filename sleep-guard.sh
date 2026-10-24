#!/bin/bash

# Re-enables sleep when it has been disabled (via toggle-sleep.sh) and the
# battery drops to the configured threshold while running on battery power.
# Run every 5 minutes as root by the local.sleep-guard LaunchDaemon.

conf=/usr/local/etc/sleep-guard.conf
threshold=$(grep -E '^THRESHOLD=' "$conf" 2>/dev/null | cut -d= -f2)
threshold=${threshold:-15}

# Nothing to do unless sleep is currently disabled
pmset -g | grep -Eq 'SleepDisabled[[:space:]]+1' || exit 0

batt=$(pmset -g batt)

# Only act when running on battery (not plugged in)
[[ $batt == *"Battery Power"* ]] || exit 0

pct=$(echo "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
[[ -n $pct ]] || exit 0

if (( pct <= threshold )); then
  echo "$(date '+%Y-%m-%d %H:%M:%S') battery at ${pct}%, re-enabling sleep"
  pmset disablesleep 0
fi
