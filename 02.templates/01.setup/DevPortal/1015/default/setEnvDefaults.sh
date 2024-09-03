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
if [ ! -f "${SUIF_SETUP_TEMPLATE_DPO_LICENSE_FILE}" ]; then
  logE "User must provide a valid Developer Portal license file, declared in the variable SUIF_SETUP_TEMPLATE_DPO_LICENSE_FILE"
  exit 202
fi

# Section 2 - the caller MAY provide
export SUIF_INSTALL_TIME_ADMIN_PASSWORD="${SUIF_INSTALL_TIME_ADMIN_PASSWORD:-manage}"

## DPO related
export SUIF_WMSCRIPT_CELHTTPPort=${SUIF_WMSCRIPT_CELHTTPPort:-9240}
export SUIF_WMSCRIPT_CELTCPPort=${SUIF_WMSCRIPT_CELTCPPort:-9340}
export SUIF_WMSCRIPT_DPO_HTTP_Port=${SUIF_WMSCRIPT_DPO_HTTP_Port:-18101}
export SUIF_WMSCRIPT_DPO_HTTPS_Port=${SUIF_WMSCRIPT_DPO_HTTPS_Port:-18102}

# Section 3 - Computed values

SUIF_SETUP_TEMPLATE_DPO_LICENSE_UrlEncoded=$(urlencode "${SUIF_SETUP_TEMPLATE_DPO_LICENSE_FILE}")
export SUIF_SETUP_TEMPLATE_DPO_LICENSE_UrlEncoded

# Section 4 - Constants

export SUIF_CURRENT_SETUP_TEMPLATE_PATH="DevPortal/1015/default"

logI "Template environment sourced successfully"
logEnv4Debug
