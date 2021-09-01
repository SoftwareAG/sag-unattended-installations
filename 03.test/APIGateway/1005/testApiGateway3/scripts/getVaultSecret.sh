#!/bin/sh
# --------------------------------------------------------
# Utility for getting secret value from a Key Vault
# Parameters:
#  1. KeyVault Name (name of Azure Key Vault)
#  2. Secret Name (secret key name)
#
# --------------------------------------------------------
LOC_KEYVAULT_NAME=$1
LOC_SECRET_NAME=$2

TOKEN=`curl -s "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net" -H Metadata:true | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])"`
SECRET=`curl -s -X GET -H "Authorization: Bearer ${TOKEN}" "https://${LOC_KEYVAULT_NAME}.vault.azure.net/secrets/${LOC_SECRET_NAME}/?api-version=7.2" | python3 -c "import sys, json; print(json.load(sys.stdin)['value'])"`

echo ${SECRET}