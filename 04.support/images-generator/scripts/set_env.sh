#!/bin/sh

######## Assume these variables are set upfront, but just in case...
# commonFunctions variables
export SUIF_ONLINE_MODE=${SUIF_ONLINE_MODE:-1}
export SUIF_AUDIT_BASE_DIR=${SUIF_AUDIT_BASE_DIR:-"/tmp"}

# setupFunctions Variables
export SUIF_INSTALL_INSTALLER_BIN=${SUIF_INSTALL_INSTALLER_BIN:-"/tmp/installer.bin"}
export SUIF_PATCH_SUM_BOOTSTRAP_BIN=${SUIF_PATCH_SUM_BOOTSTRAP_BIN:-"/tmp/sum-boostrap.bin"}

####### Also set in docker as permissions on mounts need them
export SUIF_USER_HOME=${SUIF_USER_HOME:-"/home/sag"}
export SUIF_SUM_HOME=${SUIF_SUM_HOME:-"/app/sag/sum"}
export SUIF_LOCAL_SCRIPTS_HOME=${SUIF_LOCAL_SCRIPTS_HOME:-"/mnt/scripts"}
export SUIF_AUDIT_BASE_DIR=${SUIF_AUDIT_BASE_DIR:-"/app/audit"}

export SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY=${SUIF_PRODUCT_IMAGES_OUTPUT_DIRECTORY:-"/tmp/images/products"}
export SUIF_FIX_IMAGES_OUTPUT_DIRECTORY=${SUIF_FIX_IMAGES_OUTPUT_DIRECTORY:-"/tmp/images/fixes"}
#export SUIF_FIXES_DATE_TAG=${SUIF_FIXES_DATE_TAG:-"latest"}

export SUIF_EMPOWER_USER=${SUIF_EMPOWER_USER:-"Must provide a valid empower user here!"}
export SUIF_EMPOWER_PASSWORD=${SUIF_EMPOWER_PASSWORD:-"Must provide a valid empower user password here!"}

export SUIF_PLATFORM_STRING=${SUIF_PLATFORM_STRING:-"LNXAMD64"}

env | grep SUIF | grep -v PASSWORD | sort