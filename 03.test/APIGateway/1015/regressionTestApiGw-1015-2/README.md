# API Gateway 10.7 test 1

The purpose of this test is to validate the local setup scripts for API Gateway version 10.7

The tested code is the one in the current branch, mounted locally.

## Prerequisites

- Local docker and docker compose
- GitHub project cloned locally
- The following Software AG assets (cannot be downloaded publicly)
  - installer binary for linux 64 bit
  - update manager bootstrap for linux 64 bit
  - product image containing the products in the template
  - product fix image containing the latest relevant fixes
  - license for API Gateway

## Quickstart

All prerequisite files are in mentioned in the file .env_example.

1. Procure prerequisite Software AG files
2. Copy .env_example into .env
3. Modify .env to point to your local Software AG files
4. Eventually change H_SUIF_PORT_PREFIX to avoid port conflicts
5. Issue docker-compose up
   1. Note: first run will take some time as it installs everything necessary
6. Open a browser to [localhost API Gateway UI](http://localhost:42172) or [load balancer set API Gateway UI](http://host.docker.internal:42172) (or change port if you changed the port prefix)
   1. Note LB is iset according to docker-desktop conventions if you are using another system adapt as required the file scripts/config/lb.json
7. You should observe Administrator password has been changed to manage1 and LB are set appropriately
8. You should observe the fact extended settings were altered as per the provided json configuration.
9. If you want to inspect elasticsearch contents, go to [elasicvue home](http://host.docker.internal:42180) and then point to the ES instance at http://host.docker.internal:42120

## Reusing the scripts for other environments

This test is given as an example of on-premise installation. In a classical environment, the following steps are needed to obtain an API Gateway node

1. Provision a linux centos / redhat type virtual machine.
2. Ensure the software mentioned in the Dockerfile is installed
   1. which and gettext are prerequisites, the rest are nice to have
3. Clone SUIF or copy from a clone in a folder (e.g. /home/sag/OPS/scripts/SUIF)
   1. a common initial pitfall is copying with windows endlines, please ensure all files have unix endlines
4. Prepare your own scripts mimicking the scripts in this test harness
   1. set_env.sh will contain all the variables specific to your environment
      1. Hint: don't forget to properly declare SUIF_HOME :)
   2. containerEntrypoint.sh must be adapted to your environment specifics, follow the provided sequence
      1. to install, first set the necessary env variables as shown, then apply the template "APIGateway/1005/default"
      2. to configure post install, apply the post installation templates as shown in the example
