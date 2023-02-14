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
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; azLogin $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Azure Login not successful ... exiting
    goto end
)

:: ===================================================================================================
:: Prepare Shared Volumes
:: ===================================================================================================
:: ----------------------------------
:: Create FileShare Storage for Assets
:: ----------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; deployFileShare $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision ARM template for storage ... exiting
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
:: Provision Infrastructure on Azure 
:: ===================================================================================================
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; deployEnvironment $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to provision ARM template ... exiting
    goto end
)

:: --------------------------------------------------------------------------
:: Workaround: upload license file content to KayVault secrets
:: --------------------------------------------------------------------------
:: TSA
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; addFileToDeployedKeyVault -az_name_handle 'SUIF_AZ_TES_LICENSE_SECRET_NAME' -az_file_handle 'H_SAG_BM_LICENSE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create secret in Key Vault ... exiting
    goto end
)

:: APIGW
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; addFileToDeployedKeyVault -az_name_handle 'SUIF_AZ_YAI_LICENSE_SECRET_NAME' -az_file_handle 'H_SAG_APIGW_LICENSE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to create secret in Key Vault ... exiting
    goto end
)

:: --------------------------------------------------------------------------
:: Initialize the VM (mount shares, etc.) and start application entry script
:: --------------------------------------------------------------------------
for %%x in (apigw01 apigw02 apigw03) do (
    powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; runInitVM -az_vm_name %%x $LastExitCode}"
    if "%errorlevel%" NEQ "0" (
        echo Unable to prepare the VM ... exiting
        goto end
    )
)


:: ===============================================================================================
echo -----------------------------------------------------
echo --                 testApiGateway4
echo -- Provisioning completed. Use Azure Portal to access
echo -- APIGW_ADMIN server to access individual cluster
echo -- nodes user interfaces (via Bastion RDP).
echo --  a) http://apigw01:9072 or https://apigw01:9073
echo --  b) http://apigw02:9072 or https://apigw02:9073
echo --  c) http://apigw03:9072 or https://apigw03:9073
echo -- 
echo -- Load Balancer front end addresses: 
echo --  a) http://10.1.0.100:80    (APIGW HTTP)
echo --  b) https://10.1.0.100:443  (APIGW HTTPS)
echo -- 
echo -----------------------------------------------------
:end
:: ------------------------------
:: Exit
:: ------------------------------