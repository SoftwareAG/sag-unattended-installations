# MSR 10.11 with JDBC Adapter

Purpose of this test is to provide a startup laboratory or development environment for exploring MSR service development with Postgres Database.

By minimum we intend that only the mandatory variables are provided, everything else will be initialized by default.

## Quick Start

- copy Example.env into .env
- change the H_* variables according to your context
- optionally change other variables
- run `docker-compose up`
- check the MSR instance by opening the Admin interface
  - e.g. http://host.docker.internal:48755
  - remember the admin password is set in the .env file
