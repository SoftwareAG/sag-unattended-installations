#!/bin/bash

export SUIF_TAG=${SUIF_TAG:-main}
export SUIF_HOME=${SUIF_HOME:-"/tmp/SUIF_HOME"}
export SUIF_TEMPLATE=${SUIF_TEMPLATE:-"MSR/1011/AdaptersSet1"}

git clone -b "${SUIF_TAG}" --single-branch \
  https://github.com/SoftwareAG/sag-unattended-installations.git \
  "${SUIF_HOME}"

. ${SUIF_HOME}/01.scripts/commonFunctions.sh
. ${SUIF_HOME}/01.scripts/installation/setupFunctions.sh

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