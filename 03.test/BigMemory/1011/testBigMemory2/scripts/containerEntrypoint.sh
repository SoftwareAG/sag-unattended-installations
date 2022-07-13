#!/bin/sh

# This scripts sets up the local installation

# our configuration takes precedence in front of framework defaults, set it before sourcing the framework functions
if [ ! -d "${SUIF_LOCAL_SCRIPTS_HOME}" ]; then
    echo "Scripts folder not found: ${SUIF_LOCAL_SCRIPTS_HOME}"
    exit 1
fi

export SUIF_HOME_URL="https://raw.githubusercontent.com/SoftwareAG/sag-unattended-installations/main"
mkdir -p "${SUIF_CACHE_HOME}/01.scripts"
curl "${SUIF_HOME_URL}/01.scripts/commonFunctions.sh" -o "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh"

# Source framework functions
. "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" || exit 2

if ! huntForSuifFile 01.scripts/installation setupFunctions.sh ; then
  logE "Cannot assure SUIF setup functions"
  exit 3
fi

#comment following line for test purpose and uncomment env command
. "${SUIF_CACHE_HOME}/01.scripts/installation/setupFunctions.sh" || exit 4


if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/Terracotta" ]; then
    echo "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "BigMemoryServer/1011/default" || exit 5
fi

onInterrupt(){
	echo "Interrupted! Shutting down Terracotta"
  # TODO
	exit 0 # managed expected exit
}

onKill(){
	logW "Killed!"
}

afterStartConfig(){
  logI "afterStartConfig here..."
}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

echo "Starting up Terracotta"
pushd . >/dev/null

# TODO: check if exists
cd "${SUIF_INSTALL_INSTALL_DIR}/Terracotta/server/bin"

./start-tc-server.sh &

WPID=$!

logI "Waiting for Terracotta Server to come up..."

p=`portIsReachable localhost ${SUIF_POST_TC_SERVER_PORT}`
while [ $p -eq 0 ]; do
    logI "Waiting for Big Memory Server to come up, sleeping 5..."
    sleep 5
    p=`portIsReachable localhost ${SUIF_POST_TC_SERVER_PORT}`
done

afterStartConfig

popd >/dev/null

wait ${WPID}

tail -f /dev/null
