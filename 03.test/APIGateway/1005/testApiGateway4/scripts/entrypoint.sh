#!/bin/sh
# ---------------------------------------------------------------------------------
# This scripts sets up the local installation - runs on the target provisioned VM
# and is executed from the suif scripts directory. I.e.:
#  - The VM is provisioned already
#  - Azure shared file system is mounted to the /assets mount point
#  - Shared file system contains:
#       - Product and fix images, installers (/assets/media)
#       - The complete suif script directories (/assets/suif)
#
#  Parameters passed (from vm_init.sh)
#   1) AZ_VM_HOST_NAME
#   2) SUIF_LOCAL_SCRIPTS_HOME
#   3) H_APIGW_ADMIN_PASSWORD
# ---------------------------------------------------------------------------------

# ----------------------------------------
# Current host
# ----------------------------------------
export AZ_VM_HOST_NAME=$1

# ----------------------------------------
# Script directory
# ----------------------------------------
export SUIF_LOCAL_SCRIPTS_HOME=$2
# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ----------------------------------------
# Admin Password
# ----------------------------------------
export H_APIGW_ADMIN_PASSWORD=$3
export SUIF_APIGW_ADMINISTRATOR_PASSWORD=${H_APIGW_ADMIN_PASSWORD}

# ----------------------------------------
# Source environment variables from suif.env
# ----------------------------------------
export $(grep -v '^#' $SUIF_LOCAL_SCRIPTS_HOME/suif.env | xargs)

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

# ----------------------------------------
# Ability to override suif environment variables - all variables controlled via suif.env
# ----------------------------------------
. "${SUIF_LOCAL_SCRIPTS_HOME}/set_env.sh"

# ----------------------------------------
# Source framework functions
# ----------------------------------------
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 5

# ----------------------------------------
# Install Terracotta (if not already done)
# Note: retaining variable names here to avoid changing common functions
# ----------------------------------------
export SUIF_INSTALL_INSTALL_DIR=${SUIF_ROOT_INSTALL_DIR}/TSA
export SUIF_INSTALL_IMAGE_FILE=${SUIF_INSTALL_TSA_IMAGE_FILE}
export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_PATCH_TSA_FIXES_IMAGE_FILE}
export SUIF_INSTALL_SPM_HTTP_PORT=${SUIF_INSTALL_TSA_SPM_HTTP_PORT}
export SUIF_INSTALL_SPM_HTTPS_PORT=${SUIF_INSTALL_TSA_SPM_HTTPS_PORT}
export SUIF_POST_TC_SERVER_HOST_CURRENT=${AZ_VM_HOST_NAME}
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/Terracotta" ]; then
    echo " - Setting up application ..."
    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "BigMemoryServer/1005/default" || exit 4
    applyPostSetupTemplate "BigMemoryServer/1005/ThreeNodeCluster" || exit 5
fi

# ----------------------------------------
# Install API Gateway (if not already done)
# ----------------------------------------
export SUIF_INSTALL_INSTALL_DIR=${SUIF_ROOT_INSTALL_DIR}/APIGW
export SUIF_INSTALL_IMAGE_FILE=${SUIF_INSTALL_APIGW_IMAGE_FILE}
export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_PATCH_APIGW_FIXES_IMAGE_FILE}
export SUIF_INSTALL_SPM_HTTP_PORT=${SUIF_INSTALL_APIGW_SPM_HTTP_PORT}
export SUIF_INSTALL_SPM_HTTPS_PORT=${SUIF_INSTALL_APIGW_SPM_HTTPS_PORT}
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
    echo " - Setting up application ..."
    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "APIGateway/1005/default" || exit 6
fi

# ----------------------------------------
# Perform post-install configuration
# ----------------------------------------
if [ ! -f "${SUIF_ROOT_INSTALL_DIR}/APIGW/InternalDataStore/config/elasticsearch.yml.orig" ]; then
    echo " - Applying Elastic Search configuration ..."
    mv ${SUIF_ROOT_INSTALL_DIR}/APIGW/InternalDataStore/config/elasticsearch.yml ${SUIF_ROOT_INSTALL_DIR}/APIGW/InternalDataStore/config/elasticsearch.yml.orig
    envsubst < "${SUIF_LOCAL_SCRIPTS_HOME}/config/IDS/elasticsearch.yml" > ${SUIF_ROOT_INSTALL_DIR}/APIGW/InternalDataStore/config/elasticsearch.yml
fi
if [ ! -f "${SUIF_ROOT_INSTALL_DIR}/APIGW/common/conf/terracotta-license.key" ]; then
    echo " - Applying Terracotta license ..."
    cp ${SUIF_SETUP_TEMPLATE_TES_LICENSE_FILE} ${SUIF_ROOT_INSTALL_DIR}/APIGW/common/conf/terracotta-license.key
