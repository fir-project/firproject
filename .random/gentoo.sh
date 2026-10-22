
#!/usr/bin/env bash
set -Eeuo pipefail

# too lazy to manual install gentoo so i have this (TEMPORARY!!!!)
# Gentoo Quickstart: OpenRC
# UEFI / GPT / ext4 / GRUB / locally compiled distribution kernel

DISK="/dev/nvme0n1"
MNT="/mnt/gentoo"
HOSTNAME="gentoo"
TIMEZONE="Europe/Dublin"
JOBS=3

BASE="https://distfiles.gentoo.org/releases/amd64/autobuilds"

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

[[ $EUID -eq 0 ]] || die "Run as root."
[[ -d /sys/firmware/efi ]] || die "Boot the live USB in UEFI mode."
[[ -b "$DISK" ]] || die "Target disk not found."

for cmd in parted partprobe lsblk wipefs mkfs.vfat mkfs.ext4 \
           blkid wget tar chroot mount umount mountpoint \
           udevadm sha512sum awk grep sed; do
    command -v "$cmd" >/dev/null || die "Missing command: $cmd"
done

echo "=== GENTOO QUICKSTART: OPENRC ==="
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS "$DISK"
echo
echo "WARNING: ALL DATA ON $DISK WILL BE ERASED."

read -r -p "Type $DISK to confirm: " answer
[[ "$answer" == "$DISK" ]] || die "Cancelled."

read -r -p "Type ERASE to confirm: " answer
[[ "$answer" == "ERASE" ]] || die "Cancelled."

if lsblk -nrpo MOUNTPOINT "$DISK" |
    grep -q '[^[:space:]]'; then
    die "A target partition is mounted."
fi

# Derive partition names for NVMe and SATA disks.
if [[ "$DISK" =~ [0-9]$ ]]; then
    SUF="p"
else
    SUF=""
fi

EFI="${DISK}${SUF}1"
ROOT="${DISK}${SUF}2"

mkdir -p "$MNT"

cleanup() {
    set +e
    for p in run dev sys proc; do
        mountpoint -q "$MNT/$p" &&
            umount -R "$MNT/$p"
    done
    mountpoint -q "$MNT/efi" && umount "$MNT/efi"
    mountpoint -q "$MNT" && umount "$MNT"
}
trap cleanup EXIT

# 1. Partition and format.
wipefs -af "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 1025MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart ROOT ext4 1025MiB 100%

partprobe "$DISK"
udevadm settle

[[ -b "$EFI" && -b "$ROOT" ]] ||
    die "Partition creation failed."

mkfs.vfat -F 32 "$EFI"
mkfs.ext4 -F "$ROOT"

mount "$ROOT" "$MNT"
mkdir -p "$MNT/efi"
mount "$EFI" "$MNT/efi"

# 2. Fetch the latest official OpenRC stage 3.
LIST="$BASE/latest-stage3-amd64-openrc.txt"

FILE="$(wget -qO- "$LIST" |
    awk '$1 ~ /^stage3-amd64-openrc.*\.tar\.xz$/ {
        print $1
        exit
    }')"

[[ -n "$FILE" ]] || die "Could not locate OpenRC stage 3."

ARCHIVE="/tmp/$(basename "$FILE")"
DIGESTS="$ARCHIVE.DIGESTS"

wget "$BASE/$FILE" -O "$ARCHIVE"
wget "$BASE/$FILE.DIGESTS" -O "$DIGESTS"

# Verify the SHA-512 checksum against the official digest file.
(
    cd /tmp
    awk '/^# SHA512 HASH/ { getline; print; exit }' "$DIGESTS" |
        sha512sum -c -
) || die "Stage 3 checksum verification failed."

tar -tf "$ARCHIVE" >/dev/null ||
    die "Stage 3 archive is invalid."

tar xpf "$ARCHIVE" \
    --xattrs-include='*.*' --numeric-owner -C "$MNT"

# 3. Configure the target system.
ROOT_UUID="$(blkid -s UUID -o value "$ROOT")"
EFI_UUID="$(blkid -s UUID -o value "$EFI")"

cat >> "$MNT/etc/portage/make.conf" <<EOF

# Gentoo Quickstart: local machine
COMMON_FLAGS="-O2 -pipe -march=native"
CFLAGS="\${COMMON_FLAGS}"
CXXFLAGS="\${COMMON_FLAGS}"
FCFLAGS="\${COMMON_FLAGS}"
FFLAGS="\${COMMON_FLAGS}"
MAKEOPTS="-j$JOBS"
GRUB_PLATFORMS="efi-64"
EOF

mkdir -p "$MNT/etc/portage/repos.conf"
cp "$MNT/usr/share/portage/config/repos.conf" \
   "$MNT/etc/portage/repos.conf/gentoo.conf"

# Explicit USE flags: distribution kernel + initramfs + GRUB.
mkdir -p "$MNT/etc/portage/package.use"
cat > "$MNT/etc/portage/package.use/quickstart" <<'EOF'
sys-kernel/gentoo-kernel initramfs
sys-kernel/installkernel grub dracut
EOF

