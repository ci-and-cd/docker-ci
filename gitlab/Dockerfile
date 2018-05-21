
FROM gitlab/gitlab-ce:10.7.3-ce.0

VOLUME ["/app/gitlab/data"]

ARG build_fileserver

COPY docker/debconf.txt /etc/debconf.txt
RUN sed -i 's/http:\/\/archive.ubuntu.com\/ubuntu\//http:\/\/mirrors.163.com\/ubuntu\//g' /etc/apt/sources.list \
    && apt-get update -y \
    && apt-get -yq install --reinstall locales tzdata debconf \
    && debconf-set-selections /etc/debconf.txt \
    && echo "Asia/Shanghai" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata \
    && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
    && dpkg-reconfigure -f noninteractive locales \
#    && apt-get upgrade -y \
    && apt-get install -y apt-transport-https build-essential ca-certificates curl httpie jq nano net-tools python python-pip unzip vim wget \
    && apt-get -q autoremove \
    && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

#ENV JAVA_OPTS -Duser.language=zh -Duser.region=CN -Dfile.encoding='UTF-8' -Duser.timezone='Asia/Shanghai'

COPY docker/default_deploy_key.pub /app/gitlab/data/default_deploy_key.pub
COPY docker/gitlab_utils.sh /app/gitlab/gitlab_utils.sh
COPY docker/wait-for-it.sh /app/gitlab/wait-for-it.sh
COPY docker/git_init.sh /app/gitlab/git_init.sh
COPY docker/entrypoint.sh /app/gitlab/entrypoint.sh
RUN chmod 755 /app/gitlab/*.sh

ENTRYPOINT ["/app/gitlab/entrypoint.sh"]
CMD ["/assets/wrapper"]
