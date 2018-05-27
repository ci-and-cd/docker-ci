#!/usr/bin/env bash

# see: https://github.com/jwilder/dockerize

mkdir -p /data/ssh
mkdir -p /data/gogs

. git_init.sh

case $1 in
    "git_init")
        git_init
        ;;
    "export_git_admin_key")
        export_git_admin_key
        ;;

    "export_git_deploy_key")
        export_git_deploy_key
        ;;

    *)
        echo -e "Usage: $0 param
    param are follows:
        git_init
        export_git_admin_key   export git admin user's key (ssh private key)
        export_git_deploy_key  export git project's deploy key (ssh public key)
        args                   pass to service entry point.
                               gogs's default is: /bin/s6-svscan /app/gogs/docker/s6/
        "
        git_init &
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        echo "start git service"
        exec "$@"
        ;;
esac
