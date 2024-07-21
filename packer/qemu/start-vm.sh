#!/bin/sh

set -eu
export LC_ALL=C

SRC_DIR=$(CDPATH='' cd -- "$(dirname -- "$(dirname -- "${0:?}")")" && pwd -P)
TMP_DIR=$(mktemp -d)

: "${ORIGINAL_DISK:=${SRC_DIR:?}/dist/qemu/wireguard.qcow2}"
: "${SNAPSHOT_DISK:=${TMP_DIR:?}/snapshot.qcow2}"

: "${USERDATA_YAML:=${SRC_DIR:?}/qemu/http/seed/user-data}"
: "${USERDATA_DISK:=${TMP_DIR:?}/seed.img}"

: "${QEMU_SYSTEM_BINARY:=qemu-system-x86_64}"
# : "${QEMU_SYSTEM_BINARY:=qemu-system-aarch64}"

# Remove temporary files on exit
# shellcheck disable=SC2154
trap 'ret="$?"; rm -rf -- "${TMP_DIR:?}"; trap - EXIT; exit "${ret:?}"' EXIT TERM INT HUP

# Remove keys from the known_hosts file
for host in '[localhost]:1122' '[127.0.0.1]:1122' '[::1]:1122'; do
	ssh-keygen -R "${host:?}" 2>/dev/null ||:
done

# Set main arguments for QEMU
set --
case "${QEMU_SYSTEM_BINARY#*qemu-system-}" in
	x86_64)
		: "${EFI_FIRMWARE_CODE:=/usr/share/edk2/x64/OVMF_CODE.4m.fd}"
		: "${EFI_FIRMWARE_VARS:=/usr/share/edk2/x64/OVMF_VARS.4m.fd}"
		set -- "$@" -machine q35 -smp 2 -m 1024
		;;
	aarch64)
		: "${EFI_FIRMWARE_CODE:=/usr/share/AAVMF/AAVMF_CODE.fd}"
		: "${EFI_FIRMWARE_VARS:=/usr/share/AAVMF/AAVMF_VARS.fd}"
		set -- "$@" -machine virt,gic-version=3 -cpu cortex-a76 -smp 2 -m 1024
		;;
esac
set -- "$@" -nographic -serial mon:stdio
set -- "$@" -device virtio-net,netdev=n0
set -- "$@" -netdev user,id=n0"$(printf ',hostfwd=%s:%s:%s-:%s' \
	tcp 127.0.0.1 1122    122 \
	udp 0.0.0.0   51820 51820 \
	udp 0.0.0.0   1053     53 \
	tcp 0.0.0.0   1443    443 \
)"

# Set EFI firmware code and variables
set -- "$@" -drive file="${EFI_FIRMWARE_CODE:?}",if=pflash,unit=0,format=raw,readonly=on
set -- "$@" -drive file="${EFI_FIRMWARE_VARS:?}",if=pflash,unit=1,format=raw,snapshot=on

# Use KVM if available
if [ -w /dev/kvm ] && [ "${QEMU_SYSTEM_BINARY#*qemu-system-}" = "$(uname -m)" ]; then
	set -- "$@" -accel kvm -cpu host
fi

# Create a snapshot image to preserve the original image
qemu-img create -f qcow2 -b "${ORIGINAL_DISK:?}" -F qcow2 "${SNAPSHOT_DISK:?}"
qemu-img resize "${SNAPSHOT_DISK:?}" +2G
set -- "$@" -drive file="${SNAPSHOT_DISK:?}",if=virtio,format=qcow2

# Create a seed image with metadata using cloud-localds
cloud-localds "${USERDATA_DISK:?}" "${USERDATA_YAML:?}"
set -- "$@" -drive file="${USERDATA_DISK:?}",if=virtio,format=raw

# Launch VM
"${QEMU_SYSTEM_BINARY:?}" "$@"
