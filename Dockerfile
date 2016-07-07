FROM    ubuntu:16.04

ENV DEBIAN_FRONTEND noninteractive
#prevent apt from installing recommended packages
RUN echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/docker-no-recommends && \
    echo 'APT::Install-Suggests "false";' >> /etc/apt/apt.conf.d/docker-no-recommends

RUN     apt-get update && apt-get install -y librrds-perl rrdtool net-tools librrdtool-oo-perl sysstat dpkg libnet-dns-perl libdbi-perl libdbd-mysql-perl libnumber-bytes-human-perl xtables-addons-common
ADD	    /perl/libtie-dns-perl_1.151560-1_all.deb /tmp/
RUN		dpkg --install /tmp/libtie-dns-perl_1.151560-1_all.deb
VOLUME /var/www/html/
WORKDIR /usr/local/bin
ADD   www /var/www/html/
ADD     *.pl ./
ADD     start.sh ./
CMD ["./start.sh"]
