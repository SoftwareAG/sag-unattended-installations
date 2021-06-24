#!/bin/sh
# -------------------------------------------------------------------------------------------------------
#  This scripts prepares the provisioned VM and is executed using 'az run-command' on the remote VM.
#  I.e. the local script (this file) is passed to the az cli command and all referenced
#  subscripts/properties refer to remote VM file share where suif scripts reside (/assets).
#
#  - Installs required utilities on VM
#  - Creates mount points
#  - Assigns ownership and privieleges to directories
#  - Mounts the shared file systems to the VM mount points
#  - For APIGW, ensure required OS level system settings
#  - Retrieves the license keys from key vault and stores to fs
#  - Starts the entryPoint script which installs and starts application
#
#  Parameters:
#   - $SUIF_DIR_ASSETS
#   - $SUIF_APP_HOME
#   - $SUIF_HOME
#   - $SUIF_AZ_VM_USER
#   - $LOC_AZ_STORAGE_LOCATION
#   - $SUIF_AZ_VOLUME_ASSETS
#   - $H_AZ_STORAGE_ACCOUNT
#   - $LOC_AZ_STORAGE_ACCOUNT_KEY
#   - $SUIF_AUDIT_BASE_DIR
#   - $SUIF_LOCAL_SCRIPTS_HOME
#   - $SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE
# -------------------------------------------------------------------------------------------------------
if [ ! -d "${SUIF_APP_HOME}" ]; then 
    mkdir -p ${SUIF_APP_HOME}
    chown -R ${SUIF_AZ_VM_USER}:${SUIF_AZ_VM_USER} ${SUIF_APP_HOME}
fi
if [ ! -d "${SUIF_AUDIT_BASE_DIR}" ]; then 
    mkdir -p ${SUIF_AUDIT_BASE_DIR}
    chown -R ${SUIF_AZ_VM_USER}:${SUIF_AZ_VM_USER} ${SUIF_AUDIT_BASE_DIR}
fi

LOG_FILE=${SUIF_AUDIT_BASE_DIR}vm_init.log
sudo -iu ${SUIF_AZ_VM_USER} echo " - init VM :: Starting Prepare VM process ..." >> ${LOG_FILE}

# ----------------------------------------------
# Set up pre-requisites if not already done
# ----------------------------------------------
# cifs-utils for mounting of shared Azure fs
CIFS_INSTALLED=`dnf list installed cifs-utils`
if [ $? -eq 0 ] ; then 
    sudo -iu ${SUIF_AZ_VM_USER} echo " - init VM :: CIFS Utils already installed ..." >> ${LOG_FILE}
else 
    sudo -iu ${SUIF_AZ_VM_USER} echo " - init VM :: Installing CIFS Utils ..." >> ${LOG_FILE}
    dnf -y install cifs-utils
fi
# Azure keyvault secrets
AZ_KV_INSTALLED=`sudo -iu ${SUIF_AZ_VM_USER} pip3 show azure-keyvault-secrets`
if [ $? -eq 0 ] ; then 
    sudo -iu ${SUIF_AZ_VM_USER} echo " - init VM :: Azure Keyvault Utils for Python already installed ..." >> ${LOG_FILE}
else 
    sudo -iu ${SUIF_AZ_VM_USER} echo " - init VM :: Installing Azure Keyvault Utils for Python ..." >> ${LOG_FILE}
    sudo -iu ${SUIF_AZ_VM_USER} pip3 install --user azure-keyvault-secrets
fi
# Azure identities
AZ_ID_INSTALLED=`sudo -iu ${SUIF_AZ_VM_USER} pip3 show azure.identity`
if [ $? -eq 0 ] ; then 
    sudo -iu ${SUIF_AZ_VM_USER} echo " - init VM :: Azure Identity util for Python already installed ..." >> ${LOG_FILE}
else 
    sudo -iu ${SUIF_AZ_VM_USER} echo " - init VM :: Installing Azure Identity util for Python ..." >> ${LOG_FILE}
    sudo -iu ${SUIF_AZ_VM_USER} pip3 install --user azure.identity
fi

if [ ! -d "${SUIF_DIR_ASSETS}" ]; then 
    sudo -iu ${SUIF_AZ_VM_USER} echo " - init VM :: Creating mount point ${SUIF_DIR_ASSETS} ..." >> ${LOG_FILE}
    mkdir -p ${SUIF_DIR_ASSETS}
    chown -R ${SUIF_AZ_VM_USER}:${SUIF_AZ_VM_USER} ${SUIF_DIR_ASSETS}
fi
if [ ! -d "${SUIF_HOME}" ]; then 
    sudo -iu ${SUIF_AZ_VM_USER} echo " - init VM :: Mounting file share to mount point ${SUIF_DIR_ASSETS} ..." >> ${LOG_FILE}
    mount -t cifs ${LOC_AZ_STORAGE_LOCATION}${SUIF_AZ_VOLUME_ASSETS}${SUIF_DIR_ASSETS} ${SUIF_DIR_ASSETS} -o username=${H_AZ_STORAGE_ACCOUNT},password=${LOC_AZ_STORAGE_ACCOUNT_KEY},uid=1000,gid=1000,serverino
