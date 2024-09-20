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

# Section 2 - the caller MAY provide

export SUIF_INSTALL_TIME_ADMIN_PASSWORD="${SUIF_INSTALL_TIME_ADMIN_PASSWORD:-manage}"

# Section 2 - the caller MAY provide
## Broker related
SUIF_SETUP_BROKER_DATA_DIR=${SUIF_SETUP_BROKER_DATA_DIR:-/opt/softwareag/data/brokerServer01}

SUIF_WMSCRIPT_BrokerMonPort=${SUIF_WMSCRIPT_BrokerMonPort:-6850}
export SUIF_WMSCRIPT_BrokerMonPort

## Section 3 - Post processing
## eventually provided values are overwritten!
SUIF_WMSCRIPT_BROKER_DATA_DIR_UrlEncoded=$(urlencode "${SUIF_SETUP_BROKER_DATA_DIR}")
export SUIF_WMSCRIPT_BROKER_DATA_DIR_UrlEncoded

# Section 4 - Constants

export SUIF_CURRENT_SETUP_TEMPLATE_PATH="Broker/1015/default"

logI "Template environment sourced successfully"
logEnv4Debug
