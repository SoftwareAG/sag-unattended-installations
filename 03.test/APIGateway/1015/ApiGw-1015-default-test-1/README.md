# API Gateway 10.15 test 1

The purpose of this test is to validate the local setup scripts for API Gateway version 10.15

The tested code is the one in the current branch, mounted locally.

## Prerequisites

- Local docker and docker compose
- GitHub project cloned locally
- The following Software AG assets (can be downloaded publicly)
  - installer binary for Linux 64 bit
  - update manager bootstrap for Linux 64 bit
- The following Software AG assets (cannot be downloaded publicly)
  - product image containing the products in the template
  - product fix image containing the latest relevant fixes
  - license for API Gateway

## Quick Start

All prerequisite files are in mentioned in the file `EXAMPLE.env`.

1. Procure prerequisite Software AG files
2. Copy `EXAMPLE.env` into `.env`
3. Modify `.env` to point to your local Software AG files
4. Eventually change H_SUIF_PORT_PREFIX to avoid port conflicts
5. Issue docker-compose up
   1. Note: first run will take some time as it installs everything necessary
6. Open a browser to [localhost API Gateway UI](http://localhost:44172), or better to [host.docker.internal API Gateway UI](http://host.docker.internal:44172)
7. If you want to inspect Elasticsearch contents, go to [elasicvue home](http://host.docker.internal:44180) and then point to the ES instance at http://host.docker.internal:44120

## Reusing the scripts for other environments

This test is given as an example of on-premise installation. In a classical environment, the following steps are needed to obtain an API Gateway node

1. Provision a Linux centos / RedHat type virtual machine.
2. Ensure the software mentioned in the Dockerfile is installed
   1. `which` and `gettext` are prerequisites, the rest are nice to have
3. Clone SUIF or copy from a clone in a folder (e.g. /home/sag/OPS/scripts/SUIF)
   1. a common initial pitfall is copying with windows end lines, please ensure all files have unix end lines
4. Prepare your own scripts mimicking the scripts in this test harness
   1. set_env.sh will contain all the variables specific to your environment
      1. Hint: don't forget to properly declare SUIF_HOME :)
   2. containerEntrypoint.sh must be adapted to your environment specifics, follow the provided sequence
      1. to install, first set the necessary environment variables as shown, then apply the template "APIGateway/1015/default"
      2. to configure post install, apply the post installation templates as shown in the example
