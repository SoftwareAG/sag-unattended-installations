#!/bin/sh

# Section 0 - Validations

# Check if commons have been sourced, we need urlencode() for the license
if ! command -V "urlencode" 2>/dev/null | grep function >/dev/null; then 
    echo "sourcing commonFunctions.sh ..."
    if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue! File ${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh does not exist. SUIF_CACHE_HOME=${SUIF_CACHE_HOME}"
        exit 151
    fi
    . "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh"
fi

# Check if install commons have been sourced, we need checkSetupTemplateBasicPrerequisites()
if ! command -V "checkSetupTemplateBasicPrerequisites" 2>/dev/null | grep function >/dev/null; then 
    echo "sourcing setupFunctions.sh ..."
    huntForSuifFile "01.scripts/installation" "setupFunctions.sh"
    if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/installation/setupFunctions.sh" ]; then
        echo "Panic, framework issue! File ${SUIF_CACHE_HOME}/01.scripts/installation/setupFunctions.sh does not exist. SUIF_CACHE_HOME=${SUIF_CACHE_HOME}"
        exit 152
    fi
    . "${SUIF_CACHE_HOME}/01.scripts/installation/setupFunctions.sh"
fi


# ------------------------------ Section 1 - check what the caller MUST provide, Framework related

checkSetupTemplateBasicPrerequisites || exit $?

# ------------------------------ Section 2 - check what the caller MUST provide, related to this specific template
if [ -z "${SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE+x}" ]; then
    logE "User must provide a valid license file in the SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE variable"
    exit 21
fi

if [ ! -f "${SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE}" ]; then
    logE "User must provide a valid license file in the SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE variable. Provided file ${SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE} not found!"
    exit 22
fi

# ------------------------------ Section 3 - the caller MAY provide ( framework commons )

export SUIF_INSTALL_DECLARED_HOSTNAME="${SUIF_INSTALL_DECLARED_HOSTNAME:-localhost}"
export SUIF_INSTALL_INSTALL_DIR="${SUIF_INSTALL_INSTALL_DIR:-/opt/sag/products}"
export SUIF_INSTALL_SPM_HTTP_PORT="${SUIF_INSTALL_SPM_HTTP_PORT:-9082}"
export SUIF_INSTALL_SPM_HTTPS_PORT="${SUIF_INSTALL_SPM_HTTPS_PORT:-9083}"

# ------------------------------ Section 4 - the caller MAY provide ( specific )

export SUIF_WMSCRIPT_CELHTTPPort="${SUIF_WMSCRIPT_CELHTTPPort:-9240}"
export SUIF_WMSCRIPT_CELTCPPort="${SUIF_WMSCRIPT_CELTCPPort:-9340}"
export SUIF_WMSCRIPT_IntegrationServerdiagnosticPort="${SUIF_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}"
export SUIF_WMSCRIPT_IntegrationServerPort="${SUIF_WMSCRIPT_IntegrationServerPort:-5555}"
export SUIF_WMSCRIPT_IntegrationServersecurePort="${SUIF_WMSCRIPT_IntegrationServersecurePort:-5553}"
export SUIF_WMSCRIPT_YAIHttpPort="${SUIF_WMSCRIPT_YAIHttpPort:-9072}"
export SUIF_WMSCRIPT_YAIHttpsPort="${SUIF_WMSCRIPT_YAIHttpsPort:-9073}"

# ------------------------------ Section 5 - Computed values

SUIF_WMSCRIPT_integrationServerLicenseFiletext=$(urlencode "${SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE}")
export SUIF_WMSCRIPT_integrationServerLicenseFiletext

# ------------------------------ Section 6 - Constants

export SUIF_CURRENT_SETUP_TEMPLATE_PATH="APIGateway/1007/default"

logI "Template environment sourced successfully"
logEnv4Debug
