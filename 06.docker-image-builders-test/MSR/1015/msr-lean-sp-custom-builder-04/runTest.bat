@echo off

call .\setEnv.bat

md build_context

copy ..\..\..\..\05.docker-image-builders\MSR\1015\msr-lean-sp-custom-builder-04\Dockerfile build_context\
copy ..\..\..\..\05.docker-image-builders\MSR\1015\msr-lean-sp-custom-builder-04\*.sh build_context\

COPY "%INSTALLER_BIN%" build_context\installer.bin
COPY "%SUM_BOOTSTRAP_BIN%" build_context\sum-bootstrap.bin
COPY "%PRODUCTS_ZIP%" build_context\products.zip
COPY "%FIXES_ZIP%" build_context\fixes.zip
COPY "%SP_ZIP%" build_context\sp.zip
COPY "%MSR_LICENSE_XML%" build_context\msr-license.xml


cd build_context

echo SP_ID=%SP_ID%

docker build -t msr-1015-lean-sp-custom-builder-01-test-01 --build-arg __sp_id=%SP_ID% --no-cache .

cd ..

del /q build_context\*

rd /q build_context
