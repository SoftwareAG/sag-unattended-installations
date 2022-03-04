# Test harness for SUM offline autoupdate

Purpose of this test is to show how to autoupdate Update Manager v11 and verify various fix levels for regression.

## How to use the test harness

- run this on a machine having docker and docker compose. It is originally tested with Docker Desktop on Windows.
- procure the following
  - an older update manager bootstrap binary
  - two fix images, produced in different moments in time
- copy .env.MD into .env and change the variables according to your environment
- run the test with the command in run.bat
