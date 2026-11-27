#!/bin/bash
set -e

# Selkies baseimage preloads joystick/fake-udev interposers that crash
# deepin-wine-banner (EFAULT / Bad address) and interfere with Wine.
unset LD_PRELOAD

export HOME="${HOME:-/config}"
export USER="${USER:-$(id -un)}"
export LANG="${LANG:-zh_CN.UTF-8}"
export LANGUAGE="${LANGUAGE:-zh_CN:zh}"
export LC_ALL="${LC_ALL:-zh_CN.UTF-8}"
export WINEDEBUG="${WINEDEBUG:--all}"
export XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:/opt/apps/com.qq.weixin.work.deepin/entries"

# Use a container-local 0700 runtime dir so Qt/DTK lockfiles and sockets do not
# fail on bind-mounted /config/.XDG volumes.
export XDG_RUNTIME_DIR="/tmp/runtime-wecom-$(id -u)"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Create standard XDG directories before Deepin-Wine runs FixLink so that
# My Documents links to /config/Documents (preserving chat data across upgrades)
mkdir -p "$HOME/Desktop" "$HOME/Downloads" "$HOME/Documents" "$HOME/.deepinwine"

WECOM_RUN="/opt/apps/com.qq.weixin.work.deepin/files/run.sh"
if [ ! -x "$WECOM_RUN" ]; then
    echo "WeCom launcher not found: $WECOM_RUN" >&2
    exit 1
fi

# Detect bottle name from run.sh (defaults to Deepin-WXWork)
BOTTLENAME="$(awk -F= '/^BOTTLENAME=/{gsub(/["'\'' ]/, "", $2); print $2; exit}' "$WECOM_RUN" 2>/dev/null || true)"
BOTTLENAME="${BOTTLENAME:-Deepin-WXWork}"
WINEPREFIX_DIR="$HOME/.deepinwine/$BOTTLENAME"

# Optional DPI override after bottle exists (or pre-create bottle first)
if [[ "${WECOM_DPI:-}" =~ ^[0-9]+$ ]] && [ "$WECOM_DPI" -ge 72 ] && [ "$WECOM_DPI" -le 384 ]; then
    if [ ! -d "$WINEPREFIX_DIR" ]; then
        "$WECOM_RUN" -cb || true
    fi
    if [ -d "$WINEPREFIX_DIR" ]; then
        WINE_BIN="$(awk -F= '/^export APPRUN_CMD=|^APPRUN_CMD=/{gsub(/["'\'' ]/, "", $2); print $2; exit}' "$WECOM_RUN" 2>/dev/null || true)"
        WINE_BIN="${WINE_BIN:-deepin-wine10-stable}"
        if command -v "$WINE_BIN" >/dev/null 2>&1; then
            WINEPREFIX="$WINEPREFIX_DIR" "$WINE_BIN" reg add 'HKCU\Control Panel\Desktop' /v LogPixels /t REG_DWORD /d "$WECOM_DPI" /f >/dev/null 2>&1 || true
        fi
    fi
fi

exec "$WECOM_RUN" "$@"
