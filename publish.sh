#!/bin/bash

KONG_VERSION=`cat version | sed 's/^[[:space:]]*//g' | sed 's/*[[:space:]]$//g'`

docker tag kong-baseimage:$KONG_VERSION pearsontechnology/kong:$KONG_VERSION
docker push pearsontechnology/kong:$KONG_VERSION

echo "Now log into master (or any other machine that has access to
bitesize-registry.default.svc.cluster.local) and execute:

docker pull pearsontechnology/kong:$KONG_VERSION
docker tag pearsontechnology/kong:$KONG_VERSION bitesize-registry.default.svc.cluster.local:5000/baseimages/kong:$KONG_VERSION
docker push bitesize-registry.default.svc.cluster.local:5000/baseimages/kong:$KONG_VERSION"
