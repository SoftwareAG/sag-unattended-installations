#!/bin/sh

# shellcheck source-path=SCRIPTDIR/../../../../..

# shellcheck disable=SC3043

if ! command -V "logI" 2>/dev/null | grep function >/dev/null; then 
    echo "sourcing commonFunctions.sh again (lost?)"
    if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
        echo "Panic, framework issue!"
        exit 151
    fi
    . "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh"
fi

logI "Checking prerequisites for Elasticsearch installation..."

checkVmMaxMapCount(){
    ## constants 
    local c1=262144 # p1 -> vm.max_map_count

    # shellcheck disable=SC2046
    local p1
    p1=$(sysctl "vm.max_map_count" | cut -d " " -f 3)
    # shellcheck disable=SC2086
    if [ ! $p1 -lt $c1 ]; then
        logI "vm.max_map_count is adequate ($p1)"
    else
        logE "vm.max_map_count is NOT adequate ($p1)"
        return 1
    fi
}

checkVmMaxMapCount || exit 1 
