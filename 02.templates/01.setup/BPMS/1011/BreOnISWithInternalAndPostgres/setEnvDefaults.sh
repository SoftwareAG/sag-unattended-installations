#!/bin/sh

## Installation Directory
export SUIF_WMSCRIPT_InstallDir=${SUIF_WMSCRIPT_InstallDir:-/app/sag/version/products}

## Default install time password
export SUIF_WMSCRIPT_adminPassword=${SUIF_WMSCRIPT_adminPassword:-manage1}

## SPM
export SUIF_WMSCRIPT_SPMHttpPort=${SUIF_WMSCRIPT_SPMHttpPort:-8092}
export SUIF_WMSCRIPT_SPMHttpsPort=${SUIF_WMSCRIPT_SPMHttpsPort:-8093}

## IS Ports
export SUIF_WMSCRIPT_IntegrationServersecurePort=${SUIF_WMSCRIPT_IntegrationServersecurePort:-5543}
export SUIF_WMSCRIPT_IntegrationServerdiagnosticPort=${SUIF_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}
export SUIF_WMSCRIPT_IntegrationServerPort=${SUIF_WMSCRIPT_IntegrationServerPort:-5555}

## BPM / TE DB, wired on Postgres
export SUIF_WMSCRIPT_TaskEngineRuntimeConnectionName=${SUIF_WMSCRIPT_TaskEngineRuntimeConnectionName:-postgresConnectionNameHere}
# jdbc:wm:postgresql://s-db:5432;DatabaseName=dbNameHere
export SUIF_WMSCRIPT_TaskEngineDatabaseUrl=${SUIF_WMSCRIPT_TaskEngineDatabaseUrl:-'jdbc:wm:postgresql://s-db:5432;DatabaseName=dbNameHere'}
export SUIF_WMSCRIPT_TaskEngineRuntimeUrlName=$(urlencode ${SUIF_WMSCRIPT_TaskEngineDatabaseUrl})
export SUIF_WMSCRIPT_TaskEngineRuntimeUserName=${SUIF_WMSCRIPT_TaskEngineRuntimeUserName:-db-user-name-here}
export SUIF_WMSCRIPT_TaskEngineRuntimePasswordName=${SUIF_WMSCRIPT_TaskEngineRuntimePasswordName:-db-pass-here}

## License files
# /tmp/BusinessRules_1011.xml
export SUIF_WMSCRIPT_BRMS_license_file=${SUIF_WMSCRIPT_BRMS_license_file:-/tmp/BusinessRules_1011.xml}
export SUIF_WMSCRIPT_BRMS_license=$(urlencode ${SUIF_WMSCRIPT_BRMS_license_file})
# /tmp/MicroservicesRuntime_100.xml
export SUIF_WMSCRIPT_IS_LICENSE_FILE=${SUIF_WMSCRIPT_IS_LICENSE_FILE:-/tmp/MicroservicesRuntime_100.xml}
export SUIF_WMSCRIPT_integrationServer_LicenseFile_text=$(urlencode ${SUIF_WMSCRIPT_IS_LICENSE_FILE})
