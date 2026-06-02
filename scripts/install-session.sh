#!/bin/bash
# Run as root: sudo bash scripts/install-session.sh
set -e

if [ -n "$SUDO_USER" ]; then
    TARGET_USER="$SUDO_USER"
elif [ -n "$PKEXEC_UID" ]; then
    TARGET_USER=$(getent passwd "$PKEXEC_UID" | cut -d: -f1)
else
    echo "Error: run with sudo or run0, not as root directly." >&2
    exit 1
fi
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

if [ -x "/opt/local/bin/singularity-labwc-session" ]; then
    BIN="/opt/local/bin"
    LIB="/opt/local/lib"
    LAUNCHER="$BIN/singularity-labwc-session"
    echo "Using /opt/local installation..."
else
    BIN="$TARGET_HOME/.local/singularity/bin"
    LIB="$TARGET_HOME/.local/singularity/lib"
    LAUNCHER="$BIN/singularity-session"

    cat > "$LAUNCHER" << LAUNCHER_EOF
#!/bin/bash
BIN="$BIN"
export PATH="\$BIN:\$PATH"
export LD_LIBRARY_PATH="$LIB\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
LOG="/tmp/singularity-session.log"
exec > "\$LOG" 2>&1
echo "[\$(date)] Starting Singularity session"

nohup "\$BIN/singularity-polkit-agent" >> /tmp/singularity-polkit.log 2>&1 &

if [ -n "\$GDM_SESSION_DBUS_ADDRESS" ] && [ -x "/usr/libexec/gdm-wayland-session" ]; then
    echo "GDM detected - wrapping with gdm-wayland-session"
    exec /usr/libexec/gdm-wayland-session "\$BIN/labwc" -s "\$BIN/singularity-desktop-session"
else
    exec "\$BIN/labwc" -s "\$BIN/singularity-desktop-session"
fi
LAUNCHER_EOF
    chmod +x "$LAUNCHER"
    echo "Created $LAUNCHER"
fi

if [ -d "/opt/local" ]; then
    SESSION_DIR="/opt/local/share/wayland-sessions"
else
    SESSION_DIR="/usr/share/wayland-sessions"
fi
mkdir -p "$SESSION_DIR"

cat > "$SESSION_DIR/singularity.desktop" << EOF
[Desktop Entry]
Name=Singularity
Comment=Singularity Desktop Environment
Exec=$LAUNCHER
TryExec=$BIN/singularity-desktop
Type=Application
DesktopNames=Singularity
EOF
echo "Installed $SESSION_DIR/singularity.desktop"

ACCOUNTS="/var/lib/AccountsService/users/$TARGET_USER"
if [ -f "$ACCOUNTS" ]; then
    if grep -q "^XSession=" "$ACCOUNTS"; then
        sed -i 's/^XSession=.*/XSession=singularity/' "$ACCOUNTS"
    else
        echo "XSession=singularity" >> "$ACCOUNTS"
    fi
    echo "Updated AccountsService XSession=singularity"
fi

cat > "$TARGET_HOME/.dmrc" << EOF
[Desktop]
Session=singularity
EOF
chown "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/.dmrc"
echo "Updated $TARGET_HOME/.dmrc"

echo ""
echo "Done. You can now log in with Singularity from GDM."
