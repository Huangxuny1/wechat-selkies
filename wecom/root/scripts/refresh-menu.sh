#!/bin/bash
# Regenerate openbox right-click menu from defaults + ~/Desktop/*.desktop files
set -e

MENU_DEFAULT="/defaults/menu.xml"
MENU_TARGET="/config/.config/openbox/menu.xml"
MENU_TMP=$(mktemp)
trap 'rm -f "$MENU_TMP"' EXIT

mkdir -p /config/.config/openbox
cp "$MENU_DEFAULT" "$MENU_TMP"

wecom_icon="$(find /opt/apps/com.qq.weixin.work.deepin/entries/icons -type f \( -name '*.png' -o -name '*.svg' \) 2>/dev/null | head -n 1 || true)"
if [ -n "$wecom_icon" ]; then
    sed -i "s|<item label=\"WeCom\">|<item label=\"WeCom\" icon=\"$wecom_icon\">|" "$MENU_TMP"
fi

if ! command -v pcmanfm >/dev/null; then
    sed -i '\|<command>pcmanfm</command>|d' "$MENU_TMP"
fi

if ls "$HOME/Desktop/"*.desktop >/dev/null 2>&1; then
    for desktop_file in "$HOME/Desktop/"*.desktop; do
        name=$(grep -E "^Name=" "$desktop_file" | head -n 1 | cut -d "=" -f 2-)
        exec_cmd=$(grep -E "^Exec=" "$desktop_file" | head -n 1 | cut -d "=" -f 2-)
        icon=$(grep -E "^Icon=" "$desktop_file" | head -n 1 | cut -d "=" -f 2-)

        [ -z "$name" ] || [ -z "$exec_cmd" ] && continue

        exec_cmd=$(echo "$exec_cmd" | sed 's/ %[fFuU]//g')

        if [ -n "$icon" ] && [ "${icon#/}" = "$icon" ]; then
            icon_resolved=""
            for size in 256x256 512x512 128x128 64x64 48x48 scalable; do
                found=$(find /opt/apps/*/entries/icons/hicolor/"$size"/apps/"$icon".* /usr/share/icons/hicolor/"$size"/apps/"$icon".* 2>/dev/null | head -n 1 || true)
                if [ -n "$found" ]; then
                    icon_resolved="$found"
                    break
                fi
            done
            [ -n "$icon_resolved" ] && icon="$icon_resolved"
        fi

        [ -z "$icon" ] && icon="/usr/share/pixmaps/xterm-color_48x48.xpm"

        exec_cmd=$(echo "$exec_cmd" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
        name=$(echo "$name" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')
        icon=$(echo "$icon" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g')

        printf '<item label="%s" icon="%s"><action name="Execute"><command>%s</command></action></item>\n' \
            "$name" "$icon" "$exec_cmd" | sed -i '/<menu id="root-menu" label="MENU">/r /dev/stdin' "$MENU_TMP"
    done
fi

if [ ! -f "$MENU_TARGET" ] || ! cmp -s "$MENU_TMP" "$MENU_TARGET"; then
    cat "$MENU_TMP" > "$MENU_TARGET"
    openbox --reconfigure 2>/dev/null || true
fi
