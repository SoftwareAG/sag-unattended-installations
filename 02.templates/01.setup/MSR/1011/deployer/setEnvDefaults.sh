#!/bin/sh

# Section 0 - Framework Import
if [ ! "`type -t urlencode`X" == "functionX" ]; then
    if [ ! -f "${SUIF_CACHE_HOME}/installationScripts/commonFunctions.sh" ]; then
        echo "Panic, common functions not sourced and not present locally! Cannot continue"
        exit 500
    fi
    . "$SUIF_CACHE_HOME/installationScripts/commonFunctions.sh"
fi

# Section 1 - the caller MUST provide

if [[ "x${SUIF_INSTALL_TIME_ADMIN_PASSWORD}" == "x" ]]; then
    logE "User must provide an admin installation password (variable SUIF_INSTALL_TIME_ADMIN_PASSWORD), this template does not accept default passwords"
    exit 1
fi

export SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE=${SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE:-"/provide/path/to/IS-license.xml"}

if [ ! -f ${SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE} ]; then
    logE "User must provide a valid MSR license file"
    exit 2
fi

# Section 2 - the caller MAY provide

## MSR related
export SUIF_INSTALL_MSR_MAIN_HTTP_PORT=${SUIF_INSTALL_MSR_MAIN_HTTP_PORT:-"5555"}
export SUIF_INSTALL_MSR_MAIN_HTTPS_PORT=${SUIF_INSTALL_MSR_MAIN_HTTPS_PORT:-"5553"}
export SUIF_INSTALL_MSR_DIAGS_HTTP_PORT=${SUIF_INSTALL_MSR_DIAGS_HTTP_PORT:-"9999"}
## Framework - Install
export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export SUIF_INSTALL_SPM_HTTPS_PORT=${SUIF_INSTALL_SPM_HTTPS_PORT:-"8093"}
export SUIF_INSTALL_SPM_HTTP_PORT=${SUIF_INSTALL_SPM_HTTP_PORT:-"8092"}
export SUIF_INSTALL_DECLARED_HOSTNAME=${SUIF_INSTALL_DECLARED_HOSTNAME:-"localhost"}
# Section 3 - Computed values

export SUIF_SETUP_TEMPLATE_MSR_LICENSE_UrlEncoded=$(urlencode ${SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE})

# Section 4 - Constants

export SUIF_CURRENT_SETUP_TEMPLATE_PATH="MSR/1011/deployer"

logI "Template environment sourced successfully"
logEnv4Debug
