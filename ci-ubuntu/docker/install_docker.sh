#!/usr/bin/env bash

# install docker

# add docker group if not exits
groupadd -f docker

## install docker-engine docker-machine docker-compose
if [ -z "${build_fileserver}" ]; then build_fileserver="https://github.com"; fi

# Select docker version both supported by rancher and kubernetes
# see: https://docs.rancher.com/rancher/v1.6/en/hosts/#supported-docker-versions
# see: https://github.com/gitlawr/install-docker
# 1.12
#apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
#    echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list && \
#    apt-get update && \
#    apt-cache madison docker-engine && \
#    apt-get -yq install docker-engine=1.12.6-0~ubuntu-xenial && \
#curl -sSL https://github.com/gitlawr/install-docker/blob/master/1.12.6.sh?raw=true | sh
# 17.03
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
#    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
#    apt-get update && \
#    apt-cache madison docker-ce && \
#    apt-get -yq --allow-unauthenticated install docker-ce=17.03.1~ce-0~ubuntu-xenial && \
#curl -sSL https://github.com/gitlawr/install-docker/blob/1.0/17.03.1.sh?raw=true | sh

apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
    echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-cache madison docker-engine && \
    apt-get -yq install docker-engine=1.12.6-0~ubuntu-xenial && \
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin && \
    wget -q -O /usr/local/bin/docker-machine ${build_fileserver}/docker/machine/releases/download/v0.12.0/docker-machine-Linux-x86_64 && \
    chmod +x /usr/local/bin/docker-machine && \
    wget -q -O /usr/local/bin/docker-compose ${build_fileserver}/docker/compose/releases/download/1.13.0/docker-compose-Linux-x86_64 && \
    chmod +x /usr/local/bin/docker-compose
