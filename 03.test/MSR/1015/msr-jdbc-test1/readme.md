# MSR 10.15 Lean Test #2

Purpose of this test is to verify the minimum installation of template `MSR/1015/lean`.

By minimum we intend that only the mandatory variables are provided, everything else will be initialized by default.

## Quick Start

- copy `Example.env` into `.env`
- change the H_* variables according to your context
- optionally change other variables
- run `docker-compose up`
- check the MSR instance by opening the Admin interface
  - e.g. http://host.docker.internal:48755 (adapt according to the declared port prefix)
  - remember the admin password is set in the `.env` file
