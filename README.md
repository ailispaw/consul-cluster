# Docker Cluster with Consul

Verification of [talk2docker](https://github.com/ailispaw/talk2docker) and [DockerRoot Vagrant Box](https://github.com/ailispaw/docker-root-packer) with [docker-consul](https://github.com/progrium/docker-consul).

### Requirements

- [talk2docker](https://github.com/ailispaw/talk2docker) >= v1.3.0
- [DockerRoot Vagrant Box](https://github.com/ailispaw/docker-root)
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

### Add a wordpress service

```
$ make wordpress
$ make wordpress-status
```

### Add a swarm service

```
$ make swarm
$ make swarm-status
```

### References

- [Dockerized Consul Agent](https://github.com/progrium/docker-consul)
- [Service registry bridge for Docker](https://github.com/gliderlabs/registrator)
- [DockerコンテナをConsulで管理する方法 - Qiita](http://qiita.com/foostan/items/a679ffcf3e20ff2f6032)
- [Getting started with Compose and Wordpress](https://github.com/docker/fig/blob/master/docs/wordpress.md)
- [ELB+Swarm+Compose+Consul+Registratorで夢は叶うのか(1) - Qiita](http://qiita.com/zERobYTe/items/dd9b2365c93da2638221)

