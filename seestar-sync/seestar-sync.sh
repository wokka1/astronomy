#!/bin/bash
#
# seestar-sync.sh
#
# Copies new/changed image files off a Seestar (S30/S50) onto a local Mac
# drive, over the Seestar's built-in guest SMB share - useful if your
# Seestar sits on a remote network (an observatory, a VPN-connected site,
# etc.) and you want a running local copy of everything it captures
# without manually pulling files off it.
#
# This is the Mac counterpart to seestar-sync.ps1 (Windows/PowerShell) in
# this same folder - same behavior, ported to macOS's own native tools
# (mount_smbfs, rsync, launchd) instead of Windows' (robocopy, Task
# Scheduler), so nothing extra needs to be installed. See README-Mac.md
# for full usage; -h/--help below covers the same ground.
#
# Written for macOS's stock /bin/bash (3.2) - deliberately avoids bash 4+
# only features (associative arrays, etc.) since that's what ships on an
# unmodified Mac.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="$SCRIPT_DIR/seestar-sync.config"
SHARE_NAME="EMMC Images"
RECONFIGURE=0
INSTALL_TASK=0
UNINSTALL_TASK=0
TASK_TIME="09:00"
TASK_INTERVAL_MINUTES=""
VERBOSE=0
LABEL="local.seestarsync"
PLIST_PATH="$HOME/Library/LaunchAgents/$LABEL.plist"

usage() {
    cat <<'EOF'
Usage: seestar-sync.sh [options]

  --reconfigure              Re-prompt for the Seestar IP and destination
                              folder even if a config file already exists
                              (e.g. after the Seestar got a new DHCP address).
  --share-name NAME           SMB share name the Seestar exposes its images
                              under. Default: "EMMC Images". Override if a
                              firmware version on your unit uses something
                              different (browse smb://<seestar-ip>/ in
                              Finder first to check).
  --install-task              Register this as a launchd LaunchAgent so it
                              runs automatically in the background.
  --task-time HH:MM            What local time of day to run at, once daily.
                              Default: 09:00. Ignored if
                              --task-interval-minutes is also given.
  --task-interval-minutes N   Run every N minutes, all day, instead of the
                              once-daily default. Only used with
                              --install-task.
  --uninstall-task            Remove the launchd LaunchAgent installed by
                              --install-task.
  -v, --verbose                Show rsync's live per-file progress instead
                              of just a one-line summary.
  -h, --help                   Show this help and exit.

First run (no config file yet, or --reconfigure passed) prompts for:
  - the Seestar's IP address (reachable over your VPN/LAN)
  - a local destination folder to copy files into
and saves both to seestar-sync.config next to this script.

Every run after that just does an rsync pass from the Seestar's share to
the destination. rsync's default comparison (file size + modification
time) already skips anything already copied, so re-running this on a
schedule only pulls down what's new since the last pass - it never
re-copies or deletes anything on the destination.
EOF
}

log() { echo "$@"; }

# --- arg parsing -------------------------------------------------------

while [ $# -gt 0 ]; do
    case "$1" in
        --reconfigure) RECONFIGURE=1 ;;
        --share-name) SHARE_NAME="$2"; shift ;;
        --install-task) INSTALL_TASK=1 ;;
        --task-time) TASK_TIME="$2"; shift ;;
        --task-interval-minutes) TASK_INTERVAL_MINUTES="$2"; shift ;;
        --uninstall-task) UNINSTALL_TASK=1 ;;
        -v|--verbose) VERBOSE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
    esac
    shift
done

# --- uninstall (handled before anything else needs a config) -----------

if [ "$UNINSTALL_TASK" -eq 1 ]; then
    UID_NUM="$(id -u)"
    launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null
    rm -f "$PLIST_PATH"
    log "Removed LaunchAgent '$LABEL' (if it was installed)."
    exit 0
fi

# --- config --------------------------------------------------------------
# Simple KEY="value" shell-sourceable file, deliberately not JSON - macOS
# ships nothing to parse JSON from a plain shell script without reaching
# for python3 or a third-party tool, and this keeps the whole script
# dependency-free like the Windows version (which leans on things already
# built into Windows).

read_or_create_config() {
    if [ -f "$CONFIG_PATH" ] && [ "$RECONFIGURE" -ne 1 ]; then
        # shellcheck disable=SC1090
        source "$CONFIG_PATH"
        if [ -n "${SEESTAR_IP:-}" ] && [ -n "${DESTINATION:-}" ]; then
            SHARE_NAME="${CONFIG_SHARE_NAME:-$SHARE_NAME}"
            return
        fi
        log "Config file at $CONFIG_PATH is missing required values - re-running setup."
    fi

    echo ""
    echo "== Seestar Sync - first-time setup =="
    printf "Seestar IP address (e.g. 192.168.1.50): "
    read -r SEESTAR_IP
    printf "Local folder to copy files into (e.g. /Users/you/Seestar): "
    read -r DESTINATION

    # Expand a leading ~ since read doesn't do tilde expansion for us.
    DESTINATION="${DESTINATION/#\~/$HOME}"

    if [ ! -d "$DESTINATION" ]; then
        log "Destination folder doesn't exist yet - creating it."
        mkdir -p "$DESTINATION"
    fi
    DESTINATION="$(cd "$DESTINATION" && pwd)"

    cat > "$CONFIG_PATH" <<EOF
SEESTAR_IP="$SEESTAR_IP"
DESTINATION="$DESTINATION"
CONFIG_SHARE_NAME="$SHARE_NAME"
EOF
    log "Saved config to $CONFIG_PATH"
}

# --- sync ----------------------------------------------------------------

MOUNT_POINT=""

