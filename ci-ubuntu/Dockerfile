
FROM ubuntu:18.04

ARG build_fileserver
ENV ARIA2C_DOWNLOAD aria2c --file-allocation=none -c -x 10 -s 10 -m 0 --console-log-level=notice --log-level=notice --summary-interval=0

## install tools
RUN set -ex \
    && sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu\//http:\/\/mirrors.163.com\/ubuntu\//g' /etc/apt/sources.list \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y apt-transport-https apt-utils aria2 ca-certificates curl git httpie lsb-release nano software-properties-common unzip vim wget \
    && apt-get -q autoremove \
    && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

## locale
RUN set -ex \
    && echo $'tzdata tzdata/Areas select Asia\
tzdata tzdata/Zones/Asia select Shanghai\n\
locales locales/locales_to_be_generated    multiselect en_US.UTF-8 UTF-8\
locales locales/default_environment_locale select      en_US.UTF-8\n' > /etc/debconf.txt \
    && apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get -yq install --reinstall locales tzdata debconf \
    && debconf-set-selections /etc/debconf.txt \
    && echo "Asia/Shanghai" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && dpkg-reconfigure -f noninteractive locales \
    && apt-get -q autoremove \
    && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

## install global node.js
RUN if [ -z "${build_fileserver}" ]; then build_fileserver="https://nodejs.org"; fi \
    && NODE_VERSION="v9.11.1" \
    && mkdir -p /opt \
    && wget -q -O node-${NODE_VERSION}-linux-x64.tar.xz ${build_fileserver}/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz \
    && tar xf node-${NODE_VERSION}-linux-x64.tar.xz -C /opt \
    && ln -sf /opt/node-${NODE_VERSION}-linux-x64 /opt/node \
    && rm -f node-${NODE_VERSION}-linux-x64.tar.xz
## install node.js for current user
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash \
    && nvm install 9.11.1

## install global python
RUN set -ex \
    && apt-get update -y \
    && apt-get install -y build-essential python python-pip \
    && apt-get -q autoremove \
    && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin
## install python for current user
RUN set -ex \
    && apt-get update -y \
    && apt-get install -y build-essential git libbz2-dev libreadline-dev libsqlite3-dev libssl-dev make python python-pip zlib1g-dev \
    && curl -L https://raw.github.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash \
    && touch ~/.bash_profile \
    && echo 'export PATH="${HOME}/.pyenv/bin:$PATH"' >> ~/.bashrc \
    && echo 'if which pyenv > /dev/null; then eval "$(pyenv init -)"; eval "$(pyenv virtualenv-init -)"; fi' >> ~/.bashrc \
    && apt-get -q autoremove \
    && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

## install global ruby
# see: https://gorails.com/setup/ubuntu/18.04
RUN apt-get install libgdbm-dev libncurses5-dev automake libtool bison libffi-dev \
    && gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
    && curl -L https://get.rvm.io | bash -s stable --auto-dotfiles \
    && echo '[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"' >> ~/.bashrc \
    && source /usr/local/rvm/scripts/rvm \
    && rvm install ruby-2.4.1 \
    && rvm use ruby-2.4.1 --default \
    && ruby -v

## install docker, docker-machine, docker-compose
# Select docker version both supported by rancher and kubernetes
# see: https://docs.rancher.com/rancher/v1.6/en/hosts/#supported-docker-versions
# see: https://github.com/gitlawr/install-docker
# 1.12
#apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D \
#   && echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" | tee /etc/apt/sources.list.d/docker.list \
#   && apt-get update \
#   && apt-cache madison docker-engine \
#   && apt-get -yq install docker-engine=1.12.6-0~ubuntu-xenial
#curl -sSL https://github.com/gitlawr/install-docker/blob/master/1.12.6.sh?raw=true | sh
#
# 17.03
#curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
#   && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
#   && apt-get update \
#   && apt-cache madison docker-ce \
#   && apt-get -yq --allow-unauthenticated install docker-ce=17.03.1~ce-0~ubuntu-xenial
#curl -sSL https://github.com/gitlawr/install-docker/blob/1.0/17.03.1.sh?raw=true | sh
#
#STABLE (NOT YET AVAILABLE!), please check availabilty before using:
#echo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable' > /etc/apt/sources.list.d/docker.list
#EDGE:
#echo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic edge' >> /etc/apt/sources.list.d/docker.list
#NIGHTLY:
#echo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic nightly' >> /etc/apt/sources.list.d/docker.list
RUN groupadd -f docker \
    && apt-get update \
    && apt-get -yq install apt-transport-https ca-certificates curl software-properties-common \
    && echo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable' > /etc/apt/sources.list.d/docker.list \
    && echo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic edge' >> /etc/apt/sources.list.d/docker.list \
    && echo 'deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic nightly' >> /etc/apt/sources.list.d/docker.list \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
    && apt-get update \
    && apt-cache madison docker-ce \
    && apt-get -yq install docker-ce=18.05.0~ce~3-0~ubuntu \
    && apt-get -q autoremove \
    && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin \
    && if [ -z "${build_fileserver}" ]; then build_fileserver="https://github.com"; fi \
    && wget -q -O /usr/local/bin/docker-machine ${build_fileserver}/docker/machine/releases/download/v0.14.0/docker-machine-Linux-x86_64 \
    && chmod +x /usr/local/bin/docker-machine \
    && wget -q -O /usr/local/bin/docker-compose ${build_fileserver}/docker/compose/releases/download/1.21.2/docker-compose-Linux-x86_64 \
    && chmod +x /usr/local/bin/docker-compose

