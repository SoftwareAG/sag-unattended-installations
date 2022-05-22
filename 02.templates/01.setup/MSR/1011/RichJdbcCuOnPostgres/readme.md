# Rich Microservides Runtime With JDBC Adapter

This template installs a Microservices Runtime with the JDBC Adapter and the following components

- Installer Bundles
- CDS support
- Central Users Support
- DB Support
- Monitor
- Process Engine

## Variables

Besides the framework variables, this template requires the following:

|Variable Name|Caller Must Provide?|Default Value|Notes|
|-|-|-|-|
|SUIF_SETUP_TEMPLATE_MSR_LICENSE_FILE|Yes|N/A|User must provide a valid license|
|SUIF_INSTALL_MSR_MAIN_HTTP_PORT|No|5555|Main Http port|
|SUIF_INSTALL_MSR_MAIN_HTTPS_PORT|No|5553|Main Http/s port|
|SUIF_INSTALL_MSR_DIAGS_HTTP_PORT|No|9999|Diagnostics port|
|SUIF_WMSCRIPT_CDSConnectionName|Yes|
|SUIF_WMSCRIPT_CDSPasswordName||
|SUIF_WMSCRIPT_CDSUserName||
