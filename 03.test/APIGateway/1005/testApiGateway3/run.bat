@echo off
:: ----------------------------------------------------------------------------------
:: Windows batch run-script to prepare, setup and provision an Azure VM runtime.
::
:: - This batch file controls the execution steps only.
:: - Each step is associated with a corresponding Powershell script function.
:: - Environment variables used are derived from .env and scripts/suif.env
::
:: ----------------------------------------------------------------------------------

:: ------------------------------
:: Log on to Azure interactively
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; loginAzure $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Azure Login not successful ... exiting
    goto end
)

:: ===================================================================================================
:: Prepare Shared Volumes
:: ===================================================================================================
:: ----------------------------------
:: Create Storage Volume for Assets
:: ----------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createVolume('SUIF_AZ_VOLUME_ASSETS') $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Unable to create the Assets Storage Volume ... exiting
    goto end
)

:: ------------------------------
:: Create Assets Directories
:: ------------------------------
:: Root /assets directory
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createDirectory -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS' $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Unable to create Directory ... exiting
    goto end
)
:: /assets/media directory
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createDirectory -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_MEDIA' $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Unable to create Directory ... exiting
    goto end
)
:: /assets/suif scripts directory
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createDirectory -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_SUIF' $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Unable to create Directory ... exiting
    goto end
)

:: ---------------------------------
:: Upload Files to Azure fs volume
:: ---------------------------------
:: Product Installer
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_INSTALLER_BIN' -az_target_path_handle 'SUIF_INSTALL_INSTALLER_BIN' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload file ... exiting
    goto end
)
:: Product Image - TSA
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_PRODUCTS_TSA_IMAGE_FILE' -az_target_path_handle 'SUIF_INSTALL_TSA_IMAGE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload file ... exiting
    goto end
)
:: Product Image - APIGW
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_PRODUCTS_APIGW_IMAGE_FILE' -az_target_path_handle 'SUIF_INSTALL_APIGW_IMAGE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload file ... exiting
    goto end
)
:: SUM installer
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_SUM_BOOTSTRAP_BIN' -az_target_path_handle 'SUIF_PATCH_SUM_BOOSTSTRAP_BIN' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload file ... exiting
    goto end
)
:: Fix Image - TSA
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_FIXES_TSA_IMAGE_FILE' -az_target_path_handle 'SUIF_PATCH_TSA_FIXES_IMAGE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload file ... exiting
    goto end
)
:: Fix Image - APIGW
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_FIXES_APIGW_IMAGE_FILE' -az_target_path_handle 'SUIF_PATCH_APIGW_FIXES_IMAGE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload file ... exiting
    goto end
)

