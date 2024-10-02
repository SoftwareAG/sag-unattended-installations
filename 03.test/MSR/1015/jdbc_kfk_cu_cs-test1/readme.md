# MSR 10.15 with JDBC Adapter, Kafka Adapter, CU CDS and CloudStreams Test #1

Purpose of this test is to verify the minimum installation of template `MSR/1015/jdbc_kfk_cu_cs`.

By minimum we intend that only the mandatory variables are provided, everything else will be initialized by default.

## Quick Start

- copy `Example.env` into `.env`
- change the H_* variables according to your context
- optionally change other variables
- run `docker-compose up`
- check the MSR instance by opening the Admin interface
  - e.g. http://host.docker.internal:48955 (adapt according to the declared port prefix)
  - remember the admin password is set in the `.env` file
