# BootMixs — ISO Remix Studio

BootMixs is a toolkit for remixing Linux systems into custom bootable ISO images.
It uses debootstrap, chroot, and xorriso/mkisofs to build clean, portable ISOs with
reproducible configurations and logs.

## Project Structure

<pre>
bootmixs/
├── build.sh              # Optional meta script (future: syswide / docker)
├── chroot/               # Base system created by debootstrap
├── docker/               # Containerized build workflow (planned)
└── syswide/
    ├── build.sh          # Main system-wide build script
    ├── config/           # Configuration files
    │   ├── packages.txt          # Packages to install
    │   ├── sources.list          # APT repositories
    │   ├── hostname.conf         # System hostname
    │   ├── fstab.conf            # Filesystem mounts
    │   ├── boot-options.conf     # Kernel boot parameters
    │   └── users.conf            # Default users and passwords
    ├── iso/               # ISO staging directory (kernel, bootloader, etc.)
    └── output/            # Logs, finished ISOs, checksums
</pre>
        # Logs, finished ISOs, checksums

## Usage

Run the following commands from inside the syswide/ directory.

./build.sh init
    Bootstrap the base system into chroot/

./build.sh remix
    Apply configuration files and install packages

./build.sh build
    Generate the ISO image at output/bootmixs.iso

./build.sh verify
    Generate checksums for verification

## Output

ISO image:
    syswide/output/bootmixs.iso

Checksums:
    syswide/output/*.sha256

Logs:
    syswide/output/logs/
