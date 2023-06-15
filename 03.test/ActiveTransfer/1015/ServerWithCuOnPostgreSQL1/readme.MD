# ActiveTransfer Server 10.15 on PostgreSQL with Central Users test No 1

The purpose of this harness is to test the installation template AT/1015/minimal-with-cu-on-postgresql

## Quick Start

- copy `example.env` into `.env`
- change `.env` as needed
- install with `docker-compose -f docker-compose-install.yml up`
- run with `docker-compose up`
- database may be inspected using adminer
- eventually destroy the environment with `docker-compose -f docker-compose-install.yml down -t 0 -v`
  - after environment destruction repeat installation
- after installation, use the IS admin UI to associate one of the pools to central users
