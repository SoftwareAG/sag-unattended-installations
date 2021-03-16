# Scripts for SoftwareAG provisioning contexts

## General Rules applied

The project is built so that scripts may be downloaded or injected into linux nodes, either hosts, vms or containers.

The scripts themselves have minimal comments to keep them light.

All files that require parameters are managed with gnu envsusbst. This means that all properties will be sourceable shell files.

## Important notes:

It is the caller responsibility to:

- properly cater for env variables substitutions in the provided files.
- properly prepare url-encoded variables (use the common lib primitives)