## install jdk
# http://download.oracle.com/otn-pub/java/jdk/8u171-b11/512cd62ec5174c3487ac17c61aaa89e8/jdk-8u171-linux-x64.tar.gz
RUN JAVA_VERSION_MAJOR=8 \
    && JAVA_VERSION_MINOR=171 \
    && JAVA_VERSION_BUILD=11 \
    && JAVA_PACKAGE=jdk \
    && JAVA_PACKAGE_DIGEST=512cd62ec5174c3487ac17c61aaa89e8 \
    && if [ -z "${build_fileserver}" ]; then build_fileserver="http://download.oracle.com"; fi \
    && mkdir -p /opt \
        && curl -jksSLH "Cookie: oraclelicense=accept-securebackup-cookie" \
        ${build_fileserver}/otn-pub/java/jdk/${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-b${JAVA_VERSION_BUILD}/${JAVA_PACKAGE_DIGEST}/${JAVA_PACKAGE}-${JAVA_VERSION_MAJOR}u${JAVA_VERSION_MINOR}-linux-x64.tar.gz \
        | tar -xzf - -C /opt \
        && ln -s /opt/jdk1.${JAVA_VERSION_MAJOR}.0_${JAVA_VERSION_MINOR} /opt/jdk \
        && rm -rf /opt/jdk/*src.zip \
               /opt/jdk/lib/missioncontrol \
               /opt/jdk/lib/visualvm \
               /opt/jdk/lib/*javafx* \
               /opt/jdk/jre/lib/plugin.jar \
               /opt/jdk/jre/lib/ext/jfxrt.jar \
               /opt/jdk/jre/bin/javaws \
               /opt/jdk/jre/lib/javaws.jar \
               /opt/jdk/jre/lib/desktop \
               /opt/jdk/jre/plugin \
               /opt/jdk/jre/lib/deploy* \
               /opt/jdk/jre/lib/*javafx* \
               /opt/jdk/jre/lib/*jfx* \
               /opt/jdk/jre/lib/amd64/libdecora_sse.so \
               /opt/jdk/jre/lib/amd64/libprism_*.so \
               /opt/jdk/jre/lib/amd64/libfxplugins.so \
               /opt/jdk/jre/lib/amd64/libglass.so \
               /opt/jdk/jre/lib/amd64/libgstreamer-lite.so \
               /opt/jdk/jre/lib/amd64/libjavafx*.so \
               /opt/jdk/jre/lib/amd64/libjfx*.so \
    && POLICY_DIR="UnlimitedJCEPolicyJDK${JAVA_VERSION_MAJOR}" \
    && curl -s -k -L -C - -b "oraclelicense=accept-securebackup-cookie" \
    ${build_fileserver}/otn-pub/java/jce/${JAVA_VERSION_MAJOR}/jce_policy-${JAVA_VERSION_MAJOR}.zip > policy.zip \
    && unzip policy.zip \
    && cp -f ${POLICY_DIR}/US_export_policy.jar /opt/jdk/jre/lib/security/US_export_policy.jar \
    && cp -f ${POLICY_DIR}/local_policy.jar /opt/jdk/jre/lib/security/local_policy.jar \
    && rm -rf ${POLICY_DIR} \
    && rm -f policy.zip

## install graphviz for maven site javadoc
RUN apt-get update -y \
    && apt-get install -y graphviz \
    && apt-get -q autoremove \
    && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

## install maven && gradle
RUN MAVEN_VERSION="3.5.3" \
    && if [ -z "${build_fileserver}" ]; then \
         wget -q -O apache-maven-${MAVEN_VERSION}-bin.tar.gz \
           http://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz; \
       else \
         wget -q -O apache-maven-${MAVEN_VERSION}-bin.tar.gz \
           ${build_fileserver}/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz; \
       fi \
    && mkdir -p /opt \
    && tar xf apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt \
    && ln -sf /opt/apache-maven-${MAVEN_VERSION} /opt/maven \
    && rm apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    && GRADLE_VERSION="4.7" \
    && if [ -z "${build_fileserver}" ]; then \
         wget -q -O gradle-${GRADLE_VERSION}-bin.zip https://downloads.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip; \
       else \
         wget -q -O gradle-${GRADLE_VERSION}-bin.zip ${build_fileserver}/distributions/gradle-${GRADLE_VERSION}-bin.zip; \
       fi \
    && unzip gradle-${GRADLE_VERSION}-bin.zip \
    && mv gradle-${GRADLE_VERSION} /opt \
    && ln -sf /opt/gradle-${GRADLE_VERSION} /opt/gradle \
    && rm gradle-${GRADLE_VERSION}-bin.zip

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV JAVA_HOME /opt/jdk
ENV M2_HOME /opt/maven
ENV GRADLE_HOME /opt/gradle
ENV JAVA_OPTS -Duser.language=zh -Duser.region=CN -Dfile.encoding='UTF-8' -Duser.timezone='Asia/Shanghai'
ENV NODE_HOME /opt/node
ENV PATH ${PATH}:${JAVA_HOME}/bin:${NODE_HOME}/bin:${M2_HOME}/bin:${GRADLE_HOME}/bin
