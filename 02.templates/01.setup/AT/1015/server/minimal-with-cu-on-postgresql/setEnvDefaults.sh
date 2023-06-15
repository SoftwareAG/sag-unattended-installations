#!/bin/sh

if ! command -V "urlencode" 2>/dev/null | grep function >/dev/null; then
  echo "sourcing commonFunctions.sh again (lost?)"
  if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
    echo "[checkPrerequisites.sh] - Panic, framework issue!"
    exit 151
  fi
  # shellcheck source=SCRIPTDIR/../../../../../01.scripts/commonFunctions.sh
  . "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh"
fi

########### Section 1 - the caller MUST provide

# Licenses
SUIF_WMSCRIPT_integrationServerLicenseFiletext=$(urlencode "${SUIF_SETUP_TEMPLATE_IS_LICENSE_FILE}")
export SUIF_WMSCRIPT_integrationServerLicenseFiletext

SUIF_WMSCRIPT_MFTLicenseFile=$(urlencode "${SUIF_SETUP_TEMPLATE_MFTSERVER_LICENSE_FILE}")
export SUIF_WMSCRIPT_MFTLicenseFile

# Integration server "Internal" DB connection
export SUIF_WMSCRIPT_IntegrationServerDBPassName="${SUIF_WMSCRIPT_IntegrationServerDBPassName:-isDbPass}"
export SUIF_WMSCRIPT_IntegrationServerDBUserName="${SUIF_WMSCRIPT_IntegrationServerDBUserName:-isDbUser}"
export SUIF_WMSCRIPT_IntegrationServerPoolName="${SUIF_WMSCRIPT_IntegrationServerPoolName:-isDbConnPool}"
export SUIF_WMSCRIPT_IS_JDBC_CONN_STRING="${SUIF_WMSCRIPT_IS_JDBC_CONN_STRING:-jdbc:wm:postgresql://postgres-server-is:5432;databaseName=isDbName}"
SUIF_WMSCRIPT_IntegrationServerDBURLName=$(urlencode "${SUIF_WMSCRIPT_IS_JDBC_CONN_STRING}")
export SUIF_WMSCRIPT_IntegrationServerDBURLName

# Active Transfer DB connection
export SUIF_WMSCRIPT_ActiveServerPasswordName="${SUIF_WMSCRIPT_ActiveServerPasswordName:-atsDbPass}"
export SUIF_WMSCRIPT_ActiveServerPoolName="${SUIF_WMSCRIPT_ActiveServerPoolName:-atsDbConnPool}"
export SUIF_WMSCRIPT_ActiveServerUserName="${SUIF_WMSCRIPT_ActiveServerUserName:-atsDbUser}"
export SUIF_WMSCRIPT_ATS_JDBC_CONN_STRING="${SUIF_WMSCRIPT_ATS_JDBC_CONN_STRING:-jdbc:wm:postgresql://postgres-server-ats:5432;databaseName=atsDbName}"
SUIF_WMSCRIPT_ActiveServerUrlName=$(urlencode "${SUIF_WMSCRIPT_ATS_JDBC_CONN_STRING}")
export SUIF_WMSCRIPT_ActiveServerUrlName

# Central Directory Services Connection
export SUIF_WMSCRIPT_CDSConnectionName="${SUIF_WMSCRIPT_CDSConnectionName:-cdsConnection}"
export SUIF_WMSCRIPT_CDSPasswordName="${SUIF_WMSCRIPT_CDSPasswordName:-cdsPassword}"
export SUIF_WMSCRIPT_CDSUserName="${SUIF_WMSCRIPT_CDSUserName:-cdsUser}"
export SUIF_WMSCRIPT_CDS_JDBC_CONN_STRING="${SUIF_WMSCRIPT_CDS_JDBC_CONN_STRING:-jdbc:wm:postgresql://postgres-server-cds:5432;databaseName=cdsDbName}"
SUIF_WMSCRIPT_CDSUrlName=$(urlencode "${SUIF_WMSCRIPT_CDS_JDBC_CONN_STRING}")
export SUIF_WMSCRIPT_CDSUrlName=
########### Section 1 END - the caller MUST provide

########### Section 2 - the caller MAY provide
## Framework - Install
export SUIF_INSTALL_INSTALL_DIR="${SUIF_INSTALL_INSTALL_DIR:-/opt/sag/products}"
export SUIF_INSTALL_DECLARED_HOSTNAME="${SUIF_INSTALL_DECLARED_HOSTNAME:-localhost}"
## Framework - Patch
export SUIF_SUM_HOME="${SUIF_SUM_HOME:-/opt/sag/sum}"

# Integration Server Administrator password
export SUIF_WMSCRIPT_adminPassword="${SUIF_WMSCRIPT_adminPassword:-Manage01}"

# Integration Server Ports
export SUIF_WMSCRIPT_IntegrationServerdiagnosticPort="${SUIF_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}"
export SUIF_WMSCRIPT_IntegrationServerPort="${SUIF_WMSCRIPT_IntegrationServerPort:-5555}"
export SUIF_WMSCRIPT_IntegrationServersecurePort="${SUIF_WMSCRIPT_IntegrationServersecurePort:-5543}"

# SPM Ports
export SUIF_WMSCRIPT_SPMHttpPort="${SUIF_WMSCRIPT_SPMHttpPort:-8092}"
export SUIF_WMSCRIPT_SPMHttpsPort="${SUIF_WMSCRIPT_SPMHttpsPort:-8093}"

# Active Transfer Port
export SUIF_WMSCRIPT_mftGWPortField="${SUIF_WMSCRIPT_mftGWPortField:-8500}"
########### Section 2 END - the caller MAY provide

logI "Template environment sourced successfully"
logEnv4Debug