:: SUIF scripts
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFiles -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_SUIF' -az_source_handle '../../../..' -az_include_pattern '0*/**' -az_ver_dir_handle 'SUIF_LOCAL_SCRIPTS_HOME' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload files ... exiting
    goto end
)

:: ===================================================================================================
:: Provision on Azure 
:: ===================================================================================================
:: ------------------------------
:: Create Resource Group
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createResourceGroup $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create resource group ... exiting
    goto end
)

:: ------------------------------
:: Create Application Security Group
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createASG $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)

:: ------------------------------
:: Create Network Security Group
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createNSG $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)

:: ------------------------------
:: Create NSG Rules
:: ------------------------------
:: AllowHttpsInbound
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createNSGRule -az_nsg_rule 'AllowHttpsInbound' -az_nsg_direction 'Inbound' -az_nsg_priority 120 -az_nsg_dest_prefix '*' -az_nsg_dest_port 443 -az_nsg_source_prefix 'Internet' -az_nsg_protocol 'Tcp' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create NSG rule ... exiting
    goto end
)
:: AllowGatewayManagerInbound
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createNSGRule -az_nsg_rule 'AllowGatewayManagerInbound' -az_nsg_direction 'Inbound' -az_nsg_priority 130 -az_nsg_dest_prefix '*' -az_nsg_dest_port 443 -az_nsg_source_prefix 'GatewayManager' -az_nsg_protocol 'Tcp' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create NSG rule ... exiting
    goto end
)

:: AllowAzureLoadBalancerInbound
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createNSGRule -az_nsg_rule 'AllowAzureLoadBalancerInbound' -az_nsg_direction 'Inbound' -az_nsg_priority 140 -az_nsg_dest_prefix '*' -az_nsg_dest_port 443 -az_nsg_source_prefix 'AzureLoadBalancer' -az_nsg_protocol 'Tcp' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create NSG rule ... exiting
    goto end
)

:: AllowBastionHostCommunication
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createNSGRule -az_nsg_rule 'AllowBastionHostCommunication1' -az_nsg_direction 'Inbound' -az_nsg_priority 150 -az_nsg_dest_prefix 'VirtualNetwork' -az_nsg_dest_port 8080 -az_nsg_source_prefix 'VirtualNetwork' -az_nsg_protocol 'Tcp' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create NSG rule ... exiting
    goto end
)
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createNSGRule -az_nsg_rule 'AllowBastionHostCommunication2' -az_nsg_direction 'Inbound' -az_nsg_priority 151 -az_nsg_dest_prefix 'VirtualNetwork' -az_nsg_dest_port 5701 -az_nsg_source_prefix 'VirtualNetwork' -az_nsg_protocol 'Tcp' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create NSG rule ... exiting
    goto end
)

:: AllowSshRdpOutbound
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createNSGRule -az_nsg_rule 'AllowSshRdpOutbound1' -az_nsg_direction 'Outbound' -az_nsg_priority 100 -az_nsg_dest_prefix 'VirtualNetwork' -az_nsg_dest_port 22 -az_nsg_source_prefix '*' -az_nsg_protocol '*' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create NSG rule ... exiting
    goto end
)
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createNSGRule -az_nsg_rule 'AllowSshRdpOutbound2' -az_nsg_direction 'Outbound' -az_nsg_priority 101 -az_nsg_dest_prefix 'VirtualNetwork' -az_nsg_dest_port 3389 -az_nsg_source_prefix '*' -az_nsg_protocol '*' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create NSG rule ... exiting
    goto end
)

:: AllowAzureCloudOutbound
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createNSGRule -az_nsg_rule 'AllowAzureCloudOutbound' -az_nsg_direction 'Outbound' -az_nsg_priority 110 -az_nsg_dest_prefix 'AzureCloud' -az_nsg_dest_port 443 -az_nsg_source_prefix '*' -az_nsg_protocol 'Tcp' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create NSG rule ... exiting
    goto end
)

:: AllowBastionCommunication
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createNSGRule -az_nsg_rule 'AllowBastionCommunication1' -az_nsg_direction 'Outbound' -az_nsg_priority 120 -az_nsg_dest_prefix 'VirtualNetwork' -az_nsg_dest_port 8080 -az_nsg_source_prefix 'VirtualNetwork' -az_nsg_protocol '*' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create NSG rule ... exiting
    goto end
)
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createNSGRule -az_nsg_rule 'AllowBastionCommunication2' -az_nsg_direction 'Outbound' -az_nsg_priority 121 -az_nsg_dest_prefix 'VirtualNetwork' -az_nsg_dest_port 5701 -az_nsg_source_prefix 'VirtualNetwork' -az_nsg_protocol '*' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create NSG rule ... exiting
    goto end
)

:: AllowGetSessionInformation
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createNSGRule -az_nsg_rule 'AllowGetSessionInformation' -az_nsg_direction 'Outbound' -az_nsg_priority 130 -az_nsg_dest_prefix 'Internet' -az_nsg_dest_port 80 -az_nsg_source_prefix '*' -az_nsg_protocol '*' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create NSG rule ... exiting
    goto end
)

:: ------------------------------
:: Create Virtual Network 
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createBastionVNET -az_address_prefix '10.0.0.0/16' $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Unable to create Virtual Network ... exiting
    goto end
)

:: ------------------------------
:: Create Public IP
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createPublicIP -az_allocation 'Static' -az_sku 'Standard' -az_zone 1 $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create public IP ... exiting
    goto end
)

:: ------------------------------
:: Create Bastion host service
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createBastionHostService $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create Bastion Host Service ... exiting
    goto end
)

:: ------------------------------
:: Create VM Subnet for APIGWs
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createSubnet -az_address_prefix '10.0.1.0/24' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)

:: ------------------------------
:: Create Key Vault
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createKeyVault $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create Key Vault ... exiting
    goto end
)

:: ------------------------------
:: Add License File to Key Vault
:: ------------------------------
:: TSA
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; addFileToKeyVault -az_name_handle 'SUIF_AZ_TES_LICENSE_VAULT_NAME' -az_file_handle 'H_SAG_TC_LICENSE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create secret in Key Vault ... exiting
    goto end
)
:: APIGW
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; addFileToKeyVault -az_name_handle 'SUIF_AZ_YAI_LICENSE_VAULT_NAME' -az_file_handle 'H_API_GW_LICENSE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create secret in Key Vault ... exiting
    goto end
)

:: ------------------------------
:: Provision VM 01 
:: ------------------------------
:: APIGW 01
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; provisionVMforBastion -az_vm_name 'APIGW_01' -az_host_name 'apigw01' -az_image_handle 'H_AZ_VM_IMAGE' -az_size_handle 'H_AZ_VM_SIZE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)
:: APIGW 02
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; provisionVMforBastion -az_vm_name 'APIGW_02' -az_host_name 'apigw02' -az_image_handle 'H_AZ_VM_IMAGE' -az_size_handle 'H_AZ_VM_SIZE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)
:: APIGW 03
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; provisionVMforBastion -az_vm_name 'APIGW_03' -az_host_name 'apigw03' -az_image_handle 'H_AZ_VM_IMAGE' -az_size_handle 'H_AZ_VM_SIZE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)
:: Admin
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; provisionVMforBastion -az_vm_name 'APIGW_ADMIN' -az_host_name 'admin' -az_image_handle 'SUIF_AZ_VM_ADMIN_IMAGE' -az_size_handle 'SUIF_AZ_VM_ADMIN_SIZE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)

:: ------------------------------
:: Grant Key Vault Access for VMs
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; grantKeyVaultPermission -az_vm_name 'APIGW_01' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to grant permission to Key Vault ... exiting
    goto end
)
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; grantKeyVaultPermission -az_vm_name 'APIGW_02' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to grant permission to Key Vault ... exiting
    goto end
)
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; grantKeyVaultPermission -az_vm_name 'APIGW_03' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to grant permission to Key Vault ... exiting
    goto end
)

:: --------------------------------------------------------------------------
:: Initialize the VM (mount shares, etc.) and start application entry script
:: --------------------------------------------------------------------------
:: APIGW 01
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; initializeVM -az_vm_name 'APIGW_01' -az_host_name 'apigw01' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to prepare the VM ... exiting
    goto end
)
:: APIGW 02
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; initializeVM -az_vm_name 'APIGW_02' -az_host_name 'apigw02' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to prepare the VM ... exiting
    goto end
)
:: APIGW 03
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; initializeVM -az_vm_name 'APIGW_03' -az_host_name 'apigw03' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to prepare the VM ... exiting
    goto end
)

:: ===============================================================================================
:: ------------------------------
:: Add Secret (refer to admin password and not stored on shared suif directories)
:: ------------------------------
:: powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; addSecretToKeyVault -az_name_handle '' -az_secret_handle '' $LastExitCode}"
:: if "%errorlevel%" NEQ "0" (
::     echo Unable to create secret in Key Vault ... exiting
::     goto end
:: )

:: ===============================================================================================

:end
:: ------------------------------
:: Exit
:: ------------------------------




