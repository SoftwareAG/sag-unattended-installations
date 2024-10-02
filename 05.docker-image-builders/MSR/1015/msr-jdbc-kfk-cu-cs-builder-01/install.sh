#!/bin/bash

export SUIF_HOME=${SUIF_HOME:-"/tmp/SUIF_HOME"}
export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/softwareag"}
export SUIF_SUM_HOME=${SUIF_SUM_HOME:-"/tmp/sumv11"}
export SUIF_TAG=${SUIF_TAG:-main}
export SUIF_TEMPLATE=${SUIF_TEMPLATE:-"MSR/1015/jdbc_kfk_cu_cs"}

git clone -b "${SUIF_TAG}" --single-branch --depth 1 \
  https://github.com/SoftwareAG/sag-unattended-installations.git \
  "${SUIF_HOME}"

# shellcheck source=SCRIPTDIR/../../../../01.scripts/commonFunctions.sh
. "${SUIF_HOME}"/01.scripts/commonFunctions.sh
# shellcheck source=SCRIPTDIR/../../../../01.scripts/installation/setupFunctions.sh
. "${SUIF_HOME}"/01.scripts/installation/setupFunctions.sh

logI "SUIF env before installation:"
env | grep SUIF_ | sort

logI "Installing Product according to template ${SUIF_TEMPLATE}..."

applySetupTemplate "${SUIF_TEMPLATE}"

installResult=$?

if [ "${installResult}" -ne 0 ]; then
  logE "Installation failed, code ${installResult}"
  exit 1
fi

logI "Product installation successful"
