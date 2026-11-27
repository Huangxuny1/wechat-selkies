#!/bin/bash

HOME="${HOME:-/config}"
WECOM_RUN="/opt/apps/com.qq.weixin.work.deepin/files/run.sh"
BOTTLENAME="$(awk -F= '/^BOTTLENAME=/{gsub(/["'\'' ]/, "", $2); print $2; exit}' "$WECOM_RUN" 2>/dev/null || true)"
BOTTLENAME="${BOTTLENAME:-Deepin-WXWork}"
WINEPREFIX_DIR="$HOME/.deepinwine/$BOTTLENAME"

if [ -x /opt/deepinwine/tools/kill.sh ]; then
    /opt/deepinwine/tools/kill.sh "$BOTTLENAME" >/dev/null 2>&1 || true
fi

WINE_BIN="$(awk -F= '/^export APPRUN_CMD=|^APPRUN_CMD=/{gsub(/["'\'' ]/, "", $2); print $2; exit}' "$WECOM_RUN" 2>/dev/null || true)"
WINE_BIN="${WINE_BIN:-deepin-wine10-stable}"
WINESERVER_BIN="/opt/${WINE_BIN}/bin/wineserver"
if [ -x "$WINESERVER_BIN" ] && [ -d "$WINEPREFIX_DIR" ]; then
    WINEPREFIX="$WINEPREFIX_DIR" "$WINESERVER_BIN" -k >/dev/null 2>&1 || true
fi

if pgrep -fi 'WXWork\.exe' >/dev/null 2>&1; then
    pkill -15 -fi 'WXWork\.exe' 2>/dev/null || true
    sleep 3
    if pgrep -fi 'WXWork\.exe' >/dev/null 2>&1; then
        pkill -9 -fi 'WXWork\.exe' 2>/dev/null || true
    fi
fi

# Clean up lingering Deepin banner process so future launches are not blocked
pkill -f '/opt/deepinwine/tools/deepin-wine-banner' 2>/dev/null || true
