#!/bin/sh

if [ ! "`type -t urlencode`X" == "functionX" ]; then
    if [ ! -f "${SUIF_CACHE_HOME}/installationScripts/commonFunctions.sh" ]; then
        echo "Panic, common functions not sourced and not present locally! Cannot continue"
        exit 500
    fi
    . "$SUIF_CACHE_HOME/installationScripts/commonFunctions.sh"
fi

############## Section 1 - the caller MUST provide
## Framework - Install
export SUIF_INSTALL_INSTALLER_BIN=${SUIF_INSTALL_INSTALLER_BIN:-"/path/to/installer.bin"}
export SUIF_INSTALL_IMAGE_FILE=${SUIF_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}

## Framework - Patch
export SUIF_PATCH_SUM_BOOSTSTRAP_BIN=${SUIF_PATCH_SUM_BOOSTSTRAP_BIN:-"/path/to/sum-boostrap.bin"}
export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

## Template Specific
export SUIF_WMSCRIPT_NUMLicenseFile=${SUIF_WMSCRIPT_NUMLicenseFile:'/path/to/NUMLicense.xml'}
export SUIF_WMSCRIPT_NUMRealmServerLicenseFiletext=$(urlencode ${SUIF_WMSCRIPT_NUMLicenseFile})
############## Section 1 END - the caller MUST provide

## Current Template

############## Section 2 - the caller MAY provide
## Framework - Install
export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export SUIF_INSTALL_DECLARED_HOSTNAME=${SUIF_INSTALL_DECLARED_HOSTNAME:-"localhost"}
## Framework - Patch
export SUIF_SUM_HOME=${SUIF_SUM_HOME:-"/opt/sag/sum"}
## Template specific
export SUIF_WMSCRIPT_NUMDataDirID=${SUIF_WMSCRIPT_NUMDataDirID:-'/app/data'}
export SUIF_WMSCRIPT_NUMInterfacePortID=${SUIF_WMSCRIPT_NUMInterfacePortID:-9000}
export SUIF_WMSCRIPT_NUMRealmServerNameID=${SUIF_WMSCRIPT_NUMRealmServerNameID:-'umserver'}
export SUIF_WMSCRIPT_SPMHttpPort=${SUIF_WMSCRIPT_SPMHttpPort:-8092}
export SUIF_WMSCRIPT_SPMHttpsPort=${SUIF_WMSCRIPT_SPMHttpsPort:-8093}
############## Section 2 END - the caller MAY provide

logI "Template environment sourced successfully"
logEnv4Debug
