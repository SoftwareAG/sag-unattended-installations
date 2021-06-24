# API GAteway test 3
- Based on API Gateway test 2 - a standalone APIGW installation version 10.5 provisioned on Azure
- This is now a three-way cluster with a dedicated subnet without public IP access (accessed via Bastion)
- These scripts are developed for a local Windows machine (using MS batch and Powershell scripts) with target Linux VMs

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
4. A separate (ephemeral) resource group will be created for all subsequent resources created.

In above resource group, the following will be provisioned:
5. An application and network security group
6. A Virtual Network
7. A Bastion host service with a public IP
8. A subnet for the below APIGW cluster
9. Three API Gateway nodes, and a separate administration VM for accessing the cluster
10. Each VM will then be "prepared" by mounting the above storage file share
11. The uploaded (to the file share and mounted on the VM) suif script entrypoint.sh will be execute on the VM
12. The script will install the SAG component listed above for this project (it not already installed)
13. Fixes will be applied and the components will start up


## Quickstart

All prerequisite files and Azure information are in mentioned in the file .env_example.

1. Procure prerequisite Software AG files (installers, images, license file)
2. Copy .env_example into .env
3. Modify .env to identify where local SAG components are located
4. Modify .env to identify Azure related properties (refer to prerequisites above)
5. Execute run.bat

For browser access to the APIGW cluster:
6. After initialization completed, log on to Azure Portal and access the newly create resource group APIGW_RG 
7. Access the Resource "APIGW_ADMIN", which is the central administration host (Windows).
8. Connect to the Admin VM by using Bastion connect via RDP. Use username/passwords as per suif.env
9. Open an Edge browser and enter in to [APIGW] http://apigw01:9072, alt https://apigw01:9073 (or apigw02/apigw03)

Notes:
10. You should observe Administrator password has been changed to pwd define in suif.env and LB are set appropriately
11. You should observe the fact extended settings were altered as per the provided json configuration.

12. When finished testing, remove the complete resource group in Azure Portal.

