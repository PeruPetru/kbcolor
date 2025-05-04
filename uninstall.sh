#!/usr/bin/env bash
set -euo pipefail

# Determine the directory of this script, regardless of where it's called from
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Configuration
RULE_FILENAME="69-kbcolor.rules"
GROUP_NAME="kbcolor"
PROGRAM_NAME="kbcolor"
DAEMON_NAME="kbcolordaemon"

RULE_DIR="/lib/udev/rules.d"
LOCAL_BINARY_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"

# Ensure we have root (re-exec with sudo if not)
if [[ "${EUID}" -ne 0 ]]; then
    echo "Re-running with sudo to gain necessary privileges…"
    exec sudo bash "$0" "$@"
fi


if [[ -f "${RULE_DIR}/${RULE_FILENAME}" ]]; then    
    echo "Uninstalling udev rule: ${RULE_FILENAME}"
    rm "${RULE_DIR}/${RULE_FILENAME}"
    echo "Reloading udev rules"
    udevadm control --reload-rules
    udevadm trigger

    echo "Udev rules uninstalled."
fi

# Check group membership and add if needed
if getent group "${GROUP_NAME}" >/dev/null; then
  groupdel "${GROUP_NAME}"
  echo "Group '${GROUP_NAME}' created."
fi


if [[ -f "${LOCAL_BINARY_DIR}/${PROGRAM_NAME}" ]]; then
    echo "Unlinking executable"
    rm "${SCRIPT_DIR}/${PROGRAM_NAME}" "${LOCAL_BINARY_DIR}/${PROGRAM_NAME}"
fi

if [[ -f "${LOCAL_BINARY_DIR}/${DAEMON_NAME}" ]]; then
    echo "Unlinking daemon"
    rm "${SCRIPT_DIR}/${DAEMON_NAME}" "${LOCAL_BINARY_DIR}/${DAEMON_NAME}"
fi

if [[ -f "${SERVICE_DIR}/${PROGRAM_NAME}" ]]; then
    echo "Unlinking service"
    rm "${SCRIPT_DIR}/${PROGRAM_NAME}.service" "${SERVICE_DIR}/${PROGRAM_NAME}.service"
fi

if systemctl | grep PROGRAM_NAME; then
    systemctl disable --now kbcolor
fi
