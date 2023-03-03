@echo off

echo ###################################################################################### Testing section 1 - file SUIF1.yaml ####################
SET SUIF_TEST_YAML_FILE=.\SUIF1.yaml

echo =========================================================== Testing with alpine       ==============================
SET SUIF_TEST_IMAGE=alpine
docker-compose run --rm parse-yaml-test1
echo ERRORLEVEL=%ERRORLEVEL%
echo =========================================================== Test with alpine finished ==============================

echo =========================================================== Testing with ubuntu       ==============================
SET SUIF_TEST_IMAGE=ubuntu
docker-compose run --rm parse-yaml-test1
echo ERRORLEVEL=%ERRORLEVEL%
echo =========================================================== Test with ubuntu finished ==============================

echo =========================================================== Testing with ubi minimal  ==============================
SET SUIF_TEST_IMAGE=registry.access.redhat.com/ubi8/ubi-minimal:latest
docker-compose run --rm parse-yaml-test1
echo ERRORLEVEL=%ERRORLEVEL%
echo =========================================================== Test with ubi minimal finished =========================

echo ###################################################################################### Testing section 2 - file SUIF2.yaml ####################
SET SUIF_TEST_YAML_FILE=.\SUIF2.yaml

echo =========================================================== Testing with alpine       ==============================
SET SUIF_TEST_IMAGE=alpine
docker-compose run --rm parse-yaml-test1
echo ERRORLEVEL=%ERRORLEVEL%
echo =========================================================== Test with alpine finished ==============================

echo =========================================================== Testing with ubuntu       ==============================
SET SUIF_TEST_IMAGE=ubuntu
docker-compose run --rm parse-yaml-test1
echo ERRORLEVEL=%ERRORLEVEL%
echo =========================================================== Test with ubuntu finished ==============================

echo =========================================================== Testing with ubi minimal  ==============================
SET SUIF_TEST_IMAGE=registry.access.redhat.com/ubi8/ubi-minimal:latest
docker-compose run --rm parse-yaml-test1
echo ERRORLEVEL=%ERRORLEVEL%
echo =========================================================== Test with ubi minimal finished =========================


pause
