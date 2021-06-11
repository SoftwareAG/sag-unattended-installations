@echo off

:: ------------------------------
:: Run script to....
:: 
:: TODO: 
::  - Ignore .git files/dirs in upload - no support but "file globbing" 
::  - Ability to refresh file/directory if changes made (e.g. remove and upload)
::  - Store sensitive assets in vault
:: ------------------------------

:: ------------------------------
:: Log on to Azure interactively
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; loginAzure $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Azure Login not successful ... exiting
    goto end
)

:: ------------------------------
:: Create Storage Volumes
:: ------------------------------
:: powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createVolume('AZ_VOLUME_APPLICATION') $LastExitCode}" 
:: if "%errorlevel%" NEQ "0" (
::     echo Unable to create the Application Storage Volume ... exiting
::     goto end
:: )
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createVolume('SUIF_AZ_VOLUME_ASSETS') $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Unable to create the Assets Storage Volume ... exiting
    goto end
)

:: ------------------------------
:: Create Assets Directories
:: ------------------------------
:: Root /assets directory
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createDirectory -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_AZ_DIR_ASSETS' $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Unable to create Directory ... exiting
    goto end
)
:: /assets/media directory
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createDirectory -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_AZ_DIR_ASSETS_MEDIA' $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Unable to create Directory ... exiting
    goto end
)
:: /assets/licenses directory
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createDirectory -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_AZ_DIR_ASSETS_LICENCES' $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Unable to create Directory ... exiting
    goto end
)
:: /assets/suif scripts directory
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; createDirectory -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_AZ_DIR_ASSETS_SUIF' $LastExitCode}" 
if "%errorlevel%" NEQ "0" (
    echo Unable to create Directory ... exiting
    goto end
)

:: ------------------------------
:: Upload Files to Azure fs
:: ------------------------------
:: License key
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_AZ_DIR_ASSETS_LICENCES' -az_local_file_handle 'H_SAG_TC_LICENSE_FILE' -az_target_path_handle 'SUIF_SETUP_TEMPLATE_TES_LICENSE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload file ... exiting
    goto end
)
:: Product Installer
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_AZ_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_INSTALLER_BIN' -az_target_path_handle 'SUIF_INSTALL_INSTALLER_BIN' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload file ... exiting
    goto end
)
:: Product Image
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_AZ_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_PRODUCTS_IMAGE_FILE' -az_target_path_handle 'SUIF_INSTALL_IMAGE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload file ... exiting
    goto end
)
:: SUM installer
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_AZ_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_SUM_BOOTSTRAP_BIN' -az_target_path_handle 'SUIF_PATCH_SUM_BOOSTSTRAP_BIN' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload file ... exiting
    goto end
)
:: Fix Image
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFile -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_AZ_DIR_ASSETS_MEDIA' -az_local_file_handle 'H_SAG_FIXES_IMAGE_FILE' -az_target_path_handle 'SUIF_PATCH_FIXES_IMAGE_FILE' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload file ... exiting
    goto end
)
:: SUIF scripts
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; uploadFiles -az_volume_handle 'SUIF_AZ_VOLUME_ASSETS' -az_dir_handle 'SUIF_AZ_DIR_ASSETS_SUIF' -az_source_handle '../../../..' -az_ver_dir_handle 'SUIF_LOCAL_SCRIPTS_HOME' $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo Unable to upload files ... exiting
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
:: Run entryPoint script
:: ------------------------------
powershell.exe -NonInteractive -ExecutionPolicy Unrestricted -Command "& {. '.\scripts\suif_ps_functions.ps1'; entryPointVM $LastExitCode}"
if "%errorlevel%" NEQ "0" (
    echo entryPoint.sh script failed ... exiting
    goto end
)

:: ------------------------------
:: Store secrets/sensitive assets in Vault
:: ------------------------------

:: ------------------------------
:: Open non-SSH Ports (?)
:: ------------------------------

:: ------------------------------
:: Separate script for decomissioning
:: ------------------------------

:end
:: ------------------------------
:: Exit
:: ------------------------------




