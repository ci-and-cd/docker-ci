
# jenkins-swarm-slave
jenkins-swarm-slave

## Environment variables

- INFRASTRUCTURE_CONF_GIT_TOKEN
> see docker-gitlab/gitlab-runner for more info

## Note

This should be done by a cron script on host that fix permission of '/var/run/docker.sock' periodically

```
sudo chmod a+rw /var/run/docker.sock
```

## Auto-provision slaves

- `export INFRASTRUCTURE_CONF_GIT_TOKEN=<your_INFRASTRUCTURE_CONF_GIT_TOKEN>`

- Create a user

- Replace user/password in deploy descriptor of k8s or docker-compose

## Provision on k8s

- Do steps in 'Auto-provision slaves' section

- Generate jenkins-swarm-slave-secret.yaml

```sh
sed "s#<PUT_BASE64_INFRASTRUCTURE_CONF_GIT_TOKEN_HERE_MANUALLY>#$(echo -n ${INFRASTRUCTURE_CONF_GIT_TOKEN} | base64 -w 0)#" jenkins-swarm-slave-secret.template \
> jenkins-swarm-slave-secret.yaml
```

- Run `kubectl create -f jenkins-swarm-slave-secret.yaml` and `kubectl create -f jenkins-swarm-slave-deploy.yaml` to deploy

- `kubectl get po` to see jenkins-swarm-slave's pod

## References

[https://wiki.jenkins-ci.org/display/JENKINS/Swarm+Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Swarm+Plugin)
[https://hub.docker.com/r/csanchez/jenkins-swarm-slave/](https://hub.docker.com/r/csanchez/jenkins-swarm-slave/)
[https://github.com/carlossg/jenkins-swarm-slave-docker](https://github.com/carlossg/jenkins-swarm-slave-docker)

[https://github.com/evarga/docker-images](https://github.com/evarga/docker-images)
[https://github.com/code-troopers/docker-jenkins-slaves](https://github.com/code-troopers/docker-jenkins-slaves)

[https://github.com/yasn77/docker-jenkins-slave](https://github.com/yasn77/docker-jenkins-slave)
[https://github.com/jenkinsci/docker-ssh-slave](https://github.com/jenkinsci/docker-ssh-slave)
