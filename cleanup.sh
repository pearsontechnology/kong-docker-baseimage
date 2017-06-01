#!/bin/bash

echo "Cleaning up any existing containers"

containers=`docker ps -aqf name=kong-baseimage`

echo "Killing all docker containers with kong-baseimage in the name"
for container in $containers; do
  echo "Killing $container"
  docker kill $container
  docker rm $container
done
