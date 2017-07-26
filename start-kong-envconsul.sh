#!/bin/bash

set -e

# Disabling nginx daemon mode
export KONG_NGINX_DAEMON="off"
if [[ "$KONG_CUSTOM_PLUGINS" == "" ]]; then
  cd /usr/local/share/lua/5.1/kong/custom-plugins/
  kong_plugins=`ls -dm * | sed 's/,[ \t\n\r]*/,/g'`
  export KONG_CUSTOM_PLUGINS=$kong_plugins
fi

echo "Kong Database "$KONG_DATABASE
echo "Kong custom plugins "$KONG_CUSTOM_PLUGINS

if [[ "$CONSUL_HOST" == "" ]]; then
  CONSUL_HOST=consul.kube-system.svc.cluster.local
fi

if [[ "$CONSUL_PREFIX" == "" ]]; then
  CONSUL_PREFIX=/
fi

if [[ "$CONSUL_USE_SSL" == "true" ]]; then
  if [[ "$CONSUL_PORT" == "" ]]; then
    CONSUL_PORT=8543
  fi
  echo "Starting Kong: Using SSL and Token"
  envconsul -kill-signal=SIGHUP -consul=$CONSUL_HOST:$CONSUL_PORT -prefix=$CONSUL_PREFIX -ssl -ssl-verify=false -token=$CONSUL_TOKEN kong start "$@"
else
  if [[ "$CONSUL_PORT" == "" ]]; then
    CONSUL_PORT=8500
  fi
  if [[ "${CONSUL_TOKEN}" != "" ]]; then
    echo "Starting Kong: Using Token"
    envconsul -kill-signal=SIGHUP -consul=$CONSUL_HOST:$CONSUL_PORT -prefix=$CONSUL_PREFIX -token=$CONSUL_TOKEN kong start "$@"
  else
    echo "Starting Kong"
    envconsul -kill-signal=SIGHUP -consul=$CONSUL_HOST:$CONSUL_PORT -prefix=$CONSUL_PREFIX kong start "$@"
  fi
fi
