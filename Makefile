# This is an attempt at scripting to getting started tutorial for Kong at 
# https://getkong.org/docs/0.10.x/getting-started/. It's main purpose is for me to
# have a play with Kong and make.

BASE_URL=http://localhost:8001
APIS_PATH=/apis/
PLUGINS_PATH=/plugins/
CONSUMERS_PATH=/consumers/


# The getting started 

gettingStarted:
	make start
	make _waitForStartup
	make addApi NAME=example-api HOSTS=example.com UPSTREAM=http://httpbin.org
	make forward HOST=example.com
	make addPlugin API_NAME=example-api NAME=key-auth
	make forward HOST=example.com
	make addConsumer USERNAME=Jason
	make configureConsumer CONSUMER_NAME=Jason PLUGIN=key-auth DATA='key=ENTER_KEY_HERE'
	make forward HOST=example.com APIKEY=ENTER_KEY_HERE


# Kong runtime controls

start:
	@docker-compose up -d

_waitForStartup:
	@while ! curl --silent http://localhost:8001/ > /dev/null ; \
	do \
		echo 'Waiting for Kong...'; \
		sleep 1; \
	done;

stop:
	@docker-compose stop

clean:
	@make _kill
	@make _rm

_kill:
	@docker-compose kill

_rm:
	@docker-compose rm


# Helper targets

_curl:|
	@curl --silent --url $(BASE_URL)$(URL_PATH) \
		-X $(METHOD) \
		$(EXTRA_DATA)

_curl_api:
	@echo $(METHOD): $(BASE_URL)$(URL_PATH)
	make _curl | jq

_get:
	@make _curl_api METHOD=GET

_post:
	@make _curl_api METHOD=POST

_delete:
	@make _curl_api METHOD=DELETE


# Targets for interacting with APIs

listApis:
	@make _get URL_PATH=$(APIS_PATH)

addApi:
	@make _post URL_PATH=$(APIS_PATH) EXTRA_DATA=" \
			--data 'name=$(NAME)' \
			--data 'hosts=$(HOSTS)' \
      --data 'upstream_url=$(UPSTREAM)'"

deleteApi:
	@make _delete URL_PATH=$(APIS_PATH)$(API_ID)


# Targets for interacting with plugins

listPlugins:
	@make _get URL_PATH=$(PLUGINS_PATH)

addPlugin:
	@make _post URL_PATH=$(APIS_PATH)$(API_NAME)/plugins/ \
		EXTRA_DATA="--data 'name=$(NAME)'"


# Targets for interacting with consumers

listConsumers:
	@make _get URL_PATH=$(CONSUMERS_PATH)

addConsumer:
	@make _post URL_PATH=$(CONSUMERS_PATH) \
		EXTRA_DATA="--data 'username=$(USERNAME)'"

configureConsumer:
	@make _post URL_PATH=$(CONSUMERS_PATH)$(CONSUMER_NAME)/$(PLUGIN) \
		EXTRA_DATA="--data '$(DATA)'"


forward:
	@make _curl METHOD=GET BASE_URL=http://localhost:8000/get \
		EXTRA_DATA="--header 'Host: $(HOST)' --header 'apikey: $(APIKEY)'"


.PHONY: start listApis addApi deleteApi listPlugins addPlugin forward \
				listConsumers addConsumer configureConsumer clean _curl _curl_api \
				_get _post _delete _waitForStartup gettingStarted stop _kill _rm