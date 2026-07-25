<p align="center">
  <a href="https://github.com/voorz/vohive-release/blob/master/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/voorz/vohive-release/releases"><img src="https://img.shields.io/badge/version-v1.5.3-green.svg" alt="Version"></a>
  <img src="https://img.shields.io/badge/platform-Linux%20%7C%20OpenWrt-lightgrey.svg" alt="Platform">
</p>

<p align="center">
  <a href="README.zh-CN.md">中文</a> | <b>English</b>
</p>

<h1 align="center">VoHive Release</h1>

One-line installation and lifecycle management for VoHive — a high-performance VoWiFi signaling proxy.

## Prerequisites

- Linux (amd64 / arm64 / armv7)
- `curl` or `wget`
- `root` or `sudo` privileges

If `curl` / `wget` is not installed:

```bash
apt update && apt install -y curl
```

## Quick Start

### Install

Install the latest stable release:

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/install.sh | bash
```

or

```bash
wget -O - https://raw.githubusercontent.com/voorz/vohive-release/master/install.sh | sh
```

Install a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/install.sh | bash -s -- --version v1.5.5
```

After installation, open `http://<host-ip>:7575` in your browser.

| Item | Value |
|------|-------|
| Default port | `7575` |
| Default credentials | `admin` / `admin` |

### Verify Installation

```bash
# systemd
systemctl status vohive

# OpenWrt
/etc/init.d/vohive status
```

### View Logs

```bash
# systemd
journalctl -u vohive -f

# OpenWrt
logread -f
```

## Upgrade

Re-run the installer to perform an in-place upgrade. The previous binary is automatically backed up to `/opt/vohive/bin/vohive.bak`.

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/install.sh | bash
```

To install a specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/install.sh | bash -s -- --version v1.5.3
```

## Rollback

Install a previous version:

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/install.sh | bash -s -- --version v1.5.2
```

Or manually restore the backup:

```bash
# systemd
sudo cp /opt/vohive/bin/vohive.bak /opt/vohive/bin/vohive
sudo systemctl restart vohive

# OpenWrt
cp /opt/vohive/bin/vohive.bak /opt/vohive/bin/vohive
/etc/init.d/vohive restart
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/uninstall.sh | sudo bash
```

Remove everything including configuration and data:

```bash
curl -fsSL https://raw.githubusercontent.com/voorz/vohive-release/master/uninstall.sh | sudo bash -s -- --purge
```

## Installer Options

| Flag | Description |
|------|-------------|
| `--version <vX.Y.Z\|latest\|stable>` | Install a specific version |
| `--channel <stable\|latest>` | Select release channel |
| `--no-systemd` | Skip service registration (compatibility mode) |
| `--dry-run` | Preview actions without making changes |
| `--force` | Overwrite existing configuration |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VOHIVE_RELEASE_REPO` | `voorz/vohive-release` | GitHub repository for releases |
| `VOHIVE_RELEASE_CHANNEL` | `stable` | Default release channel |
| `VOHIVE_INSTALL_ROOT` | `/opt/vohive` | Installation root directory |

## Directory Layout

```
/opt/vohive
├── bin/
│   └── vohive              # Binary
├── config/
│   └── config.yaml         # Configuration file
├── data/                   # Runtime data
└── logs/                   # Log files
```

## Project Structure

```
.
├── install.sh              # Installer script
├── uninstall.sh            # Uninstaller script
├── versions.json           # Version metadata
├── systemd/
│   └── vohive.service      # systemd unit template
└── tests/
    └── installer_compat_test.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-change`)
3. Commit your changes (`git commit -m 'Add feature'`)
4. Push to the branch (`git push origin feature/my-change`)
5. Open a Pull Request

## License

[MIT](LICENSE)
