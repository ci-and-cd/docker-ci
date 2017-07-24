
# gitlab-runner

## Start and register a runner

1. INFRASTRUCTURE_CONF_GIT_TOKEN

OSS's ci script need the INFRASTRUCTURE_CONF_GIT_TOKEN to access script or configuration in internal or private repository.

- There are 2 ways to get INFRASTRUCTURE_CONF_GIT_TOKEN from gitlab:

  1. From git service page (e.g. gitlab: http(s)://gitlab.local:10080/profile/personal_access_tokens page).
  2. From cli (e.g. gitlab: `curl --request POST "http://gitlab.local:10080/api/v3/session?login=user&password=user_pass"`).

- INFRASTRUCTURE_CONF_GIT_TOKEN need to be set before container start by `export INFRASTRUCTURE_CONF_GIT_TOKEN=<your_INFRASTRUCTURE_CONF_GIT_TOKEN>`.

2. Prepare directories and files on host
```
docker run --privileged=true --rm -v /var/run/docker.sock:/var/run/docker.sock busybox chmod a+rw /var/run/docker.sock
docker run --privileged=true --rm -v /var/run/docker.sock:/var/run/docker.sock busybox ls -l /var/run/docker.sock
```
<del>
```
mkdir -p ${HOME}/.oss/gitlab-runner.local/home/gitlab-runner ${HOME}/.oss/gitlab-runner.local/etc/gitlab-runner
chmod -R 777 ${HOME}/.oss/gitlab-runner.local
```
</del>

Gitlab can not distribute settings and keys like jenkins, need to mount or download manually (e.g. maven's ~/.m2/settings-security.xml or git deploy key).

3. Execute `docker-compose up -d`

4. Find token for runner.
Shared: Goto admin/runners page (e.g. http(s)://gitlab.local:10080/admin/runners).
Specific: Goto repo's settings/ci_cd page (e.g. http(s)://gitlab.local:10080/<namespace>/<repo>/settings/ci_cd).

5. Execute `docker exec -it gitlab-runner.local gitlab-runner register` and input following info (in <>).
```
Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com/):
<e.g. http://gitlab.local:10080/>
Please enter the gitlab-ci token for this runner:
<Token found in step 4>
Please enter the gitlab-ci description for this runner:
<gitlab-runner-<ip>>
Please enter the gitlab-ci tags for this runner (comma separated):
<gitlab-runner>
Whether to run untagged builds [true/false]:
<true>
Whether to lock Runner to current project [true/false]:
<false>
Registering runner... succeeded runner=********
Please enter the executor: parallels, virtualbox, shell, ssh, docker+machine, docker-ssh+machine, kubernetes, docker, docker-ssh:
<shell>
Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

## Advanced configuration (config.toml)
Use `CONFIG_FILE` environment variable specify a configuration file.
[Official doc for config.toml](https://docs.gitlab.com/runner/configuration/advanced-configuration.html)

```
# e.g. set concurrent to 3
docker exec -it gitlab-runner.local /bin/sed -Ei 's#^concurrent = [0-9]+$#concurrent = 3#g' /etc/gitlab-runner/config.toml
```

## Note
- Container instance needs to access docker (/var/run/docker.sock) on host.
```
sudo chmod a+rw /var/run/docker.sock
```

- When register a runner "Whether to run untagged builds" should be true.

- You can inspect container by:
```
docker exec -it gitlab-runner.local cat /etc/gitlab-runner/config.toml
docker exec -it gitlab-runner.local cat /home/gitlab-runner/.gitlab-runner/config.toml
docker exec -it gitlab-runner.local cat /home/gitlab-runner/.ssh/config
docker exec -it gitlab-runner.local ls -la /home/gitlab-runner/.ssh
docker exec -it gitlab-runner.local ls -la /home/gitlab-runner/.docker
```


- ERROR: Uploading artifacts to coordinator... too large archive  id=116 responseStatus=413

https://gitlab.com/gitlab-org/gitlab-ce/issues/20612
![](src/site/markdown/images/gitlab-runner-max-artifacts-size.png)
