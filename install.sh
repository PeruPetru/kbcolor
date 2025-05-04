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


#install if not previously installed
if ! [[ -f "${RULE_DIR}/${RULE_FILENAME}" ]]; then    
    echo "Installing udev rule: ${RULE_FILENAME}"
    echo "Copying ${SCRIPT_DIR}/${RULE_FILENAME} → ${RULE_DIR}/${RULE_FILENAME}"
    cp "${SCRIPT_DIR}/${RULE_FILENAME}" "${RULE_DIR}/${RULE_FILENAME}"
    echo "Reloading udev rules"
    udevadm control --reload-rules
    udevadm trigger
    echo "udev rules installed."
fi

# Check group membership and add if needed
if ! getent group "${GROUP_NAME}" >/dev/null; then
  echo "Group '${GROUP_NAME}' does not exist — creating it now…"
  groupadd "${GROUP_NAME}"
  echo "Group '${GROUP_NAME}' created."
fi

invoking_user="${SUDO_USER:-$USER}"
if id -nG "${invoking_user}" | grep -qw "${GROUP_NAME}"; then
    echo "User '${invoking_user}' is already in group '${GROUP_NAME}'."
else
    echo "Adding '${invoking_user}' to group '${GROUP_NAME}'."
    usermod -aG "${GROUP_NAME}" "${invoking_user}"
    echo "Note: ${invoking_user} must log out and back in for the change to take effect."
fi

echo "Building program"
make

if ! [[ -f "${LOCAL_BINARY_DIR}/${PROGRAM_NAME}" ]]; then
    echo "Linking executable"
    sudo ln -s "${SCRIPT_DIR}/${PROGRAM_NAME}" "${LOCAL_BINARY_DIR}/${PROGRAM_NAME}"
fi

if ! [[ -f "${LOCAL_BINARY_DIR}/${DAEMON_NAME}" ]]; then
    echo "Linking daemon"
    sudo ln -s "${SCRIPT_DIR}/${DAEMON_NAME}" "${LOCAL_BINARY_DIR}/${DAEMON_NAME}"
fi

if ! [[ -f "${SERVICE_DIR}/${PROGRAM_NAME}" ]]; then
    echo "Linking service"
    sudo ln -s "${SCRIPT_DIR}/${PROGRAM_NAME}.service" "${SERVICE_DIR}/${PROGRAM_NAME}.service"
fi

systemctl enable --now kbcolor

echo "Installation complete."
