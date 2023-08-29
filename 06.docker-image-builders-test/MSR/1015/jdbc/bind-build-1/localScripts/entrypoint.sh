#!/bin/sh

cd /tmp || exit 1

buildah bud --storage-opt mount_program=/usr/bin/fuse-overlayfs --isolation=chroot -t msr-1015-jdbc-test-bind-1 .
