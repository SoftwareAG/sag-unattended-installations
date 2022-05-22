# MSR 10.11 ATS CU DB Test

Purpose of this test is to verify the Central User management on MSR.
For this reason we use:

- Postgres DB to store data
- adminer to manage data
- ATS with Central User to create one user
- MSR with Common Directory Service Support

Once installed access

ATS:
http://localhost:43355
MSR:
http://localhost:48755/
Admirer:
http://localhost:43380/

Set the CentralUser in the MSR and restart it to activate the Central User Management

## Quick Start

- copy .env_example.md into .env
- change the H_* variables according to your context
- optionally change other variables
- run `docker-compose up`
- check the MSR instance by opening the Admin interface
  - e.g. http://host.docker.internal:48755
  - remember the admin password is set in the .env file
