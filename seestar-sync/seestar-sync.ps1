<#
.SYNOPSIS
    Copies new/changed image files off a Seestar (S30/S50/S60) onto a local
    Windows drive, over the Seestar's built-in guest SMB share.

.DESCRIPTION
    First run (no config file yet, or -Reconfigure passed) prompts for:
      - the Seestar's IP address (reachable over your VPN/LAN)
      - a local destination folder to copy files into
    and saves both to a small JSON config file next to this script.

    Every run after that just does a Robocopy pass from the Seestar's
    share to the destination. Robocopy's default comparison (file size +
    timestamp) already skips anything already copied, so re-running this
    on a schedule only pulls down what's new since the last pass - it
    never re-copies or deletes anything on the destination.

    Pass -InstallTask to also register this script as a repeating Windows
    Scheduled Task, so it runs on its own without you remembering to.

.PARAMETER ConfigPath
    Where to read/write the JSON config. Defaults to a file next to this
    script, so the whole thing stays portable if you move the folder.

.PARAMETER Reconfigure
    Forces the IP/destination prompts again, even if a config file
    already exists. Use this if the Seestar's IP changed (e.g. DHCP
    reassigned it) or you want to change the destination folder.

.PARAMETER ShareName
    The SMB share name the Seestar exposes its images under. Every
    Seestar observed so far uses "EMMC Images", so that's the default -
    override this if a firmware version on your unit uses something
    different (check by browsing \\<seestar-ip>\ in File Explorer first).

.PARAMETER InstallTask
    Registers this script as a Windows Scheduled Task that re-runs every
    -TaskIntervalMinutes, under the current user account, without needing
    Administrator rights. Safe to run more than once - it replaces the
    existing task rather than creating a duplicate.

.PARAMETER TaskIntervalMinutes
    How often the scheduled task should run, in minutes. Only used with
    -InstallTask. Defaults to 15.

.EXAMPLE
    .\seestar-sync.ps1
    First run: prompts for the Seestar IP and a destination folder, saves
    them, then does one sync pass.

.EXAMPLE
    .\seestar-sync.ps1 -InstallTask -TaskIntervalMinutes 30
    Runs a sync pass now, and also registers/updates a scheduled task that
    repeats every 30 minutes from here on.

.EXAMPLE
    .\seestar-sync.ps1 -Reconfigure
    Re-prompts for the Seestar IP and destination even though a config
    file already exists (e.g. after the Seestar got a new DHCP address).
#>

[CmdletBinding()]
param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "seestar-sync.config.json"),
    [switch]$Reconfigure,
    [string]$ShareName = "EMMC Images",
    [switch]$InstallTask,
    [int]$TaskIntervalMinutes = 15
)

$ErrorActionPreference = "Stop"

# A separate log file per run, timestamped, kept next to the config file.
# Robocopy's own /LOG option only writes plain text - /TEE below also
# echoes everything to the console so you see progress live either way.
$LogDir = Join-Path (Split-Path $ConfigPath -Parent) "logs"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}
$LogFile = Join-Path $LogDir ("sync_{0:yyyy-MM-dd_HHmmss}.log" -f (Get-Date))

function Read-OrCreateConfig {
    <#
        Loads the JSON config if it exists and -Reconfigure wasn't passed.
        Otherwise interactively prompts for the two required values and
        writes a fresh config file. Keeping this in its own function means
        -InstallTask (below) can call it non-interactively once a config
        already exists, without re-prompting every time the task fires.
    #>
    if ((Test-Path $ConfigPath) -and (-not $Reconfigure)) {
        try {
            return Get-Content $ConfigPath -Raw | ConvertFrom-Json
        } catch {
            Write-Warning "Config file at $ConfigPath is unreadable/corrupt - re-running setup."
        }
    }

    Write-Host ""
    Write-Host "== Seestar Sync - first-time setup ==" -ForegroundColor Cyan
    $seestarIp = Read-Host "Seestar IP address (e.g. 192.168.1.50)"
    $destination = Read-Host "Local folder to copy files into (e.g. D:\Seestar)"

    if (-not (Test-Path $destination)) {
        Write-Host "Destination folder doesn't exist yet - creating it." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
    }

    $config = [PSCustomObject]@{
        SeestarIp   = $seestarIp
        Destination = (Resolve-Path $destination).Path
        ShareName   = $ShareName
    }

    $config | ConvertTo-Json | Set-Content -Path $ConfigPath -Encoding UTF8
    Write-Host "Saved config to $ConfigPath" -ForegroundColor Green
    return $config
}

