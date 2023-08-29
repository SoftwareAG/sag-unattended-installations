#!/bin/sh

# Section 0 - Framework Import

# Check if commons have been sourced, we need urlencode() for the license
if ! command -V "urlencode" 2>/dev/null | grep function >/dev/null; then 
  echo "sourcing commonFunctions.sh ..."
  if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
    echo "Panic, framework issue! File ${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh does not exist. SUIF_CACHE_HOME=${SUIF_CACHE_HOME}"
    exit 151
  fi

  # shellcheck source=SCRIPTDIR/../../../../../01.scripts/commonFunctions.sh
  . "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh"
fi

# Section 1 - the caller MUST provide
export SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE="${SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE:-/provide/path/to/IS-license.xml}"

if [ ! -f "${SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE}" ]; then
  logE "User must provide a valid MSR license file, declared in the variable SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE"
  exit 202
fi

# Section 2 - the caller MAY provide
export SUIF_INSTALL_TIME_ADMIN_PASSWORD="${SUIF_INSTALL_TIME_ADMIN_PASSWORD:-manage}"

## MSR related
export SUIF_INSTALL_MSR_MAIN_HTTP_PORT="${SUIF_INSTALL_MSR_MAIN_HTTP_PORT:-5555}"
export SUIF_INSTALL_MSR_MAIN_HTTPS_PORT="${SUIF_INSTALL_MSR_MAIN_HTTPS_PORT:-5553}"
export SUIF_INSTALL_MSR_DIAGS_HTTP_PORT="${SUIF_INSTALL_MSR_DIAGS_HTTP_PORT:-9999}"

# Section 3 - Computed values

SUIF_SETUP_TEMPLATE_MSR_LICENSE_UrlEncoded=$(urlencode "${SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE}")
export SUIF_SETUP_TEMPLATE_MSR_LICENSE_UrlEncoded

# Section 4 - Constants

export SUIF_CURRENT_SETUP_TEMPLATE_PATH="MSR/1015/lean"

logI "Template environment sourced successfully"
logEnv4Debug
