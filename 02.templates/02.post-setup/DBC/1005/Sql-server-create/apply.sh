#!/bin/sh

# This scripts apply the post-setup configuration for the current template

# Dependency 1
if [ ! "`type -t huntForSuifFile`X" == "functionX" ]; then
    echo "sourcing commonFunctions.sh again (lost?)"
    if [ ! -f "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue!"
        exit 500
    fi
    . "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh"
fi
thisFolder="02.templates/02.post-setup/DBC/1005/Sql-server-create"

huntForSuifFile "${thisFolder}" "setEnvDefaults.sh"

if [ ! -f "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" ]; then
    logE "File not found: ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
    exit 100
fi

chmod u+x "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" 

logI "Sourcing variables from ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
. "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"

##############
createDbAndAssets(){

    if [ `portIsReachable ${WMLAB_SQLSERVER_HOSTNAME} ${SUIF_SQLSERVER_PORT}` ]; then

        local lCmd = "${SUIF_INSTALL_InstallDir}/common/db/bin/dbConfigurator.sh"
        if [ "${SUIF_DATABASE_ALREADY_CREATED}" -eq 0 ]; then
            # TODO: find a command to check if DB already exists -> --action catalog maybe?
            logI "Creating a new database named ${SUIF_SQLSERVER_DATABASE_NAME} on server ${SUIF_SQLSERVER_HOSTNAME}:${SUIF_SQLSERVER_PORT}"
            local lDBC_DB_URL_M="jdbc:wm:sqlserver://${SUIF_SQLSERVER_HOSTNAME}:${SUIF_SQLSERVER_PORT};databaseName=master" 
            lCmd = "${lCmd} --action create"
            lCmd = "${lCmd} --dbms sqlserver"
            lCmd = "${lCmd} --component storage"
            lCmd = "${lCmd} --version latest"
            lCmd = "${lCmd} --url '${lDBC_DB_URL_M}'"
            lCmd = "${lCmd} --user '${SUIF_SQLSERVER_USER_NAME}'"
            lCmd = "${lCmd} --password '${SUIF_SQLSERVER_PASSWORD}'"
            lCmd = "${lCmd} -au sa"
            lCmd = "${lCmd} -ap '${SUIF_SQLSERVER_SA_PASSWORD}'"
            lCmd = "${lCmd} -n '${SUIF_SQLSERVER_DATABASE_NAME}'"
            lCmd = "${lCmd} --printActions"

            controlledExec "${lCmd}" "CreateDatabase_${SUIF_SQLSERVER_DATABASE_NAME}"

            local resCreateDb=$?
            if [ "${resCreateDb}" -ne 0 ];then
                logE "Database creation failed! Result: ${resCreateDb}"
                return 2
            fi
        fi

        SUIF_DBC_COMPONENT_NAME
        local lDBC_DB_URL="jdbc:wm:sqlserver://${SUIF_SQLSERVER_HOSTNAME}:${SUIF_SQLSERVER_PORT};databaseName=${SUIF_SQLSERVER_DATABASE_NAME}"
        logI "Initializing database ${SUIF_SQLSERVER_DATABASE_NAME} on server ${SUIF_SQLSERVER_HOSTNAME}:${SUIF_SQLSERVER_PORT} ..."
        lCmd = "${SUIF_INSTALL_InstallDir}/common/db/bin/dbConfigurator.sh"
        lCmd = "${lCmd} --action create"
        lCmd = "${lCmd} --dbms sqlserver"
        lCmd = "${lCmd} --component ${SUIF_DBC_COMPONENT_NAME}"
        lCmd = "${lCmd} --version ${SUIF_DBC_COMPONENT_VERSION}"
        lCmd = "${lCmd} --url '${lDBC_DB_URL}'"
        lCmd = "${lCmd} --user '${WMLAB_SQLSERVER_USER_NAME}'"
        lCmd = "${lCmd} --password '${WMLAB_SQLSERVER_PASSWORD}'"
        lCmd = "${lCmd} --printActions"

        controlledExec "${lCmd}" "InitializeDatabase_${SUIF_SQLSERVER_DATABASE_NAME}"

        local resInitDb=$?
        if [ "${resInitDb}" -ne 0 ];then
            logE "Database initialization failed! Result: ${resInitDb}"
            return 3
        fi

    else
        logE "Cannot reach socket ${WMLAB_SQLSERVER_HOSTNAME}:${SUIF_SQLSERVER_PORT}, database initialization failed!"
        return 1
    fi
}

createDbAndAssets
