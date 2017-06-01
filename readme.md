# kong-docker-baseimage

Based on https://github.com/phusion/baseimage-docker this baseimage installs
and sets up Kong.

## Build/Test

Execute ./test_build.sh in order to start cassandra and kong in local mode

```
./test_build.sh
```

Execute ./test_build.sh --debug in order to start cassandra and then drop to a
shell inside of the kong container.  You can run ./start-kong.sh inside the
container to debug the startup script.

```
./test_build.sh --debug
```

## Cleanup

Execute cleanup.sh to kill and then remove any running containers.

```
./cleanup.sh
```

## Publish for use within Bitesize

Once you have a working local version of the image the following steps should be
used to publish the image for partners to consume.

First publish to the pearsontechnology Docker Hub account:

```
docker tag kong-baseimage:0.10.3 pearsontechnology/kong:0.10.3
docker push pearsontechnology/kong
```

Next log into master (or any other machine that has access to
bitesize-registry.default.svc.cluster.local) and execute:

```
docker pull pearsontechnology/kong
docker tag pearsontechnology/kong bitesize-registry.default.svc.cluster.local:5000/baseimages/kong:0.10.3
docker push bitesize-registry.default.svc.cluster.local:5000/baseimages/kong:0.10.3
```
