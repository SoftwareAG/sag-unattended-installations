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
if [ ! -d "${SUIF_INSTALL_InstallDir}/API_Portal" ]; then
    echo "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "APIPortal/1005/default" || exit 6
fi

onInterrupt(){
	echo "Interrupted! Shutting down API Portal"
    pushd . >/dev/null
    echo "Shutting down Runnables ..."
    cd "${SUIF_INSTALL_InstallDir}/API_Portal/server/acc/bin"
    ./acc.sh -h localhost -u Clous -pwd g3h31m -p 18011
    stopall
    quit
	echo "Shutting down CloudAgent ..."
    cd "${SUIF_INSTALL_InstallDir}/API_Portal/server/bin"
    ./CloudAgentApp.sh stop
    #popd >/dev/null
	exit 0 # managed expected exit
}

onKill(){
	logW "Killed!"
}

checkPrerequisites(){
    local c1=262144 # p1 -> vm.max_map_count
    local p1=$(sysctl "vm.max_map_count" | cut -d " " -f 3)
    if [[ ! $p1 -lt $c1 ]]; then
        logI "vm.max_map_count is adequate ($p1)"
    else
        logE "vm.max_map_count is NOT adequate ($p1), container will exit now"
		return 1
    fi
} 

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

echo "Starting up API Portal"
echo "Checking prerequisites ..."
checkPrerequisites || exit 7
pushd . >/dev/null
echo "Starting CloudAgent ..."
cd "${SUIF_INSTALL_InstallDir}/API_Portal/server/bin"
./CloudAgentApp.sh start
echo "Starting Runnables ..."
cd "${SUIF_INSTALL_InstallDir}/API_Portal/server/acc/bin"
./acc.sh -h localhost -u Clous -pwd g3h31m -p 18011
startall
quit

WPID=$!

logI "Waiting for API Portal to come up"

p=`portIsReachable localhost 18101`
while [ $p -eq 0 ]; do
    logI "Waiting for API Portal to come up, sleeping 5..."
    sleep 5
    p=`portIsReachable localhost 18101`
done

afterStartConfig

wait ${WPID}

popd >/dev/null
