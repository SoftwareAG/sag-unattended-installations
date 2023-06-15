#!/bin/sh

# This scripts sets up the local installation

# shellcheck disable=SC3043,SC2006

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
# shellcheck source=../../../../../01.scripts/commonFunctions.sh
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 4

onInterrupt() {
  echo "Interrupted! Shutting Activetransfer Server..."
  # pushd . >/dev/null
  cd "${SUIF_INSTALL_INSTALL_DIR_ATS}/profiles/IS_default/bin/" || exit 101
  ./shutdown.sh
  # popd >/dev/null
  exit 0 # managed expected exit
}

onKill() {
  logW "Killed!"
}

trap "onInterrupt" INT TERM

logI "Starting Active Transfer Server..."
# pushd . > /dev/null
cd "${SUIF_INSTALL_INSTALL_DIR_ATS}/profiles/IS_default/bin/" || exit 102
./console.sh &
wait

# popd > /dev/null

if [ "${SUIF_DEBUG_ON}" -eq 1 ]; then
  logW "Stopping for debug"
  tail -f /dev/null
fi
