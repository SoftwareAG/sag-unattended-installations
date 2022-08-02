@echo off

call .\setEnv.bat

md build_context

copy ..\..\..\..\..\..\05.docker-image-builders\MSR\1011\all-packages\multi-stage1\Dockerfile build_context\
copy ..\..\..\..\..\..\05.docker-image-builders\MSR\1011\all-packages\multi-stage1\*.sh build_context\

COPY "%INSTALLER_BIN%" build_context\installer.bin
COPY "%SUM_BOOTSTRAP_BIN%" build_context\sum-bootstrap.bin
COPY "%PRODUCTS_ZIP%" build_context\products.zip
COPY "%FIXES_ZIP%" build_context\fixes.zip
COPY "%MSR_LICENSE_XML%" build_context\msr-license.xml

cd build_context

pause

docker build --arg __suif_template=CloudStreamsServer/1011/lean -t css-1011-lean-ms-test-1 .

cd ..

del /q build_context\*

rd /q build_context
