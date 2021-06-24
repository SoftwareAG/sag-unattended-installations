#!/bin/sh

# The values in this file reflect the purpose of the current test harness

# commonFunctions variables
export SUIF_ONLINE_MODE=0                   # we are running offline
export SUIF_DEBUG_ON=1                      # we want to see details

# expect these values to match the mounts
export SUIF_AUDIT_BASE_DIR=${SUIF_AUDIT_BASE_DIR:-"/app/audit"}

export SUIF_HOME=${SUIF_HOME."/mnt/SUIF_HOME"} # must have this, we are running offline

if [ ! -f "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" ]; then
    echo "PANIC! Working in offline mode, but SUIF dependency not present! declared SUIF_HOME is ${SUIF_HOME}"
    exit 1
fi

# setupFunctions Variables - for this test they are provided with docker-compose mounts
export SUIF_INSTALL_INSTALLER_BIN=${SUIF_INSTALL_INSTALLER_BIN:-"/tmp/installer.bin"}
export SUIF_INSTALL_IMAGE_FILE=${SUIF_INSTALL_IMAGE_FILE:-"/tmp/product.image.zip"}
export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export SUIF_INSTALL_SPM_HTTPS_PORT=${SUIF_INSTALL_SPM_HTTPS_PORT:-"9083"}
export SUIF_INSTALL_SPM_HTTP_PORT=${SUIF_INSTALL_SPM_HTTP_PORT:-"9082"}

export SUIF_PATCH_SUM_BOOSTSTRAP_BIN=${SUIF_PATCH_SUM_BOOSTSTRAP_BIN:-"/tmp/sum-boostrap.bin"}
export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_PATCH_FIXES_IMAGE_FILE:-"/tmp/fixes.image.zip"}

# Specific product setup variables
export SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE=${SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE:-"/tmp/API_Gateway_license.xml"}

export SUIF_APIGW_ADMINISTRATOR_PASSWORD=${SUIF_APIGW_ADMINISTRATOR_PASSWORD:-"manage1"}

export SUIF_APIGW_OLD_ADMINISTRATOR_PASSWORD=${SUIF_APIGW_OLD_ADMINISTRATOR_PASSWORD:-"manage"}
export SUIF_APIGW_NEW_ADMINISTRATOR_PASSWORD="${SUIF_APIGW_ADMINISTRATOR_PASSWORD}"
export SUIF_INSTALL_DECLARED_HOSTNAME=${SUIF_INSTALL_DECLARED_HOSTNAME:-"localhost"}

export SUIF_INSTALL_IS_MAIN_HTTP_PORT=${SUIF_INSTALL_IS_MAIN_HTTP_PORT:-"5555"}

export SUIF_APIGW_URL_PROTOCOL=${SUIF_APIGW_URL_PROTOCOL:-"http"}
export SUIF_APIGW_DOMAINNAME=${SUIF_INSTALL_DECLARED_HOSTNAME}
export SUIF_APIGW_SERVICE_PORT=${SUIF_INSTALL_IS_MAIN_HTTP_PORT}

export SUIF_APIGW_LB_JSON_FILE=${SUIF_APIGW_LB_JSON_FILE:-"/mnt/scripts/config/lb.json"}
export SUIF_APIGW_SETTINGS_JSON_FILE=${SUIF_APIGW_SETTINGS_JSON_FILE:-"/mnt/scripts/config/putSettings.json"}
