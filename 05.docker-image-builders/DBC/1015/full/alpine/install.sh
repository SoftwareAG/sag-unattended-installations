#!/bin/sh

export SUIF_TAG="${SUIF_TAG:-main}"
export SUIF_HOME="${SUIF_HOME:-/tmp/SUIF_HOME}"
export SUIF_TEMPLATE="${SUIF_TEMPLATE:-DBC/1015/full}"

echo "Cloning SUIF for tag ${SUIF_TAG}..."

git clone -b "${SUIF_TAG}" --single-branch \
  https://github.com/SoftwareAG/sag-unattended-installations.git \
  "${SUIF_HOME}"

# shellcheck source=/dev/null
. "${SUIF_HOME}/01.scripts/commonFunctions.sh"

# shellcheck source=/dev/null
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh"

logI "SUIF env before installation:"
env | grep SUIF_ | sort

logI "Installing Product according to template ${SUIF_TEMPLATE}..."

applySetupTemplate "${SUIF_TEMPLATE}"

installResult=$?

if [ "${installResult}" -ne 0 ]; then
  logE "Installation failed, code ${installResult}"

  grep -rnw "error" "$SUIF_AUDIT_SESSION_DIR"
  exit 1
fi

logI "Product installation successful"