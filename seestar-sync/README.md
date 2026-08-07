# Seestar Sync

A small PowerShell script that copies new/changed image files off a Seestar
(S30/S50) onto a local Windows drive, over the Seestar's built-in guest
SMB share - useful if your Seestar sits on a remote network (an observatory,
a VPN-connected site, etc.) and you want a running local copy of everything
it captures without manually pulling files off it.

It's built around [Robocopy](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/robocopy),
which only copies files that are new or have changed since the last run -
so this is safe to run on a schedule and it'll never re-copy or delete
anything.

## Getting the script

**Option 1 - one PowerShell command (easiest, no GitHub/git knowledge needed):**

```powershell
New-Item -ItemType Directory -Path "$env:USERPROFILE\SeestarSync" -Force | Out-Null
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/wokka1/astronomy/main/seestar-sync/seestar-sync.ps1" -OutFile "$env:USERPROFILE\SeestarSync\seestar-sync.ps1"
Unblock-File "$env:USERPROFILE\SeestarSync\seestar-sync.ps1"
```

Paste that into a PowerShell window - it creates a `SeestarSync` folder in
your user profile and downloads the script into it. The `Unblock-File`
line matters: Windows tags anything downloaded from the internet with a
"Mark of the Web," which otherwise triggers a security warning (or an
outright block) the first time you try to run it.

**Option 2 - download from GitHub's website:**

