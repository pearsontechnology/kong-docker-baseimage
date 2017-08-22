# kong-docker-baseimage

Based on https://github.com/phusion/baseimage-docker this baseimage installs
and sets up Kong.

## Included 3rd party plugins

 * dynamic-access-control
 * external-oauth
 * oidc
 * rewrite
 * upstream-auth-basic

## Build/Test

Increment the value at the end of the version in version file.  So if the contents were 0.10.3-1 you would change this to 0.10.3-2

Note the new version as in the rest of the document it will be referenced as $KONG_VERSION

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

First make sure you have checked your changes into github.

Next publish to the pearsontechnology Docker Hub account by running the ./publish.sh script:

```
./publish.sh
```

Finally log into master (or any other machine that has access to
bitesize-registry.default.svc.cluster.local) and execute:

**NOTE:** A proper script should be output from publish.sh that you can copy/paste.

```
docker pull pearsontechnology/kong:$KONG_VERSION
docker tag pearsontechnology/kong:$KONG_VERSION bitesize-registry.default.svc.cluster.local:5000/baseimages/kong:$KONG_VERSION
docker push bitesize-registry.default.svc.cluster.local:5000/baseimages/kong:$KONG_VERSION
```
