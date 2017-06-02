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

echo "Starting Kong"
kong start "$@"
