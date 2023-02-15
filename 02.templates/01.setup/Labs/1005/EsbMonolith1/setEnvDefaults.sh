#!/bin/sh

# Section 0 - Framework Import

if ! commonFunctionsSourced 2>/dev/null; then
	if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/commonFunctions.sh" ]; then
		echo "Panic, common functions not sourced and not present locally! Cannot continue"
		exit 254
	fi
	# shellcheck source=/dev/null
	. "$SUIF_CACHE_HOME/01.scripts/commonFunctions.sh"
fi

if ! setupFunctionsSourced 2>/dev/null; then
	if [ ! -f "${SUIF_CACHE_HOME}/01.scripts/installation/setupFunctions.sh" ]; then
		echo "Panic, setup functions not sourced and not present locally! Cannot continue"
		exit 253
	fi
	# shellcheck source=/dev/null
	. "$SUIF_CACHE_HOME/01.scripts/installation/setupFunctions.sh"
fi

checkSetupTemplateBasicPrerequisites || exit $?

# Section 1 - the caller MUST provide License files

#NUMRealmServer.LicenseFile.text=__VERSION1__,${SUIF_WMSCRIPT_NUMRealmServer_LicenseFile_text_UrlEncoded}
#PrestoLicenseChooser=__VERSION1__,${SUIF_WMSCRIPT_PrestoLicenseChooser_UrlEncoded}

if [ -z "${SUIF_WMSCRIPT_BRMS_LICENSE_FILE+x}" ]; then
	logE "User must provide a variable called SUIF_WMSCRIPT_BRMS_LICENSE_FILE pointing to a valid Business Rules Engine license file local path"
	exit 21
fi
if [ ! -f "${SUIF_WMSCRIPT_BRMS_LICENSE_FILE}" ]; then
	logE "SUIF_WMSCRIPT_BRMS_LICENSE_FILE points to inexistent file ${SUIF_WMSCRIPT_BRMS_LICENSE_FILE}"
	exit 22
fi

if [ -z "${SUIF_WMSCRIPT_integrationServer_LicenseFile+x}" ]; then
	logE "User must provide a variable called SUIF_WMSCRIPT_integrationServer_LicenseFile pointing to a valid IS/MSR license file local path"
	exit 23
fi
if [ ! -f "${SUIF_WMSCRIPT_integrationServer_LicenseFile}" ]; then
	logE "SUIF_WMSCRIPT_integrationServer_LicenseFile points to inexistent file ${SUIF_WMSCRIPT_integrationServer_LicenseFile}"
	exit 24
fi

if [ -z "${SUIF_WMSCRIPT_NUMRealmServer_LicenseFile+x}" ]; then
	logE "User must provide a variable called SUIF_WMSCRIPT_NUMRealmServer_LicenseFile pointing to a valid Universal Messaging license file local path"
	exit 25
fi
if [ ! -f "${SUIF_WMSCRIPT_NUMRealmServer_LicenseFile}" ]; then
	logE "SUIF_WMSCRIPT_NUMRealmServer_LicenseFile points to inexistent file ${SUIF_WMSCRIPT_NUMRealmServer_LicenseFile}"
	exit 26
fi

if [ -z "${SUIF_WMSCRIPT_PrestoLicenseChooser_LICENSE_FILE+x}" ]; then
	logE "User must provide a variable called SUIF_WMSCRIPT_PrestoLicenseChooser_LICENSE_FILE pointing to a valid Presto license file local path"
	exit 27
fi
if [ ! -f "${SUIF_WMSCRIPT_PrestoLicenseChooser_LICENSE_FILE}" ]; then
	logE "SUIF_WMSCRIPT_PrestoLicenseChooser_LICENSE_FILE points to inexistent file ${SUIF_WMSCRIPT_PrestoLicenseChooser_LICENSE_FILE}"
	exit 28
fi

SUIF_WMSCRIPT_BRMS_LICENSE_UrlEncoded=$(urlencode "${SUIF_WMSCRIPT_BRMS_LICENSE_FILE}")
export SUIF_WMSCRIPT_BRMS_LICENSE_UrlEncoded
SUIF_WMSCRIPT_integrationServer_LicenseFile_text_UrlEncoded=$(urlencode "${SUIF_WMSCRIPT_integrationServer_LicenseFile}")
export SUIF_WMSCRIPT_integrationServer_LicenseFile_text_UrlEncoded
SUIF_WMSCRIPT_NUMRealmServer_LicenseFile_text_UrlEncoded=$(urlencode "${SUIF_WMSCRIPT_NUMRealmServer_LicenseFile}")
export SUIF_WMSCRIPT_NUMRealmServer_LicenseFile_text_UrlEncoded
SUIF_WMSCRIPT_PrestoLicenseChooser_UrlEncoded=$(urlencode "${SUIF_WMSCRIPT_PrestoLicenseChooser_LICENSE_FILE}")
export SUIF_WMSCRIPT_PrestoLicenseChooser_UrlEncoded

# Section 2 - the caller SHOULD provide database coordinates for IS Core DB
# If not passed, the jdbc pool is initialized with default values and would most probably not work

