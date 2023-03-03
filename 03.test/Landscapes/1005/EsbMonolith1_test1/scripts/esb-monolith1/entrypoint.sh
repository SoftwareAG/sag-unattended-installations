#!/bin/sh

# shellcheck source=/dev/null
# shellcheck disable=SC3043

# This scripts sets up the local installation

if [ ! -d "${SUIF_HOME}" ]; then
  echo "SUIF_HOME variable MUST point to an existing local folder! Current value is ${SUIF_HOME}"
  exit 1
fi

# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 101
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 102

export SUIF_TEST_HARNESS_FOLDER="03.test/Labs/1005/EsbMonolith1/test1"

checkEnvVariables() {

  if [ -z "${SUIF_INSTALL_INSTALL_DIR+x}" ]; then
    logE "[$SUIF_TEST_HARNESS_FOLDER/esb-monolith1/entrypoint.sh:checkEnvVariables()] - Variable SUIF_INSTALL_INSTALL_DIR was not set!"
    return 103
  fi

  if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}" ]; then
    logE "[$SUIF_TEST_HARNESS_FOLDER/esb-monolith1/entrypoint.sh:checkEnvVariables()] - Installation folder does not exist, but for this test it must be a mounted volume: ${SUIF_INSTALL_INSTALL_DIR}"
    return 104
  fi

  if [ ! -f "${SUIF_INSTALL_INSTALLER_BIN_MOUNT_POINT}" ]; then
    logE "[$SUIF_TEST_HARNESS_FOLDER/esb-monolith1/entrypoint.sh:checkEnvVariables()] - ${SUIF_INSTALL_INSTALLER_BIN_MOUNT_POINT} is not a file, cannot continue"
  fi

  if [ ! -f "${SUIF_INSTALL_INSTALLER_BIN_MOUNT_POINT}" ]; then
    logE "[$SUIF_TEST_HARNESS_FOLDER/esb-monolith1/entrypoint.sh:checkEnvVariables()] - ${SUIF_INSTALL_INSTALLER_BIN_MOUNT_POINT} is not a file, cannot continue"
  fi

  if [ ! -f "${SUIF_PATCH_SUM_BOOTSTRAP_BIN_MOUNT_POINT}" ]; then
    logE "[$SUIF_TEST_HARNESS_FOLDER/esb-monolith1/entrypoint.sh:checkEnvVariables()] - ${SUIF_PATCH_SUM_BOOTSTRAP_BIN_MOUNT_POINT} is not a file, cannot continue"
  fi
}

checkEnvVariables || exit $?

cp "${SUIF_INSTALL_INSTALLER_BIN_MOUNT_POINT}" "${SUIF_INSTALL_INSTALLER_BIN}"
cp "${SUIF_PATCH_SUM_BOOTSTRAP_BIN_MOUNT_POINT}" "${SUIF_PATCH_SUM_BOOTSTRAP_BIN}"

checkSetupTemplateBasicPrerequisites || exit $?

