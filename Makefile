SHELL := /bin/bash

# Global stuffz
DOCKER=docker
SOURCE_PATH := $(shell pwd)
WORKING_PATH=/srv/jekyll
CONFIG="makefile.json"
UID := $(shell id -u)
LATEST_POST := $(shell ls -t1 $(SOURCE_PATH)/_posts | head -1)

# Docker config
DOCKER_RUN=$(DOCKER) run -v $(SOURCE_PATH):$(WORKING_PATH) -w $(WORKING_PATH)

# Jekyll config
JEKYLL_CONTAINER=jekyll/jekyll:4.2.0

# jq config
JQ_CONTAINER=imega/jq
JQ=$(DOCKER) run -i $(JQ_CONTAINER) -c

# yq config
YQ_CONTAINER=mikefarah/yq
YQ=$(DOCKER) run --rm -i -v "${PWD}":/workdir $(YQ_CONTAINER)

# nginx config
NGINX_CONTAINER=nginx:1.21.1
NGINX=$(DOCKER) run -v $(SOURCE_PATH):/usr/share/nginx/html -p 4000:80 --name nginx -d $(NGINX_CONTAINER)

# Robot config
ROBOT_CONTAINER=ppodgorsek/robot-framework:3.8.0
ROBOT=$(DOCKER) run --network host -e ROBOT_OPTIONS="--xunit xunit/output" -v $(SOURCE_PATH)/tests:/opt/robotframework/tests -v $(SOURCE_PATH)/reports:/opt/robotframework/reports $(ROBOT_CONTAINER)

# AWS config
AWS_CONTAINER=amazon/aws-cli
AWS_WORKING_PATH=/aws
AWS=$(DOCKER) run -e AWS_SECRET_ACCESS_KEY=$$AWS_SECRET_ACCESS_KEY -e AWS_ACCESS_KEY_ID=$$AWS_ACCESS_KEY_ID 

# Items from $(CONFIG)
S3_BUCKET := $(shell cat $(CONFIG) | $(JQ) .aws.s3.destination)
S3_REGION := $(shell cat $(CONFIG) | $(JQ) .aws.s3.region)
DISTRIBUTION_ID := $(shell cat $(CONFIG) | $(JQ) .aws.cloudfront.distribution_id)
INVALIDATION_PATH := $(shell cat $(CONFIG) | $(JQ) .aws.cloudfront.invalidation_path) 

# Most recent file in _posts

.PHONY: list
list:
	# List options of nothing specified
	grep '^[^#[:space:]].*:' Makefile

.PHONY: serve
serve:
	$(DOCKER_RUN) --network host $(JEKYLL_CONTAINER) jekyll serve

.PHONY: nginx_start
nginx_start:
	$(NGINX) 

.PHONY: nginx_stop
nginx_stop: 
	$(DOCKER) stop nginx
	$(DOCKER) rm nginx

.PHONY: init
init:
	$(DOCKER_RUN) -e JEKYLL_ROOTLESS=1 $(JEKYLL_CONTAINER) bundle

.PHONY: update
update:
	$(DOCKER_RUN) -e JEKYLL_ROOTLESS=1 $(JEKYLL_CONTAINER) bundle update

.PHONY: build
build:
	$(DOCKER_RUN) -e JEKYLL_ROOTLESS=1 $(JEKYLL_CONTAINER) jekyll build
	ln -s _site blog

.PHONY: test
test:
	mkdir -p $(SOURCE_PATH)/reports/xunit && chmod -R 777 $(SOURCE_PATH)/reports
	LATEST_POST=`cat _posts/$(LATEST_POST) | $(YQ) --front-matter=extract .title | tr '[:upper:]' '[:lower:]'` ; \
    sed "s/LATEST_POST/$$LATEST_POST/" tests/_chrome.robot > tests/chrome.robot
	$(ROBOT)

.PHONY: deploy
deploy:
	$(AWS) -v $(SOURCE_PATH)/_site:$(AWS_WORKING_PATH) -w $(AWS_WORKING_PATH) $(AWS_CONTAINER)  s3 sync . s3://$(S3_BUCKET)/blog --delete --acl public-read --region $(S3_REGION)

.PHONY: invalidate
invalidate:
	$(AWS) $(AWS_CONTAINER) cloudfront create-invalidation --distribution-id $(DISTRIBUTION_ID) --paths $(INVALIDATION_PATH) --region $(S3_REGION)

.PHONY: clean
clean:
	rm -rf Gemfile.lock _site .bundle .sass-cache .jekyll-cache vendor reports tests/chrome.robot blog dist cache

all: 
	init update build
