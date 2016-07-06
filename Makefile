T2D := talk2docker --config=talk2docker.yml

NODES := node-01 node-02 node-03

SSH_CONFIG := .ssh_config

GET_IP  := ifconfig eth1 | awk '/inet addr/{print substr(\\$$2,6)}'
NODE_IP := `ssh -F $(SSH_CONFIG) node "$(GET_IP)"`

up: $(NODES)

node-01:
	vagrant up $@
	vagrant ssh-config $@ > $(SSH_CONFIG)

	$(T2D) host add $@ "tcp://$(NODE_IP:node=$@):2375" || $(T2D) host switch $@

	$(T2D) compose consul.yml $@ --name=consul --hostname=$@ \
		--env=JOIN_IP=$(NODE_IP:node=node-01) --env=NODE_IP=$(NODE_IP:node=$@)
	$(T2D) container start consul
	$(T2D) ps -l

	$(T2D) compose consul.yml registrator --hostname=$@ --cmd=-ip,$(NODE_IP:node=$@),consul://consul:8500
	$(T2D) container start registrator
	$(T2D) ps -l

node-02 node-03:
	vagrant up $@
	vagrant ssh-config $@ >> $(SSH_CONFIG)

	$(T2D) host add $@ "tcp://$(NODE_IP:node=$@):2375" || $(T2D) host switch $@

	$(eval CONSUL_IP=$$(shell echo $$(NODE_IP:node=node-01)))

	ssh -F $(SSH_CONFIG) $@ 'echo "DOCKER_EXTRA_ARGS=\"--userland-proxy=false --cluster-store=consul://$(CONSUL_IP):8500 --cluster-advertise=eth1:0\"" | sudo tee -a /etc/default/docker'
	ssh -F $(SSH_CONFIG) $@ "sudo /etc/init.d/docker restart"

	$(T2D) compose consul.yml $@ --name=consul --hostname=$@ \
		--env=JOIN_IP=$(NODE_IP:node=node-01) --env=NODE_IP=$(NODE_IP:node=$@)
	$(T2D) container start consul
	$(T2D) ps -l

	$(T2D) compose consul.yml registrator --hostname=$@ --cmd=-ip,$(NODE_IP:node=$@),consul://consul:8500
	$(T2D) container start registrator
	$(T2D) ps -l

status:
	for node in $(NODES); do \
		$(T2D) --host=$$node ps; \
		$(T2D) --host=$$node docker network ls; \
	done

test:
	ssh -F $(SSH_CONFIG) node-01 "docker exec -t consul consul members"

	open http://$(NODE_IP:node=node-01):8500/ui/

network-test:
	$(T2D) host switch node-02

	-$(T2D) docker -- network create -d overlay myapp

	-$(T2D) docker -- run -itd --name=web --net=myapp joshix/caddy /bin/caddy -port=80

	$(T2D) --host=node-03 docker -- run -it --rm --net=myapp busybox wget -qO- http://web.myapp

clean:
	vagrant destroy -f
	$(RM) -r .vagrant .ssh_config
	$(RM) talk2docker.yml

.PHONY: up $(NODES) status test network-test clean

wordpress:
	$(T2D) host switch node-02
	$(T2D) docker -- network create -d overlay wordpress
	$(T2D) compose wordpress.yml db --net=wordpress
	$(T2D) container start db
	$(T2D) ps -l

	test -d wordpress/wordpress || (cd wordpress && \
		curl https://wordpress.org/latest.tar.gz | tar -xzf - && \
		cp wp-config.php wordpress/)

	$(T2D) host switch node-03
	$(T2D) compose wordpress.yml web --net=wordpress \
		--env=DB_NAME=wordpress,DB_USER=root,DB_PASSWORD=,DB_HOST=db.wordpress:3306
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
	-$(T2D) container stop db
	-$(T2D) container rm db

	$(T2D) docker network rm wordpress

	$(RM) -r wordpress/wordpress

.PHONY: wordpress wordpress-status wordpress-clean
