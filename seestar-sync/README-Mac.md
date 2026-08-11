# Seestar Sync (Mac)

A small bash script that copies new/changed image files off a Seestar
(S30/S50) onto a local Mac drive, over the Seestar's built-in guest SMB
share - useful if your Seestar sits on a remote network (an observatory,
a VPN-connected site, etc.) and you want a running local copy of everything
it captures without manually pulling files off it.

This is the Mac counterpart to [seestar-sync.ps1](seestar-sync.ps1) - same
behavior, built on macOS's own native tools (`mount_smbfs`, `rsync`,
`launchd`) instead of Windows' (Robocopy, Task Scheduler), so nothing extra
needs to be installed.

It's built around [rsync](https://ss64.com/mac/rsync.html), which only
copies files that are new or have changed since the last run - so this is
safe to run on a schedule and it'll never re-copy or delete anything.

## Getting the script

**Option 1 - one Terminal command (easiest, no GitHub/git knowledge needed):**

```bash
installPath="$HOME/SeestarSync"   # change this to install somewhere else, e.g. "/Volumes/Data/SeestarSync"

mkdir -p "$installPath"
curl -fsSL "https://raw.githubusercontent.com/wokka1/astronomy/main/seestar-sync/seestar-sync.sh" -o "$installPath/seestar-sync.sh"
chmod +x "$installPath/seestar-sync.sh"
cd "$installPath"
```

Paste that into Terminal - it creates a `SeestarSync` folder in your home
directory, downloads the script into it, makes it executable, and leaves
you sitting in that folder so you can go straight into
[First run](#first-run) below without a manual `cd`. Edit the
`installPath` line first if you'd rather it go somewhere else (an external
drive, an existing tools folder, etc.) - the rest of the block doesn't need
to change since it all reads from that one variable.

**Option 2 - download from GitHub's website:**

1. Go to [github.com/wokka1/astronomy/tree/main/seestar-sync](https://github.com/wokka1/astronomy/tree/main/seestar-sync)
2. Click `seestar-sync.sh`, then click the **Download raw file** button
   (top-right of the file view).
3. Save it into whatever folder you want to run it from.
4. Open Terminal, `cd` to that folder, and run `chmod +x seestar-sync.sh`
   so it's allowed to execute (macOS doesn't flag downloaded shell scripts
   the way Windows flags downloaded PowerShell scripts, but they still
   need the executable bit set).

**Option 3 - if you already use git:**

```bash
git clone https://github.com/wokka1/astronomy.git
cd astronomy/seestar-sync
```

That pulls the whole repo (including the images elsewhere in it). To get
just this folder instead, use a sparse checkout (git 2.36+):

```bash
git clone --filter=blob:none --sparse https://github.com/wokka1/astronomy.git
cd astronomy
git sparse-checkout set seestar-sync
```

This still fetches the repo's commit history, but `--filter=blob:none`
skips downloading file contents up front (they're fetched on demand as you
check them out), and `sparse-checkout set` limits your working folder to
just `seestar-sync/` - the rest of the repo won't show up on disk at all.
Not worth the extra steps for a one-time download (Option 1 above is
simpler for that); mainly useful if you're going to `git pull` this repo
repeatedly to pick up script updates.

## Requirements

- macOS - built and tested against the stock `/bin/bash` (3.2) that ships
  on every Mac, and the `mount_smbfs`/`rsync`/`launchd` tools built in -
  nothing extra to install.
- Network access from the Mac to the Seestar (same LAN, or a VPN that
  reaches it) - test this first by connecting to `smb://<seestar-ip>/` in
  Finder (**Go → Connect to Server...**) before running the script.
- The Seestar's SMB share left at its default guest/anonymous access - no
  credentials are handled by this script.

## First run

Open Terminal, `cd` into the folder you downloaded the script into, and run:

```bash
./seestar-sync.sh
```

You'll be prompted for two things:

