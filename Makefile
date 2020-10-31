-include .env
export $(shell sed 's/=.*//' .env)

export NPM_HOSTNAME=${NPM_CONTAINER}.${NGINX_HOSTNAME}
export NPM_HTTP_URL=http://${NPM_HOSTNAME}:${NGINX_PROXY_HTTP}
export NPM_HTTPS_URL=https://${NPM_HOSTNAME}:${NGINX_PROXY_HTTPS}
export NPM_EXTERNAL_URL=${NPM_HTTPS_URL}

SHELL = bash
.ONESHELL:

.PHONY: env_var
env_var: # Print environnement variables
	@cat .env
	@echo
	@echo NPM_HOSTNAME=${NPM_HOSTNAME}
	@echo NPM_HTTP_URL=${NPM_HTTP_URL}
	@echo NPM_HTTPS_URL=${NPM_HTTPS_URL}
	@echo NPM_EXTERNAL_URL=${NPM_EXTERNAL_URL}

.PHONY: env
env:
	cp -u .env.default .env
	envsubst < config.tpl.json > config.json

.PHONY: config
config:
	docker-compose config

.PHONY: up
up:
	git log -1 --pretty="%h %B" > .up
	docker-compose up -d
	@make -s url

.PHONY: down
down:
	docker-compose down

.PHONY: erase
erase:
	docker-compose down -v

.PHONY: logs
logs:
	docker-compose logs -f

.PHONY: shell
shell:
	docker exec -it npm-app /bin/bash

.PHONY: shell-db
shell-db:
	docker exec -it npm-db /bin/sh

.PHONY: vol-backup
vol-backup:
	mkdir -p backup
	docker run --rm --volumes-from npm-app -v $(PWD)/backup:/backup ubuntu tar cvf /backup/data.tar /data
	docker run --rm --volumes-from npm-db -v $(PWD)/backup:/backup ubuntu tar cvf /backup/db.tar /var/lib/mysql

.PHONY: vol-restore
vol-restore:
	docker run --rm --volumes-from npm-app -v $(PWD)/backup:/backup ubuntu bash -c "cd /data && tar xvf /backup/data.tar --strip 1"
	docker run --rm --volumes-from npm-db -v $(PWD)/backup:/backup ubuntu bash -c "cd /var/lib/mysql && tar xvf /backup/db.tar --strip 3"

.PHONY: url
url:
	@echo ${NPM_EXTERNAL_URL}
