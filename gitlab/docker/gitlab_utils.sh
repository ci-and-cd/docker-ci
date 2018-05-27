#!/usr/bin/env bash

# : is %3A
# / is %2F
# @ is %40

# arguments:
# returns: git_workspace
git_workspace() {
    if [ -z "${GIT_WORKSPACE}" ]; then echo "no GIT_WORKSPACE specified"; exit 1; else echo "${GIT_WORKSPACE}"; fi
}

# arguments:
# returns: git_deploy_key
git_deploy_key() {
    if [ -z "${GIT_DEPLOY_KEY}" ]; then echo "no GIT_DEPLOY_KEY specified"; exit 1; else echo "${GIT_DEPLOY_KEY}"; fi
}

# arguments:
# returns: git_admin_key
git_admin_key() {
    if [ -z "${GIT_VOLUME}" ]; then echo "no GIT_VOLUME specified"; exit 1; else echo "${GIT_VOLUME}/$(git_hostname)"; fi
}

# arguments:
# returns: git_admin_user
git_admin_user() {
    if [ -z "${GIT_ADMIN_USERNAME}" ]; then echo "no GIT_ADMIN_USERNAME specified"; exit 1; else echo "${GIT_ADMIN_USERNAME}"; fi
}

# arguments:
# returns: git_admin_passwd
git_admin_passwd() {
    if [[ -z "${GIT_ADMIN_PASSWORD}" ]]; then echo "$(git_admin_user)_pass"; else echo "${GIT_ADMIN_PASSWORD}"; fi
}

# arguments:
# returns: git_root_passwd
git_root_passwd() {
    if [[ -z "${GITLAB_ROOT_PASSWORD}" ]]; then echo "no GITLAB_ROOT_PASSWORD specified"; exit 1; else echo "${GITLAB_ROOT_PASSWORD}"; fi
}

git_root_email(){
    GITLAB_ROOT_EMAIL=${GIT_ADMIN_EMAIL}
    if [[ -z "${GIT_ADMIN_EMAIL}" ]]; then echo "$(git_admin_user)@$(git_hostname)"; else echo "${GIT_ADMIN_EMAIL}"; fi
}


# arguments:
# returns: git_hostname
git_hostname() {
    if [ -z "${GIT_HOSTNAME}" ]; then echo "gitlab.local"; else echo "${GIT_HOSTNAME}"; fi
}

# arguments:
# returns: git_ssh_port
git_ssh_port() {
    if [ -z "${GITLAB_SHELL_SSH_PORT}" ]; then echo "no GITLAB_SHELL_SSH_PORT specified"; exit 1; else echo "${GITLAB_SHELL_SSH_PORT}"; fi
}

# arguments:
# returns: git_http_port
git_http_port() {
    if [ -z "${GIT_HTTP_PORT}" ]; then echo "no GIT_HTTP_PORT specified"; exit 1; else echo "${GIT_HTTP_PORT}"; fi
}

git_http_prefix() {
    echo "http://$(git_hostname):$(git_http_port)"
}

# arguments: host, git_http_port, git_ssh_port
git_wait_service_up() {
    if [ ! -f /usr/bin/waitforit ]; then
        echo "git_wait_service_up waitforit not found, exit."
        exit 1
    else
        echo "git_wait_service_up waitforit found."
    fi

    echo "git_wait_service_up."
#    /app/gitlab/wait-for-it.sh $1:${var_git_ssh_port} -t 600
#    /app/gitlab/wait-for-it.sh $1:${var_git_http_port} -t 600
    waitforit -address=tcp://$1:$2 -timeout=600
    waitforit -address=tcp://$1:$3 -timeout=600
    sleep 10
    echo "git_wait_service_up end."
}

# arguments:
git_wait_http_ok(){
    echo "wait http response Ok(200)"
    # 重试时间间隔
    local retry_interval=5
    # 重试次数
    local retry_times=100

    for i in $(seq 10); do
        local http_resp_status=$(curl -s -o /dev/null -I -w "%{http_code}\n" $(git_http_prefix)/help);
        echo "http response code :${http_resp_status}"
        if test ${http_resp_status} = "200"; then
            echo "gitlab service ok"
            break;
        fi
        echo "wait ${retry_interval} seconds"
        sleep ${retry_interval};
    done;
}