1. Go to [github.com/wokka1/astronomy/tree/main/seestar-sync](https://github.com/wokka1/astronomy/tree/main/seestar-sync)
2. Click `seestar-sync.ps1`, then click the **Download raw file** button
   (top-right of the file view).
3. Save it into whatever folder you want to run it from.
4. Right-click the downloaded file → **Properties** → if there's an
   **Unblock** checkbox near the bottom, check it and click OK (same
   "Mark of the Web" issue as above, just fixed through Explorer instead
   of `Unblock-File`).

**Option 3 - if you already use git:**

```powershell
git clone https://github.com/wokka1/astronomy.git
cd astronomy\seestar-sync
```

That pulls the whole repo (including the images elsewhere in it). To get
just this folder instead, use a sparse checkout (git 2.36+):

```powershell
git clone --filter=blob:none --sparse https://github.com/wokka1/astronomy.git
cd astronomy
git sparse-checkout set seestar-sync
```

This still fetches the repo's commit history, but `--filter=blob:none`
skips downloading file contents up front (they're fetched on demand as
you check them out), and `sparse-checkout set` limits your working
folder to just `seestar-sync\` - the rest of the repo won't show up on
disk at all. Not worth the extra steps for a one-time download (Option 1
above is simpler for that); mainly useful if you're going to `git pull`
this repo repeatedly to pick up script updates.

## Requirements

- Windows 10/11 (or Server 2016+) - `robocopy` and the `ScheduledTasks`
  PowerShell module are both built in, nothing extra to install.
- Network access from the Windows PC to the Seestar (same LAN, or a VPN
  that reaches it) - test this first by browsing to `\\<seestar-ip>\` in
  File Explorer before running the script.
- The Seestar's SMB share left at its default guest/anonymous access - no
  credentials are handled by this script.

## First run

Open PowerShell, `cd` into the folder you downloaded the script into, and run:

```powershell
.\seestar-sync.ps1
```

If you get an error about the script being blocked because "running
scripts is disabled on this system," that's PowerShell's execution
policy (a separate protection from the Mark-of-the-Web one above) - it
defaults to fairly strict on most Windows installs. Either run it once
this way instead:

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\seestar-sync.ps1
```

or allow locally-created scripts to run going forward for your user
account:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

You'll be prompted for two things:

1. **Seestar IP address** - whatever address it has on your network/VPN.
2. **Local destination folder** - where files should be copied to (created
   automatically if it doesn't exist).

Both get saved to `seestar-sync.config.json` next to the script, so every
run after this is non-interactive.

If you ever need to change either value (e.g. the Seestar got a new DHCP
address), run:

```powershell
.\seestar-sync.ps1 -Reconfigure
```

Since first runs are usually done interactively, add `-Verbose` to see
Robocopy's live per-file progress (filenames and % as they copy) instead
of just a one-line summary at the end:

```powershell
.\seestar-sync.ps1 -Verbose
```

Scheduled runs (below) leave `-Verbose` off automatically, so the log
stays short once this is running unattended.

## Scheduling it

To have Windows run this automatically in the background, once a day:

```powershell
.\seestar-sync.ps1 -InstallTask
```

This registers a Scheduled Task named **SeestarSync** under your current
user account - no Administrator prompt needed - that runs once a day at
**9:00 AM local time** by default. Running this again later updates the
existing task instead of creating a duplicate.

**To run at a different time of day**, pass `-TaskTime`:

```powershell
.\seestar-sync.ps1 -InstallTask -TaskTime "22:30"
```

This is always your PC's own local time - Task Scheduler triggers run on
whatever time zone the PC itself is set to, so just pick the wall-clock
time you want it to run; there's no time zone math to do even if the
Seestar or the person setting this up is somewhere else.

**To run more often than once a day**, pass `-TaskIntervalMinutes`
instead - this switches the task to repeat every N minutes, all day,
instead of the once-daily default:

```powershell
.\seestar-sync.ps1 -InstallTask -TaskIntervalMinutes 15
```

You can check on it any time with:

```powershell
Get-ScheduledTask -TaskName SeestarSync | Get-ScheduledTaskInfo
```

or open Task Scheduler and look under the root task library for
**SeestarSync**.

By default the task only runs while you're logged in. If you need it to
run even when logged out, re-register it yourself with a stored
credential and a Highest run level:

```powershell
$action = New-ScheduledTaskAction -Execute "powershell.exe" `
    -Argument "-NoProfile -ExecutionPolicy Bypass -File `"C:\path\to\seestar-sync.ps1`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
    -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration ([TimeSpan]::MaxValue)
Register-ScheduledTask -TaskName SeestarSync -Action $action -Trigger $trigger `
    -User "YOURDOMAIN\YourUser" -Password "YourPassword" -RunLevel Highest -Force
```

## Logs

Each run writes a timestamped log to a `logs\` folder next to the config
file, and also prints progress to the console. If a sync fails, check the
most recent log first - it's Robocopy's own output.

## Troubleshooting: "can't connect" / "unsecure" errors

If the script can't reach the Seestar's share, but you can otherwise ping
it or reach it over the VPN, this is almost always a Windows setting, not
a Seestar problem: Windows has disabled **insecure guest logons** by
default since around the Windows 10 1709 / Server 2019 era, which is
exactly what a Seestar's anonymous SMB share looks like from Windows'
side. Starfront Observatories has their own writeup of this exact issue:
[Remote Mounting Seestar Internal Storage (Windows Edition)](https://starfront.zendesk.com/hc/en-us/articles/51136311376148-Remote-Mounting-Seestar-Internal-Storage-Windows-Edition).

Easiest fix - let the script do it:

```powershell
# Run PowerShell as Administrator first
.\seestar-sync.ps1 -FixGuestAuth
```

This sets the same registry value the manual steps below set, works on
Windows 10 Pro and Windows 11 alike (it edits the registry directly
rather than going through Group Policy, so it isn't gated to any
particular edition), and is a no-op if it's already enabled. It needs a
reboot afterward to take effect.

Or do it by hand:

- **Group Policy** (`gpedit.msc`, Pro/Enterprise only): Computer
  Configuration → Administrative Templates → Network → Lanman Workstation
  → **Enable insecure guest logons** → set to Enabled.
- **Registry / Command Prompt** (works on every edition, including Home):
  set `AllowInsecureGuestAuth` to `1` (DWORD) under
  `HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters`,
  then reboot. From an elevated Command Prompt:
  ```
  reg add HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f
  ```

After any of these, reboot, then reconnect/remap and re-run the script.

If the share name itself is wrong (some firmware versions may differ from
the default), pass `-ShareName` with whatever name you see when you
browse to `\\<seestar-ip>\` directly:

```powershell
.\seestar-sync.ps1 -ShareName "Some Other Share Name"
```

## What it doesn't do

- No credential handling - this is built for the Seestar's default guest
  share only.
- No deletion, ever, on either side - it only ever adds files to the
  destination (deliberately not using Robocopy's `/MIR`, which would
  delete local files if they were ever removed from the Seestar).
- No support (yet) for syncing multiple Seestars from one script - run a
  second copy of the script in its own folder with its own config if you
  need that.
