#!/bin/sh

set -eu
export LC_ALL=C

SRC_DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
TMP_DIR=$(mktemp -d)

ORIGINAL_DISK=${SRC_DIR:?}/dist/qemu/wireguard.qcow2
SNAPSHOT_DISK=${TMP_DIR:?}/snapshot.qcow2

USERDATA_DISK=${TMP_DIR:?}/seed.img
USERDATA_YAML=${SRC_DIR:?}/qemu/http/seed/user-data

# Remove temporary files on exit
trap 'rm -rf "${TMP_DIR:?}"; trap - EXIT; exit 0' EXIT TERM INT HUP

# Create a snapshot image to preserve the original image
qemu-img create -b "${ORIGINAL_DISK:?}" -f qcow2 "${SNAPSHOT_DISK:?}"
qemu-img resize "${SNAPSHOT_DISK:?}" +2G

# Create a seed image with metadata using cloud-localds
cloud-localds "${USERDATA_DISK:?}" "${USERDATA_YAML:?}"

# Remove keys from the known_hosts file
ssh-keygen -R '[127.0.0.1]:1122' 2>/dev/null
ssh-keygen -R '[localhost]:1122' 2>/dev/null

# hostfwd helper
hostfwd() { printf ',hostfwd=%s::%s-:%s' "$@"; }

# Launch VM
kvm \
	-smp 1 -m 512 \
	-nographic -serial mon:stdio \
	-device e1000,netdev=n0 \
	-netdev user,id=n0"$(hostfwd \
		tcp 1122    122 \
		udp 51820 51820 \
		udp 1053     53 \
		tcp 1443    443 \
	)" \
	-drive file="${SNAPSHOT_DISK:?}",if=virtio,format=qcow2 \
	-drive file="${USERDATA_DISK:?}",if=virtio,format=raw
