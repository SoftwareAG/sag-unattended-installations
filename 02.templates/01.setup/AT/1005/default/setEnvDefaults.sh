#!/bin/sh

if [ ! "`type -t urlencode`X" == "functionX" ]; then
    if [ ! -f "${SUIF_CACHE_HOME}/installationScripts/commonFunctions.sh" ]; then
        echo "Panic, common functions not sourced and not present locally! Cannot continue"
        exit 500
    fi
    . "$SUIF_CACHE_HOME/installationScripts/commonFunctions.sh"
fi

# Section 1 - the caller MUST provide
## Framework - Install
export SUIF_INSTALL_INSTALLER_BIN=${SUIF_INSTALL_INSTALLER_BIN:-"/path/to/installer.bin"}
export SUIF_INSTALL_IMAGE_FILE=${SUIF_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}

## Framework - Patch
export SUIF_PATCH_SUM_BOOTSTRAP_BIN=${SUIF_PATCH_SUM_BOOTSTRAP_BIN:-"/path/to/sum-boostrap.bin"}
export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

## Current Template
export SUIF_SETUP_TEMPLATE_IS_LICENSE_FILE=${SUIF_SETUP_TEMPLATE_IS_LICENSE_FILE:-"/provide/path/to/IS-license.xml"}
export SUIF_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE=${SUIF_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE:-"/provide/path/to/MFTSERVER-license.xml"}

# Section 2 - the caller MAY provide
## Framework - Install
export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export SUIF_INSTALL_SPM_HTTPS_PORT=${SUIF_INSTALL_SPM_HTTPS_PORT:-"9083"}
export SUIF_INSTALL_SPM_HTTP_PORT=${SUIF_INSTALL_SPM_HTTP_PORT:-"9082"}
export SUIF_INSTALL_DECLARED_HOSTNAME=${SUIF_INSTALL_DECLARED_HOSTNAME:-"localhost"}
## Framework - Patch
export SUIF_SUM_HOME=${SUIF_SUM_HOME:-"/opt/sag/sum"}
## YAI related
export SUIF_INSTALL_IS_MAIN_HTTP_PORT=${SUIF_INSTALL_IS_MAIN_HTTP_PORT:-"5555"}
export SUIF_INSTALL_IS_DIAGS_HTTP_PORT=${SUIF_INSTALL_IS_DIAGS_HTTP_PORT:-"9999"}

## AT related
export SUIF_INSTALL_MFTSERVER_PORT=${SUIF_INSTALL_MFTSERVER_PORT:-"8500"}

export SUIF_SETUP_TEMPLATE_IS_LICENSE_UrlEncoded=$(urlencode ${SUIF_SETUP_TEMPLATE_IS_LICENSE_FILE})
export SUIF_SETUP_TEMPLATE_MFTSERVER_LICENSE_UrlEncoded=$(urlencode ${SUIF_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE})

# database
## User MUST provide
export SUIF_SQLSERVER_HOSTNAME=${SUIF_SQLSERVER_HOSTNAME:-"ProvideDBHostName!"}
export SUIF_SQLSERVER_DATABASE_NAME=${SUIF_SQLSERVER_DATABASE_NAME:-"ProvideDatabaseName!"}
export SUIF_SQLSERVER_USER_NAME=${SUIF_SQLSERVER_USER_NAME:-"ProvideUserName!"}
export SUIF_SQLSERVER_PASSWORD=${SUIF_SQLSERVER_PASSWORD:-"ProvideUserPAssowrd!"}
## User MAY provide
export SUIF_SQLSERVER_DB_CONN_ALIAS=${SUIF_SQLSERVER_DB_CONN_ALIAS:-"mftDbConn"}
export SUIF_SQLSERVER_PORT=${SUIF_SQLSERVER_PORT:-"1433"}

logI "Template environment sourced successfully"
logEnv4Debug
