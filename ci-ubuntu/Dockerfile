
FROM ubuntu:16.04

ARG build_fileserver

COPY docker/debconf.txt /etc/debconf.txt
RUN sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu\//http:\/\/mirrors.163.com\/ubuntu\//g' /etc/apt/sources.list && \
    apt-get update -y && \
    apt-get -yq install --reinstall locales tzdata debconf && \
    debconf-set-selections /etc/debconf.txt && \
    echo "Asia/Shanghai" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    dpkg-reconfigure -f noninteractive locales && \
    apt-get upgrade -y && \
    apt-get install -y apt-transport-https apt-utils ca-certificates curl lsb-release nano software-properties-common unzip vim wget && \
    apt-get install -y build-essential python python-pip && \
    apt-get -q autoremove && \
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ENV JAVA_OPTS -Duser.language=zh -Duser.region=CN -Dfile.encoding='UTF-8' -Duser.timezone='Asia/Shanghai'

RUN apt-get update -y && \
    apt-get install -y graphviz && \
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

## install ruby
ADD docker/install_ruby.sh /root/
RUN /root/install_ruby.sh

## install docker && docker-compose
ADD docker/install_docker.sh /root/
RUN /root/install_docker.sh

## install jdk
ADD docker/install_oracle_jdk.sh /root/
RUN /root/install_oracle_jdk.sh

ENV JAVA_HOME /opt/jdk
ENV PATH ${PATH}:${JAVA_HOME}/bin

## install node
ADD docker/install_nodejs.sh /root/
RUN /root/install_nodejs.sh

ENV NODE_HOME /opt/node
ENV PATH ${PATH}:${NODE_HOME}/bin

## install maven && gradle
ADD docker/install_build_tools.sh /root/
RUN /root/install_build_tools.sh

ENV M2_HOME /opt/maven
ENV GRADLE_HOME /opt/gradle
ENV PATH ${PATH}:${M2_HOME}/bin:${GRADLE_HOME}/bin
