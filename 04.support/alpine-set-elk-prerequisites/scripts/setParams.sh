#!/bin/sh

if [ $(id -u) -ne 0 ]; then
   echo "This script must be run as root" 
   exit 1
fi

setVmMaxMapCount(){
    ## constants 
    local c1=262144 # p1 -> vm.max_map_count
    echo "Setting host kernel parameters for Elasticsearch"

    local p1=$(sysctl "vm.max_map_count" | cut -d " " -f 3)
    if [ ! $p1 -lt $c1 ]; then
        echo "vm.max_map_count is adequate ($p1)"
    else
        echo "vm.max_map_count is NOT adequate ($p1), setting it to minimum required value of $c1"
        sysctl -w "vm.max_map_count=$c1" || return 2
        echo "vm.max_map_count set, checking effectiveness"
        local p2=$(sysctl "vm.max_map_count" | cut -d " " -f 3)
        if [ ! $p2 -lt $c1 ]; then
            echo "vm.max_map_count correctly set"
        else
            echo "vm.max_map_count was NOT set, cannot continue"
            return 3
        fi
    fi
}

setVmMaxMapCount || exit 2
