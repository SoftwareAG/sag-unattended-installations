#!/bin/sh

curl -u "Administrator:${SUIF_APIGW_ADMINISTRATOR_PASSWORD}" \
  -X POST -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  --silent -o ./output.json \
  -d "@/api1_subst.json" \
  "${TEST_API_GW_LB_BASE_URL}/rest/apigateway/apis/23b1b341-e238-47b1-8be5-5b71bffdbe48"

# curl -u "Administrator:${SUIF_APIGW_ADMINISTRATOR_PASSWORD}" \
#   -X POST -H "Content-Type: application/json" \
#   -H "Accept: application/json" \
#   --silent -o ./output.json \
#   -d "@/./api1_subst.json" \
#   -w '%{http_code}' \
#   "${TEST_API_GW_LB_BASE_URL}/rest/apigateway/apis/23b1b341-e238-47b1-8be5-5b71bffdbe48"