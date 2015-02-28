T2D := talk2docker --config=talk2docker.yml

NODES := node-01 node-02 node-03

GET_IP  := ifconfig eth1 | awk '/inet addr/{print substr(\\$$2,6)}'
NODE_IP := `vagrant ssh node -c "$(GET_IP)" -- -T`

up: $(NODES)

$(NODES):
	vagrant up $@

	mkdir -p .certs/$@
	vagrant ssh $@ -c 'cp /home/rancher/.certs/* /vagrant/.certs/$@/' -- -T

	$(T2D) host add $@ "tcp://$(NODE_IP:node=$@):2376" \
		--tls \
		--tls-ca-cert="`pwd`/.certs/$@/ca.pem" \
		--tls-cert="`pwd`/.certs/$@/client-cert.pem" \
		--tls-key="`pwd`/.certs/$@/client-key.pem" \
		|| $(T2D) host switch $@

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
	$(RM) -r .certs
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
