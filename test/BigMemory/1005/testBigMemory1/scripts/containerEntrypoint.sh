#!/bin/sh

# This scripts sets up the local installation


#!/bin/sh

if [ ! -d "${SUIF_LOCAL_SCRIPTS_HOME}" ]; then
    echo "Scripts folder not found: ${SUIF_LOCAL_SCRIPTS_HOME}"
    exit 1
fi

if [ ! -f "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh" ]; then
    echo "set_env script not found: ${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh"
    exit 2
fi

. "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh"

if [ ! -d "${SUIF_INSTALL_InstallDir}/Terracotta" ]; then
    echo "Starting up for the first time, setting up ..."
    TEMP_DIR="/tmp/setup/"`date +%y-%m-%dT%H.%M.%S_%3N`
    mkdir -p "${TEMP_DIR}" || exit $?
    pushd . >/dev/null
    cd "${TEMP_DIR}"
    LOCAL_SETUP_SCRIPT_URL=${LOCAL_SETUP_SCRIPT_URL:-"https://raw.githubusercontent.com/Myhael76/sag-unattented-installations/main/templates/BigMemoryServer/1005/StandaloneForIsClustering/localSetup.sh"}
    curl "${LOCAL_SETUP_SCRIPT_URL}" -o ./localSetup.sh
    if [ $? -ne 0 ]; then
        echo "curl failed for local setup script ${LOCAL_SETUP_SCRIPT_URL}"
        exit 102
    fi
    chmod u+x ./localSetup.sh
    ./localSetup.sh
    popd >/dev/null
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

echo "Starting up TMC modal"
"${SUIF_INSTALL_InstallDir}/Terracotta/tools/management-console/bin/start-tmc.sh" & wait


if [ "${SUIF_DEBUG_ON}" -eq 1 ]; then
    logD "Stopping execution for debug"
    tail -f /dev/null
fi