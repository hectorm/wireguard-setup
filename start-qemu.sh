#!/bin/sh

set -eu
export LC_ALL=C

SRC_DIR=$(dirname "$(readlink -f "$0")")
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR:?}"' EXIT

CLOUDIMG_DISK=${SRC_DIR:?}/packer_output/wireguard.qcow2
SNAPSHOT_DISK=${TMP_DIR:?}/cloudinit-snapshot.qcow2
USERDATA_DISK=${TMP_DIR:?}/cloudinit-seed.img
USERDATA_YAML=${TMP_DIR:?}/user-data

# Create a snapshot image to preserve the original cloud-image
qemu-img create -b "${CLOUDIMG_DISK:?}" -f qcow2 "${SNAPSHOT_DISK:?}"
qemu-img resize "${SNAPSHOT_DISK:?}" +2G

# Create a seed image with metadata using cloud-localds
printf '%s\n' '#cloud-config' 'runcmd: ["ssh-import-id gh:hectorm"]' > "${USERDATA_YAML:?}"
cloud-localds "${USERDATA_DISK:?}" "${USERDATA_YAML:?}"

# Remove keys from the known_hosts file
ssh-keygen -R '[127.0.0.1]:2222'
ssh-keygen -R '[localhost]:2222'

# Launch VM
kvm \
	-smp 1 -m 512 \
	-nographic -serial mon:stdio \
	-device e1000,netdev=n0 \
	-netdev user,id=n0,hostfwd=tcp::2222-:22,hostfwd=udp::5353-:53 \
	-drive file="${SNAPSHOT_DISK:?}",if=virtio,format=qcow2 \
	-drive file="${USERDATA_DISK:?}",if=virtio,format=raw
