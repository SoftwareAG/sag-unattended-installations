
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
    $H_AZ_RESOURCE_GROUP = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP')
    $H_AZ_STORAGE_ACCOUNT = $suif_host_env.Get_Item('H_AZ_STORAGE_ACCOUNT')
    $SUIF_AZ_VOLUME_ASSETS = $suif_env.Get_Item($az_volume_handle)
    Write-Host "-------------------------------------------------------"
    Write-Host " Create Azure Volume ...."
    Write-Host "-------------------------------------------------------"
    $az_cmd_response = az storage share-rm exists `
      --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $H_AZ_RESOURCE_GROUP `
      --storage-account $H_AZ_STORAGE_ACCOUNT `
      --name $SUIF_AZ_VOLUME_ASSETS
    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $true) {
        Write-Host " - createVolume :: Volume $SUIF_AZ_VOLUME_ASSETS already Exists"
        exit 0
    }
    Write-Host " - createVolume :: Creating new Volume: $SUIF_AZ_VOLUME_ASSETS ...."
    $az_cmd_response = az storage share-rm create `
      --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $H_AZ_RESOURCE_GROUP `
      --storage-account $H_AZ_STORAGE_ACCOUNT `
      --name $SUIF_AZ_VOLUME_ASSETS `
      --quota 256 `
      --enabled-protocols SMB
    if ($?) {
        exit 0
    } else {
        Write-Host " - createVolume :: Error creating volume : $az_cmd_response"
        exit -1
    }
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
    $H_AZ_RESOURCE_GROUP = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP')
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
      --resource-group $H_AZ_RESOURCE_GROUP `
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
    Write-Host " - createDirectory :: Directory does not exist: creating directory $LOC_AZ_DIR on volume: $LOC_AZ_VOLUME ..."
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
    $H_AZ_RESOURCE_GROUP = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP')
    $H_AZ_STORAGE_ACCOUNT = $suif_host_env.Get_Item('H_AZ_STORAGE_ACCOUNT')
    $LOC_AZ_VOLUME = $suif_env.Get_Item($az_volume_handle)
    $LOC_AZ_DIR = $suif_env.Get_Item($az_dir_handle)
    $LOC_AZ_LOCAL_FILE = $suif_host_env.Get_Item($az_local_file_handle)
    $LOC_AZ_PATH = $suif_env.Get_Item($az_target_path_handle)

    Write-Host "-------------------------------------------------------"
    Write-Host " Uploading single file to Azure target file system ...."
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
      --resource-group $H_AZ_RESOURCE_GROUP `
	  --account-name $H_AZ_STORAGE_ACCOUNT
    if (!$?) {
        Write-Host " - File Upload :: Unable to get the Storage Key :: $az_cmd_response"
        exit -1
    }
    $LOC_AZ_STORAGE_ACCOUNT_KEY = (ConvertFrom-Json -InputObject "$az_cmd_response")[0].value
    # Write-Host " - File Upload :: Storage key identified: $LOC_AZ_STORAGE_ACCOUNT_KEY"

    # ----------------------------------------------
    # Check if directory exists
    # ----------------------------------------------
   	$az_cmd_response = az storage directory exists --name $LOC_AZ_DIR `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
	  --account-name $H_AZ_STORAGE_ACCOUNT `
      --account-key $LOC_AZ_STORAGE_ACCOUNT_KEY `
      --share-name $LOC_AZ_VOLUME
    if (!$?) {
        Write-Host " - File Upload :: Unable to check if directory exists :: $az_cmd_response"
        exit -1
    }

    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $false) {
        Write-Host " - File Upload: Directory $LOC_AZ_DIR on volume $AZ_VOLUME does not exist... exiting"
        exit -1
    } else {
        Write-Host " - File Upload: Directory $LOC_AZ_DIR on volume $AZ_VOLUME exists..."
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
        Write-Host " - File Upload :: Unable to check if file exists :: $az_cmd_response"
        exit -1
    }

    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $true) {
        Write-Host " - File Upload: File $LOC_AZ_PATH on volume $LOC_AZ_VOLUME already exists."
        exit 0
    }
    # ----------------------------------------------
    # Upload ....
    # ----------------------------------------------
    Write-Host " - File Upload: File $LOC_AZ_PATH on volume $LOC_AZ_VOLUME does not exist: uploading ...."
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
        [string] $az_ver_dir_handle
    )
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $H_AZ_RESOURCE_GROUP = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP')
    $H_AZ_STORAGE_ACCOUNT = $suif_host_env.Get_Item('H_AZ_STORAGE_ACCOUNT')
    $LOC_AZ_VOLUME = $suif_env.Get_Item($az_volume_handle)
    $LOC_AZ_DIR = $suif_env.Get_Item($az_dir_handle)
    $LOC_AZ_SOURCE = $az_source_handle
    $LOC_AZ_VERIF_DIR = $suif_env.Get_Item($az_ver_dir_handle)

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
      --resource-group $H_AZ_RESOURCE_GROUP `
	  --account-name $H_AZ_STORAGE_ACCOUNT
    if (!$?) {
        Write-Host " - Files Upload :: Unable to get the Storage Key :: $az_cmd_response"
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
        Write-Host " - Files Upload :: Error - Unable to check if directory exists : $az_cmd_response"
        exit -1
    }

    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $false) {
        Write-Host " - Files Upload :: Directory $LOC_AZ_DIR on volume $LOC_AZ_VOLUME does not exist... exiting"
        exit -1
    } else {
        Write-Host " - Files Upload :: Directory $LOC_AZ_DIR on volume $LOC_AZ_VOLUME exists..."
    }

    # -------------------------------------------------------------
    # Check if a "verification directory" exist - if so, do not upload
    # -------------------------------------------------------------
   	$az_cmd_response = az storage directory exists --name $LOC_AZ_VERIF_DIR `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
	  --account-name $H_AZ_STORAGE_ACCOUNT `
      --account-key $LOC_AZ_STORAGE_ACCOUNT_KEY `
      --share-name $LOC_AZ_VOLUME
    if (!$?) {
        Write-Host " - Files Upload :: Error - Unable to check if $LOC_AZ_VERIF_DIR directory exists : $az_cmd_response"
        exit -1
    }

    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $true) {
        Write-Host " - Files Upload :: Directory $LOC_AZ_VERIF_DIR on volume $LOC_AZ_VOLUME already exists... skipping upload."
        exit 0
    }

    # ----------------------------------------------
    # Upload Batch
    # ----------------------------------------------
   	$az_cmd_response = az storage file upload-batch --destination $LOC_AZ_VOLUME `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
	  --account-name $H_AZ_STORAGE_ACCOUNT `
      --account-key $LOC_AZ_STORAGE_ACCOUNT_KEY `
      --source "$LOC_AZ_SOURCE" `
      --destination-path "$LOC_AZ_DIR"
    if (!$?) {
        Write-Host " - Files Upload :: Error - Unable to upload :: $az_cmd_response"
        exit -1
    } else {
        Write-Host " - Files Upload :: Transfer ok .."
        exit 0
    }

}

## ---------------------------------------------------------------------
## Provision a VM
## ---------------------------------------------------------------------
function provisionVM() {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $H_AZ_RESOURCE_GROUP = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP')
    $H_AZ_STORAGE_ACCOUNT = $suif_host_env.Get_Item('H_AZ_STORAGE_ACCOUNT')
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
   	$az_cmd_response = az vm show -g $H_AZ_RESOURCE_GROUP -n $SUIF_AZ_VM_NAME ` 2>&1 | out-null
    if ($?) {
        Write-Host " - provisionVM :: VM $SUIF_AZ_VM_NAME already exists."
        exit 0
    }
    # ----------------------------------------------
    # Deploy new VM
    # ----------------------------------------------
   	$az_cmd_response = az vm create --name $SUIF_AZ_VM_NAME `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $H_AZ_RESOURCE_GROUP `
      --image $H_AZ_VM_IMAGE `
      --admin-username $SUIF_AZ_VM_USER `
      --size $H_AZ_VM_SIZE `
      --generate-ssh-keys
    if ($?) {
        Write-Host " - provisionVM :: VM successful created."
    } else {
        Write-Host " - provisionVM :: Unable to provision VM :: $az_cmd_response"
        exit -1
    }
}

## ---------------------------------------------------------------------
## Prepare VM
## ---------------------------------------------------------------------
function prepareVM() {
    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $H_AZ_RESOURCE_GROUP = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP')
    $H_AZ_STORAGE_ACCOUNT = $suif_host_env.Get_Item('H_AZ_STORAGE_ACCOUNT')
    $H_AZ_VM_IMAGE = $suif_host_env.Get_Item('H_AZ_VM_IMAGE')
    $H_AZ_VM_SIZE = $suif_host_env.Get_Item('H_AZ_VM_SIZE')
    
    $SUIF_AZ_VM_NAME = $suif_env.Get_Item('SUIF_AZ_VM_NAME')
    $SUIF_AZ_VM_USER = $suif_env.Get_Item('SUIF_AZ_VM_USER')
    $SUIF_AZ_DIR_ASSETS = $suif_env.Get_Item('SUIF_AZ_DIR_ASSETS')
    $SUIF_AZ_VOLUME_ASSETS = $suif_env.Get_Item('SUIF_AZ_VOLUME_ASSETS')

    $SUIF_APP_HOME = $suif_env.Get_Item('SUIF_APP_HOME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Preparing the VM $SUIF_AZ_VM_NAME on Azure ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Get Public IP
    # ----------------------------------------------
   	$LOC_AZ_PUBLIC_IP = az vm show -d -g $H_AZ_RESOURCE_GROUP -n $SUIF_AZ_VM_NAME --query publicIps -o tsv 
    if (!$?) {
        Write-Host " - prepareVM :: Unable to get public IP for VM $SUIF_AZ_VM_NAME. Exiting ..."
        exit -1
    }
    Write-Host " - prepareVM :: Public IP for VM identified: $LOC_AZ_PUBLIC_IP ..."
    
    # ----------------------------------------------
    # Test if VM has already been prepared
    # ----------------------------------------------
   	$az_cmd_assets = ssh $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP "ls $SUIF_AZ_DIR_ASSETS"
    if ($?) {
        Write-Host " - prepareVM :: VM has already been prepared for processing. Exiting ..."
        exit 0
    }

    # ----------------------------------------------
    # Get the storage key
    # ----------------------------------------------
   	$az_cmd_response = az storage account keys list `
	  --subscription $H_AZ_SUBSCRIPTION_ID `
      --resource-group $H_AZ_RESOURCE_GROUP `
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
      --resource-group $H_AZ_RESOURCE_GROUP `
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
   	ssh -o "StrictHostKeyChecking no" $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP `
       "sudo yum -y install cifs-utils; `
        sudo mkdir -p $SUIF_AZ_DIR_ASSETS $SUIF_APP_HOME; `
        sudo chown -R '$SUIF_AZ_VM_USER':'$SUIF_AZ_VM_USER' $SUIF_AZ_DIR_ASSETS; `
        sudo chown -R '$SUIF_AZ_VM_USER':'$SUIF_AZ_VM_USER' $SUIF_APP_HOME; `
        sudo mount -t cifs '$LOC_AZ_STORAGE_LOCATION''$SUIF_AZ_VOLUME_ASSETS''$SUIF_AZ_DIR_ASSETS' '$SUIF_AZ_DIR_ASSETS' -o username=$H_AZ_STORAGE_ACCOUNT,password=$LOC_AZ_STORAGE_ACCOUNT_KEY,uid=1000,gid=1000,serverino"

    if ($?) {
        Write-Host " - prepareVM :: VM successfully prepared."
        exit 0
    } else {
        Write-Host " - prepareVM :: Unable to prepare VM :: Exiting."
        exit -1
    }
}

## ---------------------------------------------------------------------
## Run entrypoint script to provision 
## TODO track return codes
## ---------------------------------------------------------------------
function entryPointVM() {
    $H_AZ_RESOURCE_GROUP = $suif_host_env.Get_Item('H_AZ_RESOURCE_GROUP')
    $SUIF_AZ_VM_NAME = $suif_env.Get_Item('SUIF_AZ_VM_NAME')
    $SUIF_AZ_VM_USER = $suif_env.Get_Item('SUIF_AZ_VM_USER')
    $SUIF_LOCAL_SCRIPTS_HOME = $suif_env.Get_Item('SUIF_LOCAL_SCRIPTS_HOME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Starting Application on Azure $SUIF_AZ_VM_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Get Public IP
    # ----------------------------------------------
   	$LOC_AZ_PUBLIC_IP = az vm show -d -g $H_AZ_RESOURCE_GROUP -n $SUIF_AZ_VM_NAME --query publicIps -o tsv 
    if (!$?) {
        Write-Host " - prepareVM :: Unable to get public IP for VM $SUIF_AZ_VM_NAME. Exiting ..."
        exit -1
    }
    Write-Host " - prepareVM :: Public IP for VM identified: $LOC_AZ_PUBLIC_IP ..."
    
    ssh -o "StrictHostKeyChecking no" $SUIF_AZ_VM_USER@$LOC_AZ_PUBLIC_IP $SUIF_LOCAL_SCRIPTS_HOME/entryPoint.sh
    if (!$?) {
        Write-Host " - entryPointVM :: entryPoint.sh Script completed with errors. Exiting ..."
        exit -1
    }
    Write-Host " - entryPointVM :: entryPoint.sh Script completed successfully."
    Write-Host " ----------------------------------------------------------------"
    Write-Host " - Access TMS via :: http://$LOC_AZ_PUBLIC_IP:9889/tmc"
    Write-Host " ----------------------------------------------------------------"

    exit 0
}
