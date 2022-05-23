# MSR 10.11 Deployer and ABE Test #2

Purpose of this test is to verify the minimum installation of template MSR/1011/deployer, with the application of fixes.

By minimum we intend that only the mandatory variables are provided, everything else will be initialized by default.

## Quick Start

- copy .env_example.md into .env
- change the H_* variables according to your context
- optionally change other variables
- run `docker-compose up`
- check the MSR instance by opening the Admin interface
  - e.g. http://host.docker.internal:48755
  - remember the admin password is set in the .env file
