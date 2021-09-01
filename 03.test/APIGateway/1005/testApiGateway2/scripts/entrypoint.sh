#!/bin/sh
# ---------------------------------------------------------------------------------
# This scripts sets up the local installation - run on the target provisioned VM
#  - At this point, the VM is provisioned,
#  - Azure shared file system is mounted,
#  - Shared file system contains:
#       - Product and fix images, installers
#       - The complete suif script directories
# ---------------------------------------------------------------------------------
export LOC_AZ_PUBLIC_IP=$1 
echo " ----------------------------------------------------------"
echo " - Running entrypoint.sh script on VM :: $LOC_AZ_PUBLIC_IP"
echo " ----------------------------------------------------------"

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

# our configuration takes precedence in front of framework defaults, set it before sourcing the framework functions
if [ ! -d "${SCRIPT_DIR}" ]; then
    echo "Scripts folder not found: ${SCRIPT_DIR}"
    exit 2
fi

if [ ! -f "${SCRIPT_DIR}/set_env.sh" ]; then
    echo "set_env script not found: ${SCRIPT_DIR}/set_env.sh"
    exit 3
fi

# ----------------------------------------
# Ability to override suif environment variables - all variables controlled via suif.env
# ----------------------------------------
. "${SCRIPT_DIR}/set_env.sh"

# ----------------------------------------
# Source framework functions
# ----------------------------------------
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

# ----------------------------------------
# Start API Gateway (or install if not present)
# ----------------------------------------
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
    echo "Starting up for the first time, setting up ..."

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "APIGateway/1005/default" || exit 6
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

onKill(){
	logW "Killed!"
}

checkPrerequisites(){
    local c1=262144 # p1 -> vm.max_map_count
    local p1=$(sysctl "vm.max_map_count" | cut -d " " -f 3)
    if [[ ! $p1 -lt $c1 ]]; then
        logI "vm.max_map_count is adequate ($p1)"
    else
        logE "vm.max_map_count is NOT adequate ($p1), will exit now."
		return 1
    fi
} 

afterStartConfig(){
    logI "Applying afterStartConfig"
    applyPostSetupTemplate ApiGateway/1005/ChangeAdministratorPassword
    applyPostSetupTemplate ApiGateway/1005/SetLoadBalancerConfiguration
    applyPostSetupTemplate ApiGateway/1005/PutSettings
}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

echo "Starting up API Gateway server"
echo "Checking prerequisites ..."
checkPrerequisites || exit 7
pushd . >/dev/null
echo "Starting Elasticsearch ..."
cd "${SUIF_INSTALL_INSTALL_DIR}/InternalDataStore/bin"
./startup.sh
echo "Starting Integration Server"
cd "${SUIF_INSTALL_INSTALL_DIR}/profiles/IS_default/bin"
./console.sh & 

WPID=$!

logI "Waiting for API Gateway to come up"

p=`portIsReachable localhost $SUIF_INSTALL_YAI_HTTP_PORT`
while [ $p -eq 0 ]; do
    logI "Waiting for API Gateway to come up, sleeping 5..."
    sleep 5
    p=`portIsReachable localhost $SUIF_INSTALL_YAI_HTTP_PORT`
done

afterStartConfig

echo " ----------------------------------------------------------------------"
echo " - Access via browser ::                                               "
echo "   IS: http://$LOC_AZ_PUBLIC_IP:$SUIF_INSTALL_IS_MAIN_HTTP_PORT        "
echo "   APIGW http://$LOC_AZ_PUBLIC_IP:$SUIF_INSTALL_YAI_HTTP_PORT          "
echo "   APIGW https://$LOC_AZ_PUBLIC_IP:$SUIF_INSTALL_YAI_HTTPS_PORT        "
echo " ----------------------------------------------------------------------"

wait ${WPID}

popd >/dev/null


