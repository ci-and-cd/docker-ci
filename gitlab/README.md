
# gitlab

  see: https://hub.docker.com/r/gitlab/gitlab-ce/

1. Prepare directories and files on host

  `mkdir -p ${HOME}/.oss/gitlab.local/etc/gitlab ${HOME}/.oss/gitlab.local/var/opt/gitlab ${HOME}/.oss/gitlab.local/var/log/gitlab`

2. Environment variables

  `export GIT_HOSTNAME=gitlab.local`

  Skip auto repo init, this works only after initialized at least once
  `export SKIP_AUTO_REPO_INIT=true`
    
  Set http prot (default 10080)
  `export GIT_HTTP_PORT=10080`
    
  Default deploy key is same as configserver's deploy key (/app/gitlab/data/default_deploy_key.pub).
  You can change it by mount a new key and set a new value for GIT_DEPLOY_KEY.
  Access gitlab's group_name/repo_name/settings/repository page to manage Deploy Keys.
  `export GIT_DEPLOY_KEY=/etc/gitlab/default_deploy_key.pub`

3. Boot

    docker-compose up -d

4. Entry point methods

  Export private key
  `docker exec gitlab.local /app/gitlab/entrypoint.sh export_git_admin_key > ~/.ssh/gitlab.local && chmod 600 ~/.ssh/gitlab.local`
