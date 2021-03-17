# Scripts for SoftwareAG provisioning contexts

## General Rules applied

The project is built so that scripts may be downloaded or injected into linux nodes, either hosts, vms or containers.

The scripts themselves have minimal comments to keep them light.

All files that require parameters are managed with gnu envsusbst. This means that all properties will be sourceable shell files.

## Important notes:

It is the caller responsibility to:

- properly cater for env variables substitutions in the provided files.
- properly prepare url-encoded variables (use the common lib primitives)

## Exit $ Return Codes

|Code|Description|
|-|-|
|0|Success|
|1|Cannot create Session folder|
|100|One of the expected files is missing from product installation|
|101|Environment variables substitutions failed for a template file|
|102|curl failed|
|103|setupProductsAndFixes failed for local setup|

## Return codes

By convention all functions must return 0 if successful. Return codes then will be specific to each function