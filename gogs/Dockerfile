
# see: https://github.com/gogits/gogs/blob/v0.9.97/Dockerfile

FROM gogs/gogs:0.9.141

ARG build_fileserver

VOLUME ["/app/gogs/data"]

#COPY docker/wait-for-it.sh /app/gogs/wait-for-it.sh
RUN echo "https://mirror.tuna.tsinghua.edu.cn/alpine/v3.3/main" > /etc/apk/repositories && \
    echo "https://mirror.tuna.tsinghua.edu.cn/alpine/v3.3/community" >> /etc/apk/repositories && \
    echo "https://mirror.tuna.tsinghua.edu.cn/alpine/edge/testing/" >> /etc/apk/repositories && \
    apk --update add tzdata && \
    apk add bash git openssh curl ca-certificates tar && \
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    apk del tzdata && \
    rm -rf /tmp/* /var/cache/apk/* && \
    echo "UTC+8:00" > /etc/TZ

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

ADD docker/install_waitforit.sh /root/
RUN /root/install_waitforit.sh

COPY docker/gogs_utils.sh /app/gogs/gogs_utils.sh
COPY docker/git_init.sh /app/gogs/git_init.sh
COPY docker/entrypoint.sh /app/gogs/entrypoint.sh
RUN chmod 755 /app/gogs/*.sh

ENTRYPOINT ["/app/gogs/entrypoint.sh"]
CMD ["/bin/s6-svscan", "/app/gogs/docker/s6/"]
