#!/bin/sh

if [ ! "`type -t logI`X" == "functionX" ]; then
    echo "sourcing commonFunctions.sh again (lost?)"
    if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue!"
        exit 500
    fi
    . "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh"
fi