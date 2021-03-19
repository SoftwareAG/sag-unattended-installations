#!/bin/sh

# This scripts sets up the local installation

if [ ! -d ${SUIF_HOME} ]; then
    echo "SUIF_HOME variable MUST point to an existing local folder! Current value is ${SUIF_HOME}"
    exit 1
fi

# our configuration takes precedence in front of framework defaults, set it before sourcing the framework functions
if [ ! -d "${SUIF_LOCAL_SCRIPTS_HOME}" ]; then
    echo "Scripts folder not found: ${SUIF_LOCAL_SCRIPTS_HOME}"
    exit 1
fi

if [ ! -f "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh" ]; then
    echo "set_env script not found: ${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh"
    exit 2
fi

. "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh"

# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 2
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 3


if [ ! -d "${SUIF_INSTALL_InstallDir}/Terracotta" ]; then
    echo "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "BigMemoryServer/1005/default" || exit 4

    applyPostSetupTemplate "BigMemoryServer/1005/StandaloneForIsClustering" || exit 5
fi

onInterrupt(){
	echo "Interrupted! Shutting down TMC & TSA"
	${SUIF_INSTALL_InstallDir}/Terracotta/tools/management-console/bin/stop-tmc.sh
    pushd . >/dev/null
    cd "${SUIF_INSTALL_InstallDir}/Terracotta/server/wrapper/bin/"
    ./shutdown.sh
    popd >/dev/null
	exit 0 # managed expected exit
}

onKill(){
	logW "Killed!"
}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

echo "Starting up Terracotta Server"
pushd . >/dev/null
cd "${SUIF_INSTALL_InstallDir}/Terracotta/server/wrapper/bin/"
./startup.sh
popd >/dev/null

echo "Starting up TMC"
controlledExec "${SUIF_INSTALL_InstallDir}/Terracotta/tools/management-console/bin/start-tmc.sh" "Start TMC" &

logI "waiting 10 seconds"
sleep 10

logI "Checking Ports"

errorsCount=0

if [ `portIsReachable localhost 9510` ]; then
    logI "Terracotta Server main port is up"
else
    logE "Terracotta Server main port is NOT up"
    errorsCount=$((errorsCount+1))
fi

if [ `portIsReachable localhost 9540` ]; then
    logI "Terracotta Server group port is up"
else
    logE "Terracotta Server group port is NOT up"
    errorsCount=$((errorsCount+1))
fi

if [ `portIsReachable localhost 9889` ]; then
    logI "Terracotta Management Console Server port is up"
else
    logE "Terracotta Management Console Server port is NOT up"
    errorsCount=$((errorsCount+1))
fi

logI "Total errors found: ${errorsCount}"

logI "Stopping servers"

onInterrupt

exit ${errorsCount}
