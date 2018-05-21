
FROM home1oss/ci-ubuntu:16.04

RUN sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu\//http:\/\/mirrors.163.com\/ubuntu\//g' /etc/apt/sources.list

# install netstat to allow connection health check with
# netstat -tan | grep ESTABLISHED
RUN apt-get update &&\
    apt-get install -y net-tools curl &&\
    apt-get -q autoremove &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

## Install JDK 8 (latest edition)
#RUN apt-get -q update &&\
#    DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends openjdk-8-jdk-headless &&\
#    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# ------------------------------ jenkinsci/docker-slave ------------------------------

ENV HOME /home/jenkins
RUN groupadd -g 10000 jenkins
RUN useradd -c "Jenkins user" -d $HOME -u 10000 -g 10000 -m jenkins

ARG VERSION=2.62

RUN curl --create-dirs -sSLo /usr/share/jenkins/slave.jar https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${VERSION}/remoting-${VERSION}.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/slave.jar


USER jenkins
#RUN mkdir /home/jenkins/.jenkins
#VOLUME /home/jenkins/.jenkins
VOLUME /home/jenkins
WORKDIR /home/jenkins

# ------------------------------ jenkinsci/docker-slave ------------------------------

# ------------------------------ jenkinsci/jnlp-slave ------------------------------

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]

# ------------------------------ jenkinsci/jnlp-slave ------------------------------
