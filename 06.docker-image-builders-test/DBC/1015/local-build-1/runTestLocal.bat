@echo off

call .\setEnv.bat

md build_context

copy ..\..\..\..\05.docker-image-builders\DBC\1015\full\alpine\Dockerfile build_context\
copy ..\..\..\..\05.docker-image-builders\DBC\1015\full\alpine\*.sh build_context\

COPY "%INSTALLER_BIN%" build_context\installer.bin
COPY "%SUM_BOOTSTRAP_BIN%" build_context\sum-bootstrap.bin
COPY "%PRODUCTS_ZIP%" build_context\products.zip
COPY "%FIXES_ZIP%" build_context\fixes.zip

cd build_context

dir

docker build -t dbc-1015-full-alpine-test-1 .

cd ..

del /q build_context\*

rd /q build_context
