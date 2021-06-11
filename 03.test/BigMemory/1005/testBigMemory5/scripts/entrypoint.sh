#!/bin/sh
# ---------------------------------------------------------------------------------
# This scripts sets up the local installation - run on the target provisioned VM
#  - At this point, the VM is provisioned,
#  - Azure shared file system is mounted,
#  - Shared file system contains:
#       - Product and fix images, installers
#       - License key
#       - The complete suif script directories
# ---------------------------------------------------------------------------------

# ----------------------------------------
# Current location
# ----------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ----------------------------------------
# Source environment variables from suif.env
# ----------------------------------------
export $(grep -v '^#' $SCRIPT_DIR/suif.env | xargs)

if [ ! -d ${SUIF_HOME} ]; then
    echo "SUIF_HOME variable MUST point to an existing local folder! Current value is ${SUIF_HOME}"
    exit 1
fi

if [ ! -f "${SCRIPT_DIR}/set_env.sh" ]; then
    echo "set_env script not found: ${SCRIPT_DIR}/set_env.sh"
    exit 2
fi

# ----------------------------------------
# Ability to override suif environment variables - all variables controlled via suif.env
# ----------------------------------------
. "${SCRIPT_DIR}/set_env.sh"

# ----------------------------------------
# Source framework functions
# ----------------------------------------
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 2
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 3

# ----------------------------------------
# Start Terracotta (or install if not present)
# ----------------------------------------
if [ ! -d "${SUIF_INSTALL_DIR}/Terracotta" ]; then
    echo "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "BigMemoryServer/1005/default" || exit 4

    applyPostSetupTemplate "BigMemoryServer/1005/StandaloneForIsClustering" || exit 5
fi

onInterrupt(){
	echo "Interrupted! Shutting down TMC & TSA"
	${SUIF_INSTALL_INSTALL_DIR}/Terracotta/tools/management-console/bin/stop-tmc.sh
    pushd . >/dev/null
    cd "${SUIF_INSTALL_INSTALL_DIR}/Terracotta/server/wrapper/bin/"
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
cd "${SUIF_INSTALL_INSTALL_DIR}/Terracotta/server/wrapper/bin/"
./startup.sh
popd >/dev/null

echo "Starting up TMC"
controlledExec "${SUIF_INSTALL_INSTALL_DIR}/Terracotta/tools/management-console/bin/start-tmc.sh" "Start TMC" &

logI "waiting 20 seconds"
sleep 20

logI "Checking Ports ..."

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

# logI "Stopping servers"

# onInterrupt

exit ${errorsCount}
