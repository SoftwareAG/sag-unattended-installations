#!/bin/sh

SUIF_TEST_DBC_SAG_HOME="${SUIF_TEST_DBC_SAG_HOME:-/opt/softwareag}"

thisTestFolder="03.test/Labs/1005/EsbMonolith1/test1"

# Source framework functions
#shellcheck source=/dev/null
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
#shellcheck source=/dev/null
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

export SUIF_INSTALL_InstallDir="${SUIF_TEST_DBC_SAG_HOME}"

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

# Stopping for debug
tail -f /dev/null