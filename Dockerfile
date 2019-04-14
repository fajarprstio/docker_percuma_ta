FROM ubuntu

MAINTAINER Fajar prasetio <fajarprstyo05@gmail.com>

#Add user percuma_ta
RUN groupadd -r -g 1000 percuma_ta && \
useradd -r -g 1000 -d /percuma_ta -m -g percuma_ta percuma_ta


RUN DEBIAN_FRONTEND=noninteractive apt-get clean -y
RUN DEBIAN_FRONTEND=noninteractive apt-get autoclean -y
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

#Supervisord
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor && \
	mkdir -p /var/log/supervisor
CMD ["/usr/bin/supervisord", "-n"]

#Utilities
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y python-minimal python-pip build-essential default-jre python-virtualenv python-setuptools git wget ssh curl
RUN DEBIAN_FRONTEND=noninteractive pip install --upgrade pip && \
    pip install setuptools && \
    pip install virtualenv && \
    pip install pycrypto && \
    pip install pyasn1 && \
    pip install pyasn1-modules && \
    pip install virtualenv && \
    pip install twisted && \
    pip install cryptography && \
    pip install tzlocal


#Downloading percuma_ta and generating ssh-key pairs
RUN su - percuma_ta -c "\
    git clone https://github.com/fajarprstio/percuma_ta.git /percuma_ta/percuma_ta && \
    rm /percuma_ta/percuma_ta/private.key && \
    rm /percuma_ta/percuma_ta/public.key && \ 
    ssh-keygen -t rsa -f /percuma_ta/percuma_ta/private.key -q -N '' && \
    mv /percuma_ta/percuma_ta/private.key.pub /percuma_ta/percuma_ta/public.key && \
    cd /percuma_ta && \

    #Downloading elasticsearch
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.0.1.tar.gz && \
    tar -xzf elasticsearch-*.tar.gz && \
    rm elasticsearch-*.tar.gz && \
    mv elasticsearch-* elasticsearch && \
    cd /percuma_ta && \

    #Downloading logstash and GeoDatabase
    wget https://artifacts.elastic.co/downloads/logstash/logstash-6.0.1.tar.gz && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz && \
    tar -xzf GeoLite2-*.tar.gz && \
    tar -xzf logstash-*.tar.gz && \
    rm GeoLite2-*.tar.gz && \
    rm logstash-*.tar.gz && \
    mv logstash-* logstash && \
    mv ./GeoLite2-*/GeoLite2-* /percuma_ta/logstash/ && \
    rm -r GeoLite2-* && \
    cd /percuma_ta && \

    # downloading kibana
    wget https://artifacts.elastic.co/downloads/kibana/kibana-6.0.1-linux-x86_64.tar.gz && \
    tar -xzf kibana-*.tar.gz && \
    rm kibana-*.tar.gz && \
    mv kibana-* kibana" && \

    export DEBIAN_FRONTEND=noninteractive && \
    apt-get remove -y --purge \
      ssh \
      git \
      python-pip \
      python-setuptools \
      build-essential && \
    #Remove any auto-installed depends for the build and any temp files and package lists.
    apt-get autoremove -y && \
    dpkg -l | awk '/^rc/ {print $2}' | xargs dpkg --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#Allow kibana to be accessed from the outside machine
RUN sed -ri "s!^(\#\s*)?(server\.host:).*!\2 '0.0.0.0'!" /percuma_ta/kibana/config/kibana.yml

USER percuma_ta
COPY logstash.conf /percuma_ta/logstash/
COPY docker-start.sh /percuma_ta/percuma_ta/

WORKDIR /percuma_ta/percuma_ta

CMD [ "/bin/bash", "docker-start.sh"]

EXPOSE 2222 5601
