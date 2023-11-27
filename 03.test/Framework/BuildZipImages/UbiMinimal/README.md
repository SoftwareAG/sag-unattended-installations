# Product ZIP Images Build Test

Purpose of this test harness is to check image building using ash under UBI minimal 8.

This setup mimics an Azure DevOps pipelines situation in terms of ash shell compatibility. It also checks portability aspects of the base shell common functions.

## Quick Start

After cloning copy `EXAMPLE.env` into `.env` and insert the credentials. Also verify the output folder to be something that works on your box.
Launch the docker-compose project eventually using the command in `run.bat`.
