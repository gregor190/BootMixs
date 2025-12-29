#!/bin/bash
# BootMixs build script
# Ritual flow: init → remix → build → verify

set -e
LOGFILE="output/build.log"
ISOFILE="output/bootmixs.iso"
CHROOT_DIR="chroot"
CONFIG_DIR="config"
ISO_DIR="iso"

function log() {
    echo "[BootMixs] $1" | tee -a "$LOGFILE"
}

function init() {
    log "Starting debootstrap..."
    sudo debootstrap stable "$CHROOT_DIR" http://deb.debian.org/debian | tee -a "$LOGFILE"
    log "Debootstrap complete."
}

remix() {
    log "Entering chroot to apply configs..."
    # Ensure output log exists
    mkdir -p "$(dirname "$LOGFILE")"

    # Sources list
    sudo cp "$CONFIG_DIR/sources.list" "$CHROOT_DIR/etc/apt/sources.list"

    # Install packages
    sudo chroot "$CHROOT_DIR" /bin/bash -c "
        apt update &&
        xargs -a /config/packages.txt apt install -y
    " | tee -a "$LOGFILE"

    # Apply hostname
    sudo cp "$CONFIG_DIR/hostname.conf" "$CHROOT_DIR/etc/hostname"

    # Apply fstab
    sudo cp "$CONFIG_DIR/fstab.conf" "$CHROOT_DIR/etc/fstab"

    # Branding (copy into /usr/share/bootmixs/branding)
    if [ -d "$CONFIG_DIR/branding" ]; then
        sudo mkdir -p "$CHROOT_DIR/usr/share/bootmixs/branding"
        sudo cp -r "$CONFIG_DIR/branding/"* "$CHROOT_DIR/usr/share/bootmixs/branding/"
    fi

    # Scripts (copy into /usr/local/bin/bootmixs-scripts and run post-install if present)
    if [ -d "$CONFIG_DIR/scripts" ]; then
        sudo mkdir -p "$CHROOT_DIR/usr/local/bin/bootmixs-scripts"
        sudo cp -r "$CONFIG_DIR/scripts/"* "$CHROOT_DIR/usr/local/bin/bootmixs-scripts/"
        if [ -f "$CONFIG_DIR/scripts/post-install.sh" ]; then
            sudo chroot "$CHROOT_DIR" /bin/bash /usr/local/bin/bootmixs-scripts/post-install.sh | tee -a "$LOGFILE"
        fi
    fi

    # Services (systemd units)
    if [ -d "$CONFIG_DIR/services" ]; then
        sudo cp -r "$CONFIG_DIR/services/"* "$CHROOT_DIR/etc/systemd/system/"
        for svc in "$CONFIG_DIR/services/"*.service; do
            [ -f "$svc" ] && svcname=$(basename "$svc") && \
            sudo chroot "$CHROOT_DIR" systemctl enable "$svcname" || true
        done
    fi

    # Network configs
    if [ -d "$CONFIG_DIR/network" ]; then
        # For classic Debian/Ubuntu networking
        if [ -f "$CONFIG_DIR/network/interfaces.conf" ]; then
            sudo cp "$CONFIG_DIR/network/interfaces.conf" "$CHROOT_DIR/etc/network/interfaces"
        fi
        # For netplan (Ubuntu newer releases)
        for netfile in "$CONFIG_DIR/network/"*.yaml; do
            [ -f "$netfile" ] && sudo cp "$netfile" "$CHROOT_DIR/etc/netplan/"
        done
    fi

    # Security (sudoers, etc.)
    if [ -d "$CONFIG_DIR/security" ]; then
        sudo mkdir -p "$CHROOT_DIR/etc/sudoers.d"
        for secfile in "$CONFIG_DIR/security/"*; do
            [ -f "$secfile" ] && sudo cp "$secfile" "$CHROOT_DIR/etc/sudoers.d/"
        done
    fi

    log "All configs applied."
}


function build_iso() {
    log "Building ISO..."
    xorriso -as mkisofs -o "$ISOFILE" "$ISO_DIR" | tee -a "$LOGFILE"
    log "ISO created at $ISOFILE"
}

function verify() {
    log "Generating checksum..."
    sha256sum "$ISOFILE" | tee "output/bootmixs.iso.sha256"
    log "Checksum saved."
}

case "$1" in
    init) init ;;
    remix) remix ;;
    build) build_iso ;;
    verify) verify ;;
    *) echo "Usage: $0 {init|remix|build|verify}" ;;
esac
