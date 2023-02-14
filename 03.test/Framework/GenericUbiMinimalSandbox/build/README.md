# Generic Sandbox based on UBI minimal 

This folder provides a container build context for multiple purposes such as exploration and testing.

See `03.test\Labs\1005\EsbMonolith1\test1\docker-compose.yml` on how to use.

The prepared image is a minimal UBI image having some tools installed and the following mountpoints prepared:

## Directory volumes

|Parameter|DefaultValue|Redeclared as ENV Var|Notes
|-|-|-|-
|`__suif_audit_base_dir`|`/app/audit`|`SUIF_AUDIT_BASE_DIR`|Audit folder receiving the SUIF logs and traces
|`__suif_home`|`/mnt/suif`|`SUIF_HOME`|SUIF library home
|`__suif_install_install_dir`|`/app/sag/version/flavor`|`SUIF_INSTALL_INSTALL_DIR`|Software AG product installation home folder
|`__suif_local_scripts_home`|`/mnt/scripts/local`|`SUIF_LOCAL_SCRIPTS_HOME`|Local scripts usually mounted from the test harness
|`__suif_sum_home`|`/app/sum11`|`SUIF_SUM_HOME`|Software AG Update Manager installation home
|`__suif_work_dir`|`/mnt/work`|`SUIF_WORK_DIR`|Work directory for the test harnesses to use at their discretion


## File mountpoints

|Parameter|DefaultValue|Redeclared as ENV Var|Notes
|-|-|-|-
|`__suif_install_image_file`|`/mnt/products.zip`|`SUIF_INSTALL_IMAGE_FILE`|
|`__suif_install_installer_bin_mount_point`|`/mnt/installer.bin`|`SUIF_INSTALL_INSTALLER_BIN_MOUNT_POINT`
|`__suif_patch_fixes_image_file`|`/mnt/fixes.zip`|`SUIF_PATCH_FIXES_IMAGE_FILE`
|`__suif_patch_sum_bootstrap_bin_mount_point`|`/mnt/sum-bootstrap.bin`|`SUIF_PATCH_SUM_BOOTSTRAP_BIN_MOUNT_POINT`