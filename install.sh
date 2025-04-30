#!/usr/bin/env bash
set -euo pipefail

# Determine the directory of this script, regardless of where it's called from
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Configuration
RULE_FILENAME="69-kbcolor.rules"
SOURCE_RULE="${SCRIPT_DIR}/${RULE_FILENAME}"
TARGET_DIR="/lib/udev/rules.d"
TARGET_RULE="${TARGET_DIR}/${RULE_FILENAME}"
GROUP_NAME="kbcolor"
LINKING_NAME="kbcolor"
LINKING_DIR="/usr/local/bin"

# Check for the rule file next to the script
if [[ ! -f "${SOURCE_RULE}" ]]; then
    echo "Error: '${RULE_FILENAME}' not found in script directory (${SCRIPT_DIR})."
    exit 1
fi

# Ensure we have root (re-exec with sudo if not)
if [[ "${EUID}" -ne 0 ]]; then
    echo "Re-running with sudo to gain necessary privileges…"
    exec sudo bash "$0" "$@"
fi

echo "==> Installing udev rule: ${RULE_FILENAME}"

# Backup existing rule if present
if [[ -f "${TARGET_RULE}" ]]; then
    exit 0
    #timestamp=$(date +%Y%m%d-%H%M%S)
    #backup="${TARGET_RULE}.bak.${timestamp}"
    #echo "Backing up existing rule to ${backup}"
    #cp "${TARGET_RULE}" "${backup}"
fi

# Copy the new/updated rule
echo "Copying ${SOURCE_RULE} → ${TARGET_RULE}"
cp "${SOURCE_RULE}" "${TARGET_RULE}"

# Reload and trigger udev
echo "Reloading udev rules"
udevadm control --reload-rules
udevadm trigger

echo "✅udev rules installed."

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

echo "Linking executable"
sudo ln -s "${SCRIPT_DIR}/${LINKING_NAME}" "${LINKING_DIR}/${LINKING_NAME}"

echo "Installation complete."
