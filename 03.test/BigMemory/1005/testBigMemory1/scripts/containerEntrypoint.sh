#!/bin/sh

# This scripts sets up the local installation


. "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh" || exit 1

if [ ! -d "${SUIF_INSTALL_InstallDir}/Terracotta" ]; then
    echo "Starting up for the first time, setting up ..."

    export SUIF_CACHE_HOME="/tmp/SUIF_CACHE"
    mkdir -p "${SUIF_CACHE_HOME}/01.scripts" || exit 2
    export SUIF_HOME_URL=${SUIF_HOME_URL:-"https://raw.githubusercontent.com/Myhael76/sag-unattented-installations/main/"}
    curl "${SUIF_HOME_URL}/01.scripts/commonFunctions.sh" -o "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" || exit 3
    chmod u+x "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh"
    . "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" || exit 4

    logI "Sourcing setup functions..."
    huntForSuifFile "01.scripts/installation/setupFunctions.sh" || exit 5
    . "${SUIF_CACHE_HOME}/01.scripts/installation/setupFunctions.sh" || exit 6

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

echo "Starting up TMC modal. Open http://localhost:47140 and play with the TMC (actual port depends on the port mapping on docker-compose)"
"${SUIF_INSTALL_InstallDir}/Terracotta/tools/management-console/bin/start-tmc.sh" & wait


if [ "${SUIF_DEBUG_ON}" -eq 1 ]; then
    logD "Stopping execution for debug"
    tail -f /dev/null
fi