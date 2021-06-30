
## ---------------------------------------------------------------------
## This script contains common SUIF Powershell functions 
## used by multiple test projects.
## ---------------------------------------------------------------------

## ---------------------------------------------------------------------
## Login to Azure (interactively via Browser) - if needed
## ---------------------------------------------------------------------
function loginAzure() {
    Write-Host "-------------------------------------------------------"
    Write-Host " Login to Azure ...."
    Write-Host "-------------------------------------------------------"
    $az_cmd_response = az account list
    If ((ConvertFrom-Json -InputObject "$az_cmd_response").cloudName -eq "AzureCloud") {
        Write-Host " - loginAzure :: User Already Logged On to Azure"
        exit 0
    } else {
        $az_cmd_response = az login
        If((ConvertFrom-Json -InputObject "$az_cmd_response").cloudName -eq "AzureCloud") {
            exit 0
        } else {
            Write-Host " - loginAzure :: Error Logging on to Azure : $az_cmd_response"
            exit -1
        }
    }
}

## ---------------------------------------------------------------------
## Create Volumes
## ---------------------------------------------------------------------
function createVolume($az_volume_handle) {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $H_AZ_RESOURCE_GROUP_STORAGE = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP_STORAGE')
    $H_AZ_STORAGE_ACCOUNT = $suif_host_env.Get_Item('H_AZ_STORAGE_ACCOUNT')
    $SUIF_AZ_VOLUME_ASSETS = $suif_env.Get_Item($az_volume_handle)
    Write-Host "-------------------------------------------------------"
    Write-Host " Create Azure Volume ...."
    Write-Host "-------------------------------------------------------"
    $az_cmd_response = az storage share-rm exists `
      --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $H_AZ_RESOURCE_GROUP_STORAGE `
      --storage-account $H_AZ_STORAGE_ACCOUNT `
      --name $SUIF_AZ_VOLUME_ASSETS
    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $true) {
        Write-Host " - createVolume :: Volume $SUIF_AZ_VOLUME_ASSETS already Exists"
        exit 0
    }
    Write-Host " - createVolume :: Creating new Volume: $SUIF_AZ_VOLUME_ASSETS ...."
    $az_cmd_response = az storage share-rm create `
      --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $H_AZ_RESOURCE_GROUP_STORAGE `
      --storage-account $H_AZ_STORAGE_ACCOUNT `
      --name $SUIF_AZ_VOLUME_ASSETS `
      --quota 256 `
      --enabled-protocols SMB
    if (!$?) {
        Write-Host " - createVolume :: Error creating volume : $az_cmd_response"
        exit -1
    }
    Write-Host " - createVolume :: Volume created successfully."
    exit 0
}


## ---------------------------------------------------------------------
## Create a directory (if it doesn't exist)
## ---------------------------------------------------------------------
function createDirectory() {
    param (
        [string] $az_volume_handle,
        [string] $az_dir_handle
    )
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $H_AZ_RESOURCE_GROUP_STORAGE = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP_STORAGE')
    $H_AZ_STORAGE_ACCOUNT = $suif_host_env.Get_Item('H_AZ_STORAGE_ACCOUNT')
    $LOC_AZ_VOLUME = $suif_env.Get_Item($az_volume_handle)
    $LOC_AZ_DIR = $suif_env.Get_Item($az_dir_handle)

    # ----------------------------------------------
    # Remove leading "/" character from file path
    # ----------------------------------------------
    $LOC_AZ_DIR = $LOC_AZ_DIR.TrimStart("/"," ")

    Write-Host "-------------------------------------------------------"
    Write-Host " Create Azure FS Directory $LOC_AZ_DIR ...."
    Write-Host "-------------------------------------------------------"

    # ----------------------------------------------
    # Get the storage key
    # ----------------------------------------------
   	$az_cmd_response = az storage account keys list `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $H_AZ_RESOURCE_GROUP_STORAGE `
	  --account-name $H_AZ_STORAGE_ACCOUNT
    if (!$?) {
        Write-Host " - createDirectory :: Unable to get the Storage Key :: $az_cmd_response"
        exit -1
    }
    $LOC_AZ_STORAGE_ACCOUNT_KEY = (ConvertFrom-Json -InputObject "$az_cmd_response")[0].value

    # ----------------------------------------------
    # Check if directory exists
    # ----------------------------------------------
   	$az_cmd_response = az storage directory exists --name $LOC_AZ_DIR `
      --subscription $H_AZ_SUBSCRIPTION_ID `
      --account-name $H_AZ_STORAGE_ACCOUNT `
      --account-key $LOC_AZ_STORAGE_ACCOUNT_KEY `
      --share-name $LOC_AZ_VOLUME
    if (!$?) {
        Write-Host " - createDirectory :: Unable to check if directory exists :: $az_cmd_response"
        exit -1
    }
    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $true) {
        Write-Host " - createDirectory :: Directory $LOC_AZ_DIR already exists..."
        exit 0
    }
    # ----------------------------------------------
    # Create Directory
    # ----------------------------------------------
    Write-Host " - createDirectory :: Creating directory $LOC_AZ_DIR on volume: $LOC_AZ_VOLUME ..."
    $az_cmd_response = az storage directory create --name $LOC_AZ_DIR `
      --subscription $H_AZ_SUBSCRIPTION_ID `
      --account-name $H_AZ_STORAGE_ACCOUNT `
      --account-key $LOC_AZ_STORAGE_ACCOUNT_KEY `
      --share-name $LOC_AZ_VOLUME
    if ($?) {
        exit 0
    } else {
        Write-Host $az_cmd_response
        exit -1
    }
}

