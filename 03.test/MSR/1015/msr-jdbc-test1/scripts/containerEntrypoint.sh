#!/bin/sh

# Source framework functions

# shellcheck source=SCRIPTDIR/../../../../../01.scripts/commonFunctions.sh
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4

# shellcheck source=SCRIPTDIR/../../../../../01.scripts/installation/setupFunctions.sh
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

logFullEnv

cp "${SUIF_INSTALL_INSTALLER_BIN_MOUNT_POINT}" "${SUIF_INSTALL_INSTALLER_BIN}"
cp "${SUIF_PATCH_SUM_BOOTSTRAP_BIN_MOUNT_POINT}" "${SUIF_PATCH_SUM_BOOTSTRAP_BIN}"


# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
    logI "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "MSR/1015/jdbc" || exit 6
fi

onInterrupt(){

    logI "Interrupted, shutting down MSR..."

    "${SUIF_INSTALL_INSTALL_DIR}"/IntegrationServer/bin/shutdown.sh

    #popd >/dev/null
	exit 0 # managed expected exit
}

trap "onInterrupt" INT TERM

logI "Temp - pause"

"${SUIF_INSTALL_INSTALL_DIR}"/IntegrationServer/bin/server.sh & wait

logI "MSR was shut down"