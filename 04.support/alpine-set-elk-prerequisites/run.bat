@echo off

docker-compose run alpine-set-elk-kernel-params /root/scripts/setParams.sh

echo Finished!

pause