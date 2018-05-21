#!/usr/bin/env bash

# for gogs:0.9.97

# : is %3A
# / is %2F
# @ is %40

# arguments: git_http_prefix, git_hostname, git_http_port, git_admin_user, git_admin_passwd
# returns:
git_service_install() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_install ${4}:******@${1}"
    local var_git_app_url="http://${2}:${3}"
    curl -i -X POST -H 'Content-Type: application/x-www-form-urlencoded' \
    -d "db_type=SQLite3" \
    -d "db_host=127.0.0.1:3306" \
    -d "db_user=root" \
    -d "db_passwd=" \
    -d "db_name=gogs" \
    -d "db_path=data/gogs.db" \
    -d "log_root_path=/data/log" \
    -d "repo_root_path=/data/git/gogs-repositories" \
    -d "smtp_host=" \
    -d "smtp_from=" \
    -d "smtp_email=" \
    -d "smtp_passwd=" \
    -d "enable_captcha=on" \
    -d "run_user=git" \
    -d "ssh_port=22" \
    -d "http_port=3000" \
    -d "ssl_mode=disable" \
    -d "app_name=private+git" \
    -d "domain=${2}" \
    -d "app_url=${var_git_app_url}/" \
    -d "admin_name=${4}" \
    -d "admin_passwd=${5}" \
    -d "admin_confirm_passwd=${5}" \
    -d "admin_email=${4}@${2}" \
    "${1}/install" 2>/dev/null > /dev/null
}

# arguments: git_http_prefix, git_user_name, git_user_passwd
# returns:   _csrf token
git_service_login() {
    rm -f COOKIE
    curl -X POST -H 'Content-Type: application/x-www-form-urlencoded' \
    -L \
    -c COOKIE \
    -d "user_name=${2}" \
    -d "password=${3}" \
    -d "remember=on" \
    "${1}/user/login?redirect_to=" 2>/dev/null > /dev/null
    echo "$(cat COOKIE | grep _csrf | awk '{print $7}')"
}

# arguments: git_http_prefix, git_user_name, git_user_passwd, git_group_name
# returns:
git_service_create_orgs() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_create_repo ${1} ${2} ${4}"
    local csrf_token=$(git_service_login $1 $2 $3)
    if [ ! -f COOKIE ]; then echo "COOKIE not found."; exit 1; fi

    # https://github.com/gogits/go-gogs-client/wiki/Administration-Organizations
    curl -i -X POST \
       -b COOKIE \
       -H "Content-Type:application/json" \
       -d \
    '{
      "username": "'${4}'"
     }' \
    "${1}/api/v1/admin/users/${2}/orgs" 2>/dev/null > /dev/null
}

# arguments: git_http_prefix, git_user_name, git_user_passwd, git_group_name, repo_name
# returns:
git_service_create_repo() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_create_repo ${1} ${2} ${4}/${5}"
    local csrf_token=$(git_service_login $1 $2 $3)
    if [ ! -f COOKIE ]; then echo "COOKIE not found."; exit 1; fi
    git_service_create_orgs $1 $2 $3 $4

    # https://github.com/gogits/go-gogs-client/wiki/Repositories
    curl -i -X POST \
    -b COOKIE \
    -H "Content-Type:application/json" \
    -d \
    '{
        "name": "'$5'",
        "description": "'$5'",
        "private": false
    }' \
    "${1}/api/v1/org/${4}/repos" 2>/dev/null > /dev/null
}

# arguments: git_http_prefix, git_user_name, git_user_passwd, git_group_name, repo_name, public_key_file
# returns:
git_service_deploy_key() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_deploy_key ${1} ${2} ${4}/${5} ${6}"
    local title="$(cat ${6} | cut -d' ' -f3)_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
    local content="$(cat ${6} | cut -d' ' -f1) $(cat ${6} | cut -d' ' -f2)"
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_deploy_key title: ${title}"
    #echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_deploy_key content: ${content}"
    local csrf_token="$(git_service_login $1 $2 $3)"
    if [ ! -f COOKIE ]; then echo "COOKIE not found."; exit 1; fi
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_deploy_key csrf_token: ${csrf_token}"
    curl -i -X POST -H 'Content-Type: application/x-www-form-urlencoded' \
    -b COOKIE \
    -d "_csrf=${csrf_token}" \
    -d "title=${title}" \
    --data-urlencode "content=${content}" \
    "${1}/${4}/${5}/settings/keys" 2>/dev/null > /dev/null
}

# arguments: git_http_prefix, git_user_name, git_user_passwd, public_key_file
# returns:
git_service_ssh_key() {
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_ssh_key ${1} ${2} ${4}"
    local title="$(cat ${4} | cut -d' ' -f3)_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)"
    local content="$(cat ${4} | cut -d' ' -f1) $(cat ${4} | cut -d' ' -f2)"
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_ssh_key title: ${title}"
    #echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_ssh_key content: ${content}"
    local csrf_token="$(git_service_login $1 $2 $3)"
    if [ ! -f COOKIE ]; then echo "COOKIE not found."; exit 1; fi
    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_service_ssh_key csrf_token: ${csrf_token}"
    curl -i -X POST -H 'Content-Type: application/x-www-form-urlencoded' \
    -b COOKIE \
    -d "_csrf=${csrf_token}" \
    -d "title=${title}" \
    --data-urlencode "content=${content}" \
    "${1}/user/settings/ssh"
    # 2>/dev/null > /dev/null
    #--data-urlencode
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


# arguments: git_http_prefix, git_user_name, git_user_passwd, git_group_name, repo_name, webhook_url
# returns: http_status 201 created
git_web_hook() {
   echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> git_web_hook ${1} ${2} ${4}/${5} ${6}"
    local csrf_token=$(git_service_login $1 $2 $3)
    if [ ! -f COOKIE ]; then echo "COOKIE not found."; exit 1; fi

    # https://github.com/gogits/go-gogs-client/wiki/Repositories-Webhooks
    curl -i -X POST \
       -b COOKIE \
       -H "Content-Type:application/json" \
       -d \
    '{
        "type": "gogs",
        "Config": {
            "url": "'${6}'",
            "content_type": "json"
        },
        "events": [
            "push"
        ],
        "active": true
    }' \
    "${1}/api/v1/repos/${4}/${5}/hooks" 2>/dev/null > /dev/null
}
