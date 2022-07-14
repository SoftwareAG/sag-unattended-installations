#!/bin/sh

# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 1
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 2

logFullEnv

# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
    logI "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "CloudStreamsServer/1011/lean" || exit 3
fi

onInterrupt(){

    logI "Interrupted, shutting down MSR..."

    "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer/bin/shutdown.sh"

    #popd >/dev/null
	exit 0 # managed expected exit
}

trap "onInterrupt" SIGINT SIGTERM

logI "Temp - pause"

"${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer/bin/server.sh" & wait

logI "MSR was shut down"
