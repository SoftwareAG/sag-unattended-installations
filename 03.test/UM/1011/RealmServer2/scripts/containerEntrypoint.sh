#!/bin/sh

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
# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 3
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 4

pushd . > /dev/null

if [ ! -f "${SUIF_INSTALL_INSTALL_DIR}/UniversalMessaging/tools/InstanceManager/ninstancemanager.sh" ]; then
    echo "Starting up for the first time, setting up ..."
    export SUIF_WMSCRIPT_NUMDataDirID=${SUIF_WMSCRIPT_NUMDataDirID:-/tmp} # should not matter, no realm is created...
    applySetupTemplate "UM/1011/RealmServerNoInstance"
    local lResultInstall=$?
    logI "Product installed, result is ${lResultInstall}" # TODO: enforce. ATM there is a fix missbehaving and we go ahead nonetheless
    cd ${SUIF_INSTALL_INSTALL_DIR}/UniversalMessaging
    tar czf ../server.tgz server --remove-files
    logD "Listing files in ${SUIF_INSTALL_INSTALL_DIR}"
    ls -lrt ..
fi

onInterrupt(){
	echo "Interrupted! Shutting down Universal Messaging"
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

lServerDir="${SUIF_INSTALL_INSTALL_DIR}/UniversalMessaging/server/${SUIF_WMSCRIPT_NUMRealmServerNameID}"

# Eventually create the realm server

if [ ! -f "${lServerDir}/bin/nserver" ]; then
  logI "Realm Server does not exist, creating now"

  cd ${SUIF_INSTALL_INSTALL_DIR}/UniversalMessaging

  logD "Listing files in ${SUIF_INSTALL_INSTALL_DIR}"
  ls -lrt ..

  tar xzf ../server.tgz

  logD "Listing files in ${SUIF_INSTALL_INSTALL_DIR}"
  ls -lrt ..

  mkdir -p "${lServerDir}"
  cd "${SUIF_INSTALL_INSTALL_DIR}/UniversalMessaging/tools/InstanceManager"

  # Note: no explict data dir: it would be a partial config still relying on the base image build to hardwire the realm name
  # IRL the "data" dir is the whole server directory and the realm name should be decided at startup time, not at build time
  ./ninstancemanager.sh create \
    "${SUIF_WMSCRIPT_NUMRealmServerNameID}" \
    rs \
    0.0.0.0 \
    "${SUIF_WMSCRIPT_NUMInterfacePortID}" 
else
  logI "Realm server already present"
fi

echo "Starting up Universal Messaging"

# /app/1011/UM/UniversalMessaging/server/umserver1/bin/
# TODO: check if exists
#cd "${SUIF_INSTALL_INSTALL_DIR}/UniversalMessaging/server/${SUIF_WMSCRIPT_NUMRealmServerNameID}/bin"

"${SUIF_INSTALL_INSTALL_DIR}/UniversalMessaging/server/${SUIF_WMSCRIPT_NUMRealmServerNameID}/bin/nserver" & 

WPID=$!


logI "Waiting for UM Realm Server to come up..."

p=`portIsReachable localhost ${SUIF_WMSCRIPT_NUMInterfacePortID}`
while [ $p -eq 0 ]; do
    logI "Waiting for UM Realm Server to come up, sleeping 5..."
    sleep 5
    p=`portIsReachable localhost ${SUIF_WMSCRIPT_NUMInterfacePortID}`
done

afterStartConfig

popd >/dev/null

wait ${WPID}

#tail -f /dev/null
