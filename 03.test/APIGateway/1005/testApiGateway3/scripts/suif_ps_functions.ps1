
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
. "..\..\..\..\01.scripts\commonFunctions.ps1"


## ---------------------------------------------------------------------
## Additional custom functions
## ---------------------------------------------------------------------

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
## Provision VM under Bastion Service 
## ---------------------------------------------------------------------
function provisionVMforBastion() {
    param (
        [string] $az_vm_name,
        [string] $az_host_name,
        [string] $az_image_handle,
        [string] $az_size_handle
    )
    $LOC_VM_NAME = $az_vm_name
    $LOC_HOST_NAME = $az_host_name

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
    $SUIF_AZ_VM_USER_PASSWORD = $suif_env.Get_Item('SUIF_AZ_VM_USER_PASSWORD')

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
    $az_cmd_response = az vm create --name $LOC_VM_NAME `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --location $H_AZ_GEO_LOCATION `
       --image $LOC_AZ_VM_IMAGE `
       --size $LOC_AZ_VM_SIZE `
       --admin-username $SUIF_AZ_VM_USER `
       --admin-password $SUIF_AZ_VM_USER_PASSWORD `
       --vnet-name $SUIF_AZ_VNET_NAME `
       --asgs $SUIF_AZ_ASG_NAME `
       --nsg $SUIF_AZ_NSG_NAME `
       --nsg-rule NONE `
       --subnet $SUIF_AZ_VM_SUBNET `
       --computer-name $LOC_HOST_NAME `
       --public-ip-address '""'

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
function prepareVMCCLI() {
    param (
        [string] $az_vm_name
    )
    $LOC_VM_NAME = $az_vm_name

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

    Write-Host "-------------------------------------------------------"
    Write-Host " Preparing VM $LOC_VM_NAME on Azure ...."
    Write-Host "-------------------------------------------------------"

    # ----------------------------------------------
    # Get the storage key
    # ----------------------------------------------
   	$az_cmd_response = az storage account keys list `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $H_AZ_RESOURCE_GROUP_STORAGE `
       --account-name $H_AZ_STORAGE_ACCOUNT
    if (!$?) {
        Write-Host " - prepareVMCCLI :: Unable to get the Storage Key :: $az_cmd_response"
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
        Write-Host " - prepareVMCCLI :: Unable to get the Storage Location :: $az_cmd_response"
        exit -1
    }
    $LOC_AZ_STORAGE_LOCATION = $az_cmd_response.Substring($az_cmd_response.IndexOf(":")+1)
    Write-Host " - prepareVMCCLI :: Storage location identified: $LOC_AZ_STORAGE_LOCATION ..."
	$az_cmd = az vm run-command invoke --command-id RunShellScript `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --name $LOC_VM_NAME `
       --parameters SUIF_DIR_ASSETS=$SUIF_DIR_ASSETS `
                    SUIF_APP_HOME=$SUIF_APP_HOME `
                    SUIF_HOME=$SUIF_HOME `
                    SUIF_AZ_VM_USER=$SUIF_AZ_VM_USER `
                    LOC_AZ_STORAGE_LOCATION=$LOC_AZ_STORAGE_LOCATION `
                    SUIF_AZ_VOLUME_ASSETS=$SUIF_AZ_VOLUME_ASSETS `
                    H_AZ_STORAGE_ACCOUNT=$H_AZ_STORAGE_ACCOUNT `
                    LOC_AZ_STORAGE_ACCOUNT_KEY=$LOC_AZ_STORAGE_ACCOUNT_KEY `
                    SUIF_AUDIT_BASE_DIR=$SUIF_AUDIT_BASE_DIR `
                    SUIF_LOCAL_SCRIPTS_HOME=$SUIF_LOCAL_SCRIPTS_HOME `
                    SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE=$SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE `
       --scripts '@.\scripts\vm_init.sh'

    if (!$?) {
        Write-Host " - prepareVMCCLI :: Unable to prepare VM :: $az_cmd"
        exit -1
    }
    Write-Host " - prepareVMCCLI :: VM successfully prepared."
    exit 0

}

## ---------------------------------------------------------------------
## Run entrypoint script to provision wM application
## ---------------------------------------------------------------------
function entryPointVMviaCLI() {
    param (
        [string] $az_vm_name
    )
    $LOC_VM_NAME = $az_vm_name

    $H_AZ_SUBSCRIPTION_ID = $suif_host_env.Get_Item('H_AZ_SUBSCRIPTION_ID')
    $SUIF_AZ_RESOURCE_GROUP = $suif_env.Get_Item('SUIF_AZ_RESOURCE_GROUP')
    $SUIF_AZ_VM_USER = $suif_env.Get_Item('SUIF_AZ_VM_USER')
    $SUIF_LOCAL_SCRIPTS_HOME = $suif_env.Get_Item('SUIF_LOCAL_SCRIPTS_HOME')

    Write-Host "-------------------------------------------------------"
    Write-Host " Starting Application on $LOC_VM_NAME ...."
    Write-Host "-------------------------------------------------------"
    # ----------------------------------------------
    # Run entryPoint script
    # ----------------------------------------------
	$az_cmd = az vm run-command invoke --command-id RunShellScript `
       --subscription $H_AZ_SUBSCRIPTION_ID `
       --resource-group $SUIF_AZ_RESOURCE_GROUP `
       --name $LOC_VM_NAME `
       --parameters SUIF_AZ_VM_USER=$SUIF_AZ_VM_USER `
                    SUIF_LOCAL_SCRIPTS_HOME=$SUIF_LOCAL_SCRIPTS_HOME `
       --scripts '@.\scripts\entryPoint.sh'

    if (!$?) {
        Write-Host " - entryPointVMviaCLI :: Unable to run entryPoint script :: $az_cmd"
        exit -1
    }
    Write-Host " - entryPointVMviaCLI :: entryPoint script successfully executed."
    exit 0
}
