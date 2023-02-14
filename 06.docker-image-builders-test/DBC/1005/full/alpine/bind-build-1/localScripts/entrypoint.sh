#!/bin/sh

cd /tmp || exit 1

buildah bud --isolation=chroot -t dbc-1005-test-bind-1 .
