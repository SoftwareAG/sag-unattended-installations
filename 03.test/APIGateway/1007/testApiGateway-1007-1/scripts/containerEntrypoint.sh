#!/bin/sh

# This scripts sets up the local installation

if [ ! -d "${SUIF_HOME}" ]; then
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

# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
    echo "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "APIGateway/1007/default" || exit 6
fi

onInterrupt(){
	echo "Interrupted! Shutting down API Gateway"
    pushd . >/dev/null
	echo "Shutting down Integration server ..."
    cd "${SUIF_INSTALL_INSTALL_DIR}/profiles/IS_default/bin"
    ./shutdown.sh
	echo "Shutting down Platform manager ..."
    cd "${SUIF_INSTALL_INSTALL_DIR}/profiles/SPM/bin"
    ./shutdown.sh
	echo "Shutting down Elasticsearch ..."
    cd "${SUIF_INSTALL_INSTALL_DIR}/InternalDataStore/bin"
    ./shutdown.sh
    #popd >/dev/null
	exit 0 # managed expected exit
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

beforeStartConfig(){
    logI "Before Start Configuration"
}

afterStartConfig(){
    logI "Applying afterStartConfig"
    applyPostSetupTemplate ApiGateway/1005/ChangeAdministratorPassword
    applyPostSetupTemplate ApiGateway/1005/SetLoadBalancerConfiguration
    applyPostSetupTemplate ApiGateway/1005/PutSettings
}

trap "onInterrupt" SIGINT SIGTERM

echo "Starting up API Gateway server"
echo "Checking prerequisites ..."

checkPrerequisites || exit 7
pushd . >/dev/null

beforeStartConfig

echo "Starting Elasticsearch ..."
cd "${SUIF_INSTALL_INSTALL_DIR}/InternalDataStore/bin"
./startup.sh
echo "Starting Integration Server"
cd "${SUIF_INSTALL_INSTALL_DIR}/profiles/IS_default/bin"
./console.sh & 

WPID=$!

logI "Waiting for API Gateway to come up"

while ! portIsReachable2 localhost 9072; do
    logI "Waiting for API Gateway to come up, sleeping 5..."
    sleep 5
done

afterStartConfig

wait ${WPID}

popd >/dev/null
