#!/bin/sh


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

    echo "portIsReachable ${SUIF_DBSERVER_HOSTNAME} ${SUIF_DBSERVER_PORT}"
    export SUIF_INSTALL_INSTALL_DIR="${SUIF_INSTALL_INSTALL_DIR_DBC}"
    # template specific parameters
    applyPostSetupTemplate DBC/1011/postgresql-create
}

createDbComponents

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

#tail -f /dev/null

rm ${SUIF_INSTALL_INSTALL_DIR_MSR}/IntegrationServer/bin/.lock

${SUIF_INSTALL_INSTALL_DIR_MSR}/IntegrationServer/bin/server.sh & wait


#tail -f /dev/null

logI "MSR was shut down"