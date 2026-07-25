#!/bin/sh
set -eu

REPO="${VOHIVE_RELEASE_REPO:-voorz/vohive-release}"
CHANNEL="${VOHIVE_RELEASE_CHANNEL:-stable}"
VERSION=""
NO_SYSTEMD=0
DRY_RUN=0
FORCE=0

ROOT_DIR="${VOHIVE_INSTALL_ROOT:-/opt/vohive}"
INSTALL_DIR="${ROOT_DIR}/bin"
CONFIG_DIR="${ROOT_DIR}/config"
DATA_DIR="${ROOT_DIR}/data"
LOG_DIR="${ROOT_DIR}/logs"
BIN_PATH="${INSTALL_DIR}/vohive"
BACKUP_PATH="${INSTALL_DIR}/vohive.bak"
SYSTEMD_SERVICE_PATH="${VOHIVE_SYSTEMD_SERVICE_PATH:-/etc/systemd/system/vohive.service}"
OPENWRT_INIT_PATH="${VOHIVE_OPENWRT_INIT_PATH:-/etc/init.d/vohive}"
OPENWRT_RELEASE_FILE="${VOHIVE_OPENWRT_RELEASE_FILE:-/etc/openwrt_release}"
PROCD_PATH="${VOHIVE_PROCD_PATH:-/sbin/procd}"
SYSTEMD_RUN_DIR="${VOHIVE_SYSTEMD_RUN_DIR:-/run/systemd/system}"

DOWNLOAD_CMD=""
TMP_DIR=""
ACTIVE_PLATFORM="none"

log() { printf '[vohive-install] %s\n' "$*"; }
err() { printf '[vohive-install] 错误: %s\n' "$*" >&2; }

usage() {
  cat <<USAGE
用法: install.sh [选项]
  --version <vX.Y.Z|latest|stable>
  --channel <stable|latest>
  --no-systemd
  --dry-run
  --force
USAGE
}

run_root() {
  if [ "${DRY_RUN}" = "1" ]; then
    printf '[dry-run] %s' "$1"
    shift
    for arg in "$@"; do
      printf ' %s' "$arg"
    done
    printf '\n'
    return 0
  fi

  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    err "需要 root 权限（请使用 root 用户或安装 sudo）。"
    exit 1
  fi
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "缺少命令: $1"
    exit 1
  fi
}

need_download_cmd() {
  if command -v curl >/dev/null 2>&1; then
    DOWNLOAD_CMD="curl"
    return 0
  fi
  if command -v wget >/dev/null 2>&1; then
    DOWNLOAD_CMD="wget"
    return 0
  fi
  err "缺少下载命令: 需要 curl 或 wget"
  exit 1
}

download_to() {
  url="$1"
  dest="$2"
  if [ "${DOWNLOAD_CMD}" = "curl" ]; then
    curl -fsSL "$url" -o "$dest"
  else
    wget -q -O "$dest" "$url"
  fi
}

fetch_text() {
  url="$1"
  tmp_file="${TMP_DIR}/fetch.txt"
  download_to "$url" "$tmp_file"
  cat "$tmp_file"
}

resolve_version() {
  requested="$1"

  if [ -z "${requested}" ]; then
    requested="${CHANNEL}"
  fi

  case "${requested}" in
    latest|stable)
      api_url="https://api.github.com/repos/${REPO}/releases/latest"
      latest_json="$(fetch_text "${api_url}")"
      resolved="$(printf '%s\n' "${latest_json}" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
      if [ -z "${resolved}" ]; then
        err "无法从 GitHub API 获取最新 Release 版本号。"
        exit 1
      fi
      printf '%s\n' "${resolved}"
      ;;
    *)
      printf '%s\n' "${requested}"
      ;;
  esac
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --version)
        if [ "$#" -lt 2 ]; then
          err "--version 缺少参数"
          usage
          exit 1
        fi
        VERSION="$2"
        shift 2
        ;;
      --channel)
        if [ "$#" -lt 2 ]; then
          err "--channel 缺少参数"
          usage
          exit 1
        fi
        CHANNEL="$2"
        shift 2
        ;;
      --no-systemd)
        NO_SYSTEMD=1
        shift
        ;;
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --force)
        FORCE=1
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "未知参数: $1"
        usage
        exit 1
        ;;
    esac
  done
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) printf 'amd64\n' ;;
    aarch64|arm64) printf 'arm64\n' ;;
    armv7|armv7l) printf 'armv7\n' ;;
    *)
      err "不支持的架构: $(uname -m)"
      exit 1
      ;;
  esac
}

detect_platform() {
  if [ -n "${VOHIVE_PLATFORM_OVERRIDE:-}" ]; then
    printf '%s\n' "${VOHIVE_PLATFORM_OVERRIDE}"
    return 0
  fi
  if [ -f "${OPENWRT_RELEASE_FILE}" ] || [ -x "${PROCD_PATH}" ]; then
    printf 'openwrt\n'
    return 0
  fi
  if command -v systemctl >/dev/null 2>&1 && { [ -d "${SYSTEMD_RUN_DIR}" ] || [ -f "${SYSTEMD_RUN_DIR}" ]; }; then
    printf 'systemd\n'
    return 0
  fi
  printf 'none\n'
}

install_default_config() {
  run_root mkdir -p "${INSTALL_DIR}" "${CONFIG_DIR}" "${DATA_DIR}" "${LOG_DIR}"
  if [ "${DRY_RUN}" = "1" ]; then
    return 0
  fi
  if [ ! -f "${CONFIG_DIR}/config.yaml" ] || [ "${FORCE}" = "1" ]; then
    run_root sh -c "cat >\"${CONFIG_DIR}/config.yaml\"" <<'CFG'
server:
  port: ":7575"

web:
  username: "admin"
  password: "admin"
CFG
  fi
}

