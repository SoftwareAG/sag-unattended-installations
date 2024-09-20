#!/bin/sh

# shellcheck disable=SC3043

# This scripts apply the post-setup configuration for the current template

# Dependency 1
# shellcheck disable=SC2143
if [ ! "$(command -V 'huntForSuifFile1' 2>/dev/null | grep -qwi function)" ]; then
    echo "sourcing commonFunctions.sh again (lost?)"
    if [ ! -f "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue!"
        exit 201
    fi

     # shellcheck source=SCRIPTDIR/../../../../../01.scripts/commonFunctions.sh
    . "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh"
fi
thisFolder="02.templates/02.post-setup/DBC/1011/postgresql-create"

huntForSuifFile "${thisFolder}" "setEnvDefaults.sh"

if [ ! -f "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" ]; then
    logE "File not found: ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
    exit 100
fi

chmod u+x "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" 

logI "Sourcing variables from ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
# shellcheck source=SCRIPTDIR/setEnvDefaults.sh
. "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"

##############
createDbAssets(){

    # shellcheck disable=SC2046
    if [ ! $(portIsReachable "${SUIF_DBSERVER_HOSTNAME}" "${SUIF_DBSERVER_PORT}") ]; then
        logE "Cannot reach socket ${SUIF_DBSERVER_HOSTNAME}:${SUIF_DBSERVER_PORT}, database initialization failed!"
        return 1
    fi

    local lDBC_DB_URL="jdbc:wm:postgresql://${SUIF_DBSERVER_HOSTNAME}:${SUIF_DBSERVER_PORT};databaseName=${SUIF_DBSERVER_DATABASE_NAME}"
    local lDbcSh="${SUIF_INSTALL_INSTALL_DIR}/common/db/bin/dbConfigurator.sh"

    local lCmdCatalog="${lDbcSh} --action catalog"
    local lCmdCatalog="${lCmdCatalog} --dbms pgsql"
    local lCmdCatalog="${lCmdCatalog} --user '${SUIF_DBSERVER_USER_NAME}'"
    local lCmdCatalog="${lCmdCatalog} --password '${SUIF_DBSERVER_PASSWORD}'"
    local lCmdCatalog="${lCmdCatalog} --url '${lDBC_DB_URL}'"

    logI "Checking if product database exists"
    controlledExec "${lCmdCatalog}" "$(date +%s).CatalogDatabase"

    local resCmdCatalog=$?
    if [ ! "${resCmdCatalog}" -eq 0 ];then
        logE "Database not reachable! Result: ${resCmdCatalog}"
        logD "Command was ${lCmdCatalog}"
        return 2
    fi
    # for now this test counts as connectivity. TODO: find out a way to render the "create" idempotent

    logI "Initializing database ${SUIF_DBSERVER_DATABASE_NAME} on server ${SUIF_DBSERVER_HOSTNAME}:${SUIF_DBSERVER_PORT} ..."

    local lDbInitCmd="${lDbcSh} --action create"
    local lDbInitCmd="${lDbInitCmd} --dbms pgsql"
    local lDbInitCmd="${lDbInitCmd} --component ${SUIF_DBC_COMPONENT_NAME}"
    local lDbInitCmd="${lDbInitCmd} --version ${SUIF_DBC_COMPONENT_VERSION}"
    local lDbInitCmd="${lDbInitCmd} --url '${lDBC_DB_URL}'"
    local lDbInitCmd="${lDbInitCmd} --user '${SUIF_DBSERVER_USER_NAME}'"
    local lDbInitCmd="${lDbInitCmd} --password '${SUIF_DBSERVER_PASSWORD}'"
    local lDbInitCmd="${lDbInitCmd} --printActions"

    controlledExec "${lDbInitCmd}" "InitializeDatabase_${SUIF_DBSERVER_DATABASE_NAME}"

    local resInitDb=$?
    if [ "${resInitDb}" -ne 0 ];then
        logE "Database initialization failed! Result: ${resInitDb}"
        logD "Executed command was: ${lDbInitCmd}"
        return 3
    fi
}

createDbAssets
