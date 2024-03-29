#!/bin/sh

# This scripts sets up the local installation

# shellcheck disable=SC2153
if [ ! -d "${SUIF_HOME}" ]; then
    echo "SUIF_HOME variable MUST point to an existing local folder! Current value is ${SUIF_HOME}"
    exit 1
fi

# our configuration takes precedence in front of framework defaults, set it before sourcing the framework functions
if [ ! -d "${SUIF_LOCAL_SCRIPTS_HOME}" ]; then
    echo "Scripts folder not found: ${SUIF_LOCAL_SCRIPTS_HOME}"
    exit 2
fi

cp "$SUIF_INSTALL_INSTALLER_BIN_MOUNT_POINT" "$SUIF_INSTALL_INSTALLER_BIN"
cp "$SUIF_PATCH_SUM_BOOTSTRAP_BIN_MOUNT_POINT" "$SUIF_PATCH_SUM_BOOTSTRAP_BIN"
chomod u+x "$SUIF_INSTALL_INSTALLER_BIN" "$SUIF_PATCH_SUM_BOOTSTRAP_BIN"


# Source framework functions
# shellcheck source=../../../../../../01.scripts/commonFunctions.sh
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
# shellcheck source=../../../../../../01.scripts/installation/setupFunctions.sh
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

# If the DBC installation is not present, do it now
if [ ! -f "${SUIF_INSTALL_INSTALL_DIR}/common/db/bin/dbConfigurator.sh" ]; then
    logI "Database configurator is not present, setting up ..."
    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "DBC/1015/full" || exit 6
fi

createDbComponents(){

    logI "Eventually creating DB components..."
    sleep 5 # this container is starting too quickly...
    while  ! portIsReachable2 "${SUIF_DBSERVER_HOSTNAME}" "${SUIF_DBSERVER_PORT}" ; do
        logI "Waiting for the database to come up, sleeping 5..."
        sleep 5
        # TODO: add an maximum retry number
    done
    sleep 5 # allow som time to the DB in any case...

    # template specific parameters
    applyPostSetupTemplate DBC/1011/postgresql-create
}

createDbComponents


logI "Go to http://host.docker.internal:${SUIF_TEST_PORT_PREFIX}80 and check the database content!. Look at the .env file for details!"

logI "Issue docker-compose down -t 20 to close this project!"

tail -f /dev/null