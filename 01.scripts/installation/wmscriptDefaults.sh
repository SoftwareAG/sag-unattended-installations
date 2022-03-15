#!/bin/sh

## File containing frequently used variables

## Example: export SUIF_WMSCRIPT_Key=${SUIF_WMSCRIPT_Key:-defaultValueHere}

## Default Installation Directory
export SUIF_WMSCRIPT_InstallDir=${SUIF_WMSCRIPT_InstallDir:-/opt/suif/sag/products}

## Install time admin password
adminPassword=${SUIF_WMSCRIPT_adminPassword:-manage01}
## Install Time declared hostname
HostName=${SUIF_WMSCRIPT_HostName:-localhost}

## SPM Ports
export SUIF_WMSCRIPT_SPMHttpPort=${SUIF_WMSCRIPT_SPMHttpPort:-}8092
export SUIF_WMSCRIPT_SPMHttpsPort=${SUIF_WMSCRIPT_SPMHttpsPort:-}8093

## IS Ports
export SUIF_WMSCRIPT_IntegrationServersecurePort=${SUIF_WMSCRIPT_IntegrationServersecurePort:-5543}
export SUIF_WMSCRIPT_IntegrationServerdiagnosticPort=${SUIF_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}
export SUIF_WMSCRIPT_IntegrationServerPort=${SUIF_WMSCRIPT_IntegrationServerPort:-5555}

