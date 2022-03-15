#!/bin/sh

# Source framework functions
ls -l "${SUIF_HOME}"/
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

logFullEnv

# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
    logI "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "BPMS/1011/BreOnISWithInternalAndPostgres" || exit 6
fi

onInterrupt(){

    logI "Interrupted, shutting down MSR..."

    ${SUIF_INSTALL_INSTALL_DIR}/profiles/IS_default/bin/shutdown.sh

	exit 0 # managed expected exit
}

onKill(){
	logW "Killed!"
}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

logI "Temp - pause"

${SUIF_INSTALL_INSTALL_DIR}/profiles/IS_default/bin/startup.sh

logI "IS_Default profile started."

tail -f /dev/null # TODO: find a proper process to "wait", eventually use the same approach as API Gw
