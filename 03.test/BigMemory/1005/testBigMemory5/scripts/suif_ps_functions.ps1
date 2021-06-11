
## ---------------------------------------------------------------------
## Source the .env variables (always)
## ---------------------------------------------------------------------
Get-Content ".env" | foreach-object -begin {$suif_env=@{}} -process {
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
## Create ACI Context (if it doesn't already exist)
## ---------------------------------------------------------------------
function createContext() {
    $AZ_CTXT = $suif_env.Get_Item('AZ_ACI_CONTEXT_NAME')
    Write-Host "-------------------------------------------------------"
    Write-Host " Create Docker ACI Context ...."
    Write-Host "-------------------------------------------------------"
    docker context inspect $AZ_CTXT 2>&1 | out-null
    if ($?) {
        Write-Host " - createContext :: Context $AZ_CTXT already Exists"
        exit 0
    } else {
        Write-Host " - createContext :: Creating new Context: $AZ_CTXT ...."
        $docker_cmd_response = docker context create aci $AZ_CTXT `
            --subscription-id $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
            --resource-group $suif_env.Get_Item('AZ_RESOURCE_GROUP') `
            --location "$suif_env.Get_Item('AZ_GEO_LOCATION')"
        # Check return code from docker operation
        if ($?) {
            exit 0
        } else {
            Write-Host " - createContext :: Error creating Context : $docker_cmd_response"
            exit -1
        }
    }
}

## ---------------------------------------------------------------------
## Create Volumes
## ---------------------------------------------------------------------
function createVolume($az_volume_handle) {
    $AZ_VOLUME = $suif_env.Get_Item($az_volume_handle)
    $AZ_STORAGE_ACCOUNT = $suif_env.Get_Item('AZ_STORAGE_ACCOUNT')
    Write-Host "-------------------------------------------------------"
    Write-Host " Create Azure Volume ...."
    Write-Host "-------------------------------------------------------"
    $az_cmd_response = az storage share-rm exists `
            --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
            --resource-group $suif_env.Get_Item('AZ_RESOURCE_GROUP') `
            --storage-account $AZ_STORAGE_ACCOUNT `
            --name $AZ_VOLUME
    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $true) {
        Write-Host " - createVolume :: Volume $AZ_VOLUME already Exists"
        exit 0
    }
    Write-Host " - createVolume :: Creating new Volume: $AZ_VOLUME ...."
    $az_cmd_response = az storage share-rm create `
        --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
        --resource-group $suif_env.Get_Item('AZ_RESOURCE_GROUP') `
        --storage-account $AZ_STORAGE_ACCOUNT `
        --name $AZ_VOLUME `
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
    $AZ_VOLUME = $suif_env.Get_Item($az_volume_handle)
    $AZ_DIR = $suif_env.Get_Item($az_dir_handle)

    Write-Host "-------------------------------------------------------"
    Write-Host " Create Azure FS Directory ...."
    Write-Host "-------------------------------------------------------"

    # ----------------------------------------------
    # Remove leading "/" character from file path
    # ----------------------------------------------
    $AZ_DIR = $AZ_DIR.TrimStart("/"," ")

    # ----------------------------------------------
    # Get the storage key
    # ----------------------------------------------
   	$az_cmd_response = az storage account keys list `
	  --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
      --resource-group $suif_env.Get_Item('AZ_RESOURCE_GROUP') `
	  --account-name $suif_env.Get_Item('AZ_STORAGE_ACCOUNT')
    if (!$?) {
        Write-Host " - createDirectory :: Unable to get the Storage Key :: $az_cmd_response"
        exit -1
    }
    $AZ_STORAGE_ACCOUNT_KEY = (ConvertFrom-Json -InputObject "$az_cmd_response")[0].value

    # ----------------------------------------------
    # Check if directory exists
    # ----------------------------------------------
   	$az_cmd_response = az storage directory exists --name $AZ_DIR `
        --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
        --account-name $suif_env.Get_Item('AZ_STORAGE_ACCOUNT') `
        --account-key $AZ_STORAGE_ACCOUNT_KEY `
        --share-name $AZ_VOLUME
    if (!$?) {
        Write-Host " - createDirectory :: Unable to check if directory exists :: $az_cmd_response"
        exit -1
    }
    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $true) {
        Write-Host " - createDirectory :: Directory $AZ_DIR already exists..."
        exit 0
    }
    # ----------------------------------------------
    # Create Directory
    # ----------------------------------------------
    Write-Host " - createDirectory :: Directory does not exist: creating directory $AZ_DIR on volume: $AZ_VOLUME ..."
    $az_cmd_response = az storage directory create --name $AZ_DIR `
        --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
        --account-name $suif_env.Get_Item('AZ_STORAGE_ACCOUNT') `
        --account-key $AZ_STORAGE_ACCOUNT_KEY `
        --share-name $AZ_VOLUME
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
    $AZ_VOLUME = $suif_env.Get_Item($az_volume_handle)
    $AZ_DIR = $suif_env.Get_Item($az_dir_handle)
    $AZ_LOCAL_FILE = $suif_env.Get_Item($az_local_file_handle)
    $AZ_PATH = $suif_env.Get_Item($az_target_path_handle)

    Write-Host "-------------------------------------------------------"
    Write-Host " Uploading single file to Azure target file system ...."
    Write-Host "-------------------------------------------------------"

    # ----------------------------------------------
    # Remove leading "/" character from file path
    # ----------------------------------------------
    $AZ_DIR = $AZ_DIR.TrimStart("/"," ")
    $AZ_PATH = $AZ_PATH.TrimStart("/"," ")

    # ----------------------------------------------
    # Get the storage key
    # ----------------------------------------------
   	$az_cmd_response = az storage account keys list `
	  --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
      --resource-group $suif_env.Get_Item('AZ_RESOURCE_GROUP') `
	  --account-name $suif_env.Get_Item('AZ_STORAGE_ACCOUNT')
    if (!$?) {
        Write-Host " - File Upload :: Unable to get the Storage Key :: $az_cmd_response"
        exit -1
    }
    $AZ_STORAGE_ACCOUNT_KEY = (ConvertFrom-Json -InputObject "$az_cmd_response")[0].value
    # Write-Host " - File Upload :: Storage key identified: $AZ_STORAGE_ACCOUNT_KEY"

    # ----------------------------------------------
    # Check if directory exists
    # ----------------------------------------------
   	$az_cmd_response = az storage directory exists --name $AZ_DIR `
        --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
        --account-name $suif_env.Get_Item('AZ_STORAGE_ACCOUNT') `
        --account-key $AZ_STORAGE_ACCOUNT_KEY `
        --share-name $AZ_VOLUME
    if (!$?) {
        Write-Host " - File Upload :: Unable to check if directory exists :: $az_cmd_response"
        exit -1
    }

    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $false) {
        Write-Host " - File Upload: Directory $AZ_DIR on volume $AZ_VOLUME does not exist... exiting"
        exit -1
    } else {
        Write-Host " - File Upload: Directory $AZ_DIR on volume $AZ_VOLUME exists..."
    }

    # ----------------------------------------------
    # Check if file exists
    # ----------------------------------------------
   	$az_cmd_response = az storage file exists --path $AZ_PATH `
        --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
        --account-name $suif_env.Get_Item('AZ_STORAGE_ACCOUNT') `
        --account-key $AZ_STORAGE_ACCOUNT_KEY `
        --share-name $AZ_VOLUME
    if (!$?) {
        Write-Host " - File Upload :: Unable to check if file exists :: $az_cmd_response"
        exit -1
    }

    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $true) {
        Write-Host " - File Upload: File $AZ_PATH on volume $AZ_VOLUME already exists."
        exit 0
    }
    # ----------------------------------------------
    # Upload ....
    # ----------------------------------------------
    Write-Host " - File Upload: File $AZ_PATH on volume $AZ_VOLUME does not exist: uploading ...."
    $az_cmd_response = az storage file upload --path $AZ_PATH `
        --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
        --account-name $suif_env.Get_Item('AZ_STORAGE_ACCOUNT') `
        --account-key $AZ_STORAGE_ACCOUNT_KEY `
        --share-name $AZ_VOLUME `
        --source "$AZ_LOCAL_FILE"
    if (!$?) {
        Write-Host " - File Upload :: Unable to upload file :: $az_cmd_response"
        exit -1
    }

}
## ---------------------------------------------------------------------
## Upload multiple files to target (if it doesn't exist)
## ---------------------------------------------------------------------
function uploadFiles() {
    param (
        [string] $az_volume_handle,
        [string] $az_dir_handle,
        [string] $az_source_handle,
        [string] $az_ver_dir_handle
    )
    $AZ_VOLUME = $suif_env.Get_Item($az_volume_handle)
    $AZ_DIR = $suif_env.Get_Item($az_dir_handle)
    $AZ_SOURCE = $az_source_handle
    $AZ_VERIF_DIR = $suif_env.Get_Item($az_ver_dir_handle)

    Write-Host "-------------------------------------------------------"
    Write-Host " Uploading files to Azure target file system ...."
    Write-Host "-------------------------------------------------------"

    # ----------------------------------------------
    # Remove leading "/" character from file path
    # ----------------------------------------------
    $AZ_DIR = $AZ_DIR.TrimStart("/"," ")
    $AZ_VERIF_DIR = $AZ_VERIF_DIR.TrimStart("/"," ")

    # ----------------------------------------------
    # Get the storage key
    # ----------------------------------------------
   	$az_cmd_response = az storage account keys list `
	  --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
      --resource-group $suif_env.Get_Item('AZ_RESOURCE_GROUP') `
	  --account-name $suif_env.Get_Item('AZ_STORAGE_ACCOUNT')
    if (!$?) {
        Write-Host " - Files Upload :: Unable to get the Storage Key :: $az_cmd_response"
        exit -1
    }
    $AZ_STORAGE_ACCOUNT_KEY = (ConvertFrom-Json -InputObject "$az_cmd_response")[0].value
    # Write-Host " - Files Upload :: Storage key identified: $AZ_STORAGE_ACCOUNT_KEY"

    # ----------------------------------------------
    # Check if target directory exists
    # ----------------------------------------------
   	$az_cmd_response = az storage directory exists --name $AZ_DIR `
        --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
        --account-name $suif_env.Get_Item('AZ_STORAGE_ACCOUNT') `
        --account-key $AZ_STORAGE_ACCOUNT_KEY `
        --share-name $AZ_VOLUME
    if (!$?) {
        Write-Host " - Files Upload :: Error - Unable to check if directory exists : $az_cmd_response"
        exit -1
    }

    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $false) {
        Write-Host " - Files Upload :: Directory $AZ_DIR on volume $AZ_VOLUME does not exist... exiting"
        exit -1
    } else {
        Write-Host " - Files Upload :: Directory $AZ_DIR on volume $AZ_VOLUME exists..."
    }

    # ----------------------------------------------
    # Check if a "verification directory" exist - if so, do not upload
    # ----------------------------------------------
   	$az_cmd_response = az storage directory exists --name $AZ_VERIF_DIR `
        --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
        --account-name $suif_env.Get_Item('AZ_STORAGE_ACCOUNT') `
        --account-key $AZ_STORAGE_ACCOUNT_KEY `
        --share-name $AZ_VOLUME
    if (!$?) {
        Write-Host " - Files Upload :: Error - Unable to check if $AZ_VERIF_DIR directory exists : $az_cmd_response"
        exit -1
    }

    If ((ConvertFrom-Json -InputObject "$az_cmd_response").exists -eq $true) {
        Write-Host " - Files Upload :: Directory $AZ_VERIF_DIR on volume $AZ_VOLUME already exists... skipping upload."
        exit 0
    }

    # ----------------------------------------------
    # Upload Batch
    # ----------------------------------------------
   	$az_cmd_response = az storage file upload-batch --destination $AZ_VOLUME `
        --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
        --account-name $suif_env.Get_Item('AZ_STORAGE_ACCOUNT') `
        --account-key $AZ_STORAGE_ACCOUNT_KEY `
        --source "$AZ_SOURCE" `
        --destination-path "$AZ_DIR"
    if (!$?) {
        Write-Host " - Files Upload :: Error - Unable to upload :: $az_cmd_response"
        exit -1
    } else {
        Write-Host " - Files Upload :: Transfer ok .."
        exit 0
    }

}
## ---------------------------------------------------------------------
## Build image
## ---------------------------------------------------------------------
function buildImage() {
    $DOCKER_IMAGE_NAME = $suif_env.Get_Item('DOCKER_IMAGE_NAME')
    Write-Host "-------------------------------------------------------"
    Write-Host " Building Image ...."
    Write-Host "-------------------------------------------------------"
    $docker_cmd_response = docker-compose build --no-cache  # 2>&1 | out-null
    if ($?) {
        Write-Host " - buildImage :: Image Built : ${DOCKER_IMAGE_NAME}"
        exit 0
    } else {
        Write-Host " - buildImage :: Unable to build image ${DOCKER_IMAGE_NAME} :: $docker_cmd_response"
        exit -1
    }
}
## ---------------------------------------------------------------------
## Tag image
## ---------------------------------------------------------------------
function tagImage() {
    $AZ_CONTAINER_REGISTRY = $suif_env.Get_Item('AZ_CONTAINER_REGISTRY')
    $DOCKER_IMAGE_NAME = $suif_env.Get_Item('DOCKER_IMAGE_NAME')
    Write-Host "-------------------------------------------------------"
    Write-Host " Tagging Image ...."
    Write-Host "-------------------------------------------------------"
    $docker_cmd_response = docker tag ${DOCKER_IMAGE_NAME} ${AZ_CONTAINER_REGISTRY}/${DOCKER_IMAGE_NAME}:v1 2>&1 | out-null
    if ($?) {
        Write-Host " - tagImage :: Built Image tag: ${AZ_CONTAINER_REGISTRY}/${DOCKER_IMAGE_NAME}:v1"
        exit 0
    } else {
        Write-Host " - tagImage :: Unable to tag image ${AZ_CONTAINER_REGISTRY}/${DOCKER_IMAGE_NAME}:v1 :: $docker_cmd_response"
        exit -1
    }
}

## ---------------------------------------------------------------------
## Log on to Azure ACR
## ---------------------------------------------------------------------
function loginToACR() {
    $AZ_SUBSCRIPTION_ID = $suif_env.Get_Item('AZ_SUBSCRIPTION_ID')
    $AZ_CONTAINER_REGISTRY = $suif_env.Get_Item('AZ_CONTAINER_REGISTRY')
    Write-Host "-------------------------------------------------------"
    Write-Host " Logging on to Azure ACR ...."
    Write-Host "-------------------------------------------------------"
    $az_cmd_response = az acr login --subscription "${AZ_SUBSCRIPTION_ID}" --name ${AZ_CONTAINER_REGISTRY} # 2>&1 | out-null
    if ($?) {
        Write-Host " - logInACR :: Log in successful to ${AZ_CONTAINER_REGISTRY}"
        exit 0
    } else {
        Write-Host " - logInACR :: Unable to log on to ${AZ_CONTAINER_REGISTRY} :: $az_cmd_response"
        exit -1
    }
}

## ---------------------------------------------------------------------
## Push image to ACR
## ---------------------------------------------------------------------
function pushImageToACR() {
    $AZ_CONTAINER_REGISTRY = $suif_env.Get_Item('AZ_CONTAINER_REGISTRY')
    $DOCKER_IMAGE_NAME = $suif_env.Get_Item('DOCKER_IMAGE_NAME')
    Write-Host "-------------------------------------------------------"
    Write-Host " Pushing image to Azure ACR ...."
    Write-Host "-------------------------------------------------------"
    $docker_cmd_response = docker push ${AZ_CONTAINER_REGISTRY}/${DOCKER_IMAGE_NAME}:v1 # 2>&1 | out-null
    if ($?) {
        Write-Host " - pushImageToACR :: Image successful pushed to ${AZ_CONTAINER_REGISTRY}"
        exit 0
    } else {
        Write-Host " - pushImageToACR :: Unable to push image to ${AZ_CONTAINER_REGISTRY} :: $docker_cmd_response"
        exit -1
    }
}

## ---------------------------------------------------------------------
## Start Container
## ---------------------------------------------------------------------
function startContainer() {
    $AZ_CTXT = $suif_env.Get_Item('AZ_ACI_CONTEXT_NAME')
    $DOCKER_CONTAINER_NAME = $suif_env.Get_Item('DOCKER_CONTAINER_NAME')
    Write-Host "-------------------------------------------------------"
    Write-Host " Starting Container $DOCKER_CONTAINER_NAME on ACI ...."
    Write-Host "-------------------------------------------------------"
    $docker_cmd_response = docker context use $AZ_CTXT 2>&1 | out-null
    if ($?) {
        Write-Host " - startContainer :: Context successful changed."
    } else {
        Write-Host " - startContainer :: Unable to change context :: $docker_cmd_response"
        exit -1
    }
    $docker_cmd_response = docker compose --file .\docker-compose.yml up # 2>&1 | out-null
    if ($?) {
        Write-Host " - startContainer :: Container successful started."
        docker context use default
        exit 0
    } else {
        Write-Host " - startContainer :: Unable to start container :: $docker_cmd_response"
        docker context use default
        exit -1
    }
}

## ---------------------------------------------------------------------
## Provision a VM
## ---------------------------------------------------------------------
function provisionVM() {
    $AZ_VM_NAME = $suif_env.Get_Item('AZ_VM_NAME')
    $AZ_RESOURCE_GROUP = $suif_env.Get_Item('AZ_RESOURCE_GROUP')
    Write-Host "-------------------------------------------------------"
    Write-Host " Provisioning VM $AZ_VM_NAME on Azure ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Check if VM exists already
    # ----------------------------------------------
   	$az_cmd_response = az vm show -g $AZ_RESOURCE_GROUP -n $AZ_VM_NAME ` 2>&1 | out-null
    if ($?) {
        Write-Host " - provisionVM :: VM $AZ_VM_NAME already exists."
        exit 0
    }
    # ----------------------------------------------
    # Deploy new VM
    # ----------------------------------------------
   	$az_cmd_response = az vm create --name $AZ_VM_NAME `
      --subscription $suif_env.Get_Item('AZ_SUBSCRIPTION_ID') `
      --resource-group $suif_env.Get_Item('AZ_RESOURCE_GROUP') `
      --image $suif_env.Get_Item('AZ_VM_IMAGE') `
      --admin-username $suif_env.Get_Item('AZ_VM_USER') `
      --size $suif_env.Get_Item('AZ_VM_SIZE') `
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
    $AZ_VM_NAME = $suif_env.Get_Item('AZ_VM_NAME')
    $AZ_RESOURCE_GROUP = $suif_env.Get_Item('AZ_RESOURCE_GROUP')
    $AZ_VM_USER = $suif_env.Get_Item('AZ_VM_USER')
    $VOL_ASSETS_HOME = $suif_env.Get_Item('VOL_ASSETS_HOME')
    $AZ_SUBSCRIPTION_ID = $suif_env.Get_Item('AZ_SUBSCRIPTION_ID')
    $AZ_STORAGE_ACCOUNT = $suif_env.Get_Item('AZ_STORAGE_ACCOUNT')
    $AZ_VOLUME_ASSETS = $suif_env.Get_Item('AZ_VOLUME_ASSETS')
    $SUIF_APP_HOME = $suif_env.Get_Item('SUIF_APP_HOME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Preparing the VM $AZ_VM_NAME on Azure ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Get Public IP
    # ----------------------------------------------
   	$az_public_ip = az vm show -d -g $AZ_RESOURCE_GROUP -n $AZ_VM_NAME --query publicIps -o tsv 
    if (!$?) {
        Write-Host " - prepareVM :: Unable to get public IP for VM $AZ_VM_NAME. Exiting ..."
        exit -1
    }
    Write-Host " - prepareVM :: Public IP for VM identified: $az_public_ip ..."
    
    # ----------------------------------------------
    # Test if VM has already been prepared
    # ----------------------------------------------
   	$az_cmd_assets = ssh $AZ_VM_USER@$az_public_ip "ls $VOL_ASSETS_HOME"
    if ($?) {
        Write-Host " - prepareVM :: VM has already been prepared for processing. Exiting ..."
        exit 0
    }

    # ----------------------------------------------
    # Get the storage key
    # ----------------------------------------------
   	$az_cmd_response = az storage account keys list `
	  --subscription $AZ_SUBSCRIPTION_ID `
      --resource-group $AZ_RESOURCE_GROUP `
	  --account-name $AZ_STORAGE_ACCOUNT
    if (!$?) {
        Write-Host " - prepareVM :: Unable to get the Storage Key :: $az_cmd_response"
        exit -1
    }
    $AZ_STORAGE_ACCOUNT_KEY = (ConvertFrom-Json -InputObject "$az_cmd_response")[0].value
    Write-Host " - prepareVM :: Storage key identified: $AZ_STORAGE_ACCOUNT_KEY ..."

    # ----------------------------------------------
    # Get the storage location
    # ----------------------------------------------
   	$az_cmd_response = az storage account show `
      --resource-group $AZ_RESOURCE_GROUP `
	  --name $AZ_STORAGE_ACCOUNT `
       --query "primaryEndpoints.file" -o tsv
    if (!$?) {
        Write-Host " - prepareVM :: Unable to get the Storage Location :: $az_cmd_response"
        exit -1
    }
    $AZ_STORAGE_LOCATION = $az_cmd_response.Substring($az_cmd_response.IndexOf(":")+1)
    Write-Host " - prepareVM :: Storage location identified: $AZ_STORAGE_LOCATION ..."

    # ----------------------------------------------
    # Prepare new VM
    # TODO: resolve uid and gid
    # ----------------------------------------------
    Write-Host " - prepareVM :: Executing remote ssh commands for VM preparation ...."
   	ssh $AZ_VM_USER@$az_public_ip `
       "sudo yum install cifs-utils; `
        sudo mkdir -p $VOL_ASSETS_HOME $SUIF_APP_HOME; `
        sudo chown -R '$AZ_VM_USER':'$AZ_VM_USER' $VOL_ASSETS_HOME; `
        sudo chown -R '$AZ_VM_USER':'$AZ_VM_USER' $SUIF_APP_HOME; `
        sudo mount -t cifs '$AZ_STORAGE_LOCATION''$AZ_VOLUME_ASSETS''$VOL_ASSETS_HOME' '$VOL_ASSETS_HOME' -o username=$AZ_STORAGE_ACCOUNT,password=$AZ_STORAGE_ACCOUNT_KEY,uid=1000,gid=1000,serverino"

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
    $AZ_VM_NAME = $suif_env.Get_Item('AZ_VM_NAME')
    $AZ_VM_USER = $suif_env.Get_Item('AZ_VM_USER')
    $AZ_RESOURCE_GROUP = $suif_env.Get_Item('AZ_RESOURCE_GROUP')
    $SUIF_LOCAL_SCRIPTS_HOME = $suif_env.Get_Item('SUIF_LOCAL_SCRIPTS_HOME')
    Write-Host "-------------------------------------------------------"
    Write-Host " Starting Application on Azure $AZ_VM_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Get Public IP
    # ----------------------------------------------
   	$az_public_ip = az vm show -d -g $AZ_RESOURCE_GROUP -n $AZ_VM_NAME --query publicIps -o tsv 
    if (!$?) {
        Write-Host " - entryPointVM :: Unable to get public IP for VM $AZ_VM_NAME. Exiting ..."
        exit -1
    }
    Write-Host " - entryPointVM :: Public IP for VM identified: $az_public_ip ..."
    
    ssh $AZ_VM_USER@$az_public_ip $SUIF_LOCAL_SCRIPTS_HOME/entryPoint.sh
    if (!$?) {
        Write-Host " - entryPointVM :: entryPoint.sh Script completed with errors. Exiting ..."
        exit -1
    }
    Write-Host " - entryPointVM :: entryPoint.sh Script completed successfully."
    exit 0
}
