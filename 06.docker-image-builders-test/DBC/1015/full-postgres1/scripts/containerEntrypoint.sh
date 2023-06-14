#!/bin/sh
# shellcheck disable=SC3043

# This script creates all webmethods DB components
SAG_HOME=${SAG_HOME:-/opt/softwareag}

createDbAssets(){

    local logPfx="SUIF_TEST::createDbAssets()"

    if ! nc -z "${SUIF_TEST_DBSERVER_HOSTNAME}" "${SUIF_TEST_DBSERVER_PORT}"; then
        echo "$logPfx - Cannot reach socket ${SUIF_TEST_DBSERVER_HOSTNAME}:${SUIF_TEST_DBSERVER_PORT}, database initialization failed!"
        return 1
    fi

    local lDBC_DB_URL="jdbc:wm:postgresql://${SUIF_TEST_DBSERVER_HOSTNAME}:${SUIF_TEST_DBSERVER_PORT};databaseName=${SUIF_TEST_DBSERVER_DATABASE_NAME}"
    local lDbcSh="${SAG_HOME}/common/db/bin/dbConfigurator.sh"

    local lCmdCatalog="${lDbcSh} --action catalog"
    local lCmdCatalog="${lCmdCatalog} --dbms pgsql"
    local lCmdCatalog="${lCmdCatalog} --user '${SUIF_TEST_DBSERVER_USER_NAME}'"
    local lCmdCatalog="${lCmdCatalog} --password '${SUIF_TEST_DBSERVER_PASSWORD}'"
    local lCmdCatalog="${lCmdCatalog} --url '${lDBC_DB_URL}'"

    echo "$logPfx - Checking if product database exists"
    eval "${lCmdCatalog}"

    local resCmdCatalog=$?
    if [ ! "${resCmdCatalog}" -eq 0 ];then
        echo "$logPfx - ERROR - Database not reachable! Result: ${resCmdCatalog}"
        echo "$logPfx - Command was ${lCmdCatalog}"
        return 2
    fi
    # for now this test counts as connectivity.
    # As per product's properties, we consider the "create" action as idempotent

    echo "$logPfx - Initializing database ${SUIF_TEST_DBSERVER_DATABASE_NAME} on server ${SUIF_TEST_DBSERVER_HOSTNAME}:${SUIF_TEST_DBSERVER_PORT} ..."

    local lDbInitCmd="${lDbcSh} --action create"
    local lDbInitCmd="${lDbInitCmd} --dbms pgsql"
    local lDbInitCmd="${lDbInitCmd} --component ${SUIF_TEST_DBC_COMPONENT_NAME}"
    local lDbInitCmd="${lDbInitCmd} --version ${SUIF_TEST_DBC_COMPONENT_VERSION}"
    local lDbInitCmd="${lDbInitCmd} --url '${lDBC_DB_URL}'"
    local lDbInitCmd="${lDbInitCmd} --user '${SUIF_TEST_DBSERVER_USER_NAME}'"
    local lDbInitCmd="${lDbInitCmd} --password '${SUIF_TEST_DBSERVER_PASSWORD}'"
    local lDbInitCmd="${lDbInitCmd} --printActions"

    eval "${lDbInitCmd}"

    local resInitDb=$?
    if [ "${resInitDb}" -ne 0 ];then
        echo "$logPfx - ERROR - Database initialization failed! Result: ${resInitDb}"
        echo "$logPfx - Executed command was: ${lDbInitCmd}"
        return 3
    fi
}
createDbAssets


echo "Go to http://host.docker.internal:${SUIF_TEST_PORT_PREFIX}80 and check the database content!. Look at the .env file for details!"
