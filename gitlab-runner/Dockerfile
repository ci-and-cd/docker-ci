
FROM home1oss/ci-ubuntu:16.04

ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64 /usr/bin/dumb-init
RUN chmod +x /usr/bin/dumb-init

RUN echo "deb https://packages.gitlab.com/runner/gitlab-ci-multi-runner/ubuntu/ xenial main" > /etc/apt/sources.list.d/runner_gitlab-ci-multi-runner.list \
    && wget -q -O - https://packages.gitlab.com/gpg.key | apt-key add - \
    && apt-get update -y \
    && apt-get install -y gitlab-ci-multi-runner=9.1.1 \
    && apt-get clean \
    && mkdir -p /etc/gitlab-runner/certs \
    && chmod -R 700 /etc/gitlab-runner \
    && rm -rf /var/lib/apt/lists/*

ADD docker/entrypoint /
RUN chmod +x /entrypoint

COPY docker/set_env.sh /root/
# Set environment variables, add user gitlab-runner into docker group, fix Directory permissions.
RUN chmod +x /root/set_env.sh && \
    /root/set_env.sh && \
    gpasswd -a gitlab-runner docker && \
    chown -R gitlab-runner:root /opt/node-*/lib && \
    chown -R gitlab-runner:root /opt/node-*/bin

VOLUME ["/etc/gitlab-runner", "/home/gitlab-runner"]
ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint"]
CMD ["run", "--user=gitlab-runner", "--working-directory=/home/gitlab-runner"]
