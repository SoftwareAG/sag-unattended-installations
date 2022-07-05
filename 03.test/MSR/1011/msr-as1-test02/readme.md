# MSR 10.11 with Central Users and Adapters set #1 Test No 02

Purpose of this test is to verify the installation of template MSR/1011/AdapterSet1 with fixes.

By minimum we intend that only the mandatory variables are provided, everything else will be initialized by default.

## Quick Start

- copy .env_example.md into .env
- change the H_* variables according to your context
- optionally change other variables
- run `docker-compose up`
- check the MSR instance by opening the Admin interface
  - e.g. http://host.docker.internal:48755
  - remember the admin password is set in the .env file
