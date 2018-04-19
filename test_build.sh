#!/bin/bash

DEBUG=false

while [[ $# > 0 ]]
do
  key="$1"
  case $key in
      -d|--debug)
      DEBUG=true
      ;;
  esac
  shift # past argument or value
done

echo "Cleaning up any existing containers"

containers=`docker ps -aqf name=kong-baseimage`

echo "Killing all docker containers with kong-baseimage in the name"
for container in $containers; do
  echo "Killing $container"
  docker kill $container
  docker rm $container
done

KONG_VERSION=`cat version | sed 's/^[[:space:]]*//g' | sed 's/*[[:space:]]$//g'`

docker rm kong-baseimage
docker rmi kong-baseimage:$KONG_VERSION

echo "Starting Cassandra"
docker run -d --name kong-database \
                -p 9042:9042 \
                cassandra:3

echo "Waiting for Cassandra to come online"
while true; do
  liveness=`docker exec -it kong-database  cqlsh -e "SELECT release_version FROM system.local"`
  isAlive=`echo $liveness | grep "release_version"`
  if [[ "$isAlive" != "" ]]; then
    break;
  fi
  sleep 1
done

echo "Building kong version $KONG_VERSION"

docker build --rm -t kong-baseimage:$KONG_VERSION .

docker run --rm --name kong-migrations \
    --link kong-database:kong-database \
    -e "KONG_DATABASE=cassandra" \
    -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
    -e "KONG_PG_HOST=kong-database" \
    kong-baseimage:$KONG_VERSION kong migrations up

if [[ "$DEBUG" == "true" ]]; then
  docker run -it --name kong-baseimage-debug \
    --link kong-database:kong-database \
    -e "KONG_DATABASE=cassandra" \
    -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
    -e "KONG_PG_HOST=kong-database" \
    -p 8000:8000 \
    -p 8443:8443 \
    -p 8001:8001 \
    -p 7946:7946 \
    -p 7946:7946/udp \
    kong-baseimage:$KONG_VERSION \
    /bin/bash
    exit 1
else
  docker run -d --name kong-baseimage \
    --link kong-database:kong-database \
    -e "KONG_DATABASE=cassandra" \
    -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
    -e "KONG_PG_HOST=kong-database" \
    -p 8000:8000 \
    -p 8443:8443 \
    -p 8001:8001 \
    -p 7946:7946 \
    -p 7946:7946/udp \
    kong-baseimage:$KONG_VERSION
fi

echo "Waiting for kong to start"

curl -s localhost:8001
kongAlive=$?
SECONDS=0
while [[ $kongAlive != 0 ]]; do
  duration=$SECONDS
  if [[ $duration -ge 30 ]]; then
    echo "Something went wrong, use kong-scripts/errorlogs for information"
    echo "Exit code $kongAlive"
    exit $kongAlive
  fi
  sleep 1
  curl -s localhost:8001
  kongAlive=$?
done

echo -e "\n\nSuccess!"
