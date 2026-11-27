# WeCom Selkies（独立镜像 · Deepin-Wine · AMD64）

本项目是 `wechat-selkies` 的独立衍生镜像，基于 **LinuxServer Selkies (`ubuntunoble`, Ubuntu 24.04)** 与 **Deepin-Wine (`com.qq.weixin.work.deepin` / `deepin-wine10-stable`)**，在浏览器中通过 WebRTC 直接使用企业微信（WeCom）。

> **架构限制**：仅支持 `linux/amd64`。

## 架构说明

- **基础镜像**：`ghcr.io/linuxserver/baseimage-selkies:ubuntunoble`（Ubuntu 24.04 + Openbox + X11 + Selkies WebRTC + `stalonetray` 托盘）
- **企业微信运行层**：来自 [zq1997/deepin-wine](https://github.com/zq1997/deepin-wine) 移植源的 `com.qq.weixin.work.deepin`（依赖 `deepin-wine10-stable`、`deepin-wine-helper`）
- **Ubuntu 24.04 兼容处理**：
  - 将 `libsane1`、`libsane-common` Pin 到 `deepin-wine` 源，满足 `deepin-wine10-stable` 对 `libsane` 的依赖
  - 将 `p7zip`、`p7zip-full` Pin 到 `deepin-wine` 源的 `16.02+dfsg-8`，规避 Ubuntu 24.04 默认过渡包 `7zip` 解压容器时丢弃软链接导致启动失败的问题
  - 启动前预创建 `/config/Desktop`、`/config/Downloads`、`/config/Documents`，确保 Wine 瓶子内的 `My Documents` 正确软链到 `/config/Documents`，聊天数据与接收文件（`/config/Documents/WXWork`）在容器升级重建 Wine 瓶子后依然保留

## 快速开始

```bash
cd wecom
cp .env.example .env
# 编辑 .env 设置 PASSWORD（若与 wechat-selkies 同机运行，同时修改 HTTP_PORT / HTTPS_PORT）
docker compose up -d --build
```

启动后在浏览器访问：`https://localhost:3001`（或 `.env` 中配置的 `HTTPS_PORT`）。

> 首次启动需要解压企业微信 Deepin-Wine 容器（`~/.deepinwine/Deepin-WXWork`），耗时约 20–60 秒（视磁盘速度而定），请耐心等待登录窗口弹出。

## 环境变量说明

| 变量名 | 默认值 | 说明 |
| --- | --- | --- |
| `HTTP_PORT` / `HTTPS_PORT` | `3000` / `3001` | 宿主机映射端口 |
| `PUID` / `PGID` | `1000` / `100` | 容器桌面会话的用户/组 ID |
| `CUSTOM_USER` | `abc` | Web UI 登录用户名 |
| `PASSWORD` | - | Web UI 登录密码（必填） |
| `TITLE` | `WeCom-Selkies` | Web UI 页面标题 |
| `TZ` | `Asia/Shanghai` | 时区 |
| `LC_ALL` | `zh_CN.UTF-8` | 语言环境 |
| `AUTO_START_WECOM` | `true` | 桌面就绪后是否自动启动企业微信 |
| `WECOM_DPI` | 空 | 可选覆盖 Wine DPI（如 `96`、`120`、`144`） |
| `SHM_SIZE` | `2gb` | 共享内存大小，建议至少 `2gb` |
| `ENABLE_WECOM_NIGHTLY_RESTART` | `false` | 是否启用凌晨定时停启 |
| `WECOM_NIGHTLY_STOP_TIME` | `23:30` | 定时停止时间（`HH:MM`） |
| `WECOM_NIGHTLY_START_TIME` | `01:30` | 定时重启时间（`HH:MM`） |

## 持久化目录与文件传输

所有数据持久化在宿主机 `wecom/config/`（对应容器 `/config`）：

- **聊天记录与文件**：`/config/Documents/WXWork`
- **Wine 容器目录**：`/config/.deepinwine/Deepin-WXWork`
- **浏览器侧栏文件上传下载目录**：`/config/Desktop`（在企业微信文件选择框中对应 `桌面` 或 `Z:\config\Desktop`）

若企业微信运行异常需要重置 Wine 容器（不会删除 `/config/Documents/WXWork` 聊天记录）：

```bash
docker exec -u abc wecom-selkies /scripts/wecom/wecom-stop.sh
rm -rf ./config/.deepinwine/Deepin-WXWork
docker exec -u abc wecom-selkies /scripts/wecom/wecom-restart.sh
```

## 已知限制

1. **仅支持真实 `linux/amd64`（`x86_64`）主机**：在 Apple Silicon（ARM64）宿主机上通过 Rosetta 2 模拟 `linux/amd64` 时，Rosetta 2 不支持 Wine WoW64 的 32 位 GDT 段切换（会出现 `rosetta error: invalid gdt selector index`），因此**需要部署在真实 `x86_64` Linux 服务器/NAS 上运行**。
2. **无原生 Pelorus / AT-SPI 控件树**：企业微信运行在 Wine 兼容层内，Linux AT-SPI2 无法直接读取其内部控件树，不支持原版 `wechat-selkies` 的 AT-SPI 自动登录或控件树 API。
3. **企业安全合规**：请遵守所在企业的终端安全策略与腾讯企业微信用户协议。
