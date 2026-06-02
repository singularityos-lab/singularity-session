#!/bin/bash
# Run as root: sudo bash scripts/install-gdm-config.sh
set -e

CONFIG_DIR="/etc/systemd/system/gdm.service.d"
CONFIG_FILE="$CONFIG_DIR/singularity-session.conf"

echo "Configuring GDM to recognize sessions in /opt/local/share..."

mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_FILE" << EOF
[Service]
Environment="XDG_DATA_DIRS=/var/lib/flatpak/exports/share:/opt/local/share:/usr/local/share:/usr/share"
EOF

echo "Created $CONFIG_FILE"

if command -v systemctl >/dev/null 2>&1; then
    echo "Reloading systemd daemon..."
    systemctl daemon-reload
    echo "GDM configuration updated. Please restart GDM or reboot to see the changes."
else
    echo "Warning: systemctl not found. Manual reload/reboot required."
fi
