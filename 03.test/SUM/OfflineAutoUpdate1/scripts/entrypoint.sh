#!/bin/sh

if [ ! -d ${SUIF_HOME} ]; then
    echo "SUIF_HOME variable MUST point to an existing local folder! Current value is ${SUIF_HOME}"
    exit 1
fi

# Source framework functions
. "${SUIF_HOME}/01.scripts/commonFunctions.sh" || exit 2
. "${SUIF_HOME}/01.scripts/installation/setupFunctions.sh" || exit 3

bootstrapSum "${SUIF_PATCH_SUM_BOOSTSTRAP_BIN}" "${SUIF_OLDER_SUM_FIX_IMAGE}" "${SUIF_SUM_HOME}"

patchSum "${SUIF_NEWER_SUM_FIX_IMAGE}" "${SUIF_SUM_HOME}"
 