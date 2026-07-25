<p align="center">
  <a href="https://github.com/voorz/vohive-release/blob/master/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/voorz/vohive-release/releases"><img src="https://img.shields.io/badge/version-v1.5.3-green.svg" alt="Version"></a>
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20OpenWrt-lightgrey.svg" alt="Platform">
</p>

<p align="center">
  <b>中文</b> | <a href="README.md">English</a>
</p>

<h1 align="center">VoHive Release</h1>

VoHive 一键安装与生命周期管理工具。VoHive 是一个高性能的 VoWiFi 信令代理。

## 环境要求

- Linux (amd64 / arm64 / armv7)
- `curl` 或 `wget`
- `root` 或 `sudo` 权限

## 快速开始

### 安装

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/install.sh | bash
```

或

```bash
wget -O - https://raw.githubusercontent.com/voorz/vohive-release/master/install.sh | sh
```

安装完成后，在浏览器中打开 `http://<设备IP>:7575`。

| 项目 | 值 |
|------|-----|
| 默认端口 | `7575` |
| 默认账号密码 | `admin` / `admin` |

### 验证安装

```bash
# systemd
systemctl status vohive

# OpenWrt
/etc/init.d/vohive status
```

### 查看日志

```bash
# systemd
journalctl -u vohive -f

# OpenWrt
logread -f
```

## 升级

重新运行安装脚本即可执行原地升级，旧版本二进制会自动备份到 `/opt/vohive/bin/vohive.bak`。

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/install.sh | bash
```

指定版本安装：

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/install.sh | bash -s -- --version v1.5.3
```

## 回滚

安装指定旧版本：

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/install.sh | bash -s -- --version v1.5.2
```

或手动恢复备份：

```bash
# systemd
sudo cp /opt/vohive/bin/vohive.bak /opt/vohive/bin/vohive
sudo systemctl restart vohive

# OpenWrt
cp /opt/vohive/bin/vohive.bak /opt/vohive/bin/vohive
/etc/init.d/vohive restart
```

## 卸载

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/uninstall.sh | sudo bash
```

完全卸载（包括配置和数据）：

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/uninstall.sh | sudo bash -s -- --purge
```

## 安装参数

| 参数 | 说明 |
|------|------|
| `--version <vX.Y.Z\|latest\|stable>` | 指定安装版本 |
| `--channel <stable\|latest>` | 指定发布通道 |
| `--no-systemd` | 跳过服务注册（兼容模式） |
| `--dry-run` | 仅预览操作，不实际执行 |
| `--force` | 强制覆盖已有配置 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `VOHIVE_RELEASE_REPO` | `voorz/vohive-release` | GitHub 仓库地址 |
| `VOHIVE_RELEASE_CHANNEL` | `stable` | 默认发布通道 |
| `VOHIVE_INSTALL_ROOT` | `/opt/vohive` | 安装根目录 |

## 目录结构

```
/opt/vohive
├── bin/
│   └── vohive              # 程序二进制
├── config/
│   └── config.yaml         # 配置文件
├── data/                   # 运行时数据
└── logs/                   # 日志文件
```

## 项目结构

```
.
├── install.sh              # 安装脚本
├── uninstall.sh            # 卸载脚本
├── versions.json           # 版本元数据
├── systemd/
│   └── vohive.service      # systemd 服务模板
└── tests/
    └── installer_compat_test.sh
```

## 贡献

1. Fork 本仓库
2. 创建功能分支 (`git checkout -b feature/my-change`)
3. 提交更改 (`git commit -m 'Add feature'`)
4. 推送到远程 (`git push origin feature/my-change`)
5. 创建 Pull Request

## 许可证

[MIT](LICENSE)
