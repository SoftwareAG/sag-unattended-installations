#!/bin/sh

# This scripts sets up the local installation

thisTestFolder="03.test/DBC/1005/full/oracle/scripts"

if [ ! -d "${SUIF_HOME}" ]; then
    echo "[${thisTestFolder}/containerEntrypoints.sh] - SUIF_HOME variable MUST point to an existing local folder! Current value is ${SUIF_HOME}"
    exit 1
fi

# our configuration takes precedence in front of framework defaults, set it before sourcing the framework functions
if [ ! -d "${SUIF_LOCAL_SCRIPTS_HOME}" ]; then
    echo "[${thisTestFolder}/containerEntrypoints.sh] - Scripts folder not found: ${SUIF_LOCAL_SCRIPTS_HOME}"
    exit 2
fi

# Source framework functions
#shellcheck source=/dev/null
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
#shellcheck source=/dev/null
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

logFullEnv

rm "${SUIF_INSTALL_INSTALLER_BIN}" 2>/dev/null
cp "${SUIF_INSTALL_INSTALLER_BIN_MOUNT_POINT}" "${SUIF_INSTALL_INSTALLER_BIN}"

rm "${SUIF_PATCH_SUM_BOOTSTRAP_BIN}" 2>/dev/null
cp "${SUIF_PATCH_SUM_BOOTSTRAP_BIN_MOUNT_POINT}" "${SUIF_PATCH_SUM_BOOTSTRAP_BIN}"

# If the DBC installation is not present, do it now
if [ ! -f "${SUIF_INSTALL_INSTALL_DIR}/common/db/bin/dbConfigurator.sh" ]; then
    logI "[${thisTestFolder}/containerEntrypoints.sh] - Database configurator is not present, setting up ..."
    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "DBC/1005/full" || exit 6
fi

createDbComponents(){

    logI "[${thisTestFolder}/containerEntrypoints.sh] - Eventually creating DB components..."
    sleep 5 # this container is starting too quickly...
    while ! portIsReachable2 "${SUIF_DBSERVER_HOSTNAME}" "${SUIF_DBSERVER_PORT}"; do
        logI "[${thisTestFolder}/containerEntrypoints.sh] - Waiting for the database to come up, sleeping 5..."
        sleep 5
        # TODO: add an maximum retry number
    done
    sleep 5 # allow som time to the DB in any case...

    # template specific parameters
    applyPostSetupTemplate DBC/1005/Oracle-create
}

createDbComponents


logI "[${thisTestFolder}/containerEntrypoints.sh] - Go to http://host.docker.internal:${SUIF_TEST_PORT_PREFIX}80 and check the database content!. Look at the .env file for details!"

logI "[${thisTestFolder}/containerEntrypoints.sh] - Issue docker-compose down -t 20 to close this project!"

tail -f /dev/null