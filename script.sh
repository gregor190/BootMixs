#!/bin/bash
# BootMixs config scaffolding script
# Adds missing folders/files under syswide/config without overwriting existing ones

set -e

CONFIG_DIR="syswide/config"

echo "[BootMixs] Checking config structure in $CONFIG_DIR ..."

# Core files (create only if missing)
for file in boot-options.conf fstab.conf hostname.conf packages.txt sources.list users.conf; do
    if [ ! -f "$CONFIG_DIR/$file" ]; then
        echo "[BootMixs] Creating $file ..."
        touch "$CONFIG_DIR/$file"
    fi
done

# Branding subfolder
if [ ! -d "$CONFIG_DIR/branding" ]; then
    echo "[BootMixs] Creating branding/ ..."
    mkdir -p "$CONFIG_DIR/branding"
    echo "# Place wallpapers, mascot images, and themes here" > "$CONFIG_DIR/branding/README.md"
fi

# Scripts subfolder
if [ ! -d "$CONFIG_DIR/scripts" ]; then
    echo "[BootMixs] Creating scripts/ ..."
    mkdir -p "$CONFIG_DIR/scripts"
    cat <<'EOF' > "$CONFIG_DIR/scripts/post-install.sh"
#!/bin/bash
echo "[BootMixs] Running post-install tweaks..."
EOF
    chmod +x "$CONFIG_DIR/scripts/post-install.sh"
fi

# Services subfolder
if [ ! -d "$CONFIG_DIR/services" ]; then
    echo "[BootMixs] Creating services/ ..."
    mkdir -p "$CONFIG_DIR/services"
    cat <<'EOF' > "$CONFIG_DIR/services/example.service"
[Unit]
Description=Example service

[Service]
ExecStart=/bin/true

[Install]
WantedBy=multi-user.target
EOF
fi

# Network subfolder
if [ ! -d "$CONFIG_DIR/network" ]; then
    echo "[BootMixs] Creating network/ ..."
    mkdir -p "$CONFIG_DIR/network"
    cat <<'EOF' > "$CONFIG_DIR/network/interfaces.conf"
auto lo
iface lo inet loopback
EOF
fi

# Security subfolder
if [ ! -d "$CONFIG_DIR/security" ]; then
    echo "[BootMixs] Creating security/ ..."
    mkdir -p "$CONFIG_DIR/security"
    echo "root ALL=(ALL:ALL) ALL" > "$CONFIG_DIR/security/sudoers.conf"
fi

echo "[BootMixs] Config scaffolding complete."
