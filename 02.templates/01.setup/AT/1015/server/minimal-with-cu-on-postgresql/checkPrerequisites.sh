#!/bin/sh

if ! command -V "logE" 2>/dev/null | grep function >/dev/null; then
  echo "sourcing commonFunctions.sh again (lost?)"
  if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
    echo "[checkPrerequisites.sh] - Panic, framework issue!"
    exit 151
  fi
  # shellcheck source=SCRIPTDIR/../../../../../01.scripts/commonFunctions.sh
  . "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh"
fi

# No checks for now
errCount=0
logPrefix="02.templates/01.setup/AT/1015/minimal-with-cu-on-postgresql/checkPrerequisites.sh"

if [ ! -f "$SUIF_SETUP_TEMPLATE_IS_LICENSE_FILE" ]; then
  logE "$logPrefix -- SUIF_SETUP_TEMPLATE_IS_LICENSE_FILE = $SUIF_SETUP_TEMPLATE_IS_LICENSE_FILE does not exist!"
  errCount=$((errCount + 1))
fi

if [ ! -f "$SUIF_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE" ]; then
  logE "$logPrefix -- SUIF_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE = $SUIF_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE does not exist!"
  errCount=$((errCount + 1))
fi

if [ $errCount -ne 0 ]; then
  logE "$logPrefix -- $errCount errors found. Exitting with code 254"
  exit 254
fi