1. **Seestar IP address** - whatever address it has on your network/VPN.
2. **Local destination folder** - where files should be copied to (created
   automatically if it doesn't exist).

Both get saved to `seestar-sync.config` next to the script, so every run
after this is non-interactive.

If you ever need to change either value (e.g. the Seestar got a new DHCP
address), run:

```bash
./seestar-sync.sh --reconfigure
```

Since first runs are usually done interactively, add `-v`/`--verbose` to
see rsync's live per-file progress (filenames as they copy) instead of
just a one-line summary at the end:

```bash
./seestar-sync.sh --verbose
```

Scheduled runs (below) leave `--verbose` off automatically, so the log
stays short once this is running unattended.

## Scheduling it

To have macOS run this automatically in the background, once a day:

```bash
./seestar-sync.sh --install-task
```

This registers a `launchd` LaunchAgent named **local.seestarsync** under
your user account - no admin password needed - that runs once a day at
**9:00 AM local time** by default. Running this again later (e.g. with a
different `--task-time`) updates the existing agent instead of creating a
duplicate.

**To run at a different time of day**, pass `--task-time`:

```bash
./seestar-sync.sh --install-task --task-time "22:30"
```

This is always your Mac's own local time - like Windows Task Scheduler,
`launchd`'s calendar triggers run on whatever time zone the Mac itself is
set to, so just pick the wall-clock time you want it to run.

**To run more often than once a day**, pass `--task-interval-minutes`
instead - this switches the agent to repeat every N minutes, all day,
instead of the once-daily default:

```bash
./seestar-sync.sh --install-task --task-interval-minutes 15
```

You can check on it any time with:

```bash
launchctl list | grep seestarsync
```

**To remove it**, run:

```bash
./seestar-sync.sh --uninstall-task
```

By default the agent only runs while you're logged in (this is `launchd`'s
normal behavior for a per-user LaunchAgent, same limitation as the Windows
version's default Scheduled Task). If you need it to run even when logged
out, that requires installing it as a system-wide LaunchDaemon instead
(runs as root, needs `sudo`, and is out of scope for this script) - see
[Apple's launchd documentation](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)
if you need that.

## Logs

Each run writes a timestamped log to a `logs/` folder next to the config
file, and also prints progress to the console. If a sync fails, check the
most recent log first - it's rsync's own output. Scheduled runs also
produce `logs/launchd.out.log` and `logs/launchd.err.log`, which capture
anything printed before the script's own log file gets created (useful if
a scheduled run fails before it even gets that far).

## Troubleshooting: "can't reach" errors

If the script can't mount the Seestar's share, but you can otherwise ping
it or reach it over the VPN, first double check the basics:

- The Seestar is powered on and actually on the same LAN/VPN as your Mac.
- The share name is right - browse to `smb://<seestar-ip>/` in Finder
  (**Go → Connect to Server...**, connect as **Guest**) to see the actual
  share name, then pass it with `--share-name` if it's not "EMMC Images".
- Try mounting it by hand to see the real error message:
  ```bash
  mkdir -p /tmp/seestar-test
  mount -t smbfs "//guest:@<seestar-ip>/EMMC%20Images" /tmp/seestar-test
  ```
  (note the `%20` for the space in the default share name - `mount_smbfs`
  treats the share path as a URL). Unmount afterward with
  `umount /tmp/seestar-test`.

macOS's SMB client is generally more permissive about anonymous/guest
shares out of the box than Windows is (Windows disables "insecure guest
logons" by default, which is the single most common cause of this same
symptom over there - see [README-Windows.md](README-Windows.md)'s
troubleshooting section). If the manual mount above still fails with a
protocol/signing-related error, macOS does have an equivalent knob, just
rarely needed: create (or edit) `/etc/nsmb.conf` with:

```
[default]
protocol_vers_map=7
signing_required=no
```

`protocol_vers_map=7` enables SMB 1/2/3 (this is actually already the
default), and `signing_required=no` disables mandatory packet signing
(also already the default) - so this is only worth trying if something
else on your Mac (an MDM profile, a prior manual config change) has
overridden those defaults. No reboot needed - just retry the mount after
saving the file.

## What it doesn't do

- No credential handling - this is built for the Seestar's default guest
  share only.
- No deletion, ever, on either side - it only ever adds files to the
  destination (deliberately not using rsync's `--delete`, which would
  remove local files if they were ever removed from the Seestar).
- No support (yet) for syncing multiple Seestars from one script - run a
  second copy of the script in its own folder with its own config if you
  need that.
