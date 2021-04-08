@echo off

docker-compose run --rm alpine-set-elk-kernel-params /root/scripts/setParams.sh

echo Finished!

pause