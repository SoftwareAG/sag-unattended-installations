#!/bin/sh

env


# This scripts sets up the local installation

if [ ! -d ${SUIF_HOME} ]; then
    echo "SUIF_HOME variable MUST point to an existing local folder! Current value is ${SUIF_HOME}"
    exit 1
fi

# our configuration takes precedence in front of framework defaults, set it before sourcing the framework functions
if [ ! -d "${SUIF_LOCAL_SCRIPTS_HOME}" ]; then
    echo "Scripts folder not found: ${SUIF_LOCAL_SCRIPTS_HOME}"
    exit 2
fi


# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
    echo "Integration server not present, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "ATG/1011/default"

    if [ $? -ne 0 ]; then
        logE "setup failed, copying over the ephemeral scritps"
        cp /dev/shm/* "${SUIF_AUDIT_SESSION_DIR}/"

        logW "Stopping for debug"
        tail -f /dev/null
    fi
    # || exit 8
fi

onInterrupt(){
	echo "Interrupted! Shutting down MFT Server"
    pushd . >/dev/null
	echo "Shutting down Integration server ..."
    cd "${SUIF_INSTALL_INSTALL_DIR}/profiles/IS_default/bin"
    ./shutdown.sh
	echo "Shutting down Platform manager ..."
    cd "${SUIF_INSTALL_INSTALL_DIR}/profiles/SPM/bin"
    ./shutdown.sh
	exit 0 # managed expected exit
}

onKill(){
	logW "Killed!"
}

checkPrerequisites(){
    #TODO: check database?
    logI "Nothing here yet"
} 

afterStartConfig(){
    logI "Applying afterStartConfig"
}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

echo "Starting up MFT Server"
#echo "Checking prerequisites ..."
#checkPrerequisites || exit 7
pushd . >/dev/null
echo "Starting Integration Server"
cd "${SUIF_INSTALL_INSTALL_DIR}/profiles/IS_default/bin"
./console.sh & 

WPID=$!

logI "Waiting for MFT Gateway to come up"

p=`portIsReachable localhost ${SUIF_INSTALL_IS_MAIN_HTTP_PORT}`
while [ $p -eq 0 ]; do
    logI "Waiting for Active Transfer to come up, sleeping 5..."
    sleep 5
    p=`portIsReachable localhost ${SUIF_INSTALL_IS_MAIN_HTTP_PORT}`
done

afterStartConfig

wait ${WPID}

popd >/dev/null
