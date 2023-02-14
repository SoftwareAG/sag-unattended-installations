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
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_SUM_BOOTSTRAP_BIN' -az_target_path_handle 'SUIF_PATCH_SUM_BOOTSTRAP_BIN' $LastExitCode}"
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

:: SUIF scripts - 01.scripts
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFiles -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_SUIF' -az_source_handle '../../../..' -az_include_pattern '01.scripts/**' -az_ver_dir_handle 'SUIF_LOCAL_SCRIPTS_HOME' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload files ... exiting
    goto end
)
:: SUIF scripts - 02.templates
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFiles -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_SUIF' -az_source_handle '../../../..' -az_include_pattern '02.templates/**' -az_ver_dir_handle 'SUIF_LOCAL_SCRIPTS_HOME' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload files ... exiting
    goto end
)
:: SUIF scripts - 03.test (scripts only)
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFiles -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_SUIF' -az_source_handle '../../../..' -az_include_pattern '03.test/**/scripts/**' -az_ver_dir_handle 'SUIF_LOCAL_SCRIPTS_HOME' $LastExitCode}"
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
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; addFileToKeyVault -az_name_handle 'SUIF_AZ_TES_LICENSE_SECRET_NAME' -az_file_handle 'H_SAG_BM_LICENSE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create secret in Key Vault ... exiting
    goto end
)
:: APIGW
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; addFileToKeyVault -az_name_handle 'SUIF_AZ_YAI_LICENSE_SECRET_NAME' -az_file_handle 'H_SAG_APIGW_LICENSE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create secret in Key Vault ... exiting
    goto end
)

:: ------------------------------
:: Provision VM 01 
:: ------------------------------
:: APIGW 01
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; provisionVMforBastion -az_vm_name 'APIGW_01' -az_host_name 'apigw01' -az_image_handle 'H_AZ_VM_IMAGE' -az_size_handle 'H_AZ_VM_SIZE' -az_job_wait false $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)
:: APIGW 02
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; provisionVMforBastion -az_vm_name 'APIGW_02' -az_host_name 'apigw02' -az_image_handle 'H_AZ_VM_IMAGE' -az_size_handle 'H_AZ_VM_SIZE'  -az_job_wait false $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)
:: APIGW 03
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; provisionVMforBastion -az_vm_name 'APIGW_03' -az_host_name 'apigw03' -az_image_handle 'H_AZ_VM_IMAGE' -az_size_handle 'H_AZ_VM_SIZE' -az_job_wait false $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)
:: Admin
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; provisionVMforBastion -az_vm_name 'APIGW_ADMIN' -az_host_name 'admin' -az_image_handle 'SUIF_AZ_VM_ADMIN_IMAGE' -az_size_handle 'SUIF_AZ_VM_ADMIN_SIZE' -az_job_wait true $LastExitCode}"
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

:: ------------------------------
:: Set up Load Balancer config
:: ------------------------------
:: Create Load Balancer
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createLoadBalancer $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create Load Balancer ... exiting
    goto end
)
:: Create Health Probes
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createLoadBalancerProbe -az_vm_be_probe 'PROBE_9072' -az_vm_be_port 9072 $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create Load Balancer Probe ... exiting
    goto end
)
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createLoadBalancerProbe -az_vm_be_probe 'PROBE_9073' -az_vm_be_port 9073 $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create Load Balancer Probe ... exiting
    goto end
)
:: Add VM Addresses to Backend Pool
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; addBackEndToAddressPool -az_vm_name 'APIGW_01' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to add IP to backend pool ... exiting
    goto end
)
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; addBackEndToAddressPool -az_vm_name 'APIGW_02' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to add IP to backend pool ... exiting
    goto end
)
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; addBackEndToAddressPool -az_vm_name 'APIGW_03' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to add IP to backend pool ... exiting
    goto end
)

:: Create Rule for HTTP (port 80 -> 9072)
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createLoadBalancerRule -az_vm_rule_name 'LB_RULE_HTTP' -az_vm_fe_port 80 -az_vm_be_port 9072 -az_vm_be_probe 'PROBE_9072' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to add IP to backend pool ... exiting
    goto end
)
:: Create Rule for HTTPS (port 443 -> 9073)
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createLoadBalancerRule -az_vm_rule_name 'LB_RULE_HTTPS' -az_vm_fe_port 443 -az_vm_be_port 9073 -az_vm_be_probe 'PROBE_9073' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to add IP to backend pool ... exiting
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
echo -----------------------------------------------------
echo --                 testApiGateway3 
echo -- Provisioning completed. Use Azure Portal to access
echo -- APIGW_ADMIN server to access individual cluster
echo -- nodes user interfaces (via Bastion RDP).
echo --  a) http://apigw01:9072 or https://apigw01:9073
echo --  b) http://apigw02:9072 or https://apigw02:9073
echo --  c) http://apigw03:9072 or https://apigw03:9073
echo -- 
echo -- Load Balancer front end addresses: 
echo --  a) http://10.0.1.100:80    (APIGW HTTP)
echo --  b) https://10.0.1.100:443  (APIGW HTTPS)
echo -- 
echo -----------------------------------------------------
:end
:: ------------------------------
:: Exit
:: ------------------------------




