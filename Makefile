T2D := talk2docker --config=talk2docker.yml

NODES := node-01 node-02 node-03

GET_IP  := ifconfig eth1 | awk '/inet addr/{print substr(\\$$2,6)}'
NODE_IP := `vagrant ssh node -c "$(GET_IP)" -- -T`

up: $(NODES)

node-01:
	vagrant up $@

	$(T2D) host add $@ "tcp://$(NODE_IP:node=$@):2375" || $(T2D) host switch $@

	$(T2D) compose consul.yml $@ --name=consul --hostname=$@ \
		--env=JOIN_IP=$(NODE_IP:node=node-01) --env=NODE_IP=$(NODE_IP:node=$@)
	$(T2D) container start consul
	$(T2D) ps -l

node-02 node-03:
	vagrant up $@

	$(T2D) host add $@ "tcp://$(NODE_IP:node=$@):2375" || $(T2D) host switch $@

	$(eval CONSUL_IP=$$(shell echo $$(NODE_IP:node=node-01)))

	vagrant ssh $@ -c 'echo "DOCKER_EXTRA_ARGS=\"--userland-proxy=false --cluster-store=consul://$(CONSUL_IP):8500 --cluster-advertise=eth1:0\"" | sudo tee -a /var/lib/docker-root/profile'
	vagrant ssh $@ -c 'sudo /etc/init.d/docker restart' -- -T

status:
	for node in $(NODES); do \
		$(T2D) host switch $$node; \
		$(T2D) ps; \
		$(T2D) docker network ls; \
	done

test:
	$(T2D) host switch node-02

	-$(T2D) docker -- network create -d overlay myapp

	-$(T2D) docker -- run -itd --name=web --net=myapp nginx

	$(T2D) --host=node-03 docker -- run -it --rm --net=myapp busybox wget -qO- http://web.myapp

clean:
	vagrant destroy -f
	$(RM) -r .vagrant
	$(RM) talk2docker.yml

.PHONY: up $(NODES) status test clean

wordpress:
	$(T2D) host switch node-02
	$(T2D) docker -- network create -d overlay wordpress
	$(T2D) compose wordpress.yml db --net=wordpress
	$(T2D) container start db
	$(T2D) ps -l

	test -d wordpress/wordpress || (cd wordpress && \
		curl https://wordpress.org/latest.tar.gz | tar -xzf - && \
		cp wp-config.php wordpress/ && \
		cp router.php wordpress/)

	$(T2D) host switch node-03
	$(T2D) compose wordpress.yml web --net=wordpress \
		--env=DB_NAME=wordpress,DB_USER=root,DB_PASSWORD=,DB_HOST=db.wordpress:3306
	$(T2D) container start web
	$(T2D) ps -l

wordpress-test:
	open http://$(NODE_IP:node=node-03):8000/

wordpress-clean:
	$(T2D) host switch node-03
	-$(T2D) container stop web
	-$(T2D) container rm web

	$(T2D) host switch node-02
	$(T2D) container stop db
	$(T2D) container rm db

	$(T2D) docker network rm wordpress

	$(RM) -r wordpress/wordpress

.PHONY: wordpress wordpress-test wordpress-clean