# arguments: git_user_name, git_user_passwd
# returns:   oauth2_token
# session endpoint removed on gitlab 9.x, see: https://docs.gitlab.com/ce/api/session.html
# see: https://github.com/python-gitlab/python-gitlab/issues/380
# see: https://docs.gitlab.com/ce/api/oauth2.html#resource-owner-password-credentials
# jq:  https://stedolan.github.io/jq/tutorial/
git_service_login() {
    #  printf '%s \n' ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_login"

#    echo $(curl -sb -X POST -d '' "$(git_http_prefix)/api/v4/session?login=${1}&password=${2}" \
#        | jq -r '.private_token')

    local body='{
      "grant_type": "password",
      "username": "'${1}'",
      "password":"'${2}'"
    }'
    echo $(curl -sb -X POST -H "Content-Type:application/json" -d "${body}" $(git_http_prefix)/oauth/token \
      | jq -r '.access_token')
}

# arguments: git_admin_user, git_admin_passwd
# returns:
git_service_install() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_install ${1}:******@$(git_http_prefix)"

    local oauth2_token=$(git_service_login "root" "$(git_root_passwd)")

    local body='{
      "email": "'${1}'@'$(git_hostname)'",
      "name": "'${1}'",
      "username": "'${1}'",
      "password":"'${2}'",
      "admin": true,
      "skip_confirmation": true
    }'
    # https://docs.gitlab.com/ce/api/users.html#user-creation
    curl -i -X POST \
      -H "Content-Type:application/json" \
      -H "Authorization: Bearer ${oauth2_token}" \
      -d "${body}"\
    "$(git_http_prefix)/api/v4/users"
# confirm user
#    curl -i -X POST \
#      -H "Content-Type: application/x-www-form-urlencoded" \
#      -d "_method=put&authenticity_token=${oauth2_token}" \
#    "$(git_http_prefix)/admin/users/${1}/confirm"
}

# arguments: git_user_name, git_user_passwd, git_group_name
# returns:
git_service_create_group() {
#    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_create_group $(git_http_prefix) ${1} ${3}"

    local oauth2_token=$(git_service_login $1 $2)

    local body='{
        "name": "'${3}'",
        "path": "'${3}'"
    }'
    # https://docs.gitlab.com/ce/api/groups.html#new-group
   curl -X POST \
   -H "Content-Type:application/json" \
   -H "Authorization: Bearer ${oauth2_token}" \
   -d "${body}"\
    "$(git_http_prefix)/api/v4/groups"
}

# arguments: git_user_name, git_user_passwd, git_group_name
# returns:
git_service_find_group_id() {
    # printf '%s \n' ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_find_group_id $(git_http_prefix) ${1} ${3}"

    local oauth2_token=$(git_service_login $1 $2)

    # https://docs.gitlab.com/ce/api/groups.html#search-for-group
    local var_group_id=$(curl -X GET \
      -H "Authorization: Bearer ${oauth2_token}" \
      "$(git_http_prefix)/api/v4/groups/${3}" \
      | jq -r '.id')
    echo ${var_group_id}
}


# arguments: git_user_name, git_user_passwd, git_group_name, git_project_name
# returns:
git_service_find_project_id() {
#    printf '%s\n' ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_find_project_id $(git_http_prefix) ${1} ${3} ${4}"

    local oauth2_token=$(git_service_login $1 $2)

    # https://docs.gitlab.com/ce/api/projects.html#get-single-project
    local project_id=$(curl -X GET \
      -H "Authorization: Bearer ${oauth2_token}" \
      "$(git_http_prefix)/api/v4/projects/${3}%2F${4}" \
      | jq -r '.id')
    echo ${project_id}
}

# arguments: git_user_name, git_user_passwd, git_group_name, repo_name
# returns:
git_service_create_repo() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_create_repo $(git_http_prefix) ${1} ${3} ${4}"

    git_service_create_group $1 $2 $3
    local group_id=$(git_service_find_group_id $1 $2 $3)

    local oauth2_token=$(git_service_login $1 $2)

    local body='{
      "name": "'${4}'",
      "namespace_id": '${group_id}'
    }'
    echo ${body}
    # https://docs.gitlab.com/ce/api/projects.html#create-project
    curl -i -X POST \
     -H "Content-Type:application/json" \
     -H "Authorization: Bearer ${oauth2_token}" \
     -d "${body}" \
    "$(git_http_prefix)/api/v4/projects"
}

