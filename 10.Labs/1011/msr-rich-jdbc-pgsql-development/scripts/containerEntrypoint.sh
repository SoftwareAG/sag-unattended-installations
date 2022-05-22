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

# use the same users for the DB, but richer laboratories may use different users
export SUIF_WMSCRIPT_CDSConnectionName="CDSConnPool"
export SUIF_WMSCRIPT_CDSPasswordName="${SUIF_DBSERVER_PASSWORD}"
export SUIF_WMSCRIPT_CDSUserName="${SUIF_DBSERVER_USER_NAME}"

logFullEnv

# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
    logI "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "MSR/1011/RichJdbcCuOnPostgres" || exit 6
fi

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

rm ${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer/bin/.lock

getDriver(){
    if [ ! -f "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer/packages/WmJDBCAdapter/code/jars/pgsql.jar" ]; then
        logI "Postgresql driver not present, downloading now from ${SUIF_LABS_PGSQL_DRIVER_URL} ..."
        curl "${SUIF_LABS_PGSQL_DRIVER_URL}" \
          -o "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer/packages/WmJDBCAdapter/code/jars/pgsql.jar"
        if [ $? -ne 0 ]; then
            logE "Error downloading driver, the JDBC adapter will not work"
        fi
    fi
}
getDriver

${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer/bin/server.sh & wait

#tail -f /dev/null

logI "MSR was shut down"