cleanup_mount() {
    if [ -n "$MOUNT_POINT" ] && mount | grep -q " $MOUNT_POINT "; then
        umount "$MOUNT_POINT" 2>/dev/null
    fi
    if [ -n "$MOUNT_POINT" ] && [ -d "$MOUNT_POINT" ]; then
        rmdir "$MOUNT_POINT" 2>/dev/null
    fi
}

url_encode_share() {
    # Only handles spaces - the one character that shows up in real
    # Seestar share names ("EMMC Images"). Good enough without pulling in
    # a full URL-encoding routine for a share-name field.
    echo "$1" | sed 's/ /%20/g'
}

do_sync() {
    LOG_DIR="$SCRIPT_DIR/logs"
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/sync_$(date +%Y-%m-%d_%H%M%S).log"

    MOUNT_POINT="$(mktemp -d /tmp/seestar-sync.XXXXXX)"
    trap cleanup_mount EXIT

    SHARE_ENCODED="$(url_encode_share "$SHARE_NAME")"
    SOURCE_URL="//guest:@${SEESTAR_IP}/${SHARE_ENCODED}"

    log "Mounting $SOURCE_URL ..."

    # Retry a couple of times, 5s apart - mirrors the Windows version's
    # /R:2 /W:5 robocopy retry so a flaky VPN hop doesn't fail the whole
    # run on one bad attempt.
    ATTEMPT=0
    MOUNTED=0
    while [ "$ATTEMPT" -lt 3 ]; do
        if mount -t smbfs "$SOURCE_URL" "$MOUNT_POINT" 2>>"$LOG_FILE"; then
            MOUNTED=1
            break
        fi
        ATTEMPT=$((ATTEMPT + 1))
        [ "$ATTEMPT" -lt 3 ] && sleep 5
    done

    if [ "$MOUNTED" -ne 1 ]; then
        echo "Can't reach //${SEESTAR_IP}/${SHARE_NAME} - check the Seestar is powered on, on the same VPN/LAN, and that --share-name ('$SHARE_NAME') is correct. If it's otherwise reachable, see README-Mac.md's troubleshooting section." | tee -a "$LOG_FILE" >&2
        return 1
    fi

    log "Syncing $SOURCE_URL -> $DESTINATION"

    # -a     archive mode: recursive, preserves times/perms/symlinks
    # --stats  always print a transfer summary, even in quiet mode
    #
    # Deliberately NOT using --delete here: --delete would remove
    # anything from the destination that's no longer on the source,
    # which would wipe out this whole local archive if the Seestar's own
    # storage ever got cleared. This is meant to be an accumulating local
    # backup, so it only ever adds files - it never deletes on either
    # side, same as the Windows version's choice not to use robocopy's
    # /MIR.
    RSYNC_OPTS="-a --stats"
    if [ "$VERBOSE" -eq 1 ]; then
        RSYNC_OPTS="$RSYNC_OPTS -v --progress"
    fi

    # shellcheck disable=SC2086
    rsync $RSYNC_OPTS "$MOUNT_POINT/" "$DESTINATION/" 2>&1 | tee -a "$LOG_FILE"
    RSYNC_EXIT="${PIPESTATUS[0]}"

    if [ "$RSYNC_EXIT" -ne 0 ]; then
        echo "rsync reported an error (exit code $RSYNC_EXIT) - see $LOG_FILE for details." | tee -a "$LOG_FILE" >&2
        return 1
    fi

    echo "Sync complete. Log: $LOG_FILE"
    return 0
}

# --- launchd ---------------------------------------------------------------

install_task() {
    UID_NUM="$(id -u)"
    SCRIPT_PATH="$SCRIPT_DIR/seestar-sync.sh"

    if [ -n "$TASK_INTERVAL_MINUTES" ]; then
        SCHEDULE_XML="<key>StartInterval</key><integer>$((TASK_INTERVAL_MINUTES * 60))</integer>"
        SCHEDULE_DESC="every $TASK_INTERVAL_MINUTES minute(s)"
    else
        HOUR="${TASK_TIME%%:*}"
        MINUTE="${TASK_TIME##*:}"
        SCHEDULE_XML="<key>StartCalendarInterval</key><dict><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>$MINUTE</integer></dict>"
        SCHEDULE_DESC="once daily at $TASK_TIME (this Mac's local time)"
    fi

    mkdir -p "$HOME/Library/LaunchAgents"
    cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$SCRIPT_PATH</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$SCRIPT_DIR</string>
    $SCHEDULE_XML
    <key>StandardOutPath</key>
    <string>$SCRIPT_DIR/logs/launchd.out.log</string>
    <key>StandardErrorPath</key>
    <string>$SCRIPT_DIR/logs/launchd.err.log</string>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

    mkdir -p "$SCRIPT_DIR/logs"

    # Unload first if it's already registered, so re-running this after
    # changing --task-time/--task-interval-minutes updates it in place
    # instead of erroring that the label already exists.
    launchctl bootout "gui/$UID_NUM/$LABEL" 2>/dev/null

    launchctl bootstrap "gui/$UID_NUM" "$PLIST_PATH"
    log "Registered LaunchAgent '$LABEL', running $SCHEDULE_DESC."
    log "Check on it any time with: launchctl list | grep $LABEL"
    log "Remove it with: ./seestar-sync.sh --uninstall-task"
}

# --- main --------------------------------------------------------------

read_or_create_config

if ! do_sync; then
    SYNC_OK=0
else
    SYNC_OK=1
fi

if [ "$INSTALL_TASK" -eq 1 ]; then
    install_task
fi

if [ "$SYNC_OK" -ne 1 ]; then
    exit 1
fi
