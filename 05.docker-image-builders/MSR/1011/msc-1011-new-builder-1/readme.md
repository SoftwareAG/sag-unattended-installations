# MSR 10.11 Docker Image builder new type #1

## Purpose

Purpose of this project is to build an MSR container image using docker, as close as possible to the documented procedure, online, using the new option introduced with 10.11

## Prerequisites

1. A docker-compose environment
2. The linux 64 bit installer (10.11+)
3. Empower SDC user and password

## Usage

1. Clone the project from GitHub
2. Copy .env_example.md into .env
3. Alter .env accroding to your local env. You will have to provide at least the following
   1. installer binary for linux
   2. your Empower SDC user and password
4. Besides the above mandatory files, you may alter the variables as needed, but it is not required.
5. Run the file "run.bat" (or the command inside if you are not using Windows)
6. The result will be an image tagged msr1011-lean-builder-type-1:latest
7. You may test the resulting image with the tests harnesses MSR/1011/suif-msr-1011-lean-type1-*