install_service_systemd() {
  tmp_unit_path="$1"
  cat >"${tmp_unit_path}" <<EOF
[Unit]
Description=VoHive Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=${ROOT_DIR}
ExecStart=${BIN_PATH} -c ${CONFIG_DIR}/config.yaml
Restart=always
RestartSec=3
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

  run_root install -m 0644 "${tmp_unit_path}" "${SYSTEMD_SERVICE_PATH}"
  run_root systemctl daemon-reload
  run_root systemctl enable vohive
  run_root systemctl restart vohive
  run_root systemctl is-active --quiet vohive
}

install_service_openwrt() {
  tmp_init_path="$1"
  cat >"${tmp_init_path}" <<EOF
#!/bin/sh /etc/rc.common
START=99
USE_PROCD=1

start_service() {
  procd_open_instance
  procd_set_param command ${BIN_PATH} -c ${CONFIG_DIR}/config.yaml
  procd_set_param directory ${ROOT_DIR}
  procd_set_param respawn 3600 5 5
  procd_set_param stdout 1
  procd_set_param stderr 1
  procd_close_instance
}
EOF

  run_root install -m 0755 "${tmp_init_path}" "${OPENWRT_INIT_PATH}"
  run_root "${OPENWRT_INIT_PATH}" enable
  run_root "${OPENWRT_INIT_PATH}" restart
}

restart_service() {
  case "$1" in
    systemd)
      run_root systemctl restart vohive || true
      ;;
    openwrt)
      run_root "${OPENWRT_INIT_PATH}" restart || true
      ;;
  esac
}

collect_ips() {
  ips=""
  if command -v hostname >/dev/null 2>&1; then
    ips="$(hostname -I 2>/dev/null || true)"
  fi
  if [ -n "${ips}" ]; then
    printf '%s\n' "${ips}"
    return 0
  fi
  if command -v ip >/dev/null 2>&1; then
    ip -o -4 addr show scope global | awk '{print $4}' | cut -d/ -f1
  fi
}

print_access_info() {
  port="7575"
  log "最小配置已生成: ${CONFIG_DIR}/config.yaml"
  log "默认 Web 账号密码: admin / admin"
  log "一键访问链接: http://127.0.0.1:${port}"
  for ip in $(collect_ips); do
    case "$ip" in
      127.*|::1|"")
        continue
        ;;
    esac
    log "一键访问链接: http://${ip}:${port}"
  done
}

main() {
  parse_args "$@"

  need_cmd uname
  need_cmd mktemp
  need_download_cmd

  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  if [ "${os}" != "linux" ]; then
    err "不支持的系统: ${os}"
    exit 1
  fi

  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "${TMP_DIR}"' EXIT INT TERM

  arch="$(detect_arch)"
  resolved_version="$(resolve_version "${VERSION}")"
  asset="vohive_${resolved_version}_linux_${arch}"
  base="https://github.com/${REPO}/releases/download/${resolved_version}"
  downloaded="${TMP_DIR}/${asset}"
  extracted="${downloaded}"

  log "已解析版本: ${resolved_version}"
  log "正在下载二进制: ${base}/${asset}"

  download_to "${base}/${asset}" "${downloaded}"
  chmod +x "${downloaded}"

  if [ ! -f "${extracted}" ]; then
    err "下载的二进制文件不存在"
    exit 1
  fi

  if [ -x "${BIN_PATH}" ]; then
    log "检测到已安装版本，备份到: ${BACKUP_PATH}"
    run_root cp -f "${BIN_PATH}" "${BACKUP_PATH}"
  fi

  install_default_config
  rollback_needed=1

  rollback() {
    if [ "${rollback_needed}" = "1" ] && [ -f "${BACKUP_PATH}" ]; then
      err "正在回滚到上一个版本"
      run_root cp -f "${BACKUP_PATH}" "${BIN_PATH}" || true
      if [ "${NO_SYSTEMD}" = "0" ]; then
        restart_service "${ACTIVE_PLATFORM}"
      fi
    fi
  }

  run_root install -m 0755 "${extracted}" "${BIN_PATH}"

  ACTIVE_PLATFORM="$(detect_platform)"
  service_registered=0

  if [ "${NO_SYSTEMD}" = "0" ]; then
    case "${ACTIVE_PLATFORM}" in
      openwrt)
        if ! install_service_openwrt "${TMP_DIR}/vohive.init"; then
          rollback
          err "openwrt procd 安装或启动失败"
          exit 1
        fi
        service_registered=1
        ;;
      systemd)
        if ! install_service_systemd "${TMP_DIR}/vohive.service"; then
          rollback
          err "systemd 安装或启动失败"
          exit 1
        fi
        service_registered=1
        ;;
      none)
        log "未检测到 systemd 或 OpenWrt procd，跳过服务注册"
        ;;
      *)
        err "未知平台: ${ACTIVE_PLATFORM}"
        exit 1
        ;;
    esac
  else
    log "已跳过服务注册（--no-systemd 兼容模式）"
  fi

  rollback_needed=0
  log "安装完成: ${BIN_PATH} (${resolved_version})"

  if [ "${service_registered}" = "1" ]; then
    case "${ACTIVE_PLATFORM}" in
      openwrt)
        log "服务状态: 运行中（OpenWrt procd）"
        ;;
      systemd)
        log "服务状态: 运行中（systemd）"
        ;;
    esac
  else
    log "手动启动命令: ${BIN_PATH} -c ${CONFIG_DIR}/config.yaml"
  fi
  print_access_info
}

main "$@"