function Invoke-SeestarSync {
    param($Config)

    $source = "\\{0}\{1}" -f $Config.SeestarIp, $Config.ShareName

    # Guest-SMB note: Windows has disabled "insecure guest logons" by
    # default since the Windows 10 1709 / Server 2019 era, which is
    # exactly what a Seestar's anonymous/guest-only share looks like from
    # Windows' perspective. If Test-Path below fails with an
    # "unsecure/insecure" or "you can't connect" message, that's almost
    # certainly it - fix on the Windows PC (not the Seestar) via:
    #   Computer Config > Admin Templates > Network > Lanman Workstation
    #   > Enable insecure guest logons  (gpedit.msc), or the equivalent
    #   registry value AllowInsecureGuestAuth under
    #   HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters
    if (-not (Test-Path $source)) {
        Write-Error "Can't reach $source - check the Seestar is powered on, on the same VPN/LAN, and that ShareName ('$($Config.ShareName)') is correct. See the comment above this check for the most common Windows-side cause (insecure guest logons disabled)."
        return $false
    }

    Write-Host "Syncing $source -> $($Config.Destination)" -ForegroundColor Cyan

    # /E     - copy subfolders, including empty ones (Seestar organizes by date/target)
    # /R:2   /W:5 - only retry twice, 5s apart, instead of Robocopy's very
    #          patient defaults (1 million retries) - a flaky VPN hop
    #          shouldn't hang the scheduled task for hours
    # /NP    - don't print per-file percentage-copied noise
    # /NFL /NDL - don't list every single file/dir name (still logs summary)
    # /LOG+: - append to our timestamped log instead of overwriting it
    # /TEE   - also mirror log output to the console
    #
    # Deliberately NOT using /MIR here: /MIR deletes anything in the
    # destination that's no longer on the source, which would wipe out
    # this whole local archive if the Seestar's own storage got cleared.
    # This is meant to be an accumulating local backup, so it only ever
    # adds files - it never deletes on either side.
    $robocopyArgs = @(
        $source, $Config.Destination,
        "/E", "/R:2", "/W:5", "/NP", "/NFL", "/NDL",
        "/LOG+:$LogFile", "/TEE"
    )
    robocopy @robocopyArgs

    # Robocopy is one of the few Windows tools where a non-zero exit code
    # does NOT mean failure - it's a bitmask (see `robocopy /?`):
    #   0 = no files copied, no failures (destination was already current)
    #   1 = one or more files copied successfully
    #   2 = extra files/dirs exist in destination that aren't in source
    #   4 = some mismatched files/dirs were detected
    #   8+ = at least one failure occurred copying files (this is the one
    #        that actually means "something went wrong")
    # Codes combine (e.g. 3 = "files copied" + "extra files found"), so
    # anything under 8 is a normal/successful run.
    $exitCode = $LASTEXITCODE
    if ($exitCode -ge 8) {
        Write-Error "Robocopy reported failures (exit code $exitCode) - see $LogFile for details."
        return $false
    }

    Write-Host "Sync complete (Robocopy exit code $exitCode - run 'robocopy /?' for what that means). Log: $LogFile" -ForegroundColor Green
    return $true
}

function Install-SyncScheduledTask {
    param([int]$IntervalMinutes)

    # Windows Task Scheduler is fully scriptable from PowerShell via the
    # built-in ScheduledTasks module (no extra install needed on any
    # supported Windows 10/11 or Server release) - New-ScheduledTask* /
    # Register-ScheduledTask to create, Get-ScheduledTask to query,
    # Set-ScheduledTask to update, Unregister-ScheduledTask to remove.
    $taskName = "SeestarSync"

    # -Argument re-runs this exact script, non-interactively, using the
    # config file that's already been saved - so the scheduled run never
    # hits the interactive prompts in Read-OrCreateConfig above.
    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -ConfigPath `"$ConfigPath`""

    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) `
        -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) `
        -RepetitionDuration ([TimeSpan]::MaxValue)

    # Limited run-level = runs as the current user, only while they're
    # logged on, and does NOT require an Administrator prompt to register.
    # If you need it to run even when logged out, re-register manually
    # with -User/-Password and RunLevel Highest instead - see the README.
    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
        -StartWhenAvailable

    $existing = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Task '$taskName' already exists - updating it in place." -ForegroundColor Yellow
        Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings | Out-Null
    } else {
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger `
            -Settings $settings -Description "Syncs new Seestar files to a local folder (seestar-sync.ps1)" | Out-Null
        Write-Host "Registered scheduled task '$taskName', repeating every $IntervalMinutes minute(s)." -ForegroundColor Green
    }

    # Confirm what actually got registered - useful for the "can you query
    # it" half of this: Get-ScheduledTask + Get-ScheduledTaskInfo together
    # show both the definition and its last/next run times.
    Get-ScheduledTask -TaskName $taskName | Get-ScheduledTaskInfo |
        Select-Object TaskName, LastRunTime, LastTaskResult, NextRunTime
}

# --- main --------------------------------------------------------------

$config = Read-OrCreateConfig
$syncOk = Invoke-SeestarSync -Config $config

if ($InstallTask) {
    Install-SyncScheduledTask -IntervalMinutes $TaskIntervalMinutes
}

if (-not $syncOk) {
    exit 1
}
