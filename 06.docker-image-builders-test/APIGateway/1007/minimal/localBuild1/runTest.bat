@echo off

call .\setEnv.bat

md build_context

SET RELATIVE_BUILDER_PATH=..\..\..\..\..\05.docker-image-builders\APIGateway\1007\minimal\multi-stage-1

copy %RELATIVE_BUILDER_PATH%\Dockerfile build_context\
copy %RELATIVE_BUILDER_PATH%\*.sh build_context\

COPY "%INSTALLER_BIN%" build_context\installer.bin
COPY "%SUM_BOOTSTRAP_BIN%" build_context\sum-bootstrap.bin
COPY "%PRODUCTS_ZIP%" build_context\products.zip
COPY "%FIXES_ZIP%" build_context\fixes.zip
COPY "%YAI_LICENSE_XML%" build_context\yai-license.xml

cd build_context

docker build -t sag-apigw-1107-custom-builder-01-test-01 ^
  --build-arg __suif_tag=%SUIF_TAG% .

cd ..

del /q build_context\*

rd /q build_context