export SUIF_WMSCRIPT_IntegrationServerDBUser_Name="${SUIF_WMSCRIPT_IntegrationServerDBUser_Name:-webm}"
export SUIF_WMSCRIPT_IntegrationServerDBPass_Name="${SUIF_WMSCRIPT_IntegrationServerDBPass_Name:-webm}"
export SUIF_WMSCRIPT_IntegrationServerPool_Name="${SUIF_WMSCRIPT_IntegrationServerPool_Name:-iscore}"

# composite SUIF_WMSCRIPT_IntegrationServerDBURL_Name_UrlEncoded
# e.g. jdbc:wm:oracle://​<server>:<1521|port>;​serviceName=<value>[;<option>=<value>...]
DB_SERVER_FQDN=${SUIF_SETUP_ISCORE_DB_SERVER_FQDN:-oracle-db-server}
DB_SERVER_PORT=${SUIF_SETUP_ISCORE_DB_SERVER_PORT:-1521}
DB_SERVICE_NAME=${SUIF_SETUP_ISCORE_DB_SERVICE_NAME:-oradbservicename}
DB_CONN_EXTRA_PARAMS=${SUIF_SETUP_ISCORE_DB_CONN_EXTRA_PARAMS:-}

SUIF_WMSCRIPT_IntegrationServerDBURL_Name_UrlEncoded=\
$(urlencode \
"jdbc:wm:oracle://${DB_SERVER_FQDN}:${DB_SERVER_PORT};serviceName=${DB_SERVICE_NAME}${DB_CONN_EXTRA_PARAMS}")
export SUIF_WMSCRIPT_IntegrationServerDBURL_Name_UrlEncoded

# Section 3 - the caller SHOULD provide database coordinates for Central Users DB
# If not passed, the jdbc pool is initialized with default values and would most probably not work

export SUIF_WMSCRIPT_mwsDBUserField="${SUIF_WMSCRIPT_mwsDBUserField:-webm}"
export SUIF_WMSCRIPT_mwsDBPwdField="${SUIF_WMSCRIPT_mwsDBPwdField:-webm}"
export SUIF_WMSCRIPT_mwsNameField="${SUIF_WMSCRIPT_mwsNameField:-mws}"

# composite SUIF_WMSCRIPT_mwsDBURLField_UrlEncoded
# e.g. jdbc:wm:oracle://​<server>:<1521|port>;​serviceName=<value>[;<option>=<value>...]
DB_SERVER_FQDN=${SUIF_SETUP_MWS_DB_SERVER_FQDN:-oracle-db-server}
DB_SERVER_PORT=${SUIF_SETUP_MWS_DB_SERVER_PORT:-1521}
DB_SERVICE_NAME=${SUIF_SETUP_MWS_DB_SERVICE_NAME:-oradbservicename}
DB_CONN_EXTRA_PARAMS=${SUIF_SETUP_MWS_DB_CONN_EXTRA_PARAMS:-}

SUIF_WMSCRIPT_mwsDBURLField_UrlEncoded=\
$(urlencode \
"jdbc:wm:oracle://${DB_SERVER_FQDN}:${DB_SERVER_PORT};serviceName=${DB_SERVICE_NAME}${DB_CONN_EXTRA_PARAMS}")
export SUIF_WMSCRIPT_mwsDBURLField_UrlEncoded

# Section 4 - the caller MAY provide UM Realm Parameters
export SUIF_WMSCRIPT_NUM_Realm_Server_Name_ID="${SUIF_WMSCRIPT_NUM_Realm_Server_Name_ID:-umserver}"
SUIF_WMSCRIPT_NUM_Data_Dir_ID=\
"${SUIF_WMSCRIPT_NUM_Data_Dir_ID:-${SUIF_INSTALL_INSTALL_DIR}/UniversalMessaging/server/umserver}"
SUIF_WMSCRIPT_NUM_Data_Dir_ID_UrlEncoded=$(urlencode \ "${SUIF_WMSCRIPT_NUM_Data_Dir_ID}")
export SUIF_WMSCRIPT_NUM_Data_Dir_ID_UrlEncoded

# Section 5 - the caller MAY provide PORTS

## IS/MSR related
export SUIF_WMSCRIPT_IntegrationServerPort="${SUIF_WMSCRIPT_IntegrationServerPort:-5555}"
export SUIF_WMSCRIPT_IntegrationServerdiagnosticPort="${SUIF_WMSCRIPT_IntegrationServerdiagnosticPort:-9999}"
export SUIF_WMSCRIPT_mwsPortField="${SUIF_WMSCRIPT_mwsPortField:-8585}"
export SUIF_WMSCRIPT_NUM_Interface_Port_ID="${SUIF_WMSCRIPT_NUM_Interface_Port_ID:-9000}"
export SUIF_WMSCRIPT_PrestoHTTPPort="${SUIF_WMSCRIPT_PrestoHTTPPort:-8080}"
export SUIF_WMSCRIPT_PrestoShutdownPort="${SUIF_WMSCRIPT_PrestoShutdownPort:-8005}"
export SUIF_WMSCRIPT_SPMHttpPort="${SUIF_WMSCRIPT_SPMHttpPort:-9082}"
export SUIF_WMSCRIPT_SPMHttpsPort="${SUIF_WMSCRIPT_SPMHttpsPort:-9083}"

# Section 6 - Constants

export SUIF_CURRENT_SETUP_TEMPLATE_PATH="Labs/1005/EsbMonolith1"

logI "Template environment sourced successfully"
logEnv4Debug
