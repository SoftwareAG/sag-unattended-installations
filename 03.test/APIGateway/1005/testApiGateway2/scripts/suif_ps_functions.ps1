
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


