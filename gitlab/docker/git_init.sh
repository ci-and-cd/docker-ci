#!/usr/bin/env bash

. /app/gitlab/gitlab_utils.sh

# arguments:
# returns: configserver_webhook_endpoint
configserver_webhook_endpoint() {
    if [[ -z "${CONFIGSERVER_WEBHOOK_ENDPOINT}" ]];then
        echo "no CONFIGSERVER_WEBHOOK_ENDPOINT specified, can not config HTTP endpoint for webhooks";
    else
        echo "${CONFIGSERVER_WEBHOOK_ENDPOINT}";
    fi
}

# arguments:
# returns:
git_init_admin_key() {
    if [ ! -f $(git_admin_key) ]; then
        ssh-keygen -t rsa -N "" -C "$(git_admin_user)" -f $(git_admin_key)
        chmod 600 $(git_admin_key)
        chmod 600 $(git_admin_key).pub
    fi
}

print_info() {
    echo "--------------------------------------------------------------------------------"
    echo "git_admin_key public:"
    cat "$(git_admin_key)".pub
    echo "git_deploy_key:"
    cat "$(git_deploy_key)"

    local var_git_workspace="$(git_workspace)"
    echo "files in GIT_WORKSPACE ${var_git_workspace}:"
    ls -l ${var_git_workspace}
    echo "--------------------------------------------------------------------------------"
}

get_git_group_name(){
    local git_repo_dir=$1
    local var_git_group_name=$(cd ${git_repo_dir}; git remote -v | grep -E 'upstream.+(fetch)' | sed -E 's#.+[:|/]([^/]+)/[^/]+\.git.*#\1#');
    if [ -z ${var_git_group_name} ]; then
        var_git_group_name=$(cd ${git_repo_dir}; git remote -v | grep -E 'origin.+(fetch)' | sed -E 's#.+[:|/]([^/]+)/[^/]+\.git.*#\1#');
    fi
    echo ${var_git_group_name}
}

