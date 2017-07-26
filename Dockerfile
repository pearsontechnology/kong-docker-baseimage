# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM ubuntu:16.04
MAINTAINER Jeremy Darling, jeremy.darling@pearson.com

# From the kong base image
ENV KONG_VERSION 0.10.3

RUN apt-get update && apt-get -y install openssl libpcre3 procps perl curl

RUN curl -LO https://releases.hashicorp.com/envconsul/0.6.2/envconsul_0.6.2_linux_amd64.tgz
RUN tar -xvzf envconsul_0.6.2_linux_amd64.tgz
RUN chmod +x envconsul
RUN mv envconsul /bin/envconsul

RUN curl -LO https://github.com/Mashape/kong/releases/download/0.10.3/kong-0.10.3.jessie_all.deb

RUN dpkg -i kong-0.10.3.jessie_all.deb

RUN rm -f kong-0.10.3.jessie_all.deb

COPY kong-plugins/ /usr/local/share/lua/5.1/kong/custom-plugins/
COPY kong-plugins/ /usr/local/share/lua/5.1/kong/plugins/

COPY start-kong.sh /start-kong.sh
COPY start-kong-envconsul.sh /start-kong-envconsul.sh
COPY register-ui.sh /register-ui.sh

RUN chmod +x /start-kong.sh
RUN chmod +x /start-kong-envconsul.sh
RUN chmod +x /register-ui.sh

CMD ["/start-kong.sh"]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
