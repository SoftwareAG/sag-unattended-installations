#!/bin/bash

export SUIF_HOME=${SUIF_HOME:-"/tmp/SUIF_HOME"}
export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/softwareag"}
export SUIF_SUM_HOME=${SUIF_SUM_HOME:"/tmp/sumv11"}
export SUIF_TAG=${SUIF_TAG:-main}
export SUIF_TEMPLATE=${SUIF_TEMPLATE:-"MSR/1015/lean"}

git clone -b "${SUIF_TAG}" --single-branch \
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

logI "Installing support patch $SUIF_SP_ID..."

# Parameters - patchInstallation
# $1 - Fixes Image (this will allways happen offline in this framework)
# $2 - OTPIONAL SUM Home, default /opt/sag/sum
# $3 - OTPIONAL Products Home, default /opt/sag/products
# $4 - OTPIONAL Engineering patch modifier (default "N")
# $5 - OTPIONAL Engineering patch diagnoser key (default "5437713_PIE-68082_5", however user must provide if $4=Y)

patchInstallation /tmp/sp.zip "${SUIF_SUM_HOME}" "${SUIF_INSTALL_INSTALL_DIR}" "Y" "${SUIF_SP_ID}"

patchResult=$?
if [ "${patchResult}" -ne 0 ]; then
  logE "Installation of support patch ${SUIF_SP_ID} failed, code ${patchResult}"
  exit 1
fi

logI "Product installation successful"