# arguments: git_user_name, git_user_passwd, git_group_name, repo_name, public_key_file
# returns:
git_service_deploy_key() {
    local project_id=$(git_service_find_project_id ${1} ${2} ${3} ${4})
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_deploy_key $(git_http_prefix) ${1} ${3} ${4} ${5}"
    local title="$(cat ${5} | cut -d' ' -f3)_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
    local content="$(cat ${5} | cut -d' ' -f1) $(cat ${5} | cut -d' ' -f2)"
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_deploy_key title: ${title}"
    # echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_deploy_key content: ${content}"

    local oauth2_token=$(git_service_login $1 $2)

    # https://docs.gitlab.com/ce/api/deploy_keys.html#add-deploy-key
    local body='{
       "key" : "'${content}'",
       "id" : '${project_id}',
       "title" : "'${title}'",
       "can_push": true
    }'
    echo ${body}
    curl -i -X POST \
      -H "Authorization: Bearer ${oauth2_token}" \
      -H "Content-Type:application/json" \
      -d "${body}"\
    "$(git_http_prefix)/api/v4/projects/${project_id}/deploy_keys"

}

# arguments: git_user_name, git_user_passwd, public_key_file
# returns:
git_service_ssh_key() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_ssh_key $(git_http_prefix) ${1} ${3}"
    local title="$(cat ${3} | cut -d' ' -f3)_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
    local content="$(cat ${3} | cut -d' ' -f1) $(cat ${3} | cut -d' ' -f2)"
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_ssh_key title: ${title}"
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_ssh_key content: ${content}"

    local oauth2_token=$(git_service_login $1 $2)

    local body='{
      "title":"'${title}'",
      "key":"'${content}'"
     }'

    # https://docs.gitlab.com/ce/api/users.html#add-ssh-key
    curl -i -X POST \
      -H "Content-Type:application/json" \
      -H "Authorization: Bearer ${oauth2_token}" \
      -d "${body}" \
    "$(git_http_prefix)/api/v4/user/keys"
}

# arguments: git_hostname, git_ssh_port, private_key_file
# returns:
git_service_ssh_config() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_ssh_config ${1}:${2} ${3}"
    if [ ! -f ${3} ]; then
        echo "private_key_file ${3} not found"
        exit 1
    fi
    mkdir -p "${HOME}/.ssh"
    local sshconfig="${HOME}/.ssh/config"
    if [ ! -f ${sshconfig} ] || [ -z "$(cat ${sshconfig} | grep 'StrictHostKeyChecking no')" ]; then
        printf "\nHost *\n\tStrictHostKeyChecking no\n\tUserKnownHostsFile /dev/null\n" >> ${sshconfig}
    fi
    if [ -z "$(cat ${sshconfig} | grep Port | grep ${2})" ]; then
        printf "\nHost ${1}\n\tHostName ${1}\n\tPort ${2}\n\tUser git\n\tPreferredAuthentications publickey\n\tIdentityFile ${3}\n" >> ${sshconfig}
    fi
    chmod 644 ${sshconfig}
    cat ${sshconfig}
}

# arguments: repo_location, git_hostname, remote, git_group_name, repo_name, source_ref, target_ref
# returns:
git_service_push_repo() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_push_repo ${1}/${5} ${2} ${3} ${4}/${5} ${6} ${7}"
    local repo_dir="${1}/${5}"
    local remote="${3}"
    # git remote -v
    if [ -d ${repo_dir}/.git ]; then
        echo "git remote rm ${remote}; git remote add ${remote} git@${2}:${4}/${5}.git;"
        (cd ${repo_dir}; git remote rm ${remote}; git remote add ${remote} git@${2}:${4}/${5}.git;)
        echo "git push ${remote} ${6}:${7}"
        (cd ${repo_dir}; git push ${remote} ${6}:${7})
    else
        echo "git repo ${repo_dir}/.git not found"
    fi
}

# arguments: git_user_name, git_user_passwd, git_group_name, repo_name, webhook_url
# returns: http_status 201 created
git_web_hook() {
    local project_id=$(git_service_find_project_id ${1} ${2} ${3} ${4})
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_web_hook $(git_http_prefix) ${1} ${3} ${4} ${5}"

    local oauth2_token=$(git_service_login $1 $2)

    local body='{
        "url": "'${5}'",
        "enable_ssl_verification":false
    }'
    echo ${project_id}  ${body}
    # https://docs.gitlab.com/ce/api/projects.html#add-project-hook
   curl -v -X POST \
     -H "Authorization: Bearer ${oauth2_token}" \
     -H "Content-Type:application/json" \
     -d "${body}" \
   "$(git_http_prefix)/api/v4/projects/${project_id}/hooks"
}
