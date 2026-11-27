# WeCom (Enterprise WeChat) for Linux via Deepin-Wine on Selkies WebRTC (linux/amd64 only)
FROM ghcr.io/linuxserver/baseimage-selkies:ubuntunoble

# Metadata labels
LABEL org.opencontainers.image.title="WeCom Selkies"
LABEL org.opencontainers.image.description="WeCom (Enterprise WeChat) via Deepin-Wine in a browser using Selkies WebRTC (amd64)"
LABEL org.opencontainers.image.source="https://github.com/nickrunning/wechat-selkies"
LABEL org.opencontainers.image.licenses="MIT"

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG INSTALL_PCMANFM=true
ARG WECOM_PACKAGE="com.qq.weixin.work.deepin"
ARG DEBIAN_FRONTEND=noninteractive

# Deepin-Wine packages require linux/amd64
RUN case "${TARGETPLATFORM:-linux/amd64}" in \
        "linux/amd64") echo "Building WeCom-Selkies on ${BUILDPLATFORM:-unknown}, targeting linux/amd64" ;; \
        *) echo "Unsupported platform: ${TARGETPLATFORM}. WeCom Deepin-Wine image only supports linux/amd64." >&2; exit 1 ;; \
    esac

# Base desktop utilities, Chinese locale/fonts, and tray support
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        locales \
        inotify-tools \
        stalonetray \
        xdg-utils \
        xdg-user-dirs \
        xdotool \
        zenity \
        fonts-noto-cjk \
        fonts-wqy-zenhei \
        fonts-wqy-microhei && \
    localedef -i zh_CN -f UTF-8 zh_CN.UTF-8 && \
    if [ "$INSTALL_PCMANFM" = "true" ]; then \
        apt-get install -y --no-install-recommends pcmanfm; \
    fi

# Configure deepin-wine.i-m.dev repository and APT pinning for Ubuntu 24.04 compatibility:
# - Pin libsane1/libsane-common to satisfy deepin-wine10-stable's libsane dependency
# - Pin p7zip/p7zip-full to 16.02+dfsg-8 to avoid Ubuntu 24.04's transitional 7zip package
#   stripping symlinks when unpacking Deepin-Wine bottles
RUN dpkg --add-architecture i386 && \
    printf '%s\n' 'deb [trusted=yes] https://deepin-wine.i-m.dev /' \
        > /etc/apt/sources.list.d/deepin-wine.i-m.dev.list && \
    printf '%s\n' \
        'Package: *' \
        'Pin: release l=deepin-wine' \
        'Pin-Priority: 400' \
        '' \
        'Package: libsane1 libsane-common p7zip p7zip-full' \
        'Pin: release l=deepin-wine' \
        'Pin-Priority: 1001' \
        > /etc/apt/preferences.d/deepin-wine.i-m.dev.pref && \
    printf '%s\n' \
        'XDG_DATA_DIRS=${XDG_DATA_DIRS:-/usr/local/share:/usr/share}' \
        'for deepin_dir in /opt/apps/*/entries; do' \
        '    if [ -d "$deepin_dir/applications" ]; then' \
        '        XDG_DATA_DIRS="$XDG_DATA_DIRS:$deepin_dir"' \
        '    fi' \
        'done' \
        'export XDG_DATA_DIRS' \
        > /etc/profile.d/deepin-wine.i-m.dev.sh

# Install WeCom Deepin-Wine package plus curated GUI/audio/TLS libraries recommended by Wine
# (using --no-install-recommends avoids pulling unnecessary host daemons like avahi/sane-airscan)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        "$WECOM_PACKAGE" \
        libglu1-mesa \
        libosmesa6 \
        libsdl2-2.0-0 \
        libv4l-0t64 \
        libxcursor1 \
        libgnutls30t64 \
        libgssapi-krb5-2 \
        libkrb5-3 && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf \
        /config/.cache \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*

# Configure Openbox dock mode for stalonetray
RUN sed -i '/<dock>/,/<\/dock>/s/<noStrut>no<\/noStrut>/<noStrut>yes<\/noStrut>/' /etc/xdg/openbox/rc.xml

# Update Selkies web UI favicon if WeCom PNG icon is available
RUN wecom_icon="$(find /opt/apps/com.qq.weixin.work.deepin/entries/icons -type f -name '*.png' 2>/dev/null | head -n 1 || true)" && \
    if [ -n "$wecom_icon" ] && [ -d /usr/share/selkies/www ]; then \
        cp "$wecom_icon" /usr/share/selkies/www/icon.png; \
    fi

# Default runtime configuration
ENV TITLE="WeCom-Selkies"
ENV TZ="Asia/Shanghai"
ENV LANG="zh_CN.UTF-8" \
    LANGUAGE="zh_CN:zh" \
    LC_ALL="zh_CN.UTF-8"
ENV AUTO_START_WECOM="true"
ENV WECOM_DPI=""
ENV ENABLE_WECOM_NIGHTLY_RESTART="false"
ENV WECOM_NIGHTLY_STOP_TIME="23:30"
ENV WECOM_NIGHTLY_START_TIME="01:30"

COPY root/ /
RUN chmod +x /scripts/*.sh /scripts/wecom/*.sh