fi

# ==============================================
# Ensure APIGW OS level settings
# ==============================================
# ----------------------------------------------
# Test System wide file descriptors
# ----------------------------------------------
RES_SETTING=`sysctl -a | grep fs.file-max | cut -f 3 -d ' '`
if [ ${RES_SETTING} -lt 65536 ]; then 
    echo " - init VM :: Number of system-wide file descriptors insufficient (${RES_SETTING}) - increasing to 65536 ...." >> ${LOG_FILE}
    echo "fs.file-max = 65536" | sudo tee -a /etc/sysctl.conf; sudo sysctl -p
else
    echo " - init VM :: Number of system-wide file descriptors sufficient :: ${RES_SETTING} - required: 65536." >> ${LOG_FILE}
fi
# ----------------------------------------------
# Test Open file descriptors Soft
# ----------------------------------------------
RES_SETTING=`sudo -iu ${SUIF_AZ_VM_USER} ulimit -Sn`
if [ ${RES_SETTING} -lt 65536 ]; then 
    echo " - init VM :: Number of Soft open file descriptors insufficient (${RES_SETTING}) - increasing to 65536 ...." >> ${LOG_FILE}
    echo "${SUIF_AZ_VM_USER} soft nofile 65536" | sudo tee -a /etc/security/limits.conf;
else
    echo " - init VM :: Number of Soft open file descriptors sufficient :: ${RES_SETTING} - required: 65536." >> ${LOG_FILE}
fi

# ----------------------------------------------
# Test Open file descriptors Hard
# ----------------------------------------------
RES_SETTING=`sudo -iu ${SUIF_AZ_VM_USER} ulimit -Hn`
if [ ${RES_SETTING} -lt 65536 ]; then 
    echo " - init VM :: Number of hard open file descriptors insufficient (${RES_SETTING}) - increasing to 65536 ...." >> ${LOG_FILE}
    echo "${SUIF_AZ_VM_USER} hard nofile 65536" | sudo tee -a /etc/security/limits.conf;
else
    echo " - init VM :: Number of Hard open file descriptors sufficient :: ${RES_SETTING} - required: 65536." >> ${LOG_FILE}
fi

# ----------------------------------------------
# Test maximum system-wide map count
# ----------------------------------------------
RES_SETTING=`sysctl -a | grep vm.max_map_count | cut -f 3 -d ' '`
if [ ${RES_SETTING} -lt 262144 ]; then 
    echo " - init VM :: Number of systen-wide map count insufficient (${RES_SETTING}) - increasing to 262144 ...." >> ${LOG_FILE}
    echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf; sudo sysctl -p;
else
    echo " - init VM :: Number of systen-wide map count sufficient :: ${RES_SETTING} - required: 262144." >> ${LOG_FILE}
fi

# ----------------------------------------------
# Test maximum number of processes
# ----------------------------------------------
RES_SETTING=`sudo -iu ${SUIF_AZ_VM_USER} ulimit -u`
if [ ${RES_SETTING} -lt 4096 ]; then 
    echo " - init VM ::  Number of processes insufficient (${RES_SETTING}) - increasing to 4096 ...." >> ${LOG_FILE}
    echo "${SUIF_AZ_VM_USER} soft nproc 4096" | sudo tee -a /etc/security/limits.conf; 
    echo "${SUIF_AZ_VM_USER} hard nproc 4096" | sudo tee -a /etc/security/limits.conf;
else
    echo " - init VM :: Number of processes sufficient :: ${RES_SETTING} - required: 4096." >> ${LOG_FILE}
fi

# ----------------------------------------------
# Retrieve License keys from Azure Key Vault and 
# store in local VM directory
# ----------------------------------------------
# 
echo " - init VM :: Getting License Key from Key Vault and storing to ${SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE}" >> ${LOG_FILE}
VAULT_SECRET=`${SUIF_LOCAL_SCRIPTS_HOME}/getVaultSecret.sh "APIGW-KEYVAULT" "API-Gateway-LicenseKey"`
echo ${VAULT_SECRET} > ${SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE} && chown ${SUIF_AZ_VM_USER}:${SUIF_AZ_VM_USER} ${SUIF_SETUP_TEMPLATE_YAI_LICENSE_FILE}

# ----------------------------------------------
# Start Application
# ----------------------------------------------
# 
echo " - init VM :: Starting Application script ..." >> ${LOG_FILE}
sudo -iu ${SUIF_AZ_VM_USER} ${SUIF_LOCAL_SCRIPTS_HOME}/entryPoint.sh > /dev/null 2>&1 &

exit 0
