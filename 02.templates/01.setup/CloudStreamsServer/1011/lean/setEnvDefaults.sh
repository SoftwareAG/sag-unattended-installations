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
if [ -z "${SUIF_SETUP_TEMPLATE_CSS_LICENSE_FILE+x}" ]; then
    logE "User must provide a valid license file in the SUIF_SETUP_TEMPLATE_CSS_LICENSE_FILE variable"
    exit 21
fi

if [ ! -f "${SUIF_SETUP_TEMPLATE_CSS_LICENSE_FILE}" ]; then
    logE "User must provide a valid CloudStreams Server license file, ${SUIF_SETUP_TEMPLATE_CSS_LICENSE_FILE} not found"
    exit 22
fi

# ------------------------------ Section 3 - the caller MAY provide

## MSR related
export SUIF_WMSCRIPT_adminPassword="${SUIF_WMSCRIPT_adminPassword:-manage}"
export SUIF_WMSCRIPT_IntegrationServerPort="${SUIF_WMSCRIPT_IntegrationServerPort:-5555}"
export SUIF_WMSCRIPT_IntegrationServersecurePort="${SUIF_WMSCRIPT_IntegrationServersecurePort:-5553}"
export SUIF_WMSCRIPT_IntegrationServerdiagnosticPort="${SUIF_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}"

# ------------------------------ Section 4 - Computed values

SUIF_WMSCRIPT_integrationServerLicenseFiletext=$(urlencode "${SUIF_SETUP_TEMPLATE_CSS_LICENSE_FILE}")
export SUIF_WMSCRIPT_integrationServerLicenseFiletext

# ------------------------------ Section 5 - Constants

export SUIF_CURRENT_SETUP_TEMPLATE_PATH="CloudStreamServer/1011/lean"

logI "Template environment sourced successfully"
logEnv4Debug
