FROM    ubuntu:latest

ENV DEBIAN_FRONTEND noninteractive
#prevent apt from installing recommended packages
RUN echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/docker-no-recommends && \
    echo 'APT::Install-Suggests "false";' >> /etc/apt/apt.conf.d/docker-no-recommends

RUN     apt-get update && apt-get install -y librrds-perl rrdtool net-tools
VOLUME /var/www/html/
WORKDIR /usr/local/bin
ADD   www /var/www/html/
ADD     *.pl ./
ADD     start.sh ./
CMD ["./start.sh"]
