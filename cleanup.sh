#!/bin/bash

echo "Cleaning up any existing containers"

containers=`docker ps -aqf name=kong`

echo "Killing all docker containers with kong in the name"
for container in $containers; do
  echo "Killing $container"
  docker kill $container
  docker rm $container
done