# Prevent Dracut from selecting modules only from the live environment.
mkdir -p "$MNT/etc/dracut.conf.d"
cat > "$MNT/etc/dracut.conf.d/00-quickstart.conf" <<'EOF'
hostonly="no"
EOF

cat > "$MNT/etc/fstab" <<EOF
UUID=$ROOT_UUID / ext4 defaults,noatime 0 1
UUID=$EFI_UUID /efi vfat umask=0077 0 2
EOF

echo "$HOSTNAME" > "$MNT/etc/hostname"
printf 'hostname="%s"\n' "$HOSTNAME" \
    > "$MNT/etc/conf.d/hostname"

grep -qE '^#?[[:space:]]*en_US\.UTF-8 UTF-8' \
    "$MNT/etc/locale.gen" &&
    sed -i -E \
        's/^#[[:space:]]*(en_US\.UTF-8 UTF-8)/\1/' \
        "$MNT/etc/locale.gen" ||
    echo 'en_US.UTF-8 UTF-8' >> "$MNT/etc/locale.gen"

ln -sf "/usr/share/zoneinfo/$TIMEZONE" "$MNT/etc/localtime"

grep -qE '^[[:space:]]*127\.0\.1\.1[[:space:]]' \
    "$MNT/etc/hosts" ||
    printf '127.0.1.1\t%s\n' "$HOSTNAME" >> "$MNT/etc/hosts"

mkdir -p "$MNT/etc/profile.d"
cat > "$MNT/etc/profile.d/99-rust-native.sh" <<'EOF'
export RUSTFLAGS="-C opt-level=2 -C target-cpu=native"
EOF

# 4. Prepare the chroot.
cp -L /etc/resolv.conf "$MNT/etc/resolv.conf"

mount -t proc proc "$MNT/proc"
mount --rbind /sys "$MNT/sys"
mount --make-rslave "$MNT/sys"
mount --rbind /dev "$MNT/dev"
mount --make-rslave "$MNT/dev"
mount --rbind /run "$MNT/run"
mount --make-rslave "$MNT/run"

# 5. Install packages and configure OpenRC.
cat > "$MNT/root/finish-gentoo.sh" <<'CHROOT'
#!/usr/bin/env bash
set -Eeuo pipefail

# A web snapshot is sufficient for the initial installation.
emerge-webrsync

# Install the boot infrastructure before compiling the kernel.
emerge --ask=n --verbose \
    sys-boot/grub \
    sys-kernel/dracut \
    sys-kernel/installkernel

# Compile the distribution kernel locally.
emerge --ask=n --verbose \
    sys-kernel/gentoo-kernel \
    net-misc/networkmanager \
    app-admin/sudo \
    app-editors/vim

# NetworkManager is an OpenRC service.
rc-update add NetworkManager default

locale-gen
env-update
source /etc/profile

# Verify boot files exist.
echo "=== /boot contents ==="
ls -lh /boot

find /boot -maxdepth 1 -type f \
    \( -name 'vmlinuz-*' -o -name 'kernel-*' \) |
    grep -q . || {
        echo "ERROR: kernel not found."
        exit 1
    }

find /boot -maxdepth 1 -type f \
    \( -name 'initramfs*' -o -name 'initrd*' \) |
    grep -q . || {
        echo "ERROR: initramfs not found."
        exit 1
    }

# Generate the bootloader configuration.
grub-install --target=x86_64-efi \
    --efi-directory=/efi \
    --bootloader-id=Gentoo \
    --recheck

grub-mkconfig -o /boot/grub/grub.cfg

grep -q 'menuentry ' /boot/grub/grub.cfg ||
    { echo "ERROR: GRUB has no menu entries."; exit 1; }

# Configure sudo.
mkdir -p /etc/sudoers.d
printf '%%wheel ALL=(ALL:ALL) ALL\n' \
    > /etc/sudoers.d/10-wheel
chmod 0440 /etc/sudoers.d/10-wheel
visudo -cf /etc/sudoers

echo
echo "Set the root password:"
passwd

read -r -p "Choose a username: " USERNAME
[[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]] ||
    { echo "Invalid username."; exit 1; }

useradd -m -G wheel,users,audio,video \
    -s /bin/bash "$USERNAME"
passwd "$USERNAME"

echo
echo "=== BASE INSTALLATION COMPLETE ==="
echo "Init system: OpenRC"
echo "Kernel: gentoo-kernel, compiled locally"
echo "Initramfs: Dracut"
echo "Bootloader: GRUB / UEFI"
echo "Network: NetworkManager"
echo "Inspect /boot/grub/grub.cfg before rebooting."
CHROOT

chmod +x "$MNT/root/finish-gentoo.sh"

chroot "$MNT" /root/finish-gentoo.sh

echo
echo "Installation completed. Review the output above."
echo "Unmounting filesystems."
