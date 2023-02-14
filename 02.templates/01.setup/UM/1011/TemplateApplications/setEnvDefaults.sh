#!/bin/sh

if [ ! "`type -t urlencode`X" == "functionX" ]; then
    if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, common functions not sourced and not present locally! Cannot continue"
        exit 500
    fi
    . "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh"
fi

# Section 1 - the caller MUST provide
## Framework - Install
export SUIF_INSTALL_INSTALLER_BIN=${SUIF_INSTALL_INSTALLER_BIN:-"/path/to/installer.bin"}
export SUIF_INSTALL_IMAGE_FILE=${SUIF_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}

## Framework - Patch
export SUIF_PATCH_SUM_BOOTSTRAP_BIN=${SUIF_PATCH_SUM_BOOTSTRAP_BIN:-"/path/to/sum-boostrap.bin"}
export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

## Current Template
# Nothing special

# Section 2 - the caller MAY provide
## Framework - Install
export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export SUIF_INSTALL_DECLARED_HOSTNAME=${SUIF_INSTALL_DECLARED_HOSTNAME:-"localhost"}
## Framework - Patch
export SUIF_SUM_HOME=${SUIF_SUM_HOME:-"/opt/sag/sum"}

logI "Template environment sourced successfully"
logEnv4Debug
