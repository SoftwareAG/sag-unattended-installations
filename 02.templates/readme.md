# Templates for Unattended Installations

## Convention

Products version here is always four digits MMmm:

9.12 -> 0912
10.5 -> 1005

### Framework Base Variables and Initialization

The variables specified in this section are always used in every template and managed by the framework "init" function.

The following environment variables will always have to be provided by the caller.

|Environment Variable|Notes|
|-|-|
|SUIF_INSTALL_INSTALLER_BIN|Installer binary|
|SUIF_INSTALL_IMAGE_FILE|Installer products image file|
|SUIF_PATCH_AVAILABLE|0 if post-install are not available or not applicable|
|SUIF_PATCH_SUM_BOOTSTRAP_BIN|Software AG Update Manager bootstrap binary|
|SUIF_PATCH_FIXES_IMAGE_FILE|Fixes image file|

The following environment variables may to be provided by the caller, otherwise the framework will use default values.

|Environment Variable|Default Value|Notes|
|-|-|-|
|SUIF_AUDIT_BASE_DIR|/tmp|Audit folder for the framework -> the framework will put here logs and introspection output|
|SUIF_INSTALL_INSTALL_DIR|/opt/sag/products|Where to install the products|
|SUIF_INSTALL_DECLARED_HOSTNAME|localhost|the host name passed during the installation process|
|SUIF_SUM_HOME|/opt/sag/sum|Installation folder for Software AG Update Manager, must be different than the products intallation folder|
|SUIF_INSTALL_SPM_HTTPS_PORT|9083|Although not always used, it is used frequently, thus initialized by the framework|
|SUIF_INSTALL_SPM_HTTP_PORT|9082|Although not always used, it is used frequently, thus initialized by the framework|

The following variables MUST always be set by the template accordingly

|Environment Variable|Notes|
|-|-|
|SUIF_CURRENT_SETUP_TEMPLATE_PATH|the template relative path of the current template (e.g. AT/1005%default)|