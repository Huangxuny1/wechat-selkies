#!/bin/bash

# Clean up stale dbus pid file to prevent startup failures after container restart
rm -f /run/dbus/pid

# Ensure user directories exist before Deepin-Wine initializes bottle symlinks
export HOME="${HOME:-/config}"
export USER="${USER:-$(id -un)}"
mkdir -p "$HOME/Desktop" "$HOME/Downloads" "$HOME/Documents" "$HOME/.deepinwine"

# Configure Openbox dock mode for stalonetray
OB_RC="/config/.config/openbox/rc.xml"
if [ ! -f "$OB_RC" ] || grep -A20 "<dock>" "$OB_RC" | grep -q "<noStrut>no</noStrut>"; then
    mkdir -p /config/.config/openbox
    [ ! -f "$OB_RC" ] && cp /etc/xdg/openbox/rc.xml "$OB_RC"
    sed -i '/<dock>/,/<\/dock>/s/<noStrut>no<\/noStrut>/<noStrut>yes<\/noStrut>/' "$OB_RC"
    openbox --reconfigure 2>/dev/null || true
fi

# Prevent Openbox from force-maximizing WeCom windows and dialogs.
# Openbox applies matching rules in order (later rules override earlier ones),
# so append our rules at the end of <applications> / before </openbox_config>.
if [ -f "$OB_RC" ] && ! grep -q '<!-- WeCom fixed-size windows -->' "$OB_RC"; then
    if grep -q '</applications>' "$OB_RC"; then
        sed -i '/<\/applications>/i\    <!-- WeCom fixed-size windows -->\n    <application class="com.qq.weixin.work.deepin"><maximized>no</maximized></application>\n    <application class="wxwork.exe"><maximized>no</maximized></application>\n    <application class="WXWork.exe"><maximized>no</maximized></application>' "$OB_RC"
    else
        sed -i '/<\/openbox_config>/i\  <applications>\n    <!-- WeCom fixed-size windows -->\n    <application class="com.qq.weixin.work.deepin"><maximized>no</maximized></application>\n    <application class="wxwork.exe"><maximized>no</maximized></application>\n    <application class="WXWork.exe"><maximized>no</maximized></application>\n  </applications>' "$OB_RC"
    fi
    openbox --reconfigure 2>/dev/null || true
fi

# Generate Openbox menu from defaults + ~/Desktop/*.desktop files
/scripts/refresh-menu.sh

# Watch ~/Desktop/ for .desktop file changes and auto-refresh menu
if command -v inotifywait >/dev/null 2>&1; then
    (while inotifywait -q -e close_write,create,delete,moved_from,moved_to "$HOME/Desktop/" --include '\.desktop$'; do
        sleep 1
        /scripts/refresh-menu.sh
    done) >/dev/null 2>&1 &
fi

# Start system tray for WeCom minimize-to-tray icon
nohup stalonetray --dockapp-mode simple >/dev/null 2>&1 &

# Auto-start WeCom if enabled
if [ "${AUTO_START_WECOM:-true}" = "true" ]; then
    if [ -x /opt/apps/com.qq.weixin.work.deepin/files/run.sh ]; then
        nohup /scripts/wecom/wecom-start.sh >/tmp/wecom-start.log 2>&1 &
    fi
fi

# Start nightly restart daemon if enabled
if [ "${ENABLE_WECOM_NIGHTLY_RESTART:-false}" = "true" ]; then
    nohup /scripts/wecom/wecom-nightly-schedule.sh >/tmp/wecom-nightly.log 2>&1 &
fi
