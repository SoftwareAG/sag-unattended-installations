#!/bin/sh

INSTALL_FOLDER=${INSTALL_FOLDER:-/opt/softwareag}
d=$(date +%y-%m-%dT%H.%M.%S_%3N)

mkdir -p /mnt/local/snapshot_$d || exit 1

cd "${INSTALL_FOLDER}" || exit 2

#cp -r ./* /mnt/local/snapshot_$d/
echo "taking snapshot of folder ${INSTALL_FOLDER} in file /mnt/local/snapshot_$d/snapshot.tgz"
tar czf /mnt/local/snapshot_$d/snapshot.tgz .
echo "snapshot taken, exitting"