# arguments:
# returns:
git_init() {
    echo "git_init $@"

    local var_git_work_space="$(git_workspace)"

    git_init_admin_key
    print_info

    local default_git_http_port="80"
    if [ -f /opt/gitlab/embedded/service/gitlab-rails/config/gitlab.yml ]; then default_git_http_port=$(cat /opt/gitlab/embedded/service/gitlab-rails/config/gitlab.yml | grep port | head -n1 | awk '{print $2}'); fi
    local default_git_ssh_port="22"
    if [ -f /assets/sshd_config ]; then default_git_ssh_port=$(cat /assets/sshd_config | grep Port | awk '{print $2}'); fi

    # config http and ssh ports
    if [ "${default_git_http_port}" != "$(git_http_port)" ] || [ "${default_git_ssh_port}" != "$(git_ssh_port)" ]; then
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> waiting default ports (${default_git_http_port}, ${default_git_ssh_port}) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        git_wait_service_up "localhost" "${default_git_http_port}" "${default_git_ssh_port}"
        git_wait_http_ok "localhost" "${default_git_http_port}"

        if [ -n "${GITLAB_SHELL_SSH_PORT}" ]; then
            echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> set ssh port >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
            sed -i "s|^# gitlab_rails\['gitlab_shell_ssh_port'\]|gitlab_rails['gitlab_shell_ssh_port']|g" /etc/gitlab/gitlab.rb
            sed -i -r "s|(^gitlab_rails\['gitlab_shell_ssh_port'\] = )(.*?)|\1$(git_ssh_port)|g" /etc/gitlab/gitlab.rb
            sed -i -r "s|(^Port\s)(.*?)|\1$(git_ssh_port)|g" /assets/sshd_config
            #sed -i -r "s|(^Port\s)(.*?)|\1$(git_ssh_port)|g" /etc/ssh/sshd_config
            service ssh restart
        fi
        if [ -n "${GIT_HTTP_PORT}" ]; then
            echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> set http port >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
            sed -i "s|^# external_url|external_url|g" /etc/gitlab/gitlab.rb
            sed -i -r "s|(^external_url ')(.*?)(')|\1$(git_http_prefix)\3|g" /etc/gitlab/gitlab.rb
        fi
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> reconfigure >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        gitlab-ctl reconfigure
        if [ -n "${GITLAB_SHELL_SSH_PORT}" ]; then
            sed -i -r "s|^(\s+ssh_port:\s+)(.*?)|\1$(git_ssh_port)|g" /opt/gitlab/embedded/service/gitlab-rails/config/gitlab.yml
        fi
        while [ -z "$(cat /opt/gitlab/embedded/service/gitlab-rails/config/gitlab.yml | grep "port: ${GIT_HTTP_PORT}")" ]; do
            echo "GIT_HTTP_PORT not found in /opt/gitlab/embedded/service/gitlab-rails/config/gitlab.yml, reconfigure again."
            gitlab-ctl reconfigure
            sleep 15s
        done
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> restart >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        gitlab-ctl restart

        #gitlab-rake gitlab:check
        #
        # incorrect
        # edit /opt/gitlab/embedded/service/gitlab-rails/config/gitlab.yml
        # gitlab.host: $(git_hostname)
        # gitlab.port: $(git_http_port)
        # gitlab.ssh_port: $(git_ssh_port)
        # edit /opt/gitlab/embedded/conf/nginx.conf server.listen server_name.name
        #gitlab-ctl restart
        #
        #/opt/gitlab/embedded/service/gitlab-shell/config.yml
        #/var/opt/gitlab/gitlab-shell/config.yml
    fi

    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> waiting ports ($(git_http_port), $(git_ssh_port)) >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    git_wait_service_up
    git_wait_http_ok

    git_service_install $(git_admin_user) $(git_admin_passwd)

    # setup ssh key into for git command-line access (push repositories)
    git_service_ssh_key $(git_admin_user) $(git_admin_passwd) $(git_admin_key).pub
    # edit ~/.ssh/config
    git_service_ssh_config $(git_hostname) $(git_ssh_port) $(git_admin_key)

    # auto push local git repositories (${WORKSPACE_ON_HOST:-../../}) to git service
    if [ ! -f "/app/gitlab/data/.lock_git_init" ] && [ "${SKIP_AUTO_REPO_INIT}" == "false" ]; then
        # find all repositories that has a '-config' suffix
        local git_repos=($(find ${var_git_work_space} -mindepth 1 -maxdepth 1 -type d | awk -F "${var_git_work_space}/" '{print $2}'))
        #  | grep -E '.+-config.{0}'

        for git_repo in "${git_repos[@]}"; do
            local repo_dir="${var_git_work_space}/${git_repo}"
            if [ -d ${repo_dir}/.git ]; then
                # find remote git group
                local var_git_group_name=$(get_git_group_name ${repo_dir})
                echo "creating git_repo: ${var_git_group_name}/${git_repo}"
                git_service_create_repo $(git_admin_user) $(git_admin_passwd) ${var_git_group_name} ${git_repo}

                # git branches have been checkout
                #git_branches=($(cd ${repo_dir}; git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)'))
                # git branches of refs/remotes/origin/* except HEAD
                git_branches=($(cd ${repo_dir}; git for-each-ref --sort=-committerdate refs/remotes/origin/ --format='%(refname:short)' | sed 's#^origin/##' | grep -v HEAD))
                echo "git_branches: ${git_branches[@]}"
                for git_branch in "${git_branches[@]}"; do
                    git_service_push_repo ${var_git_work_space} $(git_hostname) $(git_hostname) ${var_git_group_name} ${git_repo} refs/remotes/origin/${git_branch} refs/heads/${git_branch}
                done

                # configserver gourp need webhook
                if [ ${var_git_group_name} == "configserver" ] && [ $(configserver_webhook_endpoint) ];then
                    git_web_hook $(git_admin_user) $(git_admin_passwd) ${var_git_group_name} ${git_repo} $(configserver_webhook_endpoint)
                fi

            fi
        done

        # setup deploy key for client read-only access
        #local var_deploy_key=$(git_deploy_key_file "$(git_deploy_key)")
        local var_deploy_key="$(git_deploy_key)"
        if [ ! -z ${var_deploy_key} ]; then
            for git_repo in "${git_repos[@]}"; do
                local repo_dir="${var_git_work_space}/${git_repo}"
                if [ -d ${repo_dir}/.git ]; then
                    echo "set deploy key for git_repo: ${git_repo}"
                    local var_git_group_name=$(get_git_group_name ${repo_dir})
                    git_service_deploy_key $(git_admin_user) $(git_admin_passwd) ${var_git_group_name} ${git_repo} ${var_deploy_key}
                fi
            done
        else
            echo "git_deploy_key_file not found."
            exit 1
        fi
    else
        echo "Skip auto repo init"
    fi

    echo "already initialized!" > /app/gitlab/data/.lock_git_init
    echo "git_init done"
}

export_git_admin_key() {
    cat $(git_admin_key)
}

export_git_deploy_key() {
    cat $(git_deploy_key)
}
