#!/bin/sh
#tail -f /dev/null
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

# If the DBC installation is not present, do it now
if [ ! -f "${SUIF_INSTALL_INSTALL_DIR_DBC}/common/db/bin/dbConfigurator.sh" ]; then
    logI "Database configurator is not present, setting up ..."

    export SUIF_INSTALL_IMAGE_FILE="${SUIF_INSTALL_IMAGE_FILE_DBC4AT}"
    export SUIF_PATCH_FIXES_IMAGE_FILE="${SUIF_PATCH_FIXES_IMAGE_FILE_DBC4AT}"
    export SUIF_INSTALL_INSTALL_DIR="${SUIF_INSTALL_INSTALL_DIR_DBC}"

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "AT/1011/DBC4AT" || exit 6
fi

createDbComponents(){

    logI "Eventually creating DB components..."
    sleep 5 # this container is starting too quickly...
    local p=`portIsReachable ${SUIF_DBSERVER_HOSTNAME} ${SUIF_DBSERVER_PORT}`
    while [ $p -eq 0 ]; do
        logI "Waiting for the database to come up, sleeping 5..."
        sleep 5
        p=`portIsReachable ${SUIF_DBSERVER_HOSTNAME} ${SUIF_DBSERVER_PORT}`
        # TODO: add an maximum retry number
    done

    export SUIF_INSTALL_INSTALL_DIR="${SUIF_INSTALL_INSTALL_DIR_DBC}"
    # template specific parameters
    applyPostSetupTemplate DBC/1011/postgresql-create
}

createDbComponents

if [ ! -d "${SUIF_INSTALL_INSTALL_DIR_ATS}/IntegrationServer" ]; then
    logI "Active Transfer Server not present, installing now..."
    export SUIF_INSTALL_IMAGE_FILE="${SUIF_INSTALL_IMAGE_FILE_ATS}"
    export SUIF_PATCH_FIXES_IMAGE_FILE="${SUIF_PATCH_FIXES_IMAGE_FILE_ATS}"
    export SUIF_INSTALL_INSTALL_DIR="${SUIF_INSTALL_INSTALL_DIR_ATS}"

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "AT/1011/server/minimal-with-cu-on-postgresql" || exit 7
fi

onInterrupt(){
	echo "Interrupted! Shutting Activetransfer Server..."
    pushd . >/dev/null
    cd "${SUIF_INSTALL_INSTALL_DIR_ATS}/profiles/IS_default/bin/"
    ./shutdown.sh
    popd >/dev/null
	exit 0 # managed expected exit
}

onKill(){
	logW "Killed!"
}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

logI "Starting Active Transfer Server..."
pushd . > /dev/null
cd "${SUIF_INSTALL_INSTALL_DIR_ATS}/profiles/IS_default/bin/"
./console.sh & wait

popd > /dev/null

if [ "${SUIF_DEBUG_ON}" -eq 1 ]; then
  logW "Stopping for debug"
  tail -f /dev/null
fi