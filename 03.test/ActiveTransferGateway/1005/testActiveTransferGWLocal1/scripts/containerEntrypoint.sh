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



# If the DBC installation is not present, do it now
#if [ ! -f "${SUIF_INSTALL_InstallDir}/common/db/bin/dbConfigurator.sh" ]; then
#    echo "Database configurator is not present, setting up ..."

#    export SUIF_INSTALL_IMAGE_FILE=${SUIF_DBC4AT_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}
#    export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_DBC4AT_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
#   applySetupTemplate "AT/1005/DBC4AT" || exit 6

#fi
# we need to set up the database
#applyPostSetupTemplate "DBC/1005/Sql-server-create" || exit 7

# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_InstallDir}/IntegrationServer" ]; then
    echo "Integration server not present, setting up ..."

    export SUIF_INSTALL_IMAGE_FILE=${SUIF_AT_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}
    export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_AT_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

    # Parameters - applySetupTemplate
    # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
    applySetupTemplate "AT/1005/default" || exit 8
fi

onInterrupt(){
	echo "Interrupted! Shutting down MFT Server"
    pushd . >/dev/null
	echo "Shutting down Integration server ..."
    cd "${SUIF_INSTALL_InstallDir}/profiles/IS_default/bin"
    ./shutdown.sh
	echo "Shutting down Platform manager ..."
    cd "${SUIF_INSTALL_InstallDir}/profiles/SPM/bin"
    ./shutdown.sh
	exit 0 # managed expected exit
}

onKill(){
	logW "Killed!"
}

checkPrerequisites(){
    #TODO: check database?
    logI "Nothing here yet"
} 

afterStartConfig(){
    logI "Applying afterStartConfig"
}

trap "onInterrupt" SIGINT SIGTERM
trap "onKill" SIGKILL

echo "Starting up MFT Server"
#echo "Checking prerequisites ..."
#checkPrerequisites || exit 7
pushd . >/dev/null
echo "Starting Integration Server"
cd "${SUIF_INSTALL_InstallDir}/profiles/IS_default/bin"
./console.sh & 

WPID=$!

logI "Waiting for MFT Gateway to come up"

p=`portIsReachable localhost 5555`
while [ $p -eq 0 ]; do
    logI "Waiting for Active Transfer to come up, sleeping 5..."
    sleep 5
    p=`portIsReachable localhost 5555`
done

afterStartConfig

wait ${WPID}

popd >/dev/null
