#!/usr/bin/python3
# --------------------------------------------------------
# Utility for getting secret value from a Key Vault
# Parameters:
#  1. KeyVault Name (name of Azure Key Vault)
#  2. Secret Name (secret key name)
#
# --------------------------------------------------------
import sys
from azure.keyvault.secrets import SecretClient
from azure.identity import ManagedIdentityCredential

keyvault_name = sys.argv[1]
secret_name = sys.argv[2]

KVUri = f"https://{keyvault_name}.vault.azure.net"

credential = ManagedIdentityCredential()
client = SecretClient(vault_url=KVUri, credential=credential)
retrieved_secret = client.get_secret(secret_name)

print(retrieved_secret.value)