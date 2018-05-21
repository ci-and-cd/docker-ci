#!/bin/sh

if [ -z "${build_fileserver}" ]; then build_fileserver="https://github.com"; fi
curl -Ls ${build_fileserver}/maxcnunes/waitforit/releases/download/v1.4.0/waitforit-linux_amd64 >> /usr/bin/waitforit && \
    chmod 755 /usr/bin/waitforit
