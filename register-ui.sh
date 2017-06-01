#!/bin/bash

curl -i -X POST \
  --url http://localhost:8001/apis/ \
  -H "Content-Type: application/json" \
  --data '{"name":"martingale-ui","hosts":"martingale-dev.prsn.io","upstream_url":"http://martingale-ui.martingale-dev.svc.cluster.local:80"}'

curl -i -X POST \
  --url http://localhost:8001/apis/ \
  -H "Content-Type: application/json" \
  --data '{"name":"martingale-kong-api","hosts":"martingale.dev","uris":["/api/kong"],"upstream_url":"http://localhost:8001"}'
