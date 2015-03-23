T2D := talk2docker --config=talk2docker.yml

NODES := node-01 node-02 node-03

GET_IP  := ifconfig eth1 | awk '/inet addr/{print substr(\\$$2,6)}'
NODE_IP := `vagrant ssh node -c "$(GET_IP)" -- -T`

up: $(NODES)

$(NODES):
	vagrant up $@

	$(T2D) host add $@ "tcp://$(NODE_IP:node=$@):2375" || $(T2D) host switch $@

	$(T2D) compose consul.yml $@ --name=consul --hostname=$@ \
		--env=JOIN_IP=$(NODE_IP:node=node-01) --env=NODE_IP=$(NODE_IP:node=$@)
	$(T2D) container start consul
	$(T2D) ps -l

	$(T2D) compose consul.yml registrator --hostname=$@
	$(T2D) container start registrator
	$(T2D) ps -l

status:
	for node in $(NODES); do \
		$(T2D) --host=$$node ps ; \
	done

test:
	vagrant ssh node-01 -c "docker exec -t consul consul members" -- -T

	nslookup consul.service.consul $(NODE_IP:node=node-01)

clean:
	vagrant destroy -f
	$(RM) -r .vagrant
	$(RM) talk2docker.yml

.PHONY: up $(NODES) status test clean

redis:
	$(T2D) host switch node-03
	$(T2D) compose redis.yml
	$(T2D) container start redis
	$(T2D) ps -l

redis-status:
	curl -s $(NODE_IP:node=node-01):8500/v1/catalog/service/redis?pretty

	nslookup redis.service.consul $(NODE_IP:node=node-01)

	open http://$(NODE_IP:node=node-01):8500/ui/#/dc1/services/redis

redis-clean:
	$(T2D) host switch node-03
	$(T2D) container stop redis
	$(T2D) container rm redis

.PHONY: redis redis-status redis-clean

wordpress:
	$(T2D) host switch node-02
	$(T2D) compose wordpress.yml db
	$(T2D) container start db
	$(T2D) ps -l

	test -d wordpress/wordpress || (cd wordpress && \
		curl https://wordpress.org/latest.tar.gz | tar -xzf - && \
		cp wp-config.php wordpress/ && \
		cp router.php wordpress/)

	$(T2D) host switch node-03
	$(T2D) compose wordpress.yml web
	$(T2D) container start web
	$(T2D) ps -l

wordpress-status:
	curl -s $(NODE_IP:node=node-01):8500/v1/catalog/service/mysql?pretty

	nslookup mysql.service.consul $(NODE_IP:node=node-01)

	open http://$(NODE_IP:node=node-01):8500/ui/#/dc1/services/mysql

	open http://$(NODE_IP:node=node-03):8000/

wordpress-clean:
	$(T2D) host switch node-03
	-$(T2D) container stop web
	-$(T2D) container rm web

	$(T2D) host switch node-02
	$(T2D) container stop db
	$(T2D) container rm db

	$(RM) -r wordpress/wordpress

.PHONY: wordpress wordpress-status wordpress-clean

TOKEN := `$(T2D) --host=node-01 container logs token`

swarm:
	$(T2D) host switch node-01
	-$(T2D) container remove token manager agent -f
	$(T2D) compose swarm.yml create --name=token
	$(T2D) container start token
	$(T2D) container wait token
	echo $(TOKEN)

	$(T2D) compose swarm.yml manager --cmd=manage,token://$(TOKEN)
	$(T2D) container start manager
	$(T2D) ps -l

	for node in $(NODES); do \
		$(T2D) host switch $$node; \
		$(T2D) container remove agent -f; \
		$(T2D) compose swarm.yml agent --cmd=join,--addr=$(NODE_IP:node=$$node):2375,token://$(TOKEN); \
		$(T2D) container start agent; \
		$(T2D) ps -l; \
	done

swarm-status:
	docker -H tcp://$(NODE_IP:node=node-01):2380 info

swarm-clean:
	for node in $(NODES); do \
		$(T2D) host switch $$node; \
		$(T2D) container remove agent -f; \
	done

	$(T2D) host switch node-01
	-$(T2D) container remove token manager -f

.PHONY: swarm swarm-status swarm-clean
