#!/bin/bash
# Run as root: sudo bash scripts/install-gdm-config.sh
set -e

UNITS=""
for unit in gdm gdm3; do
    if systemctl cat "$unit.service" >/dev/null 2>&1; then
        UNITS="$UNITS $unit"
    fi
done
[ -z "$UNITS" ] && UNITS="gdm"

echo "Configuring GDM to recognize sessions in /opt/local/share..."

for unit in $UNITS; do
    CONFIG_DIR="/etc/systemd/system/$unit.service.d"
    CONFIG_FILE="$CONFIG_DIR/singularity-session.conf"
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << EOF
[Service]
Environment="XDG_DATA_DIRS=/var/lib/flatpak/exports/share:/opt/local/share:/usr/local/share:/usr/share"
EOF
    echo "Created $CONFIG_FILE"
done

if command -v systemctl >/dev/null 2>&1; then
    echo "Reloading systemd daemon..."
    systemctl daemon-reload
    echo "GDM configuration updated. Please restart GDM or reboot to see the changes."
else
    echo "Warning: systemctl not found. Manual reload/reboot required."
fi
