#!/bin/sh

# Section 0 - Framework Import
if [ ! "`type -t urlencode`X" == "functionX" ]; then
    if [ ! -f "${SUIF_CACHE_HOME}/installationScripts/commonFunctions.sh" ]; then
        echo "Panic, common functions not sourced and not present locally! Cannot continue"
        exit 100
    fi
    . "$SUIF_CACHE_HOME/installationScripts/commonFunctions.sh"
fi

# Section 1 - the caller MUST provide

if [ -z ${SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE+x} ]; then
    logE "User must provide a valid MSR license file in the environment variable SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE"
    exit 1
fi

if [ ! -f "${SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE}" ]; then
    logE "User must provide a valid MSR license file, the declared file ${SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE} does not exist!"
    exit 2
fi

if [ -z ${SUIF_SETUP_TEMPLATE_BRMS_LICENSE_FILE+x} ]; then
    logE "User must provide a valid Business Rules license file in the environment variable SUIF_SETUP_TEMPLATE_BRMS_LICENSE_FILE"
    exit 3
fi

if [ ! -f "${SUIF_SETUP_TEMPLATE_BRMS_LICENSE_FILE}" ]; then
    logE "User must provide a valid Business Rules license file, the declared file ${SUIF_SETUP_TEMPLATE_BRMS_LICENSE_FILE} does not exist!"
    exit 4
fi

# Section 2 - the caller MAY provide

export SUIF_INSTALL_TIME_ADMIN_PASSWORD="${SUIF_INSTALL_TIME_ADMIN_PASSWORD:-manage}"

export SUIF_INSTALL_DECLARED_HOSTNAME="${SUIF_INSTALL_DECLARED_HOSTNAME:-localhost}"
## MSR related
export SUIF_INSTALL_MSR_MAIN_HTTP_PORT="${SUIF_INSTALL_MSR_MAIN_HTTP_PORT:-5555}"
export SUIF_INSTALL_MSR_MAIN_HTTPS_PORT="${SUIF_INSTALL_MSR_MAIN_HTTPS_PORT:-5553}"
export SUIF_INSTALL_MSR_DIAGS_HTTP_PORT="${SUIF_INSTALL_MSR_DIAGS_HTTP_PORT:-9999}"

# Section 3 - Computed values

SUIF_SETUP_TEMPLATE_MSR_LICENSE_UrlEncoded=$(urlencode "${SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE}")
export SUIF_SETUP_TEMPLATE_MSR_LICENSE_UrlEncoded
SUIF_SETUP_TEMPLATE_BRMS_LICENSE_UrlEncoded=$(urlencode "${SUIF_SETUP_TEMPLATE_BRMS_LICENSE_FILE}")
export SUIF_SETUP_TEMPLATE_BRMS_LICENSE_UrlEncoded

# Section 4 - Constants

export SUIF_CURRENT_SETUP_TEMPLATE_PATH="MSR/1015/BrSapJdbc"
logI "Template environment sourced successfully"
logEnv4Debug
