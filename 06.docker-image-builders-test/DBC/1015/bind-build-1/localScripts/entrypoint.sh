#!/bin/sh

cd /tmp || exit 1

buildah bud --isolation=chroot -t dbc-1015-test-bind-1 .
