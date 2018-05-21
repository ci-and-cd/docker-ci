#!/usr/bin/env bash

NODE_PACKAGE="node"
NODE_VERSION="v6.11.0"

PACKAGE_NAME="${NODE_PACKAGE}-${NODE_VERSION}-linux-x64"
PACKAGE_TAR="${PACKAGE_NAME}.tar.xz"

if [ -z "${build_fileserver}" ]; then build_fileserver="https://nodejs.org"; fi
URL="${build_fileserver}/dist/${NODE_VERSION}/${PACKAGE_TAR}"

INSTALL_DIR=/opt

mkdir -p ${INSTALL_DIR} && \
  wget -q -O ${PACKAGE_TAR} ${URL} && \
  tar xf ${PACKAGE_TAR} -C ${INSTALL_DIR} && \
  ln -sf ${INSTALL_DIR}/${PACKAGE_NAME} ${INSTALL_DIR}/${NODE_PACKAGE} &&
  rm -f ${PACKAGE_TAR}
