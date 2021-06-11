# BigMemory test 5

- Based on BigMemoryTest2 - a standalone BM installation version 10.5 with TMC/TMS
- Azure Provisioning 

## Prerequisites

- Full clone of the current repository
- The following Software AG assets (cannot be downloaded publicly)
  - installer binary for linux 64 bit
  - product image containing BigMemory 4.3 (packaged with webmethods version 10.5 and associated fixes)
  - license for Terracotta Big Memory server

- Azure account and subscription
- Resource Group and Storage Resource


## Quickstart

All prerequisite files are in mentioned in the file .env_example.

1. Procure prerequisite Software AG files
2. Copy .env_example into .env
3. Modify .env to point to your local Software AG files
4. Open a browser to [TMC] http://<azure_ip>:9889
