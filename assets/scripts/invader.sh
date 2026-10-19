#!/usr/bin/env bash

# This script sets up the container by pivoting the mount namespaces
# root filesystem, creation of terminal multiplexer, device nodes,
# procfs, etc.

set -eo pipefail

# Rebuild REALM associative array, I love bash for this ;)
eval "$REALM_DUMP"
if [ -z "${REALM[UUID]}" ]; then
	echo "Well, it was worth a try :(" >&2
fi

# directories
OLD_ROOTFS_NAME="oldrootfs"
OLD_ROOTF_DIR="${REALM[OVERLAY_MERGED]}/${OLD_ROOTFS_NAME}"

function main() {
	local pid="$$"
	echo "Starting container setup (PID: $pid)"

	mount --make-rprivate /
	# Set up
	cd "${EMPEROR_REALMS_FS_DIR}/${REALM[UUID]}"

	mount -t overlay overlay \
		-o "lowerdir=${REALM[OVERLAY_LOWER]},upperdir=${REALM[OVERLAY_UPPER]},workdir=${REALM[OVERLAY_WORK]},${REALM[MOUNT_OPTS]}" \
		"${REALM[OVERLAY_MERGED]}"

	cd "${REALM[OVERLAY_MERGED]}"
	mkdir -p "$OLD_ROOTF_DIR"

	/sbin/pivot_root . "$OLD_ROOTF_DIR"
	cd /

	mount -t proc proc /proc
	mount -t tmpfs -o mode=755,nosuid tmpfs /dev

	mkdir -p /dev/pts
	mount -t devpts devpts /dev/pts/ -o newinstance,ptmxmode=0666,mode=620
	ln -s /dev/pts/ptmx /dev/ptmx

	touch /dev/{null,random,zero}
	mount --bind /${OLD_ROOTFS_NAME}/dev/null /dev/null
	mount --bind /${OLD_ROOTFS_NAME}/dev/random /dev/random
	mount --bind /${OLD_ROOTFS_NAME}/dev/zero /dev/zero

	ln -s /proc/self/fd /dev/fd
	ln -s /proc/self/fd/0 /dev/stdin
	ln -s /proc/self/fd/1 /dev/stdout
	ln -s /proc/self/fd/2 /dev/stderr

	umount -l /${OLD_ROOTFS_NAME}
	rmdir /${OLD_ROOTFS_NAME}

	# Nameserver
	echo "nameserver 8.8.8.8" >/etc/resolv.conf
	hostname "${REALM[HOSTNAME]}"

	exec /bin/bash --norc --noprofile
}

main "$@"
