# Raycast Toggle Sleep + Sleep Guard

A Raycast command that turns macOS sleep on and off (handy for keeping a
laptop awake with the lid closed), plus a background service that turns sleep
back on if the battery runs low while it's off.

## Install

```sh
git clone https://github.com/garykzheng/raycast-sleep-package.git
cd raycast-sleep-package
./install.sh
```

The installer asks two things:

1. **Battery threshold:** the % at which sleep gets turned back on (default 15).
2. **Raycast folder:** where to put the script command (default `~/raycast-scripts`).

You can also pass both up front: `./install.sh 20 ~/raycast-scripts`.

If Raycast doesn't already watch that folder, add it once in
**Raycast Settings → Extensions → + → Add Script Directory**. Then search
Raycast for **Toggle Sleep**.

Re-run `./install.sh` any time to change the threshold or folder.

## What it installs

| Path | What |
| --- | --- |
| `<raycast folder>/toggle-sleep.sh` | The Raycast command |
| `/usr/local/libexec/sleep-guard.sh` | The battery check (root-owned copy) |
| `/Library/LaunchDaemons/local.sleep-guard.plist` | Runs the check every 5 minutes as root |
| `/usr/local/etc/sleep-guard.conf` | Threshold and Raycast folder |
| `/etc/sudoers.d/sleep-guard` | Lets your user run `pmset disablesleep 0` / `1` without a password |

The sudoers rule covers only those two exact commands, nothing else.

The guard only acts while on battery power. Plugged in, sleep stays however
you left it. The Raycast command also refuses to disable sleep when you're
already at or below the threshold.

Log: `/var/log/sleep-guard.log` (one line each time the guard steps in).

## Uninstall

```sh
./uninstall.sh
```
