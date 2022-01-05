
## ---------------------------------------------------------------------
## Source the .env variables (always)
## ---------------------------------------------------------------------
# Host provided specific variables
Get-Content ".env" | foreach-object -begin {$suif_host_env=@{}} -process {
     $k = [regex]::split($_,'='); 
     if (($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True) -and ($k[0].StartsWith("#") -ne $True)) {
         $suif_host_env.Add($k[0], $k[1]) 
    } 
}
# SUIF project defined variables
Get-Content ".\scripts\suif.env" | foreach-object -begin {$suif_env=@{}} -process {
     $k = [regex]::split($_,'='); 
     if (($k[0].CompareTo("") -ne 0) -and ($k[0].StartsWith("[") -ne $True) -and ($k[0].StartsWith("#") -ne $True)) {
         $suif_env.Add($k[0], $k[1]) 
    } 
}

## ---------------------------------------------------------------------
## Source common powershell functions
## ---------------------------------------------------------------------
. "..\..\..\..\01.scripts\pwsh\azureFunctions.ps1"

## ---------------------------------------------------------------------
## Login to Azure (interactively via Browser) - if needed
## ---------------------------------------------------------------------
function azLogin() {
    Write-Host "-------------------------------------------------------"
    Write-Host " Login to Azure ...."
    Write-Host "-------------------------------------------------------"
    $az_cmd_response = az login 2>&1 | out-null
    exit 0
}

