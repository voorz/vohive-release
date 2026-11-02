#!/bin/sh
# VoHive launch script for platforms without systemd or OpenWrt procd
# (e.g. Alpine Linux, proot/Podroid, plain containers)
# Usage: /opt/vohive/start.sh [extra args passed to vohive]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "${SCRIPT_DIR}" || { echo "cannot cd to ${SCRIPT_DIR}"; exit 1; }
exec "${SCRIPT_DIR}/bin/vohive" -c "${SCRIPT_DIR}/config/config.yaml" "$@"
