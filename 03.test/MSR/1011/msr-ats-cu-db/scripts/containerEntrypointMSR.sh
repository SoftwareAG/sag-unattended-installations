#!/bin/sh

#tail -f /dev/null
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

logFullEnv


# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
    logI "Starting up for the first time, setting up ..."

    export SUIF_INSTALL_IMAGE_FILE="${SUIF_INSTALL_IMAGE_FILE_MSR}"
    export SUIF_PATCH_FIXES_IMAGE_FILE="${SUIF_PATCH_FIXES_IMAGE_FILE_MSR}"
    export SUIF_INSTALL_INSTALL_DIR="${SUIF_INSTALL_INSTALL_DIR_MSR}"

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "MSR/1011/AdaptersSet1" || exit 6
fi

onInterrupt(){

    logI "Interrupted, shutting down MSR..."

    ${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer/bin/shutdown.sh

    #popd >/dev/null
	exit 0 # managed expected exit
}

onKill(){
	logW "Killed!"
}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

logI "Temp - pause"

logFullEnv

waitForATS(){

    logI "Waiting for ATS to come up, sleeping 10..."
    sleep 10 # this container is starting too quickly...
    local p=`portIsReachable ${SUIF_INSTALL_DECLARED_HOSTNAME} ${SUIF_WMSCRIPT_IntegrationServerPort}`
    while [ $p -eq 0 ]; do
        logI "Waiting for ATS to come up, sleeping 10..."
        sleep 10
        p=`portIsReachable ${SUIF_INSTALL_DECLARED_HOSTNAME} ${SUIF_WMSCRIPT_IntegrationServerPort}`
        # TODO: add an maximum retry number
    done
}

waitForATS

#tail -f /dev/null

rm ${SUIF_INSTALL_INSTALL_DIR_MSR}/IntegrationServer/bin/.lock

${SUIF_INSTALL_INSTALL_DIR_MSR}/IntegrationServer/bin/server.sh & wait


#tail -f /dev/null

logI "MSR was shut down"