fi
if [ ! -d "${SUIF_ROOT_INSTALL_DIR}/APIGW/IntegrationServer/instances/default/packages/WmAPIGateway/resources/configuration.orig" ]; then
    echo " - Applying APIGW configuration ..."
    mv ${SUIF_ROOT_INSTALL_DIR}/APIGW/IntegrationServer/instances/default/packages/WmAPIGateway/resources/configuration \
       ${SUIF_ROOT_INSTALL_DIR}/APIGW/IntegrationServer/instances/default/packages/WmAPIGateway/resources/configuration.orig
    mkdir -p ${SUIF_ROOT_INSTALL_DIR}/APIGW/IntegrationServer/instances/default/packages/WmAPIGateway/resources/configuration
    cp ${SUIF_LOCAL_SCRIPTS_HOME}/config/apigw_resources/*.yml ${SUIF_ROOT_INSTALL_DIR}/APIGW/IntegrationServer/instances/default/packages/WmAPIGateway/resources/configuration/
fi
if [ ! -f "${SUIF_ROOT_INSTALL_DIR}/APIGW/profiles/IS_default/apigateway/dashboard/config/kibana.yml.orig" ]; then
    echo " - Applying Kibana config ..."
    mv ${SUIF_ROOT_INSTALL_DIR}/APIGW/profiles/IS_default/apigateway/dashboard/config/kibana.yml \
       ${SUIF_ROOT_INSTALL_DIR}/APIGW/profiles/IS_default/apigateway/dashboard/config/kibana.yml.orig
    cp ${SUIF_LOCAL_SCRIPTS_HOME}/config/kibana_profile/kibana.yml ${SUIF_ROOT_INSTALL_DIR}/APIGW/profiles/IS_default/apigateway/dashboard/config
fi

onInterrupt(){
    # API Gateway
	echo "Interrupted! Shutting down API Gateway"
    pushd . >/dev/null
	echo "Shutting down Integration server ..."
    cd "${SUIF_ROOT_INSTALL_DIR}/APIGW/profiles/IS_default/bin"
    ./shutdown.sh
	echo "Shutting down Platform manager ..."
    cd "${SUIF_ROOT_INSTALL_DIR}/APIGW/profiles/SPM/bin"
    ./shutdown.sh
	echo "Shutting down Elasticsearch ..."
    cd "${SUIF_ROOT_INSTALL_DIR}/APIGW/InternalDataStore/bin"
    ./shutdown.sh
    popd >/dev/null

    # Terracotta Server
	echo " - Interrupted! Shutting down TMC & TSA"
    pushd . >/dev/null
	echo "Shutting down TMC ..."
    cd "${SUIF_ROOT_INSTALL_DIR}/TSA/Terracotta/tools/management-console/bin"
	./stop-tmc.sh
	echo "Shutting down Platform manager ..."
    cd "${SUIF_ROOT_INSTALL_DIR}/TSA/profiles/SPM/bin"
    ./shutdown.sh
    cd "${SUIF_ROOT_INSTALL_DIR}/TSA/Terracotta/server/wrapper/bin"
    ./shutdown.sh
    popd >/dev/null

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
    export SUIF_INSTALL_INSTALL_DIR=${SUIF_ROOT_INSTALL_DIR}/APIGW
    applyPostSetupTemplate ApiGateway/1005/ChangeAdministratorPassword
    applyPostSetupTemplate ApiGateway/1005/SetLoadBalancerConfiguration
    applyPostSetupTemplate ApiGateway/1005/PutSettings
}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

# Terracotta Server
echo " - Starting up Terracotta Server ${AZ_VM_HOST_NAME} ..."
pushd . >/dev/null
cd "${SUIF_ROOT_INSTALL_DIR}/TSA/Terracotta/server/wrapper/bin/"
./startup.sh -n ${AZ_VM_HOST_NAME} > /dev/null 2>&1 &
popd >/dev/null

echo " - Starting up TMC ..."
pushd . >/dev/null
cd "${SUIF_ROOT_INSTALL_DIR}/TSA/Terracotta/tools/management-console/bin"
./start-tmc.sh > /dev/null 2>&1 &
popd >/dev/null

# API Gateway
echo "Starting up API Gateway server"
echo "Checking prerequisites ..."
checkPrerequisites || exit 7
pushd . >/dev/null
echo "Starting Elasticsearch ..."
cd "${SUIF_ROOT_INSTALL_DIR}/APIGW/InternalDataStore/bin"
./startup.sh
echo "Starting Integration Server"
cd "${SUIF_ROOT_INSTALL_DIR}/APIGW/profiles/IS_default/bin"
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

wait ${WPID}

popd >/dev/null


