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

# Parameters - patchInstallation
# $1 - Fixes Image (this will allways happen offline in this framework)
# $2 - OTPIONAL SUM Home, default /opt/sag/sum
# $3 - OTPIONAL Products Home, default /opt/sag/products
patchInstallation "${SUIF_PATCH_FIXES_IMAGE_FILE}" "${SUIF_SUM_HOME}" "${SUIF_INSTALL_INSTALL_DIR}" "${SUIF_ENG_PATCH_MODE}" "${SUIF_ENG_PATCH_DIAGS_KEY}"
