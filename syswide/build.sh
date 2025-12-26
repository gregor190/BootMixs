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

function remix() {
    log "Entering chroot to apply configs..."
    sudo cp "$CONFIG_DIR/sources.list" "$CHROOT_DIR/etc/apt/sources.list"
    sudo chroot "$CHROOT_DIR" /bin/bash -c "
        apt update &&
        xargs -a /config/packages.txt apt install -y
    " | tee -a "$LOGFILE"

    # Apply hostname
    echo "$(cat $CONFIG_DIR/hostname.conf)" | sudo tee "$CHROOT_DIR/etc/hostname"

    # Apply fstab
    sudo cp "$CONFIG_DIR/fstab.conf" "$CHROOT_DIR/etc/fstab"

    log "Configs applied."
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
