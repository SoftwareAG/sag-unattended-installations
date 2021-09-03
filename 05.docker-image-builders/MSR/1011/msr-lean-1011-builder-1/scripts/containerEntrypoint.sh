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

echo "SUIF - building the image suif-msr-1011-lean-type1"
cd "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer/docker"
./is_container.sh build -Dimage.name=suif-msr-1011-lean-type1
echo "Container image suif-msr-1011-lean-type1 build executed, result is $?"
