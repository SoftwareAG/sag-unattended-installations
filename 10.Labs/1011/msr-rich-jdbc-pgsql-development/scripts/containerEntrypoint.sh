#!/bin/sh

#tail -f /dev/null
 
env

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

# compute the connection string from environment
export SUIF_DBSERVER_PORT=${SUIF_DBSERVER_PORT:-5432}
export SUIF_WMSCRIPT_CDSUrlName="jdbc:wm:postgresql://${SUIF_DBSERVER_HOSTNAME}:${SUIF_DBSERVER_PORT};databaseName=${SUIF_DBSERVER_DATABASE_NAME}"

# If the DBC installation is not present, do it now
if [ ! -f "${SUIF_INSTALL_INSTALL_DIR_DBC}/common/db/bin/dbConfigurator.sh" ]; then
    logI "Database configurator is not present, setting up ..."

    export SUIF_INSTALL_IMAGE_FILE="${SUIF_INSTALL_IMAGE_FILE_DBC}"
    export SUIF_PATCH_FIXES_IMAGE_FILE="${SUIF_PATCH_FIXES_IMAGE_FILE_DBC}"
    export SUIF_INSTALL_INSTALL_DIR="${SUIF_INSTALL_INSTALL_DIR_DBC}"

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "DBC/1011/full" || exit 6
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

    sleep 5 # wait a bit more anyway, if the while didn't execute it's too early

    export SUIF_INSTALL_INSTALL_DIR="${SUIF_INSTALL_INSTALL_DIR_DBC}"
    # template specific parameters
    applyPostSetupTemplate DBC/1011/postgresql-create
}

createDbComponents

logFullEnv

# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR_DEVOPS}/IntegrationServer" ]; then
    logI "Starting up for the first time, setting up ..."

    export SUIF_INSTALL_IMAGE_FILE="${SUIF_INSTALL_IMAGE_FILE_DEVOPS}"
    export SUIF_PATCH_FIXES_IMAGE_FILE="${SUIF_PATCH_FIXES_IMAGE_FILE_DEVOPS}"
    export SUIF_INSTALL_INSTALL_DIR="${SUIF_INSTALL_INSTALL_DIR_DEVOPS}"

    # use the same users for the DB, but richer laboratories may use different users
    export SUIF_WMSCRIPT_CDSConnectionName="CDSConnPool"
    export SUIF_WMSCRIPT_CDSPasswordName="${SUIF_DBSERVER_PASSWORD}"
    export SUIF_WMSCRIPT_CDSUserName="${SUIF_DBSERVER_USER_NAME}"

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "MSR/1011/RichJdbcCuOnPostgres" || exit 6
fi

onInterrupt(){

    logI "Interrupted, shutting down MSR..."

    ${SUIF_INSTALL_INSTALL_DIR_DEVOPS}/IntegrationServer/bin/shutdown.sh

    #popd >/dev/null
	exit 0 # managed expected exit
}

onKill(){
	logW "Killed!"
}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

logI "Temp - pause"

rm ${SUIF_INSTALL_INSTALL_DIR_DEVOPS}/IntegrationServer/bin/.lock

getDriver(){
    if [ ! -f "${SUIF_INSTALL_INSTALL_DIR_DEVOPS}/IntegrationServer/packages/WmJDBCAdapter/code/jars/pgsql.jar" ]; then
        logI "Postgresql driver not present, downloading now from ${SUIF_LABS_PGSQL_DRIVER_URL} ..."
        curl "${SUIF_LABS_PGSQL_DRIVER_URL}" \
          -o "${SUIF_INSTALL_INSTALL_DIR_DEVOPS}/IntegrationServer/packages/WmJDBCAdapter/code/jars/pgsql.jar"
        if [ $? -ne 0 ]; then
            logE "Error downloading driver, the JDBC adapter will not work"
        fi
    fi
}
getDriver

${SUIF_INSTALL_INSTALL_DIR_DEVOPS}/IntegrationServer/bin/server.sh & wait

#tail -f /dev/null

logI "MSR was shut down"