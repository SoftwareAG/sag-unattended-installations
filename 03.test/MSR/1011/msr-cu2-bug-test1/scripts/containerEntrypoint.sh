#!/bin/sh

# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

logFullEnv

# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
    logI "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "MSR/1011/CU2" || exit 6
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

${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer/bin/server.sh & wait

logI "MSR was shut down"