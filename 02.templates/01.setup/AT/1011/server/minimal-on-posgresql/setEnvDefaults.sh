#!/bin/sh

if [ ! "`type -t urlencode`X" == "functionX" ]; then
    if [ ! -f "${SUIF_CACHE_HOME}/installationScripts/commonFunctions.sh" ]; then
        echo "Panic, common functions not sourced and not present locally! Cannot continue"
        exit 500
    fi
    . "$SUIF_CACHE_HOME/installationScripts/commonFunctions.sh"
fi

# Section 1 - the caller MUST provide
## Framework - Install
export SUIF_INSTALL_INSTALLER_BIN=${SUIF_INSTALL_INSTALLER_BIN:-"/path/to/installer.bin"}
export SUIF_INSTALL_IMAGE_FILE=${SUIF_INSTALL_IMAGE_FILE:-"/path/to/install/product.image.zip"}

## Framework - Patch
export SUIF_PATCH_SUM_BOOSTSTRAP_BIN=${SUIF_PATCH_SUM_BOOSTSTRAP_BIN:-"/path/to/sum-boostrap.bin"}
export SUIF_PATCH_FIXES_IMAGE_FILE=${SUIF_PATCH_FIXES_IMAGE_FILE:-"/path/to/install/fixes.image.zip"}

## Current Template

# Section 2 - the caller MAY provide
## Framework - Install
export SUIF_INSTALL_INSTALL_DIR=${SUIF_INSTALL_INSTALL_DIR:-"/opt/sag/products"}
export SUIF_INSTALL_DECLARED_HOSTNAME=${SUIF_INSTALL_DECLARED_HOSTNAME:-"localhost"}
## Framework - Patch
export SUIF_SUM_HOME=${SUIF_SUM_HOME:-"/opt/sag/sum"}



export SUIF_WMSCRIPT_ActiveServerPasswordName=${SUIF_WMSCRIPT_ActiveServerPasswordName:-'atsDbPass'}
export SUIF_WMSCRIPT_ActiveServerPoolName=${SUIF_WMSCRIPT_ActiveServerPoolName:-'atsDbConnPool'}
export SUIF_WMSCRIPT_ActiveServerUserName=${SUIF_WMSCRIPT_ActiveServerUserName:-'atsDbUser'}
export SUIF_WMSCRIPT_adminPassword=${SUIF_WMSCRIPT_adminPassword:-'manage01'}
export SUIF_WMSCRIPT_IntegrationServerDBPassName=${SUIF_WMSCRIPT_IntegrationServerDBPassName:-'isDbPass'}
export SUIF_WMSCRIPT_IntegrationServerDBUserName=${SUIF_WMSCRIPT_IntegrationServerDBUserName:-'isDbUser'}
export SUIF_WMSCRIPT_IntegrationServerdiagnosticPort=${SUIF_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}
export SUIF_WMSCRIPT_IntegrationServerPoolName=${SUIF_WMSCRIPT_IntegrationServerPoolName:-'isDbConnPool'}
export SUIF_WMSCRIPT_IntegrationServerPort=${SUIF_WMSCRIPT_IntegrationServerPort:-5555}
export SUIF_WMSCRIPT_IntegrationServersecurePort=${SUIF_WMSCRIPT_IntegrationServersecurePort:-5543}
export SUIF_WMSCRIPT_mftGWPortField=${SUIF_WMSCRIPT_mftGWPortField:-8500}
export SUIF_WMSCRIPT_SPMHttpPort=${SUIF_WMSCRIPT_SPMHttpPort:-8092}
export SUIF_WMSCRIPT_SPMHttpsPort=${SUIF_WMSCRIPT_SPMHttpsPort:-8093}
export SUIF_WMSCRIPT_CDSConnectionName=${SUIF_WMSCRIPT_CDSConnectionName:-'cdsConnection'}
export SUIF_WMSCRIPT_CDSPasswordName=${SUIF_WMSCRIPT_CDSPasswordName:-'cdsPassword'}
export SUIF_WMSCRIPT_CDSUserName=${SUIF_WMSCRIPT_CDSUserName:-'cdsUser'}


export SUIF_WMSCRIPT_integrationServerLicenseFiletext=${SUIF_WMSCRIPT_integrationServerLicenseFiletext:-}

# JDBC URLS
SUIF_IS_JDBC_CONN_STRING=${SUIF_IS_JDBC_CONN_STRING:-'jdbc:wm:postgresql://postgres-server-is:5432;databaseName=isDbName'}
export SUIF_WMSCRIPT_IntegrationServerDBURLName=$(urlencode ${SUIF_IS_JDBC_CONN_STRING})
SUIF_CDS_JDBC_CONN_STRING=${SUIF_CDS_JDBC_CONN_STRING:-'jdbc:wm:postgresql://postgres-server-cds:5432;databaseName=cdsDbName'}
export SUIF_WMSCRIPT_CDSUrlName=$(urlencode ${SUIF_CDS_JDBC_CONN_STRING})
SUIF_ATS_JDBC_CONN_STRING=${SUIF_ATS_JDBC_CONN_STRING:-'jdbc:wm:postgresql://postgres-server-ats:5432;databaseName=atsDbName'}
export SUIF_WMSCRIPT_ActiveServerUrlName=$(urlencode ${SUIF_ATS_JDBC_CONN_STRING})


# Licenses
SUIF_SETUP_TEMPLATE_IS_LICENSE_FILE=${SUIF_SETUP_TEMPLATE_IS_LICENSE_FILE:-'No Is License File Provided'}
export SUIF_WMSCRIPT_integrationServerLicenseFiletext=$(urlencode ${SUIF_SETUP_TEMPLATE_IS_LICENSE_FILE})

SUIF_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE=${SUIF_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE:-'No Active Transfer License File Provided'}
export SUIF_WMSCRIPT_MFTLicenseFile=$(urlencode ${SUIF_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE})

logI "Template environment sourced successfully"
logEnv4Debug
