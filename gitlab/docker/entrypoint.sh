#!/usr/bin/env bash

# see: https://github.com/jwilder/dockerize

mkdir -p /data/ssh
mkdir -p /data/gitlab

. /app/gitlab/init_git.sh

case $1 in
    "init_git")
        init_git
        ;;
    "export_git_admin_key")
        export_git_admin_key
        ;;

    "export_git_deploy_key")
        export_git_deploy_key
        ;;

    "/assets/wrapper")
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> init_git in background, see /var/log/gitlab/init_git.log >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        init_git &>/var/log/gitlab/init_git.log &
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> exec $@ >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        exec "$@"
        ;;

    *)
        echo "command: $@"
        echo -e "Usage: $0 param
    param are follows:
        init_git
        export_git_admin_key   export git admin user's key (ssh private key)
        export_git_deploy_key  export git project's deploy key (ssh public key)
        args                   pass to service entry point.
                               gitlab's default is: /bin/s6-svscan /app/gitlab/docker/s6/
        "
        exec "$@"
        ;;
esac
