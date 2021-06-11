#!/bin/sh
# ----------------------------------------------------
# This scripts prepares the provisioned VM:
#  * Runs as root
#  * Install cifs-util for enabling mounting the Azure file share (assets)
#    - Assets contain the files need to perform the installation (suif scripts, installers, images, etc.)
#  * Create mount points and assign privileges to runtime user
#  * Mount the Azure file system
# ----------------------------------------------------


ls -la > test.txt

exit 