## ---------------------------------------------------------------------
## Run ARM bicep template for file share
## ---------------------------------------------------------------------
function deployFileShare() {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $H_AZ_RESOURCE_GROUP_STORAGE = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP_STORAGE')
    $H_AZ_STORAGE_ACCOUNT = $suif_host_env.Get_Item('H_AZ_STORAGE_ACCOUNT')
    $SUIF_AZ_VOLUME_ASSETS = $suif_env.Get_Item('SUIF_AZ_VOLUME_ASSETS')
    
    # ----------------------------------------------
    # Get unique identifier for deployments
    # ----------------------------------------------
    $IDENTIFIER = Get-Date -Format "yyyyMMdd-HH-mm"

    Write-Host "-------------------------------------------------------"
    Write-Host " Executing ARM Template for FileShare ..."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Deploy template
    # ----------------------------------------------
    Write-Host " - deployFileShare :: Creating a new fileshare ....."
    $az_cmd_response = az deployment group create --template-file './scripts/bicep/sharedFiles.bicep' `
      --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $H_AZ_RESOURCE_GROUP_STORAGE `
      --name deployFileShare-$IDENTIFIER `
      --parameters identifier=$IDENTIFIER `
        storageAccountName=$H_AZ_STORAGE_ACCOUNT `
        fileShareName=$SUIF_AZ_VOLUME_ASSETS

    if (!$?) {
        Write-Host " - deployFileShare :: Error - Unable to deploy template :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - deployFileShare :: ARM template successfully deployed."
    exit 0

}

## ---------------------------------------------------------------------
## Run ARM bicep template for provisioning 
## ---------------------------------------------------------------------
function deployEnvironment() {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_GEO_LOCATION = $suif_host_env.Get_Item('H_AZ_GEO_LOCATION')

    $LOC_AZ_VM_USER_PASSWORD = $suif_host_env.Get_Item('H_APIGW_ADMIN_PASSWORD')
    $H_AZ_VM_IMAGE = $suif_host_env.Get_Item('H_AZ_VM_IMAGE')
    $H_AZ_VM_SIZE = $suif_host_env.Get_Item('H_AZ_VM_SIZE')
    $SUIF_AZ_LOAD_BALANCER_IP = $suif_env.Get_Item('SUIF_AZ_LOAD_BALANCER_IP')

    # ----------------------------------------------
    # Get unique identifier for deployments
    # ----------------------------------------------
    $IDENTIFIER = Get-Date -Format "yyyyMMdd-HH-mm"

    # ----------------------------------------------
    # Get current principalId for user
    # ----------------------------------------------
    $az_user_id = az ad signed-in-user show --query objectId -o tsv

    # ----------------------------------------------
    # License secret names in KeyVault and content
    # ----------------------------------------------
    $SUIF_AZ_TES_LICENSE_SECRET_NAME = $suif_env.Get_Item('SUIF_AZ_TES_LICENSE_SECRET_NAME')
    $H_SAG_BM_LICENSE_FILE = $suif_host_env.Get_Item('H_SAG_BM_LICENSE_FILE')
    $LOC_SAG_BM_LICENSE_KEY = Get-Content $H_SAG_BM_LICENSE_FILE -Raw -Encoding UTF8

    $SUIF_AZ_YAI_LICENSE_SECRET_NAME = $suif_env.Get_Item('SUIF_AZ_YAI_LICENSE_SECRET_NAME')
    $H_SAG_APIGW_LICENSE_FILE = $suif_host_env.Get_Item('H_SAG_APIGW_LICENSE_FILE')
    $LOC_SAG_APIGW_LICENSE_KEY = Get-Content $H_SAG_APIGW_LICENSE_FILE -Raw -Encoding UTF8
    
    Write-Host "-------------------------------------------------------"
    Write-Host " Executing ARM Template for APIGW Infrastructure ..."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Deploy APIGW template
    # ----------------------------------------------
    Write-Host " - deployEnvironment :: Setting up Azure infrastructure ....."
    $az_cmd_response = az deployment sub create --template-file './scripts/bicep/infra.bicep' `
      --subscription $H_AZ_SUBSCRIPTION_ID `
      --location $H_AZ_GEO_LOCATION `
      --name deployEnvironment-$IDENTIFIER `
      --parameters identifier=$IDENTIFIER `
        azureUserId=$az_user_id `
        resourceGroupName=$SUIF_AZ_RESOURCE_GROUP `
        loadBalancerFrontEndAddress=$SUIF_AZ_LOAD_BALANCER_IP `
        userPass=$LOC_AZ_VM_USER_PASSWORD `
        vmImageIdentifier=$H_AZ_VM_IMAGE `
        vmImageSizeIdentifier=$H_AZ_VM_SIZE

        # secretNameBMLicense=$SUIF_AZ_TES_LICENSE_SECRET_NAME `
        # secretValueBMLicense=$LOC_SAG_BM_LICENSE_KEY `
        # secretNameAPIGWLicense=$SUIF_AZ_YAI_LICENSE_SECRET_NAME `
        # secretValueAPIGWLicense=$LOC_SAG_APIGW_LICENSE_KEY

    # $az_vm_deployment = az deployment group show -g 'RG-APIGW-TEST-04' -n <deployment-name> --query properties.outputs.resourceID.value
    # Write-Host " - deployARMTemplate :: $az_vm_deployment"

    if (!$?) {
        Write-Host " - deployEnvironment :: Error - Unable to deploy template :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - deployEnvironment :: ARM template successfully deployed."
    exit 0

}

## ---------------------------------------------------------------------
## Add File to Key Vault
## ---------------------------------------------------------------------
function addFileToDeployedKeyVault() {
    param (
        [string] $az_name_handle,
        [string] $az_file_handle
    )
    # ----------------------------------------------
    # Get variables from either .env or suif.env
    # ----------------------------------------------
    if ($az_name_handle.StartsWith('H_')) {
        $LOC_SECRET_NAME = $suif_host_env.Get_Item($az_name_handle)
    } else{
        $LOC_SECRET_NAME = $suif_env.Get_Item($az_name_handle)
    }
    if ($az_file_handle.StartsWith('H_')) {
        $LOC_SECRET = $suif_host_env.Get_Item($az_file_handle)
    } else{
        $LOC_SECRET = $suif_env.Get_Item($az_file_handle)
    }

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')


    Write-Host "-------------------------------------------------------"
    Write-Host " Applying Secret $LOC_SECRET_NAME to KeyVault ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Get deployed KeyVault name
    # ----------------------------------------------
    $SUIF_AZ_KEYVAULT_NAME = az deployment group list --subscription $H_AZ_SUBSCRIPTION_ID -g $SUIF_AZ_RESOURCE_GROUP --query [].properties.parameters.keyVaultName.value -o tsv
    if (!$?) {
        Write-Host " - addFileToDeployedKeyVault :: Unable to get the deployed keyvault :: $SUIF_AZ_KEYVAULT_NAME"
        exit -1
    }
    Write-Host " - addFileToDeployedKeyVault :: KeyVault = $SUIF_AZ_KEYVAULT_NAME"
    
    # ----------------------------------------------
    # Check if Secret exists already
    # ----------------------------------------------
   	$az_cmd_response = az keyvault secret show --name $LOC_SECRET_NAME --subscription $H_AZ_SUBSCRIPTION_ID --vault-name $SUIF_AZ_KEYVAULT_NAME 2>&1 | out-null
    If ($?) {
        Write-Host " - addFileToDeployedKeyVault :: Secret $LOC_SECRET_NAME already exists."
        exit 0
    }

    $az_cmd_response = az keyvault secret set --name $LOC_SECRET_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --vault-name $SUIF_AZ_KEYVAULT_NAME `
       --file $LOC_SECRET

    if (!$?) {
        Write-Host " - addFileToDeployedKeyVault :: Error - Unable to set key vault secret :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - addFileToDeployedKeyVault :: Secret $LOC_SECRET_NAME successfully created."
    exit 0

}

## ---------------------------------------------------------------------
## Run init prepare script on remote VM (using CLI)
## ---------------------------------------------------------------------
function runInitVM() {
    param (
        [string] $az_vm_name
    )
    $LOC_VM_NAME = $az_vm_name
    $LOC_HOST_NAME = $az_vm_name

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_RESOURCE_GROUP_STORAGE = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP_STORAGE')
    $H_AZ_STORAGE_ACCOUNT = $suif_host_env.Get_Item('H_AZ_STORAGE_ACCOUNT')

    $SUIF_AZ_VM_USER = $suif_env.Get_Item('SUIF_AZ_VM_USER')
    $SUIF_DIR_ASSETS = $suif_env.Get_Item('SUIF_DIR_ASSETS')
    $SUIF_AZ_VOLUME_ASSETS = $suif_env.Get_Item('SUIF_AZ_VOLUME_ASSETS')

    $SUIF_HOME = $suif_env.Get_Item('SUIF_HOME')
    $SUIF_APP_HOME = $suif_env.Get_Item('SUIF_APP_HOME')
    $SUIF_AUDIT_BASE_DIR = $suif_env.Get_Item('SUIF_AUDIT_BASE_DIR')
    $SUIF_LOCAL_SCRIPTS_HOME = $suif_env.Get_Item('SUIF_LOCAL_SCRIPTS_HOME')
    $SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE = $suif_env.Get_Item('SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE')
    $H_APIGW_ADMIN_PASSWORD = $suif_host_env.Get_Item('H_APIGW_ADMIN_PASSWORD')

    Write-Host "-------------------------------------------------------"
    Write-Host " Initializing VM $LOC_VM_NAME on Azure ...."
    Write-Host "-------------------------------------------------------"

    # ----------------------------------------------
    # Get the storage key
    # ----------------------------------------------
   	$az_cmd_response = az storage account keys list `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $H_AZ_RESOURCE_GROUP_STORAGE `
       --account-name $H_AZ_STORAGE_ACCOUNT
    if (!$?) {
        Write-Host " - initializeVM :: Unable to get the Storage Key :: $az_cmd_response"
        exit -1
    }
    $LOC_AZ_STORAGE_ACCOUNT_KEY = (ConvertFrom-Json -InputObject "$az_cmd_response")[0].value

    # ----------------------------------------------
    # Get deployed KeyVault name
    # ----------------------------------------------
    $SUIF_AZ_KEYVAULT_NAME = az deployment group list --subscription $H_AZ_SUBSCRIPTION_ID -g $SUIF_AZ_RESOURCE_GROUP --query [].properties.parameters.keyVaultName.value -o tsv
    if (!$?) {
        Write-Host " - initializeVM :: Unable to get the deployed keyvault :: $SUIF_AZ_KEYVAULT_NAME"
        exit -1
    }
    Write-Host " - initializeVM :: KeyVault = $SUIF_AZ_KEYVAULT_NAME"

    # ----------------------------------------------
    # Get the storage location
    # ----------------------------------------------
   	$az_cmd_response = az storage account show `
      --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $H_AZ_RESOURCE_GROUP_STORAGE `
      --name $H_AZ_STORAGE_ACCOUNT `
      --query "primaryEndpoints.file" -o tsv
    if (!$?) {
        Write-Host " - initializeVM :: Unable to get the Storage Location :: $az_cmd_response"
        exit -1
    }
    $LOC_AZ_STORAGE_LOCATION = $az_cmd_response.Substring($az_cmd_response.IndexOf(":")+1)
    Write-Host " - initializeVM :: Storage location identified: $LOC_AZ_STORAGE_LOCATION ..."

	$az_cmd = az vm run-command invoke --command-id RunShellScript `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --name $LOC_VM_NAME `
       --parameters SUIF_DIR_ASSETS=$SUIF_DIR_ASSETS `
                    SUIF_APP_HOME=$SUIF_APP_HOME `
                    SUIF_HOME=$SUIF_HOME `
                    AZ_VM_HOST_NAME=$LOC_HOST_NAME `
                    SUIF_AZ_VM_USER=$SUIF_AZ_VM_USER `
                    LOC_AZ_STORAGE_LOCATION=$LOC_AZ_STORAGE_LOCATION `
                    SUIF_AZ_VOLUME_ASSETS=$SUIF_AZ_VOLUME_ASSETS `
                    H_AZ_STORAGE_ACCOUNT=$H_AZ_STORAGE_ACCOUNT `
                    LOC_AZ_STORAGE_ACCOUNT_KEY=$LOC_AZ_STORAGE_ACCOUNT_KEY `
                    SUIF_AUDIT_BASE_DIR=$SUIF_AUDIT_BASE_DIR `
                    SUIF_LOCAL_SCRIPTS_HOME=$SUIF_LOCAL_SCRIPTS_HOME `
                    SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE=$SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE `
                    H_APIGW_ADMIN_PASSWORD=$H_APIGW_ADMIN_PASSWORD `
                    SUIF_AZ_KEYVAULT_NAME=$SUIF_AZ_KEYVAULT_NAME `
       --scripts '@.\scripts\vm_init.sh'

    if (!$?) {
        Write-Host " - initializeVM :: Unable to initialize VM :: $az_cmd"
        exit -1
    }
    Write-Host " - initializeVM :: VM successfully initialized - started installations and setup configurations in the background..."
    exit 0

}


