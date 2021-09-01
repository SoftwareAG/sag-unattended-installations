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
:: Product Image
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_PRODUCTS_IMAGE_FILE' -az_target_path_handle 'SUIF_INSTALL_IMAGE_FILE' $LastExitCode}"
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
:: Fix Image
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_FIXES_IMAGE_FILE' -az_target_path_handle 'SUIF_PATCH_FIXES_IMAGE_FILE' $LastExitCode}"
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

:: ------------------------------
:: Create Resource Group
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createResourceGroup $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create resource group ... exiting
    goto end
)

:: ------------------------------
:: Provision a VM
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; provisionVM $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)

:: ------------------------------
:: Prepare the VM (mount shares, etc.)
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; prepareVM $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)

:: ------------------------------
:: Upload License key
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFileToVM -suif_source_handle 'H_SAG_TC_LICENSE_FILE' -suif_target_handle 'SUIF_SETUP_TEMPLATE_TES_LICENSE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision the VM ... exiting
    goto end
)

:: ------------------------------
:: Create Inbound FW rules
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createInboundFWRule -az_nsg_rule_name 'SUIF_BM_TMS_HTTPS' -az_nsg_rule_prio 1500 -az_nsg_port 9443 $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create inbound security rule ... exiting
    goto end
)
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createInboundFWRule -az_nsg_rule_name 'SUIF_BM_TMS_HTTP' -az_nsg_rule_prio 1501 -az_nsg_port 9889 $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create inbound security rule ... exiting
    goto end
)

:: ------------------------------
:: Run entryPoint script
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; entryPointVM $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo entryPoint.sh script failed ... exiting
    goto end
)

:end
:: ------------------------------
:: Exit
:: ------------------------------




