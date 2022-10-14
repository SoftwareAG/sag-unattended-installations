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

# ------------------------------ Section 3 - the caller MAY provide ( framework commons )
export SUIF_INSTALL_DECLARED_HOSTNAME="${SUIF_INSTALL_DECLARED_HOSTNAME:-localhost}"
export SUIF_INSTALL_INSTALL_DIR="${SUIF_INSTALL_INSTALL_DIR:-/opt/sag/products}"
export SUIF_INSTALL_SPM_HTTP_PORT="${SUIF_INSTALL_SPM_HTTP_PORT:-9082}"
export SUIF_INSTALL_SPM_HTTPS_PORT="${SUIF_INSTALL_SPM_HTTPS_PORT:-9083}"

# ------------------------------ Section 4 - the caller MAY provide ( specific )

export SUIF_WMSCRIPT_adminPassword="${SUIF_WMSCRIPT_adminPassword:-manage}"
export SUIF_WMSCRIPT_CELHTTPPort="${SUIF_WMSCRIPT_CELHTTPPort:-9240}"
export SUIF_WMSCRIPT_CELTCPPort="${SUIF_WMSCRIPT_CELTCPPort:-9340}"

# ------------------------------ Section 5 - Computed values

# ------------------------------ Section 6 - Constants

export SUIF_CURRENT_SETUP_TEMPLATE_PATH="APIGateway/1011/DSOnly"

logI "Template environment sourced successfully"
logEnv4Debug
