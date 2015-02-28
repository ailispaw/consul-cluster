# RancherOS Cluster with Consul

Verification of [talk2docker](https://github.com/ailispaw/talk2docker) and [RancherOS ISO Box](https://github.com/ailispaw/rancheros-iso-box) with [docker-consul](https://github.com/progrium/docker-consul).

### Requirements

- [talk2docker](https://github.com/ailispaw/talk2docker) >= v1.1.0
- [RancherOS ISO Box](https://github.com/ailispaw/rancheros-iso-box) >= v0.3.0
- [VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

### Setup a cluster

```
$ make
$ make status
$ make test
```

### Add a redis service

```
$ make redis
$ make redis-status
```

### References

- [Dockerized Consul Agent](https://github.com/progrium/docker-consul)
- [Service registry bridge for Docker](https://github.com/gliderlabs/registrator)
- [DockerコンテナをConsulで管理する方法 - Qiita](http://qiita.com/foostan/items/a679ffcf3e20ff2f6032)
