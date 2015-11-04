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
		$(T2D) --host=$$node ps ; \
	done

test:
	-$(T2D) -H node-02 docker -- network create -d overlay myapp

	-$(T2D) -H node-02 docker -- run -itd --name=web --net=myapp nginx

	$(T2D) -H node-03 docker -- run -it --rm --net=myapp busybox wget -qO- http://web.myapp

clean:
	vagrant destroy -f
	$(RM) -r .vagrant
	$(RM) talk2docker.yml

.PHONY: up $(NODES) status test clean
