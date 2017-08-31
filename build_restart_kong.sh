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

KONG_VERSION=`cat version | sed 's/^[[:space:]]*//g' | sed 's/*[[:space:]]$//g'`

docker kill kong
docker rm kong
docker rmi kong-baseimage:$KONG_VERSION

docker build -t kong-baseimage:$KONG_VERSION .

if [[ "$DEBUG" == "true" ]]; then
  docker run -it --name kong \
    --link kong-database:kong-database \
    -e "KONG_DATABASE=cassandra" \
    -e "KONG_CASSANDRA_CONTACT_POINTS=kong-database" \
    -e "KONG_PG_HOST=kong-database" \
    -p 8000:8000 \
    -p 8443:8443 \
    -p 8444:8444 \
    -p 8001:8001 \
    -p 7946:7946 \
    -p 7946:7946/udp \
    kong-baseimage:$KONG_VERSION \
    /bin/bash
  exit 0
fi

docker run -d --name kong \
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
