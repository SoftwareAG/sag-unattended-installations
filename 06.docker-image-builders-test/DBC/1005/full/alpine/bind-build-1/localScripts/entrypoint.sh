#!/bin/sh

cd /tmp || exit 1

buildah bud -t dbc-1005-test-bind-1 .
