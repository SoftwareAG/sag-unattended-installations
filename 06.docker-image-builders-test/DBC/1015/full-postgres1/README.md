# Test: Database Configurator on Postgres #1

- copy `example.env` into `.env`
- change the contents of `.env` if needed
- issue `docker-compose up`
- open adminer interface. You should be able to login to postgres and see the created objects
- issue `docker-compose down -t 0 -v` to destroy the containers and volumes
