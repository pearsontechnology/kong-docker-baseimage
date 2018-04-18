# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM ubuntu:16.04
MAINTAINER Jeremy Darling, jeremy.darling@pearson.com

# From the kong base image
ENV KONG_VERSION 0.13.0

RUN apt-get update && apt-get -y install build-essential openssl libssl-dev libpcre3 procps perl curl unzip git

RUN curl -LO https://releases.hashicorp.com/envconsul/0.6.2/envconsul_0.6.2_linux_amd64.tgz
RUN tar -xvzf envconsul_0.6.2_linux_amd64.tgz
RUN chmod +x envconsul
RUN mv envconsul /bin/envconsul

RUN curl -LO https://bintray.com/kong/kong-community-edition-deb/download_file?file_path=dists/kong-community-edition-0.13.0.xenial.all.deb

RUN dpkg -i kong-community-edition-0.13.0.xenial.all.deb

RUN rm -f kong-community-edition-0.13.0.xenial.all.deb

#RUN luarocks install lua-resty-openidc
RUN luarocks install luacrypto 0.3.2-1 --local

RUN rm -f /usr/local/kong/nginx-kong.conf

COPY nginx-kong.conf /nginx-kong.conf
COPY nginx.conf /nginx.conf

COPY kong-plugins/ /usr/local/share/lua/5.1/kong/custom-plugins/
COPY kong-plugins/ /usr/local/share/lua/5.1/kong/plugins/

COPY start-kong.sh /start-kong.sh
COPY start-kong-envconsul.sh /start-kong-envconsul.sh
COPY register-ui.sh /register-ui.sh

RUN chmod +x /start-kong.sh
RUN chmod +x /start-kong-envconsul.sh
RUN chmod +x /register-ui.sh

RUN mkdir -p /usr/local/kong/logs \
    && ln -sf /tmp/logpipe /usr/local/kong/logs/access.log \
    && ln -sf /tmp/logpipe /usr/local/kong/logs/serf.log \
    && ln -sf /tmp/logpipe /usr/local/kong/logs/error.log

CMD ["/start-kong.sh", "-vv", "--nginx-conf", "/nginx.conf"]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
