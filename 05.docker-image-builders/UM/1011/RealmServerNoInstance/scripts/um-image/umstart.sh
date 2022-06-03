#!/bin/bash

###############################################################################
# Initial Verifications
# These are supposed to be passed at start time, not at build time
###############################################################################

if [ -z ${UM_REALM_NAME+x} ]; then
  echo "UM_REALM_NAME must contain a valid realm name"
  exit 1
fi

###############################################################################
# Variable  Declaration
###############################################################################

nirvanaLog=nirvana.log
umRealmServiceLog=UMRealmService.log

###############################################################################
# Eventually Create Realm
###############################################################################


if [ ! -d "${UM_HOME}/server/profiles" ]; then
  echo "Folder ${UM_HOME}/server/profiles does not exist, creating. This is normal for a first start where the server data volume has been just initialized"
  cd "${UM_HOME}"
  tar xzf server.tgz
fi

if [ ! -f "${UM_HOME}/server/${UM_REALM_NAME}/bin/nserver" ]; then
  echo "Realm Server does not exist, creating now. This is normal for a first start where the server data volume has been just initialized"

  cd "${UM_HOME}/tools/InstanceManager"

  # Note: no explict data dir: it would be a partial config still relying on the base image build to hardwire the realm name
  # IRL the "data" dir is the whole server directory and the realm name should be decided at startup time, not at build time

  echo "Creating realm ${UM_REALM_NAME} using port ${UM_PORT}"

  ./ninstancemanager.sh create \
    "${UM_REALM_NAME}" \
    rs \
    0.0.0.0 \
    "${UM_PORT}" \
    || exit $?

  created=$(grep -i "Created RS instance $UM_REALM_NAME" instanceLog.txt | wc -l)
  if [ $created -eq 1 ]; then
    echo "realm created"
  else
    echo "something happened, realm has not been created"
    exit 1
    #tail -f /dev/null
  fi
fi

###############################################################################
# UM Runtime Configuation related scripts
###############################################################################


# If you want to change the configurations related to JVM i.e, min max and direct memory, you can do it by providing INIT_JAVA_MEM_SIZE & MAX_JAVA_MEM_SIZE - 
# - & MAX_DIRECT_MEM_SIZE as environment variables during docker run, which will be updated in Server_Common.conf file
if [ ! -z "$INIT_JAVA_MEM_SIZE" ]; then
    echo "Updating UM init Java Heap value to $INIT_JAVA_MEM_SIZE"
    cd $UM_HOME/server/$UM_REALM_NAME/bin
    sed -i "s|^wrapper.java.initmemory=.*|wrapper.java.initmemory=$INIT_JAVA_MEM_SIZE|" $SERVER_COMMON_CONF_FILE
fi

if [ ! -z "$MAX_JAVA_MEM_SIZE" ]; then
    echo "Updating UM Max Java Heap value to $MAX_JAVA_MEM_SIZE"
    cd $UM_HOME/server/$UM_REALM_NAME/bin
    sed -i "s|^wrapper.java.maxmemory=.*|wrapper.java.maxmemory=$MAX_JAVA_MEM_SIZE|" $SERVER_COMMON_CONF_FILE
fi

if [ ! -z "$MAX_DIRECT_MEM_SIZE" ]; then
    echo "Updating UM Max Direct Memory value to $MAX_DIRECT_MEM_SIZE"
    cd $UM_HOME/server/$UM_REALM_NAME/bin
	  sed -i "s|\(.*\)=-XX:MaxDirectMemorySize=\(.*\)|\1=-XX:MaxDirectMemorySize=$MAX_DIRECT_MEM_SIZE|" $SERVER_COMMON_CONF_FILE
fi
# If you want to enable Basic auth and to enable and mandate it, you can do it by providing BASIC_AUTH_ENABLE & BASIC_AUTH_MANDATORY as env variables during docker run,
# which will update the values in Server_Common.conf file
if [ ! -z "$BASIC_AUTH_ENABLE" ]; then
    echo "Enabling Basic Auth for UM server"
    cd $UM_HOME/server/$UM_REALM_NAME/bin
    sed -i "s|\(.*\)=-DNirvana.auth.enabled=\(.*\)|\1=-DNirvana.auth.enabled=$BASIC_AUTH_ENABLE|" $SERVER_COMMON_CONF_FILE
fi

if [ ! -z "$BASIC_AUTH_MANDATORY" ]; then
    echo "Enabling and Mandating the Basic Auth for UM server"
    cd $UM_HOME/server/$UM_REALM_NAME/bin
	  sed -i "s|\(.*\)=-DNirvana.auth.mandatory=\(.*\)|\1=-DNirvana.auth.mandatory=$BASIC_AUTH_MANDATORY|" $SERVER_COMMON_CONF_FILE
fi

###############################################################################
# Function  Declaration: which does shutting down of um server
###############################################################################

function stop_um_server {
# Perform Server Shutdown
  echo "Info: Stopping the Universal Messaging Server.."
  cd "$UM_HOME/server/$UM_REALM_NAME/bin"
  ./nstopserver
  exit 0
}

onKill(){
	logW "Killed!"
}


###############################################################################
# Main  Declaration
# - Wait for SIGNAL TERMINATION from docker daemon and call the stop_um_server function
# - Create the empty logs files and stream the content to stdout and the log entries are prefixed with file names
# - Start the um server and capture its PID, to wait for it
###############################################################################

# to stop the running UM server if the server is running
trap stop_um_server SIGINT SIGTERM
trap "onKill" SIGKILL

# For streaming the nirvana.log and UMRealmService.log to stdout
cd $LOG_DIR
touch $nirvanaLog $umRealmServiceLog
tail -F $umRealmServiceLog | sed "s|^|[$umRealmServiceLog]: |" > /dev/stdout &
tail -F $nirvanaLog | sed "s|^|[$nirvanaLog]: |" > /dev/stdout &

if [[ ! -z "$ADD_HEALTH_CHECK" && "$ADD_HEALTH_CHECK"="true" ]]; then
    runUMTool.sh AddHealthMonitorPlugin -dirName=$DATA_DIR -protocol=http -adapter=0.0.0.0 -port=$PORT -mountpath=health -autostart=true
fi

# run the umserver
if [ ! -d "$UM_HOME/server/$UM_REALM_NAME/bin/" ]; then
  echo "Unknown situation, stopping for debug"
  tail -f /dev/null
fi

cd "$UM_HOME/server/$UM_REALM_NAME/bin/"
./nserver & 

# wait till the server shutdown
SERVER_PID=$!
echo "Universal Messaging Server PID:" $SERVER_PID
wait $SERVER_PID

tail -f /dev/null
