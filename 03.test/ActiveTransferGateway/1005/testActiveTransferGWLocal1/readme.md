# BigMemory test 1

The purpose of this test is to validate the local setup scripts for BigMemory used for IS clustering with version 1005

The tested code is the one in the master branch, provided in "offline" mode.

## Prerequisites

- Local docker and docker compose
- Full clone of the current repository
- The following Software AG assets (cannot be downloaded publicly)
  - installer binary for linux 64 bit
  - update manager bootstrap for linux 64 bit
  - product image containing BigMemory 4.3 (packaged with webmethods version 10.5)
  - product fix image containing the latest relevant fixes
  - licenses for Active Transfer Server ( IS and MFT)

## Quickstart

All prerequisite files are in mentioned in the file .env_example.

1. Procure prerequisite Software AG files
2. Copy .env_example into .env
3. Modify .env to point to your local Software AG files
4. Eventually change H_SUIF_PORT_PREFIX to avoid port conflicts
5. Issue docker-compose up
   1. Note: first run will take some time as it installs everything necessary
6. Open a browser to [IS Administration](http://localhost:48155) (or change port if you changed the port prefix)
   1. Test the jdbc pools, they should work
