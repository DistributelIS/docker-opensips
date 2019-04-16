FROM debian:stretch
MAINTAINER Razvan Crainea <razvan@opensips.org>

USER root
ENV DEBIAN_FRONTEND noninteractive
ARG VERSION=2.4

RUN apt-get update -qq && apt-get upgrade -y && apt-get install -y gnupg curl python-setuptools sipsak sqlite3

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 049AD65B
RUN echo "deb http://apt.opensips.org stretch $VERSION-releases" >/etc/apt/sources.list.d/opensips.list
RUN apt-get update -qq && apt-get install -y  opensips opensips-sqlite-module opensips-tls-module opensips-xmlrpc-module opensips-python-module && easy_install j2cli

EXPOSE 5060/udp

COPY run.sh /run.sh

ENTRYPOINT ["/run.sh"]
