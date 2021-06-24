# API GAteway test 3
- Based on API Gateway test 2 - a standalone APIGW installation version 10.5 provisioned on Azure
- This is a three-way cluster with a dedicated subnet without public IP access (accessed via Bastion)
- These scripts are developed for a local Windows machine (using MS batch and Powershell scripts)

## Prerequisites

- Full clone of the current repository
- The following Software AG assets (cannot be downloaded publicly)
  - installer binary for linux 64 bit
  - product image containing BigMemory 4.3 (packaged with webmethods version 10.5 and associated fixes)
  - license for API Gateway server (Advanced version)

- Azure CLI client - download via Azure Portal
- MS Azure account and subscription
- An Azure Resource Group with an existing Storage resource. This is used to upload and share with the runtime VM

## Decsription

When running the run.bat file, the following will happen:

1. Prompt for an interactive Azure Portal login via browser
2. Based on the provided storage resource provided in .env, an Azure file share volume will be created (if it doesn't exist)
3. On the volume, the local suif scripts will be uploaded, along with all SAG artefacts (installers, images, etc.)
4. A separate, ephemeral, resource group will be created for all subsequent resources created.
5. A new VM will be provisioned, in line with the size properties and type of VM image provided in .env
6. The VM will then be "prepared" by mounting the above storage file share
7. The uploaded (to the file share and mounted on the VM) suif script entrypoint.sh will be execute on the VM
8. The script will install the SAG component listed above for this project (it not already installed)
9. Fixes will be applied and the component will start up


## Quickstart

All prerequisite files and Azure information are in mentioned in the file .env_example.

1. Procure prerequisite Software AG files (installers, images, license file)
2. Copy .env_example into .env
3. Modify .env to identify where local SAG components are located
4. Modify .env to identify Azure related properties (refer to prerequisites above)
5. Execute run.bat
6. Open a browser to [APIGW] http://<azure_ip>:9072, alt https://<azure_ip>:9073
7. When finished testing, remove the complete resource group in Azure Portal.

Notes:
8. You should observe Administrator password has been changed to pwd define in suif.env and LB are set appropriately
9. You should observe the fact extended settings were altered as per the provided json configuration.
