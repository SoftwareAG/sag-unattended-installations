@echo off

call .\setEnv.bat

md build_context

copy ..\..\..\..\05.docker-image-builders\MSR\1011\msr-as1-custom-builder-01\Dockerfile build_context\
copy ..\..\..\..\05.docker-image-builders\MSR\1011\msr-as1-custom-builder-01\*.sh build_context\

COPY "%INSTALLER_BIN%" build_context\installer.bin
COPY "%SUM_BOOTSTRAP_BIN%" build_context\sum-bootstrap.bin
COPY "%PRODUCTS_ZIP%" build_context\products.zip
COPY "%FIXES_ZIP%" build_context\fixes.zip
COPY "%MSR_LICENSE_XML%" build_context\msr-license.xml

cd build_context

docker build -t msr-as1-custom-builder-01-test-01 .

cd ..

del /q build_context\*

rd /q build_context
