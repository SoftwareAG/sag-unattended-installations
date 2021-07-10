#!/bin/sh

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

if [ ! -f "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh" ]; then
    echo "set_env script not found: ${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh"
    exit 3
fi

. "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh"

# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_InstallDir}/IntegrationServer" ]; then
    echo "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "IntegrationServer/1005/default" || exit 6
fi

onInterrupt(){
	echo "Interrupted! Shutting down API Gateway"
    pushd . >/dev/null
	echo "Shutting down Integration server ..."
    cd "${SUIF_INSTALL_InstallDir}/profiles/IS_default/bin"
    ./shutdown.sh
	echo "Shutting down Platform manager ..."
    cd "${SUIF_INSTALL_InstallDir}/profiles/SPM/bin"
    ./shutdown.sh
    #popd >/dev/null
	exit 0 # managed expected exit
}

onKill(){
	logW "Killed!"
}

afterStartConfig(){
    logI "Applying afterStartConfig"
    applyPostSetupTemplate IntegrationServer/1005/ChangeAdministratorPassword

}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

echo "Starting up Integration server"
echo "Checking prerequisites ..."
checkPrerequisites || exit 7
pushd . >/dev/null
echo "Starting Integration Server"
cd "${SUIF_INSTALL_InstallDir}/profiles/IS_default/bin"
./console.sh & 

WPID=$!

logI "Waiting for Integration Server to come up"

p=`portIsReachable localhost 5555`
while [ $p -eq 0 ]; do
    logI "Waiting for Integration Server to come up, sleeping 5..."
    sleep 5
    p=`portIsReachable localhost 5555`
done

afterStartConfig

wait ${WPID}

popd >/dev/null
