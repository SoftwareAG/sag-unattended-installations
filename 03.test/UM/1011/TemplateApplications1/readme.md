# Universal Messaging Template Applications 10.11 Installation Test #1 Harness

## Objective

This test harness checks if the template UM/1011/TemplateApplications installs correctly.
Use this harness whenever you have a change on the tools (installer, update manager) or fixes (e.g. if you want to check a new fix level).

## Prerequisites

- Local docker and docker compose
- The following Software AG assets (cannot be downloaded publicly)
  - installer binary for linux 64 bit
  - product and fix images
    - update manager bootstrap for linux 64 bit
    - product image containing the tested product binaries
    - Note: these cand be obtained by using the image generator helper (see 04.support/images-generator project)
  - product fix image containing the latest relevant fixes

## Quickstart

All prerequisite files are in mentioned in the file .env_example.

1. Procure prerequisite Software AG files
2. Copy .env_example into .env
3. Modify .env to point to your local Software AG files
4. Issue docker-compose up

    -Note: first run will take some time as it installs everything necessary

5. Open a shell and use the template applications as needed

    - E.g. use UMTool

```sh
cd /app/sag/1011/UM-TA/UniversalMessaging/tools/runner
./runUMTool.sh

UM Tools Runner

This application can be used to launch different UM tools. You must pass the tool name as a subcommand followed by the tool arguments.

Usage:
runUMTool <subcommand> [args]

Example:
runUMTool CreateChannel -rname=nsp://localhost:9000 -channelname=newchannel

Available subcommands:
To enable tool debug option use -enableDebug parameter

To enable secured connection(nsps or nhps):
        key_store             : Set the keystore file that this interface uses to load the certificate
        keystore_passwd       : Set the keystore password that this interface will use to access the keystore file specified
        trust_store           : Set the truststore file against which this interface will validate the client certificate
        truststore_passwd     : Sets the truststore password that the server uses to access the trust store
        ssl_protocol          : Sets the preferred SSL protocol version to be used when establishing secured connections
        cipher_suites         : Sets the cipher suites, comma-separated

To print available tools use help parameter

1. Store tools
        <CreateChannel>
        <CreateDurable>

...
```
