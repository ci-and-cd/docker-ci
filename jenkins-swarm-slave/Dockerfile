
FROM home1oss/ci-ubuntu:16.04

RUN sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu\//http:\/\/mirrors.163.com\/ubuntu\//g' /etc/apt/sources.list

# ------------------------------ evarga/jenkins-slave ------------------------------

# ------------------------------ evarga/jenkins-slave ------------------------------

# ------------------------------ carlossg/jenkins-swarm-slave ------------------------------

ENV JENKINS_SWARM_VERSION 2.2
ENV HOME /home/jenkins-slave

# install netstat to allow connection health check with
# netstat -tan | grep ESTABLISHED
RUN apt-get update &&\
    apt-get install -y net-tools curl iputils-ping zip unzip &&\
    apt-get -q autoremove &&\
    apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

RUN useradd -c "Jenkins Slave user" -d $HOME -m jenkins-slave
RUN curl --create-dirs -sSLo /usr/share/jenkins/swarm-client-$JENKINS_SWARM_VERSION-jar-with-dependencies.jar https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/$JENKINS_SWARM_VERSION/swarm-client-$JENKINS_SWARM_VERSION-jar-with-dependencies.jar \
  && chmod 755 /usr/share/jenkins

COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN gpasswd -a jenkins-slave docker
USER jenkins-slave
RUN mkdir -p /home/jenkins-slave/.m2
RUN mkdir -p /home/jenkins-slave/.ssh
VOLUME /home/jenkins-slave

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# ------------------------------ carlossg/jenkins-swarm-slave ------------------------------
