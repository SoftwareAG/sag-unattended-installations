#!/bin/sh

cd /tmp

env | grep SUIF | sort

"${SUIF_INSTALL_INSTALLER_BIN}" create container-image\
	--base-image=redhat/ubi8 \
	--name msr1011-new-builder-type-1:latest \
	--products MSC \
	--username "${SUIF_EMPOWER_USER}" \
	--password '${SUIF_EMPOWER_PASSWORD}' \
	--release 10.11 --accept-license \
	--admin-password="${SUIF_INSTALL_TIME_ADMIN_PASSWORD}"

