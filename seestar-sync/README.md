# Seestar Sync

Copies new/changed image files off a Seestar (S30/S50) onto a local drive,
over the Seestar's built-in guest SMB share - useful if your Seestar sits
on a remote network (an observatory, a VPN-connected site, etc.) and you
want a running local copy of everything it captures without manually
pulling files off it.

Never deletes anything on either side, and only ever copies what's new or
changed since the last run - safe to run on a schedule.

Pick your platform:

- **[README-Windows.md](README-Windows.md)** - [seestar-sync.ps1](seestar-sync.ps1)
  (PowerShell, built on Robocopy + Task Scheduler)
- **[README-Mac.md](README-Mac.md)** - [seestar-sync.sh](seestar-sync.sh)
  (bash, built on rsync + launchd)

Both versions have the same feature set (first-run setup prompt, a
`--reconfigure`/`-Reconfigure` flag, scheduled background runs, verbose
live-progress mode, per-run logs) - just built on each OS's own native
tools, so neither needs anything installed beyond what the OS ships with.
