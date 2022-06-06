#!/bin/sh

# run as root, but follow the least privilege principle
# todo: look if possible to use lower privileges still. Attempted to add sag in docker users group, but it did not work.
	onInterrupt(){
			echo "Interrupted, ..."
		exit 0 # managed expected exit
	}

	onKill(){
		logW "Killed!"
	}

	trap "onInterrupt" SIGINT SIGTERM
	trap "onKill" SIGKILL

echo "running the product setup as user ${SUIF_SAG_USER_NAME}"

sudo -H -E -u "${SUIF_SAG_USER_NAME}" /bin/sh -c "${SUIF_LOCAL_SCRIPTS_HOME}/setupProduct.sh"

echo "SUIF - building the image suif-um-1011-no-instance"
cd /tmp/product_home/

#docker rmi redhat/ubi8 # force the latest built by redhat

docker build --build-arg __sag_home=${SUIF_INSTALL_INSTALL_DIR} . -t example-um-binaries-only

echo "Container image build executed, result is $?"
