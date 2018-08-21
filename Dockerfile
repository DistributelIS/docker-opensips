FROM debian:stretch
MAINTAINER Razvan Crainea <razvan@opensips.org>

USER root
ENV DEBIAN_FRONTEND noninteractive
ARG VERSION=2.4

RUN apt-get update -qq && apt-get install -y gnupg1 curl rsyslog
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 049AD65B
RUN echo "deb http://apt.opensips.org stretch $VERSION-releases" >/etc/apt/sources.list.d/opensips.list
RUN apt-get install -y opensips

RUN echo -e "local0.* -/var/log/opensips.log\n& stop" > /etc/rsyslog.d/opensips.conf
RUN touch /var/log/opensips.log

EXPOSE 5060/udp

COPY run.sh /run.sh

ENTRYPOINT ["/run.sh"]
