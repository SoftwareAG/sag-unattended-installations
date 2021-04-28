#!/bin/sh

# Dependency 1
if [ ! "`type -t huntForSuifFile`X" == "functionX" ]; then
    echo "sourcing commonFunctions.sh ..."
    if [ ! -f "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue!"
        exit 500
    fi
    . "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh"
fi

# Dependency 2
if [ ! "`type -t patchInstallation`X" == "functionX" ]; then
    huntForSuifFile "01.scripts/installation" "setupFunctions.sh"

    if [ ! -f "$SUIF_CACHE_HOME/01.scripts/installation/setupFunctions.sh" ];then
        logE "setupFunctions.sh not available, cannot continue."
        exit 1
    fi

    logI "Sourcing setup functions"
    . "$SUIF_CACHE_HOME/01.scripts/installation/setupFunctions.sh"
fi


thisFolder="02.templates/02.post-setup/UpdateManager/v11/UninstallSP"

huntForSuifFile "${thisFolder}" "setEnvDefaults.sh"

if [ ! -f "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh" ]; then
    logE "File not found: ${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"
    exit 100
fi

. "${SUIF_CACHE_HOME}/${thisFolder}/setEnvDefaults.sh"

# Parameters - removeDiagnoserPatch
# $1 - Engineering patch diagnoser key (e.g. "5437713_PIE-68082_5")
# $2 - Engineering patch ids list (expected one id only, but we never know e.g. "5437713_PIE-68082_1.0.0.0005-0001")
# $3 - OTPIONAL SUM Home, default /opt/sag/sum
# $4 - OTPIONAL Products Home, default /opt/sag/products
removeDiagnoserPatch "${SUIF_ENG_PATCH_DIAGS_KEY}" "${SUIF_ENG_PATCH_FIX_ID_LIST}" "${SUIF_SUM_HOME}" "${SUIF_INSTALL_INSTALL_DIR}"