# Parameters
# $1 - DB server FQDN
# $2 - DB server port
# $3 - DB service name
# $4 - DB user name
# $5 - DB user password
checkStorageAlreadyExists(){

  local crtFolder
  crtFolder="$(pwd)"

  cd "${SUIF_INSTALL_INSTALL_DIR}/common/db/bin" || return 222

  # for some reason I found these not executable
  chmod u+x ./*.sh 

  logI "Waiting for the database service to be available on server ${1} port ${2}..."

  if ! waitForExternalServicePort "${1}" "${2}" ; then
      logI "DB Server unavailable, cannot continue"
    exit 201
  fi

  local lDBC_DB_URL="jdbc:wm:oracle://${1}:${2};serviceName=${3}"
  local lCmdChkAlreadyCreated="./dbConfigurator.sh"' \
    --action catalog \
    --dbms oracle \
    --user '"'${4}'"' \
    --password '"'${5}'"' \
    --url '"'${lDBC_DB_URL}'"

  if [ "${SUIF_DEBUG_ON}" -ne 0 ]; then
  local lCmdChkAlreadyCreatedToLog="./dbConfigurator.sh"' \
    --action catalog \
    --dbms oracle \
    --user '"'${4}'"' \
    --password '"'*****'"' \
    --url '"'${lDBC_DB_URL}'"
    logD "[${thisFolder}/checkPrerequisites.sh:checkStorageAlreadyExists()] - Command to execute is ${lCmdChkAlreadyCreatedToLog}"
  fi

  logI "[${thisFolder}/checkPrerequisites.sh:checkStorageAlreadyExists()] - Checking if product database exists"
  controlledExec "${lCmdChkAlreadyCreated}" "$(date +%s).CheckDatabaseExists"

  local resChkAlreadyCreated=$?
  if [ "${resChkAlreadyCreated}" -eq 0 ]; then
    logI "[${thisFolder}/checkPrerequisites.sh:checkStorageAlreadyExists()] - Schema ${4} already exists, continuing..."
  else
    logI "[${thisFolder}/checkPrerequisites.sh:checkStorageAlreadyExists()] - Schema ${4} does not exist or not reachable, code ${resChkAlreadyCreated}"
    cd "${crtFolder}" || return 223
    return 221
  fi

  cd "${crtFolder}" || return 224
}

waitForDb(){
  until checkStorageAlreadyExists "${SUIF_SETUP_ISCORE_DB_SERVER_FQDN}" "${SUIF_SETUP_ISCORE_DB_SERVER_PORT}" "${SUIF_SETUP_ISCORE_DB_SERVICE_NAME}" "${SUIF_WMSCRIPT_IntegrationServerDBUser_Name}" "${SUIF_WMSCRIPT_IntegrationServerDBPass_Name} "
  do
    logI "Waiting for the DB to be initialized"
    sleep 5
  done
}


# If the installation is not present, do it now
if [ ! -d "${SUIF_INSTALL_INSTALL_DIR}/IntegrationServer" ]; then
  echo "Starting up for the first time, setting up ..."

  # Parameters - applySetupTemplate
  # $1 - Setup template directory, relative to <repo_home>/02.templates/01.setup
  applySetupTemplate "Landscapes/1005/EsbMonolith1" || exit 6
fi

onInterrupt() {
  echo "Shutting down Integration server ..."
  cd "${SUIF_INSTALL_INSTALL_DIR}/profiles/IS_default/bin" || return 1
  ./shutdown.sh

  logI "Stopping MWS ..."
  cd "${SUIF_INSTALL_INSTALL_DIR}/MWS/server/mws/bin" || exit 8
  ./shutdown.sh

  logI "Stopping Universal Messaging ..."
  cd "${SUIF_INSTALL_INSTALL_DIR}/UniversalMessaging/server/umserver/bin" || exit 9
  ./nserverdaemon stop

  echo "Shutting down Platform manager ..."
  cd "${SUIF_INSTALL_INSTALL_DIR}/profiles/SPM/bin" || return 2
  ./shutdown.sh
  #popd >/dev/null
  exit 0 # managed expected exit
}

onKill() {
  logW "Killed!"
}

logI "Waiting for the database availability ..."
waitForDb


trap "onInterrupt" INT TERM

logI "Starting up MWS ..."
cd "${SUIF_INSTALL_INSTALL_DIR}/MWS/server/mws/bin" || exit 8
./startup.sh

logI "Starting up Universal Messaging ..."
cd "${SUIF_INSTALL_INSTALL_DIR}/UniversalMessaging/server/umserver/bin" || exit 9
./nserverdaemon start


logI "Starting up Integration server ..."
cd "${SUIF_INSTALL_INSTALL_DIR}/profiles/IS_default/bin" || exit 7
./console.sh &

WPID=$!

until portIsReachable2 localhost 5555; do
  logI "Waiting for Integration Server to come up, sleeping 5..."
  sleep 5
done

wait ${WPID}
