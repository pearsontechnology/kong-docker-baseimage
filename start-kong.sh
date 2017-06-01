#!/bin/bash

set -e

# Disabling nginx daemon mode
export KONG_NGINX_DAEMON="off"
if [[ "$KONG_CUSTOM_PLUGINS" == "" ]]; then
  export KONG_CUSTOM_PLUGINS=rewrite,external-oauth,upstream-auth-basic
fi

echo "Kong Database "$KONG_DATABASE
echo "Kong custom plugins "$KONG_CUSTOM_PLUGINS

echo "Starting Kong"
kong start "$@"