## ---------------------------------------------------------------------
## Upload individual file to target (if it doesn't exist)
## ---------------------------------------------------------------------
function uploadFile() {
    param (
        [string] $az_volume_handle,
        [string] $az_dir_handle,
        [string] $az_local_file_handle,
        [string] $az_target_path_handle
    )
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $H_AZ_RESOURCE_GROUP_STORAGE = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP_STORAGE')
    $H_AZ_STORAGE_ACCOUNT = $suif_host_env.Get_Item('H_AZ_STORAGE_ACCOUNT')
    $LOC_AZ_VOLUME = $suif_env.Get_Item($az_volume_handle)
    $LOC_AZ_DIR = $suif_env.Get_Item($az_dir_handle)
    $LOC_AZ_LOCAL_FILE = $suif_host_env.Get_Item($az_local_file_handle)
    $LOC_AZ_PATH = $suif_env.Get_Item($az_target_path_handle)

    Write-Host "-------------------------------------------------------"
    Write-Host " Uploading $LOC_AZ_LOCAL_FILE to Azure storage ....    "
    Write-Host "-------------------------------------------------------"

    # ----------------------------------------------
    # Remove leading "/" character from file path
    # ----------------------------------------------
    $LOC_AZ_DIR = $LOC_AZ_DIR.TrimStart("/"," ")
    $LOC_AZ_PATH = $LOC_AZ_PATH.TrimStart("/"," ")

    # ----------------------------------------------
    # Get the storage key
    # ----------------------------------------------
   	$az_cmd_response = az storage account keys list `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $H_AZ_RESOURCE_GROUP_STORAGE `
	  --account-name $H_AZ_STORAGE_ACCOUNT
    if (!$?) {
        Write-Host " - uploadFile :: Unable to get the Storage Key :: $az_cmd_response"
        exit -1
    }
    $LOC_AZ_STORAGE_ACCOUNT_KEY = (ConvertFrom-Json -InputObject "$az_cmd_response")[0].value

    # ----------------------------------------------
    # Check if directory exists
    # ----------------------------------------------
   	$az_cmd_response = az storage directory exists --name $LOC_AZ_DIR `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
	  --account-name $H_AZ_STORAGE_ACCOUNT `
      --account-key $LOC_AZ_STORAGE_ACCOUNT_KEY `
      --share-name $LOC_AZ_VOLUME
    if (!$?) {
        Write-Host " - uploadFile :: Unable to check if directory exists :: $az_cmd_response"
        exit -1
    }

    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $false) {
        Write-Host " - uploadFile :: Directory $LOC_AZ_DIR on volume $AZ_VOLUME does not exist... exiting"
        exit -1
    }

    # ----------------------------------------------
    # Check if file exists
    # ----------------------------------------------
   	$az_cmd_response = az storage file exists --path $LOC_AZ_PATH `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
	  --account-name $H_AZ_STORAGE_ACCOUNT `
      --account-key $LOC_AZ_STORAGE_ACCOUNT_KEY `
      --share-name $LOC_AZ_VOLUME
    if (!$?) {
        Write-Host " - uploadFile :: Unable to check if file exists :: $az_cmd_response"
        exit -1
    }

    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $true) {
        Write-Host " - uploadFile :: File $LOC_AZ_PATH on volume $LOC_AZ_VOLUME already exists."
        exit 0
    }
    # ----------------------------------------------
    # Upload ....
    # ----------------------------------------------
    $az_cmd_response = az storage file upload --path $LOC_AZ_PATH `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
	  --account-name $H_AZ_STORAGE_ACCOUNT `
      --account-key $LOC_AZ_STORAGE_ACCOUNT_KEY `
      --share-name $LOC_AZ_VOLUME `
      --source "$LOC_AZ_LOCAL_FILE"
    if (!$?) {
        Write-Host " - File Upload :: Unable to upload file :: $az_cmd_response"
        exit -1
    }
    Write-Host " - uploadFile :: Uploading file $LOC_AZ_PATH ..."
    exit 0

}
## ---------------------------------------------------------------------
## Upload multiple files to target (if it doesn't exist)
## - Note: the 'az_ver_dir_handle' refers to a sourced variable from 
##   suif.env and should point to an individual directory that is used to
##   verify if upload is required or not. If found, then no files are
##   uploaded.
## ---------------------------------------------------------------------
function uploadFiles() {
    param (
        [string] $az_volume_handle,
        [string] $az_dir_handle,
        [string] $az_source_handle,
        [string] $az_include_pattern,
        [string] $az_ver_dir_handle
    )
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $H_AZ_RESOURCE_GROUP_STORAGE = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP_STORAGE')
    $H_AZ_STORAGE_ACCOUNT = $suif_host_env.Get_Item('H_AZ_STORAGE_ACCOUNT')
    $LOC_AZ_VOLUME = $suif_env.Get_Item($az_volume_handle)
    $LOC_AZ_DIR = $suif_env.Get_Item($az_dir_handle)
    $LOC_AZ_SOURCE = $az_source_handle
    $LOC_AZ_INCL_PATTERN = $az_include_pattern
    $LOC_AZ_VERIF_DIR = $suif_env.Get_Item($az_ver_dir_handle)
    $SUIF_ASSETS_SCRIPTS_OVERWRITE = $suif_env.Get_Item('SUIF_ASSETS_SCRIPTS_OVERWRITE')

    Write-Host "-------------------------------------------------------"
    Write-Host " Uploading files to Azure target file system ...."
    Write-Host "-------------------------------------------------------"

    # ----------------------------------------------
    # Remove leading "/" character from file path
    # ----------------------------------------------
    $LOC_AZ_DIR = $LOC_AZ_DIR.TrimStart("/"," ")
    $LOC_AZ_VERIF_DIR = $LOC_AZ_VERIF_DIR.TrimStart("/"," ")

    # ----------------------------------------------
    # Get the storage key
    # ----------------------------------------------
   	$az_cmd_response = az storage account keys list `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $H_AZ_RESOURCE_GROUP_STORAGE `
	  --account-name $H_AZ_STORAGE_ACCOUNT
    if (!$?) {
        Write-Host " - uploadFiles :: Unable to get the Storage Key :: $az_cmd_response"
        exit -1
    }
    $LOC_AZ_STORAGE_ACCOUNT_KEY = (ConvertFrom-Json -InputObject "$az_cmd_response")[0].value
    # Write-Host " - File Upload :: Storage key identified: $LOC_AZ_STORAGE_ACCOUNT_KEY"

    # ----------------------------------------------
    # Check if target directory exists
    # ----------------------------------------------
   	$az_cmd_response = az storage directory exists --name $LOC_AZ_DIR `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
	  --account-name $H_AZ_STORAGE_ACCOUNT `
      --account-key $LOC_AZ_STORAGE_ACCOUNT_KEY `
      --share-name $LOC_AZ_VOLUME
    if (!$?) {
        Write-Host " - uploadFiles :: Error - Unable to check if directory exists : $az_cmd_response"
        exit -1
    }

    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $false) {
        Write-Host " - uploadFiles :: Directory $LOC_AZ_DIR on volume $LOC_AZ_VOLUME does not exist... exiting"
        exit -1
    } else {
        Write-Host " - uploadFiles :: Directory $LOC_AZ_DIR on volume $LOC_AZ_VOLUME exists..."
    }

    # -------------------------------------------------------------
    # Check if a "verification directory" exist - if so, do not upload
    # - This will only be checked if the SUIF_ASSETS_SCRIPTS_OVERWRITE flag is set to 0
    # -------------------------------------------------------------
    If ($SUIF_ASSETS_SCRIPTS_OVERWRITE -eq 0) {
        $az_cmd_response = az storage directory exists --name $LOC_AZ_VERIF_DIR `
        --subscription $H_AZ_SUBSCRIPTION_ID `
        --account-name $H_AZ_STORAGE_ACCOUNT `
        --account-key $LOC_AZ_STORAGE_ACCOUNT_KEY `
        --share-name $LOC_AZ_VOLUME
        if (!$?) {
            Write-Host " - uploadFiles :: Error - Unable to check if $LOC_AZ_VERIF_DIR directory exists : $az_cmd_response"
            exit -1
        }

        If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $true) {
            Write-Host " - uploadFiles :: $LOC_AZ_VERIF_DIR already exists... skipping upload."
            exit 0
        }
    } else {
        Write-Host " - uploadFiles :: Script overwrite flag is set to ${SUIF_ASSETS_SCRIPTS_OVERWRITE}, performing upload without verification ...."
    }

    # ----------------------------------------------
    # Upload Batch
    # ----------------------------------------------
    Write-Host " - uploadFiles :: Performing batch upload of $LOC_AZ_SOURCE using pattern $LOC_AZ_INCL_PATTERN"
   	$az_cmd_response = az storage file upload-batch --destination $LOC_AZ_VOLUME `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
	  --account-name $H_AZ_STORAGE_ACCOUNT `
      --account-key $LOC_AZ_STORAGE_ACCOUNT_KEY `
      --source "$LOC_AZ_SOURCE" `
      --destination-path "$LOC_AZ_DIR" `
      --pattern $LOC_AZ_INCL_PATTERN `
      --no-progress
    if (!$?) {
        Write-Host " - uploadFiles :: Error - Unable to upload :: $az_cmd_response"
        exit -1
    }
    Write-Host " - uploadFiles :: Transfer ok .."
    exit 0

}

## ---------------------------------------------------------------------
## Create a Resource Group
## ---------------------------------------------------------------------
function createResourceGroup() {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_GEO_LOCATION = $suif_host_env.Get_Item('H_AZ_GEO_LOCATION')
    
    Write-Host "-------------------------------------------------------"
    Write-Host " Creating resource group $SUIF_AZ_RESOURCE_GROUP on Azure ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if Resource Group exists already
    # ----------------------------------------------
   	$az_cmd_response = az group exists --name $SUIF_AZ_RESOURCE_GROUP --subscription $H_AZ_SUBSCRIPTION_ID
    If ($az_cmd_response -eq 'true') {
        Write-Host " - createResourceGroup :: Resource Group $SUIF_AZ_RESOURCE_GROUP already exists."
        exit 0
    }
    $az_cmd_response = az group create --name $SUIF_AZ_RESOURCE_GROUP `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
      --location $H_AZ_GEO_LOCATION
    if (!$?) {
        Write-Host " - createResourceGroup :: Error - Unable to create resource group :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - createResourceGroup :: $SUIF_AZ_RESOURCE_GROUP successfully created."
    exit 0

}

## ---------------------------------------------------------------------
## Provision a VM
## ---------------------------------------------------------------------
function provisionVM() {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_VM_IMAGE = $suif_host_env.Get_Item('H_AZ_VM_IMAGE')
    $H_AZ_VM_SIZE = $suif_host_env.Get_Item('H_AZ_VM_SIZE')
    
    $SUIF_AZ_VM_NAME = $suif_env.Get_Item('SUIF_AZ_VM_NAME')
    $SUIF_AZ_VM_USER = $suif_env.Get_Item('SUIF_AZ_VM_USER')

    Write-Host "-------------------------------------------------------"
    Write-Host " Provisioning VM $SUIF_AZ_VM_NAME on Azure ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if VM exists already
    # ----------------------------------------------
   	$az_cmd_response = az vm show -g $SUIF_AZ_RESOURCE_GROUP -n $SUIF_AZ_VM_NAME ` 2>&1 | out-null
    if ($?) {
        Write-Host " - provisionVM :: VM $SUIF_AZ_VM_NAME already exists."
        exit 0
    }
    # ----------------------------------------------
    # Deploy new VM
    # ----------------------------------------------
   	$az_cmd_response = az vm create --name $SUIF_AZ_VM_NAME `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $SUIF_AZ_RESOURCE_GROUP `
      --image $H_AZ_VM_IMAGE `
      --admin-username $SUIF_AZ_VM_USER `
      --size $H_AZ_VM_SIZE `
      --generate-ssh-keys
    if (!$?) {
        Write-Host " - provisionVM :: Unable to provision VM :: $az_cmd_response"
        exit -1
    }
    Write-Host " - provisionVM :: VM successful created."
    exit 0
}

## ---------------------------------------------------------------------
## Prepare VM
##  - Possible alternative:  az vm run-command invoke .. --command-id RunShellScript
## 
##  - This should perhaps be done more dynamic from a caller perspective:
##    - define preparation script (sh) to be executed remotely.
##    - APIGW has additional requirements
##
## ---------------------------------------------------------------------
function prepareVM() {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_RESOURCE_GROUP_STORAGE = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP_STORAGE')
    $H_AZ_STORAGE_ACCOUNT = $suif_host_env.Get_Item('H_AZ_STORAGE_ACCOUNT')
    
    $SUIF_AZ_VM_NAME = $suif_env.Get_Item('SUIF_AZ_VM_NAME')
    $SUIF_AZ_VM_USER = $suif_env.Get_Item('SUIF_AZ_VM_USER')
    $SUIF_DIR_ASSETS = $suif_env.Get_Item('SUIF_DIR_ASSETS')
    $SUIF_AZ_VOLUME_ASSETS = $suif_env.Get_Item('SUIF_AZ_VOLUME_ASSETS')

    $SUIF_APP_HOME = $suif_env.Get_Item('SUIF_APP_HOME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Preparing the VM $SUIF_AZ_VM_NAME on Azure ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Get Public IP
    # ----------------------------------------------
   	$LOC_AZ_PUBLIC_IP = az vm show -d -g $SUIF_AZ_RESOURCE_GROUP -n $SUIF_AZ_VM_NAME --query publicIps -o tsv 
    if (!$?) {
        Write-Host " - prepareVM :: Unable to get public IP for VM $SUIF_AZ_VM_NAME. Exiting ..."
        exit -1
    }
    Write-Host " - prepareVM :: Public IP for VM identified: $LOC_AZ_PUBLIC_IP ..."
    
    # ----------------------------------------------
    # Test if VM has already been prepared
    # ----------------------------------------------
    $ssh_key = ssh-keyscan -H $LOC_AZ_PUBLIC_IP >> ~\.ssh\known_hosts 2> $null
   	$ssh_cmd_response = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP "ls $SUIF_DIR_ASSETS" 2> $null
    if ($?) {
        Write-Host " - prepareVM :: VM has already been prepared for processing."
        exit 0
    }

    # ----------------------------------------------
    # Get the storage key
    # ----------------------------------------------
   	$az_cmd_response = az storage account keys list `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $H_AZ_RESOURCE_GROUP_STORAGE `
	  --account-name $H_AZ_STORAGE_ACCOUNT
    if (!$?) {
        Write-Host " - Files Upload :: Unable to get the Storage Key :: $az_cmd_response"
        exit -1
    }
    $LOC_AZ_STORAGE_ACCOUNT_KEY = (ConvertFrom-Json -InputObject "$az_cmd_response")[0].value
    # Write-Host " - prepareVM :: Storage key identified: $LOC_AZ_STORAGE_ACCOUNT_KEY"

    # ----------------------------------------------
    # Get the storage location
    # ----------------------------------------------
   	$az_cmd_response = az storage account show `
      --resource-group $H_AZ_RESOURCE_GROUP_STORAGE `
      --name $H_AZ_STORAGE_ACCOUNT `
      --query "primaryEndpoints.file" -o tsv
    if (!$?) {
        Write-Host " - prepareVM :: Unable to get the Storage Location :: $az_cmd_response"
        exit -1
    }
    $LOC_AZ_STORAGE_LOCATION = $az_cmd_response.Substring($az_cmd_response.IndexOf(":")+1)
    Write-Host " - prepareVM :: Storage location identified: $LOC_AZ_STORAGE_LOCATION ..."

    # ----------------------------------------------
    # Prepare new VM
    # TODO: resolve uid and gid
    # ----------------------------------------------
    Write-Host " - prepareVM :: Executing remote ssh commands for VM preparation ...."
   	$ssh_cmd_response = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP `
       "sudo yum -y install cifs-utils; `
        sudo mkdir -p $SUIF_DIR_ASSETS $SUIF_APP_HOME; `
        sudo chown -R '$SUIF_AZ_VM_USER':'$SUIF_AZ_VM_USER' $SUIF_DIR_ASSETS; `
        sudo chown -R '$SUIF_AZ_VM_USER':'$SUIF_AZ_VM_USER' $SUIF_APP_HOME; `
        sudo mount -t cifs '$LOC_AZ_STORAGE_LOCATION''$SUIF_AZ_VOLUME_ASSETS''$SUIF_DIR_ASSETS' '$SUIF_DIR_ASSETS' -o username=$H_AZ_STORAGE_ACCOUNT,password=$LOC_AZ_STORAGE_ACCOUNT_KEY,uid=1000,gid=1000,serverino"

    if ($?) {
        Write-Host " - prepareVM :: VM successfully prepared."
        exit 0
    } else {
        Write-Host " - prepareVM :: Unable to prepare VM :: $ssh_cmd_response"
        exit -1
    }
}

## ---------------------------------------------------------------------
## Create a firewall rule to open port on VM
##  - Passed 'az_nsg_rule_name' parameter is a unique identifier for the nsg rule
##  - Passed 'az_nsg_rule_prio' parameter is the priority for the rule. Must be unique.
##  - Passed 'az_nsg_port' parameter is a single port value
## ---------------------------------------------------------------------
function createInboundFWRule() {
    param (
        [string] $az_nsg_rule_name,
        [string] $az_nsg_rule_prio,
        [string] $az_nsg_port
    )
    $LOC_AZ_NSG_RULE_NAME = $az_nsg_rule_name
    $LOC_AZ_NSG_RULE_PRIORITY = $az_nsg_rule_prio
    $LOC_AZ_NSG_PORT = $az_nsg_port

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $SUIF_AZ_VM_NAME = $suif_env.Get_Item('SUIF_AZ_VM_NAME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Inbound FW Rule for $SUIF_AZ_VM_NAME (port: $LOC_AZ_NSG_PORT) ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Constructing the Network Security Group
    # ----------------------------------------------
   	$LOC_AZ_NSG_NAME = $SUIF_AZ_VM_NAME + 'NSG'

    # ----------------------------------------------
    # Check if exists
    # ----------------------------------------------
    $az_cmd_response = az network nsg rule show --name $LOC_AZ_NSG_RULE_NAME --nsg-name $LOC_AZ_NSG_NAME `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $SUIF_AZ_RESOURCE_GROUP `
      2> $null
    if ($?) {
        Write-Host " - createInboundFWRule :: security rule $LOC_AZ_NSG_RULE_NAME already exists."
        exit 0
    }

    # ----------------------------------------------
    # Creating the rule
    # ----------------------------------------------
    $az_cmd_response = az network nsg rule create --name $LOC_AZ_NSG_RULE_NAME --nsg-name $LOC_AZ_NSG_NAME `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $SUIF_AZ_RESOURCE_GROUP `
      --priority $LOC_AZ_NSG_RULE_PRIORITY `
      --access Allow `
      --source-address-prefixes Internet `
      --destination-port-ranges $LOC_AZ_NSG_PORT `
      --protocol Tcp `
      --description "Allow inbound access to SAG components"
    if (!$?) {
        Write-Host " - createInboundFWRule :: creating security rule failed with errors :: $az_cmd_response"
        exit -1
    }
    Write-Host " - createInboundFWRule :: inbound security rule created successfully."
    exit 0
}

## ---------------------------------------------------------------------
## Transfer file to VM referenced by source and target directories
## ---------------------------------------------------------------------
function uploadFileToVM() {
    param (
        [string] $suif_source_handle,
        [string] $suif_target_handle
    )
    $LOC_SUIF_SOURCE = $suif_host_env.Get_Item($suif_source_handle)
    $LOC_SUIF_TARGET = $suif_env.Get_Item($suif_target_handle)

    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $SUIF_AZ_VM_NAME = $suif_env.Get_Item('SUIF_AZ_VM_NAME')
    $SUIF_AZ_VM_USER = $suif_env.Get_Item('SUIF_AZ_VM_USER')

    Write-Host "-------------------------------------------------------"
    Write-Host " Uploading file to $SUIF_AZ_VM_NAME ...."
    Write-Host "  - Source: $LOC_SUIF_SOURCE"
    Write-Host "  - Target: $LOC_SUIF_TARGET"
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Get Public IP
    # ----------------------------------------------
   	$LOC_AZ_PUBLIC_IP = az vm show -d -g $SUIF_AZ_RESOURCE_GROUP -n $SUIF_AZ_VM_NAME --query publicIps -o tsv 
    if (!$?) {
        Write-Host " - uploadFileToVM :: Unable to get public IP for VM $SUIF_AZ_VM_NAME. Exiting ..."
        exit -1
    }
    # ----------------------------------------------
    # Test if file has already been uploaded
    # ----------------------------------------------
   	$ssh_cmd_response = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP "ls $LOC_SUIF_TARGET" 2> $null
    if ($?) {
        Write-Host " - uploadFileToVM :: File has already been uploaded."
        exit 0
    }
    $ssh_cmd_response = scp ${LOC_SUIF_SOURCE} ${SUIF_AZ_VM_USER}@${LOC_AZ_PUBLIC_IP}:${LOC_SUIF_TARGET}
    if (!$?) {
        Write-Host " - uploadFileToVM :: Error - Unable to upload file :: $ssh_cmd_response"
        exit -1
    } 
    Write-Host " - uploadFileToVM :: Transfer ok .."
    exit 0

}

## ---------------------------------------------------------------------
## Run entrypoint script to provision 
## ---------------------------------------------------------------------
function entryPointVM() {
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $SUIF_AZ_VM_NAME = $suif_env.Get_Item('SUIF_AZ_VM_NAME')
    $SUIF_AZ_VM_USER = $suif_env.Get_Item('SUIF_AZ_VM_USER')
    $SUIF_LOCAL_SCRIPTS_HOME = $suif_env.Get_Item('SUIF_LOCAL_SCRIPTS_HOME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Starting Application on Azure $SUIF_AZ_VM_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Get Public IP
    # ----------------------------------------------
   	$LOC_AZ_PUBLIC_IP = az vm show -d -g $SUIF_AZ_RESOURCE_GROUP -n $SUIF_AZ_VM_NAME --query publicIps -o tsv 
    if (!$?) {
        Write-Host " - entryPointVM :: Unable to get public IP for VM $SUIF_AZ_VM_NAME. Exiting ..."
        exit -1
    }
    Write-Host " - entryPointVM :: Public IP for VM identified: $LOC_AZ_PUBLIC_IP ..."
    ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP "$SUIF_LOCAL_SCRIPTS_HOME/entryPoint.sh $LOC_AZ_PUBLIC_IP"
    if (!$?) {
        Write-Host " - entryPointVM :: entryPoint.sh Script completed with errors :: $ssh_cmd_response"
        exit -1
    }
    Write-Host " - entryPointVM :: entryPoint.sh Script completed successfully."
    exit 0
}

## ---------------------------------------------------------------------
## Ensure API Gateway has sufficient resource
## ---------------------------------------------------------------------
function ensureOSSettings() {
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $SUIF_AZ_VM_NAME = $suif_env.Get_Item('SUIF_AZ_VM_NAME')
    $SUIF_AZ_VM_USER = $suif_env.Get_Item('SUIF_AZ_VM_USER')

    Write-Host "-------------------------------------------------------"
    Write-Host " Ensuring API Gateway Settings ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Get Public IP
    # ----------------------------------------------
   	$LOC_AZ_PUBLIC_IP = az vm show -d -g $SUIF_AZ_RESOURCE_GROUP -n $SUIF_AZ_VM_NAME --query publicIps -o tsv 
    if (!$?) {
        Write-Host " - ensureOSSettings :: Unable to get public IP for VM $SUIF_AZ_VM_NAME. Exiting ..."
        exit -1
    }
    Write-Host " - ensureOSSettings :: Public IP for VM identified: $LOC_AZ_PUBLIC_IP ..."
    
    # ----------------------------------------------
    # Test System wide file descriptors
    # ----------------------------------------------
   	$ssh_cmd = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP "sysctl -a | grep fs.file-max | cut -f 3 -d ' '" 2> $null
    if ([int]$ssh_cmd -lt 65536) {
        Write-Host " - ensureOSSettings :: Number of system-wide file descriptors insufficient ($ssh_cmd) - increasing to 65536 ...."
       	$ssh_cmd = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP `
          "echo "fs.file-max = 65536" | sudo tee -a /etc/sysctl.conf; sudo sysctl -p;"
    } else {
        Write-Host " - ensureOSSettings :: Number of system-wide file descriptors ok :: $ssh_cmd. [Required min: 65536]"
    }

    # ----------------------------------------------
    # Test Open file descriptors Soft
    # ----------------------------------------------
   	$ssh_cmd = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP "ulimit -Sn" 2> $null
    if ([int]$ssh_cmd -lt 65536) {
        Write-Host " - ensureOSSettings :: Number of Soft open file descriptors insufficient ($ssh_cmd) - increasing to 65536 ...."
       	$ssh_cmd = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP `
          "echo "sag soft nofile 65536" | sudo tee -a /etc/security/limits.conf;"
    } else {
        Write-Host " - ensureOSSettings :: Number of Soft open file descriptors ok :: $ssh_cmd. [Required min: 65536]"
    }

    # ----------------------------------------------
    # Test Open file descriptors Hard
    # ----------------------------------------------
   	$ssh_cmd = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP "ulimit -Hn" 2> $null
    if ([int]$ssh_cmd -lt 65536) {
        Write-Host " - ensureOSSettings :: Number of Hard open file descriptors insufficient ($ssh_cmd) - increasing to 65536 ...."
       	$ssh_cmd = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP `
          "echo "sag hard nofile 65536" | sudo tee -a /etc/security/limits.conf;"
    } else {
        Write-Host " - ensureOSSettings :: Number of Hard open file descriptors ok :: $ssh_cmd. [Required min: 65536]"
    }

    # ----------------------------------------------
    # Test maximum system-wide map count
    # ----------------------------------------------
   	$ssh_cmd = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP "sysctl -a | grep vm.max_map_count | cut -f 3 -d ' '" 2> $null
    if ([int]$ssh_cmd -lt 262144) {
        Write-Host " - ensureOSSettings :: Number of systen-wide map count insufficient ($ssh_cmd) - increasing to 262144 ...."
       	$ssh_cmd = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP `
          "echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf; sudo sysctl -p;"
    } else {
        Write-Host " - ensureOSSettings :: Number of systen-wide map count ok :: $ssh_cmd. [Required min: 262144]"
    }

    # ----------------------------------------------
    # Test maximum number of processes
    # ----------------------------------------------
   	$ssh_cmd = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP "ulimit -u" 2> $null
    if ([int]$ssh_cmd -lt 4096) {
        Write-Host " - ensureOSSettings :: Number of processes insufficient ($ssh_cmd) - increasing to 4096 ...."
       	$ssh_cmd = ssh -o StrictHostKeyChecking=no $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP `
          "echo "$SUIF_AZ_VM_USER soft nproc 4096" | sudo tee -a /etc/security/limits.conf; `
           echo "$SUIF_AZ_VM_USER hard nproc 4096" | sudo tee -a /etc/security/limits.conf;"
    } else {
        Write-Host " - ensureOSSettings :: Number of processes ok :: $ssh_cmd. [Required min: 4096]"
    }

}

## ---------------------------------------------------------------------
## Create Application Security Group
## ---------------------------------------------------------------------
function createASG() {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_GEO_LOCATION = $suif_host_env.Get_Item('H_AZ_GEO_LOCATION')
    $SUIF_AZ_ASG_NAME = $suif_env.Get_Item('SUIF_AZ_ASG_NAME')
    
    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Application Security Group $SUIF_AZ_ASG_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if Security Group exists already
    # ----------------------------------------------
   	$az_cmd_response = az network asg show --name $SUIF_AZ_ASG_NAME --subscription $H_AZ_SUBSCRIPTION_ID --resource-group $SUIF_AZ_RESOURCE_GROUP 2>&1 | out-null
    If ($?) {
        Write-Host " - createASG :: Application Security Group $SUIF_AZ_ASG_NAME already exists."
        exit 0
    }
    $az_cmd_response = az network asg create --name $SUIF_AZ_ASG_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --location $H_AZ_GEO_LOCATION
    if (!$?) {
        Write-Host " - createASG :: Error - Unable to create ASG :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - createASG :: $SUIF_AZ_ASG_NAME successfully created."
    exit 0

}

## ---------------------------------------------------------------------
## Create Network Security Group
## ---------------------------------------------------------------------
function createNSG() {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_GEO_LOCATION = $suif_host_env.Get_Item('H_AZ_GEO_LOCATION')
    $SUIF_AZ_NSG_NAME = $suif_env.Get_Item('SUIF_AZ_NSG_NAME')
    
    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Network Security Group $SUIF_AZ_NSG_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if Security Group exists already
    # ----------------------------------------------
   	$az_cmd_response = az network nsg show --name $SUIF_AZ_NSG_NAME --subscription $H_AZ_SUBSCRIPTION_ID --resource-group $SUIF_AZ_RESOURCE_GROUP 2>&1 | out-null
    If ($?) {
        Write-Host " - createNSG :: Network Security Group $SUIF_AZ_NSG_NAME already exists."
        exit 0
    }
    $az_cmd_response = az network nsg create --name $SUIF_AZ_NSG_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --location $H_AZ_GEO_LOCATION
    if (!$?) {
        Write-Host " - createNSG :: Error - Unable to create NSG :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - createNSG :: $SUIF_AZ_NSG_NAME successfully created."
    exit 0

}

## ---------------------------------------------------------------------
## Create NSG Rule
## ---------------------------------------------------------------------
function createNSGRule() {
    param (
        [string] $az_nsg_rule,
        [string] $az_nsg_direction,
        [string] $az_nsg_priority,
        [string] $az_nsg_dest_prefix,
        [string] $az_nsg_dest_port,
        [string] $az_nsg_source_prefix,
        [string] $az_nsg_protocol
    )
    $LOC_NSG_RULE_NAME = $az_nsg_rule
    $LOC_NSG_DIRECTION = $az_nsg_direction
    $LOC_NSG_PRIORITY = $az_nsg_priority
    $LOC_NSG_DEST_PREFIX = $az_nsg_dest_prefix
    $LOC_NSG_DEST_PORT = $az_nsg_dest_port
    $LOC_NSG_SOURCE_PREFIX = $az_nsg_source_prefix
    $LOC_NSG_PROTOCOL = $az_nsg_protocol

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $SUIF_AZ_NSG_NAME = $suif_env.Get_Item('SUIF_AZ_NSG_NAME')
    
    Write-Host "-------------------------------------------------------"
    Write-Host " Creating NSG Rule :: $LOC_NSG_RULE_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if exists
    # ----------------------------------------------
    $az_cmd_response = az network nsg rule show --name $LOC_NSG_RULE_NAME --nsg-name $SUIF_AZ_NSG_NAME `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $SUIF_AZ_RESOURCE_GROUP `
      2> $null
    if ($?) {
        Write-Host " - createNSGRule :: NSG rule $LOC_NSG_RULE_NAME already exists."
        exit 0
    }

    # ----------------------------------------------
    # Creating the rule
    # ----------------------------------------------
    $az_cmd_response = az network nsg rule create --name $LOC_NSG_RULE_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --nsg-name $SUIF_AZ_NSG_NAME `
       --direction  $LOC_NSG_DIRECTION `
       --priority $LOC_NSG_PRIORITY `
       --access Allow `
       --destination-address-prefixes $LOC_NSG_DEST_PREFIX `
       --destination-port-ranges $LOC_NSG_DEST_PORT `
       --protocol $LOC_NSG_PROTOCOL `
       --source-address-prefixes $LOC_NSG_SOURCE_PREFIX `
       --description "SUIF generated NSG rule."
    if (!$?) {
        Write-Host " - createNSGRule :: creating NSG rule failed with errors :: $az_cmd_response"
        exit -1
    }
    Write-Host " - createNSGRule :: NSG rule $LOC_NSG_RULE_NAME created successfully."
    exit 0
}

## ---------------------------------------------------------------------
## Create Virtual Network for Bastion Setup
## ---------------------------------------------------------------------
function createBastionVNET() {
    param (
        [string] $az_address_prefix
    )
    $LOC_ADDRESS_PREFIX = $az_address_prefix

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_GEO_LOCATION = $suif_host_env.Get_Item('H_AZ_GEO_LOCATION')
    $SUIF_AZ_NSG_NAME = $suif_env.Get_Item('SUIF_AZ_NSG_NAME')
    $SUIF_AZ_VNET_NAME = $suif_env.Get_Item('SUIF_AZ_VNET_NAME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Virtual Network $SUIF_AZ_VNET_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if Virtual Network exists already
    # ----------------------------------------------
   	$az_cmd_response = az network vnet show --name $SUIF_AZ_VNET_NAME --subscription $H_AZ_SUBSCRIPTION_ID --resource-group $SUIF_AZ_RESOURCE_GROUP 2>&1 | out-null
    If ($?) {
        Write-Host " - createBastionVNET :: Virtual Network $SUIF_AZ_VNET_NAME already exists."
        exit 0
    }
    $az_cmd_response = az network vnet create --name $SUIF_AZ_VNET_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --location $H_AZ_GEO_LOCATION `
       --network-security-group $SUIF_AZ_NSG_NAME `
       --address-prefixes $LOC_ADDRESS_PREFIX `
       --subnet-name AzureBastionSubnet

    if (!$?) {
        Write-Host " - createBastionVNET :: Error - Unable to create virtual network :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - createBastionVNET :: $SUIF_AZ_VNET_NAME successfully created."
    exit 0

}

## ---------------------------------------------------------------------
## Create Public IP
## ---------------------------------------------------------------------
function createPublicIP() {
    param (
        [string] $az_allocation,
        [string] $az_sku,
        [string] $az_zone
    )
    $LOC_ALLOCATION_METHOD = $az_allocation
    $LOC_SKU = $az_sku
    $LOC_ZONE = $az_zone

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_GEO_LOCATION = $suif_host_env.Get_Item('H_AZ_GEO_LOCATION')
    $SUIF_AZ_PUBLIC_IP_NAME = $suif_env.Get_Item('SUIF_AZ_PUBLIC_IP_NAME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Public IP $SUIF_AZ_PUBLIC_IP_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if Public IP exists already
    # ----------------------------------------------
   	$az_cmd_response = az network public-ip show --name $SUIF_AZ_PUBLIC_IP_NAME --subscription $H_AZ_SUBSCRIPTION_ID --resource-group $SUIF_AZ_RESOURCE_GROUP 2>&1 | out-null
    If ($?) {
        Write-Host " - createPublicIP :: Public IP $SUIF_AZ_PUBLIC_IP_NAME already exists."
        exit 0
    }
    $az_cmd_response = az network public-ip create --name $SUIF_AZ_PUBLIC_IP_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --location $H_AZ_GEO_LOCATION `
       --allocation-method $LOC_ALLOCATION_METHOD `
       --sku $LOC_SKU `
       --zone $LOC_ZONE

    if (!$?) {
        Write-Host " - createPublicIP :: Error - Unable to create public IP :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - createPublicIP :: $SUIF_AZ_PUBLIC_IP_NAME successfully created."
    exit 0

}

## ---------------------------------------------------------------------
## Create Key Vault
## ---------------------------------------------------------------------
function createKeyVault() {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_GEO_LOCATION = $suif_host_env.Get_Item('H_AZ_GEO_LOCATION')
    $SUIF_AZ_KEYVAULT_NAME = $suif_env.Get_Item('SUIF_AZ_KEYVAULT_NAME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Key Vault $SUIF_AZ_KEYVAULT_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if Key Vault exists already
    # ----------------------------------------------
   	$az_cmd_response = az keyvault show --name $SUIF_AZ_KEYVAULT_NAME --subscription $H_AZ_SUBSCRIPTION_ID --resource-group $SUIF_AZ_RESOURCE_GROUP 2>&1 | out-null
    If ($?) {
        Write-Host " - createKeyVault :: Key Vault $SUIF_AZ_KEYVAULT_NAME already exists."
        exit 0
    }

    # ----------------------------------------------
    # Purge soft-deleted Key Vault when purge protection is enabled...
    # ----------------------------------------------
   	$az_cmd_response = az keyvault purge --name $SUIF_AZ_KEYVAULT_NAME --subscription $H_AZ_SUBSCRIPTION_ID --location $H_AZ_GEO_LOCATION 2>&1 | out-null
    # ----------------------------------------------
    # Create Key Vault ...
    # ----------------------------------------------
    $az_cmd_response = az keyvault create --name $SUIF_AZ_KEYVAULT_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --location $H_AZ_GEO_LOCATION

    if (!$?) {
        Write-Host " - createKeyVault :: Error - Unable to create keyVault :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - createKeyVault :: $SUIF_AZ_KEYVAULT_NAME successfully created."
    exit 0

}

## ---------------------------------------------------------------------
## Add Secret to Key Vault
## ---------------------------------------------------------------------
function addSecretToKeyVault() {
    param (
        [string] $az_name_handle,
        [string] $az_secret_handle
    )
    # ----------------------------------------------
    # Get variables from either .env or suif.env
    # ----------------------------------------------
    if ($az_name_handle.StartsWith('H_')) {
        $LOC_SECRET_NAME = $suif_host_env.Get_Item($az_name_handle)
    } else{
        $LOC_SECRET_NAME = $suif_env.Get_Item($az_name_handle)
    }
    if ($az_secret_handle.StartsWith('H_')) {
        $LOC_SECRET = $suif_host_env.Get_Item($az_secret_handle)
    } else{
        $LOC_SECRET = $suif_env.Get_Item($az_secret_handle)
    }

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_KEYVAULT_NAME = $suif_env.Get_Item('SUIF_AZ_KEYVAULT_NAME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Secret $LOC_SECRET_NAME in $SUIF_AZ_KEYVAULT_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if Secret exists already
    # ----------------------------------------------
   	$az_cmd_response = az keyvault secret show --name $LOC_SECRET_NAME --subscription $H_AZ_SUBSCRIPTION_ID --vault-name $SUIF_AZ_KEYVAULT_NAME 2>&1 | out-null
    If ($?) {
        Write-Host " - addKeyVaultSecret :: Secret $LOC_SECRET_NAME already exists."
        exit 0
    }

    $az_cmd_response = az keyvault secret set --name $LOC_SECRET_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --vault-name $SUIF_AZ_KEYVAULT_NAME `
       --value $LOC_SECRET

    if (!$?) {
        Write-Host " - addKeyVaultSecret :: Error - Unable to set key vault secret :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - addKeyVaultSecret :: Secret $LOC_SECRET_NAME successfully created."
    exit 0

}

## ---------------------------------------------------------------------
## Add File to Key Vault
## ---------------------------------------------------------------------
function addFileToKeyVault() {
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
    $SUIF_AZ_KEYVAULT_NAME = $suif_env.Get_Item('SUIF_AZ_KEYVAULT_NAME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Secret $LOC_SECRET_NAME in $SUIF_AZ_KEYVAULT_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if Secret exists already
    # ----------------------------------------------
   	$az_cmd_response = az keyvault secret show --name $LOC_SECRET_NAME --subscription $H_AZ_SUBSCRIPTION_ID --vault-name $SUIF_AZ_KEYVAULT_NAME 2>&1 | out-null
    If ($?) {
        Write-Host " - addFileToKeyVault :: Secret $LOC_SECRET_NAME already exists."
        exit 0
    }

    $az_cmd_response = az keyvault secret set --name $LOC_SECRET_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --vault-name $SUIF_AZ_KEYVAULT_NAME `
       --file $LOC_SECRET

    if (!$?) {
        Write-Host " - addFileToKeyVault :: Error - Unable to set key vault secret :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - addFileToKeyVault :: Secret $LOC_SECRET_NAME successfully created."
    exit 0

}

## ---------------------------------------------------------------------
## Create Bastion Host Service
## ---------------------------------------------------------------------
function createBastionHostService() {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_GEO_LOCATION = $suif_host_env.Get_Item('H_AZ_GEO_LOCATION')
    $SUIF_AZ_BASTION_NAME = $suif_env.Get_Item('SUIF_AZ_BASTION_NAME')
    $SUIF_AZ_VNET_NAME = $suif_env.Get_Item('SUIF_AZ_VNET_NAME')
    $SUIF_AZ_PUBLIC_IP_NAME = $suif_env.Get_Item('SUIF_AZ_PUBLIC_IP_NAME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Bastion Host Service $SUIF_AZ_BASTION_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if Bastion Host exists already
    # ----------------------------------------------
   	$az_cmd_response = az network bastion show --name $SUIF_AZ_BASTION_NAME --subscription $H_AZ_SUBSCRIPTION_ID --resource-group $SUIF_AZ_RESOURCE_GROUP 2> $null
    If ((ConvertFrom-Json -InputObject "$az_cmd_response").id -ne $null) {
        Write-Host " - createBastionHostService :: Bastion $SUIF_AZ_BASTION_NAME already exists."
        exit 0
    }
    $az_cmd_response = az network bastion create --name $SUIF_AZ_BASTION_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --location $H_AZ_GEO_LOCATION `
       --vnet-name $SUIF_AZ_VNET_NAME `
       --public-ip-address $SUIF_AZ_PUBLIC_IP_NAME

    if (!$?) {
        Write-Host " - createBastionHostService :: Error - Unable to create Bastion host Service :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - createBastionHostService :: $SUIF_AZ_BASTION_NAME successfully created."
    exit 0

}

## ---------------------------------------------------------------------
## Create Subnet
## ---------------------------------------------------------------------
function createSubnet() {
    param (
        [string] $az_address_prefix
    )
    $LOC_ADDRESS_PREFIX = $az_address_prefix

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $SUIF_AZ_VNET_NAME = $suif_env.Get_Item('SUIF_AZ_VNET_NAME')
    $SUIF_AZ_NSG_NAME = $suif_env.Get_Item('SUIF_AZ_NSG_NAME')
    $SUIF_AZ_VM_SUBNET = $suif_env.Get_Item('SUIF_AZ_VM_SUBNET')

    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Subnet $SUIF_AZ_VM_SUBNET ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if Subnet exists already
    # ----------------------------------------------
   	$az_cmd_response = az network vnet subnet show --name $SUIF_AZ_VM_SUBNET --subscription $H_AZ_SUBSCRIPTION_ID --resource-group $SUIF_AZ_RESOURCE_GROUP --vnet-name $SUIF_AZ_VNET_NAME 2>&1 | out-null
    If ($?) {
        Write-Host " - createSubnet :: Subnet $SUIF_AZ_VM_SUBNET already exists."
        exit 0
    }
    $az_cmd_response = az network vnet subnet create --name $SUIF_AZ_VM_SUBNET `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --vnet-name $SUIF_AZ_VNET_NAME `
       --address-prefixes $LOC_ADDRESS_PREFIX `
       --network-security-group $SUIF_AZ_NSG_NAME

    if (!$?) {
        Write-Host " - createSubnet :: Error - Unable to create subnet :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - createSubnet :: $SUIF_AZ_VM_SUBNET successfully created."
    exit 0

}

## ---------------------------------------------------------------------
## Create Load Balancer
## ---------------------------------------------------------------------
function createLoadBalancer() {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_GEO_LOCATION = $suif_host_env.Get_Item('H_AZ_GEO_LOCATION')
    $SUIF_AZ_VNET_NAME = $suif_env.Get_Item('SUIF_AZ_VNET_NAME')
    $SUIF_AZ_VM_SUBNET = $suif_env.Get_Item('SUIF_AZ_VM_SUBNET')
    $SUIF_AZ_LOAD_BALANCER_NAME = $suif_env.Get_Item('SUIF_AZ_LOAD_BALANCER_NAME')
    $SUIF_AZ_LOAD_BALANCER_IP = $suif_env.Get_Item('SUIF_AZ_LOAD_BALANCER_IP')
    $SUIF_AZ_LOAD_BALANCER_IP_NAME = $suif_env.Get_Item('SUIF_AZ_LOAD_BALANCER_IP_NAME')
    $SUIF_AZ_LOAD_BALANCER_POOL = $suif_env.Get_Item('SUIF_AZ_LOAD_BALANCER_POOL')
    

    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Load Balancer $SUIF_AZ_LOAD_BALANCER_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if LB exists already
    # ----------------------------------------------
   	$az_cmd_response = az network lb show --name $SUIF_AZ_LOAD_BALANCER_NAME --subscription $H_AZ_SUBSCRIPTION_ID --resource-group $SUIF_AZ_RESOURCE_GROUP 2>&1 | out-null
    If ($?) {
        Write-Host " - createLoadBalancer :: Load Balancer $SUIF_AZ_LOAD_BALANCER_NAME already exists."
        exit 0
    }
    $az_cmd_response = az network lb create --name $SUIF_AZ_LOAD_BALANCER_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --location $H_AZ_GEO_LOCATION `
       --vnet-name $SUIF_AZ_VNET_NAME `
       --subnet $SUIF_AZ_VM_SUBNET `
       --sku Standard `
       --private-ip-address $SUIF_AZ_LOAD_BALANCER_IP `
       --frontend-ip-name $SUIF_AZ_LOAD_BALANCER_IP_NAME `
       --backend-pool-name $SUIF_AZ_LOAD_BALANCER_POOL

    if (!$?) {
        Write-Host " - createLoadBalancer :: Error - Unable to create load balancer :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - createLoadBalancer :: $SUIF_AZ_LOAD_BALANCER_NAME successfully created."
    exit 0

}

## ---------------------------------------------------------------------
## Create LB Probe
## ---------------------------------------------------------------------
function createLoadBalancerProbe() {
    param (
        [string] $az_vm_be_probe,
        [string] $az_vm_be_port
    )
    $LOC_LB_BACKEND_PROBE = $az_vm_be_probe
    $LOC_VM_PORT = $az_vm_be_port

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $SUIF_AZ_LOAD_BALANCER_NAME = $suif_env.Get_Item('SUIF_AZ_LOAD_BALANCER_NAME')
    
    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Load Balancer Probe $LOC_LB_BACKEND_PROBE ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if Probe exists already
    # ----------------------------------------------
   	$az_cmd_response = az network lb probe show --name $LOC_LB_BACKEND_PROBE --subscription $H_AZ_SUBSCRIPTION_ID --resource-group $SUIF_AZ_RESOURCE_GROUP --lb-name $SUIF_AZ_LOAD_BALANCER_NAME 2>&1 | out-null
    If ($?) {
        Write-Host " - createLoadBalancerProbe :: Load Balancer probe $LOC_LB_BACKEND_PROBE already exists."
        exit 0
    }
    $az_cmd_response = az network lb probe create --name $LOC_LB_BACKEND_PROBE `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --lb-name $SUIF_AZ_LOAD_BALANCER_NAME `
       --protocol Tcp `
       --port $LOC_VM_PORT `
       --interval 5 `
       --threshold 2
    if (!$?) {
        Write-Host " - createLoadBalancerProbe :: Error - Unable to create load balancer probe :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - createLoadBalancerProbe :: $LOC_LB_BACKEND_PROBE successfully created."
    exit 0
}

## ---------------------------------------------------------------------
## Add Back End VM to LB Address Pool
## ---------------------------------------------------------------------
function addBackEndToAddressPool() {
    param (
        [string] $az_vm_name
    )
    $LOC_VM_NAME = $az_vm_name
    $LOC_POOL_ADDRESS_NAME = "ADDRESS_" + $LOC_VM_NAME

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_GEO_LOCATION = $suif_host_env.Get_Item('H_AZ_GEO_LOCATION')
    $SUIF_AZ_VNET_NAME = $suif_env.Get_Item('SUIF_AZ_VNET_NAME')
    $SUIF_AZ_VM_SUBNET = $suif_env.Get_Item('SUIF_AZ_VM_SUBNET')
    $SUIF_AZ_LOAD_BALANCER_NAME = $suif_env.Get_Item('SUIF_AZ_LOAD_BALANCER_NAME')
    $SUIF_AZ_LOAD_BALANCER_POOL = $suif_env.Get_Item('SUIF_AZ_LOAD_BALANCER_POOL')

    Write-Host "-------------------------------------------------------"
    Write-Host " Adding Private IP to LB Address Pool $SUIF_AZ_LOAD_BALANCER_POOL ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Get private IP from VM
    # ----------------------------------------------
    Write-Host " - addBackEndToAddressPool :: Getting private IP for $LOC_VM_NAME"
   	$LOC_PRIVATE_IP = az vm show -d --resource-group $SUIF_AZ_RESOURCE_GROUP --name $LOC_VM_NAME --query privateIps -o tsv
    if (!$?) {
        Write-Host " - addBackEndToAddressPool :: Unable to detect private IP for $LOC_VM_NAME"
        exit -1
    }
    Write-Host " - addBackEndToAddressPool :: Private IP $LOC_VM_NAME identified :: $LOC_PRIVATE_IP"
    # ----------------------------------------------
    # Check if Address exists already
    # ----------------------------------------------
   	$az_cmd_response = az network lb address-pool address list `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --pool-name $SUIF_AZ_LOAD_BALANCER_POOL `
       --lb-name $SUIF_AZ_LOAD_BALANCER_NAME `
       --query [].name | ConvertFrom-Json
    If ($az_cmd_response -Contains $LOC_POOL_ADDRESS_NAME) {
        Write-Host " - addBackEndToAddressPool :: Address in backend pool already exists."
        exit 0
    }

    $az_cmd_response = az network lb address-pool address add --name $LOC_POOL_ADDRESS_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --lb-name $SUIF_AZ_LOAD_BALANCER_NAME `
       --vnet $SUIF_AZ_VNET_NAME `
       --subnet $SUIF_AZ_VM_SUBNET `
       --pool-name $SUIF_AZ_LOAD_BALANCER_POOL `
       --ip-address $LOC_PRIVATE_IP

    if (!$?) {
        Write-Host " - addBackEndToAddressPool :: Error - Unable to add address to pool :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - addBackEndToAddressPool :: $LOC_ADDRESS successfully added to backend pool."
    exit 0
}

## ---------------------------------------------------------------------
## Create LB Rule
## ---------------------------------------------------------------------
function createLoadBalancerRule() {
    param (
        [string] $az_vm_rule_name,
        [string] $az_vm_fe_port,
        [string] $az_vm_be_port,
        [string] $az_vm_be_probe
    )
    $LOC_LB_RULE_NAME = $az_vm_rule_name
    $LOC_LB_FRONTEND_PORT = $az_vm_fe_port
    $LOC_LB_BACKEND_PORT = $az_vm_be_port
    $LOC_LB_BACKEND_PROBE = $az_vm_be_probe

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $SUIF_AZ_LOAD_BALANCER_NAME = $suif_env.Get_Item('SUIF_AZ_LOAD_BALANCER_NAME')
    $SUIF_AZ_LOAD_BALANCER_IP_NAME = $suif_env.Get_Item('SUIF_AZ_LOAD_BALANCER_IP_NAME')
    $SUIF_AZ_LOAD_BALANCER_POOL = $suif_env.Get_Item('SUIF_AZ_LOAD_BALANCER_POOL')
    $SUIF_AZ_LOAD_BALANCER_PROBE = $suif_env.Get_Item('SUIF_AZ_LOAD_BALANCER_PROBE')
    
    Write-Host "-------------------------------------------------------"
    Write-Host " Creating Load Balancer Rule $LOC_LB_RULE_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if Rule exists already
    # ----------------------------------------------
   	$az_cmd_response = az network lb rule show --name $LOC_LB_RULE_NAME --subscription $H_AZ_SUBSCRIPTION_ID --resource-group $SUIF_AZ_RESOURCE_GROUP --lb-name $SUIF_AZ_LOAD_BALANCER_NAME 2>&1 | out-null
    If ($?) {
        Write-Host " - createLoadBalancerRule :: Load Balancer Rule $LOC_LB_RULE_NAME already exists."
        exit 0
    }
    $az_cmd_response = az network lb rule create --name $LOC_LB_RULE_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --lb-name $SUIF_AZ_LOAD_BALANCER_NAME `
       --frontend-ip-name $SUIF_AZ_LOAD_BALANCER_IP_NAME `
       --backend-pool-name $SUIF_AZ_LOAD_BALANCER_POOL `
       --frontend-port $LOC_LB_FRONTEND_PORT `
       --backend-port $LOC_LB_BACKEND_PORT `
       --protocol Tcp `
       --load-distribution Default `
       --probe-name $LOC_LB_BACKEND_PROBE

    if (!$?) {
        Write-Host " - createLoadBalancerRule :: Error - Unable to create load balancer rule :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - createLoadBalancerRule :: $LOC_LB_RULE_NAME successfully created."
    exit 0
}

## ---------------------------------------------------------------------
## Provision VM under Bastion Service 
## ---------------------------------------------------------------------
function provisionVMforBastion() {
    param (
        [string] $az_vm_name,
        [string] $az_host_name,
        [string] $az_image_handle,
        [string] $az_size_handle,
        [string] $az_job_wait
    )
    $LOC_VM_NAME = $az_vm_name
    $LOC_HOST_NAME = $az_host_name
    $LOC_WAIT = $az_job_wait

    # ----------------------------------------------
    # Get values from either .env or suif.env
    # ----------------------------------------------
    if ($az_image_handle.StartsWith('H_')) {
        $LOC_AZ_VM_IMAGE = $suif_host_env.Get_Item($az_image_handle)
    } else{
        $LOC_AZ_VM_IMAGE = $suif_env.Get_Item($az_image_handle)
    }
    if ($az_size_handle.StartsWith('H_')) {
        $LOC_AZ_VM_SIZE = $suif_host_env.Get_Item($az_size_handle)
    } else{
        $LOC_AZ_VM_SIZE = $suif_env.Get_Item($az_size_handle)
    }

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $H_AZ_GEO_LOCATION = $suif_host_env.Get_Item('H_AZ_GEO_LOCATION')
    $SUIF_AZ_VNET_NAME = $suif_env.Get_Item('SUIF_AZ_VNET_NAME')
    $SUIF_AZ_ASG_NAME = $suif_env.Get_Item('SUIF_AZ_ASG_NAME')
    $SUIF_AZ_NSG_NAME = $suif_env.Get_Item('SUIF_AZ_NSG_NAME')
    $SUIF_AZ_VM_SUBNET = $suif_env.Get_Item('SUIF_AZ_VM_SUBNET')

    $SUIF_AZ_VM_USER = $suif_env.Get_Item('SUIF_AZ_VM_USER')
    $LOC_AZ_VM_USER_PASSWORD = $suif_host_env.Get_Item('H_APIGW_ADMIN_PASSWORD')

    Write-Host "-------------------------------------------------------"
    Write-Host " Provisioning VM $LOC_VM_NAME (hostname: $LOC_HOST_NAME) ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if VM exists already
    # ----------------------------------------------
   	$az_cmd_response = az vm show -g $SUIF_AZ_RESOURCE_GROUP -n $LOC_VM_NAME ` 2>&1 | out-null
    if ($?) {
        Write-Host " - provisionVMforBastion :: VM $LOC_VM_NAME already exists."
        exit 0
    }
    If ($LOC_WAIT -eq $false) {
        $az_cmd_response = az vm create --name $LOC_VM_NAME `
        --subscription $H_AZ_SUBSCRIPTION_ID `
        --resource-group $SUIF_AZ_RESOURCE_GROUP `
        --location $H_AZ_GEO_LOCATION `
        --image $LOC_AZ_VM_IMAGE `
        --size $LOC_AZ_VM_SIZE `
        --admin-username $SUIF_AZ_VM_USER `
        --admin-password $LOC_AZ_VM_USER_PASSWORD `
        --vnet-name $SUIF_AZ_VNET_NAME `
        --asgs $SUIF_AZ_ASG_NAME `
        --nsg $SUIF_AZ_NSG_NAME `
        --nsg-rule NONE `
        --subnet $SUIF_AZ_VM_SUBNET `
        --computer-name $LOC_HOST_NAME `
        --public-ip-address '""' `
        --no-wait
    } else {
        $az_cmd_response = az vm create --name $LOC_VM_NAME `
        --subscription $H_AZ_SUBSCRIPTION_ID `
        --resource-group $SUIF_AZ_RESOURCE_GROUP `
        --location $H_AZ_GEO_LOCATION `
        --image $LOC_AZ_VM_IMAGE `
        --size $LOC_AZ_VM_SIZE `
        --admin-username $SUIF_AZ_VM_USER `
        --admin-password $LOC_AZ_VM_USER_PASSWORD `
        --vnet-name $SUIF_AZ_VNET_NAME `
        --asgs $SUIF_AZ_ASG_NAME `
        --nsg $SUIF_AZ_NSG_NAME `
        --nsg-rule NONE `
        --subnet $SUIF_AZ_VM_SUBNET `
        --computer-name $LOC_HOST_NAME `
        --public-ip-address '""'
    }

    if (!$?) {
        Write-Host " - provisionVMforBastion :: Error - Unable to provision VM :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - provisionVMforBastion :: $LOC_VM_NAME successfully provisioned."
    exit 0

}

## ---------------------------------------------------------------------
## Grant Key Vault Access Permission for VM
## ---------------------------------------------------------------------
function grantKeyVaultPermission() {
    param (
        [string] $az_vm_name
    )
    $LOC_VM_NAME = $az_vm_name

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $SUIF_AZ_KEYVAULT_NAME = $suif_env.Get_Item('SUIF_AZ_KEYVAULT_NAME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Granting Permissions for $LOC_VM_NAME to Key Vault $SUIF_AZ_KEYVAULT_NAME...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Create identity if not already exists
    # ----------------------------------------------
   	$az_cmd_response = az vm identity show --name $LOC_VM_NAME --subscription $H_AZ_SUBSCRIPTION_ID --resource-group $SUIF_AZ_RESOURCE_GROUP
    If ((ConvertFrom-Json -InputObject "$az_cmd_response").principalId -ne $null) {
        Write-Host " - grantKeyVaultPermission :: Identity Key for $LOC_VM_NAME already exists (no need to create)."
        $LOC_IDENTITY_KEY = (ConvertFrom-Json -InputObject "$az_cmd_response").principalId
    } else {
        Write-Host " - grantKeyVaultPermission :: Creating new VM Identity Key for $LOC_VM_NAME..."
        $az_cmd_response = az vm identity assign --name $LOC_VM_NAME --subscription $H_AZ_SUBSCRIPTION_ID --resource-group $SUIF_AZ_RESOURCE_GROUP
        if (!$?) {
            Write-Host " - grantKeyVaultPermission :: Error - Unable to create identity :: $az_cmd_response"
            exit -1
        } else {
            $LOC_IDENTITY_KEY = (ConvertFrom-Json -InputObject "$az_cmd_response").systemAssignedIdentity
        }
    }
    Write-Host " - grantKeyVaultPermission :: Identity Key for $LOC_VM_NAME :: $LOC_IDENTITY_KEY"

    # ----------------------------------------------
    # Add Permissions to Key Vault
    # ----------------------------------------------
    Write-Host " - grantKeyVaultPermission :: Setting Permissions for VM in Key Vault....."
    $az_cmd_response = az keyvault set-policy --name $SUIF_AZ_KEYVAULT_NAME `
      --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $SUIF_AZ_RESOURCE_GROUP `
      --object-id $LOC_IDENTITY_KEY `
      --secret-permissions get list

    if (!$?) {
        Write-Host " - grantKeyVaultPermission :: Error - Unable to set Key Vault Permissions :: $az_cmd_response"
        exit -1
    } 
    Write-Host " - grantKeyVaultPermission :: $LOC_VM_NAME successfully given Key Vault permissions."
    exit 0

}

## ---------------------------------------------------------------------
## Run init prepare script on remote VM (using CLI)
## ---------------------------------------------------------------------
function initializeVM() {
    param (
        [string] $az_vm_name,
        [string] $az_host_name
    )
    $LOC_VM_NAME = $az_vm_name
    $LOC_HOST_NAME = $az_host_name

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
    # Get the storage location
    # ----------------------------------------------
   	$az_cmd_response = az storage account show `
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
       --scripts '@.\scripts\vm_init.sh'

    if (!$?) {
        Write-Host " - initializeVM :: Unable to initialize VM :: $az_cmd"
        exit -1
    }
    Write-Host " - initializeVM :: VM successfully initialized - started installations and setup configurations in the background..."
    exit 0

}
