#!/usr/bin/env bash

# see: https://github.com/jwilder/dockerize

mkdir -p /data/ssh
mkdir -p /data/gitlab

. /app/gitlab/git_init.sh

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

    "/assets/wrapper")
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_init in background, see /var/log/gitlab/git_init.log >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        git_init &>/var/log/gitlab/git_init.log &
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> exec $@ >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        exec "$@"
        ;;

    *)
        echo "command: $@"
        echo -e "Usage: $0 param
    param are follows:
        git_init
        export_git_admin_key   export git admin user's key (ssh private key)
        export_git_deploy_key  export git project's deploy key (ssh public key)
        args                   pass to service entry point.
                               gitlab's default is: /bin/s6-svscan /app/gitlab/docker/s6/
        "
        exec "$@"
        ;;
esac
