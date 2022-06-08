SHELL := /bin/bash

# Global stuff
DOCKER=docker
SOURCE_PATH := $(shell pwd)
WORKING_PATH=/srv/jekyll
CONFIG="makefile.json"
UID := $(shell id -u)

# Docker config
DOCKER_RUN=$(DOCKER) run -v $(SOURCE_PATH):$(WORKING_PATH) -w $(WORKING_PATH)

# Jekyll config
JEKYLL_CONTAINER=jekyll/jekyll:4.2.0

# jq config
JQ_CONTAINER=imega/jq
JQ=$(DOCKER) run -i $(JQ_CONTAINER) -c

# nginx config
NGINX_CONTAINER=nginx
NGINX=$(DOCKER) run -v $(SOURCE_PATH):/usr/share/nginx/html -p 4000:80 --name nginx -d $(NGINX_CONTAINER)

# Robot config
ROBOT_CONTAINER=ppodgorsek/robot-framework:latest
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

list:
	# List options of nothing specified
	grep '^[^#[:space:]].*:' Makefile

serve:
	$(DOCKER_RUN) --network host $(JEKYLL_CONTAINER) jekyll serve

nginx_start:
	$(NGINX) 

nginx_stop: 
	$(DOCKER) stop nginx
	$(DOCKER) rm nginx

init:
	$(DOCKER_RUN) -e JEKYLL_ROOTLESS=1 $(JEKYLL_CONTAINER) bundle

update:
	$(DOCKER_RUN) -e JEKYLL_ROOTLESS=1 $(JEKYLL_CONTAINER) bundle update

build:
	$(DOCKER_RUN) -e JEKYLL_ROOTLESS=1 $(JEKYLL_CONTAINER) jekyll build
	ln -s _site blog

test:
	mkdir -p $(SOURCE_PATH)/reports/xunit && chmod -R 777 $(SOURCE_PATH)/reports 
	LATEST_POST=`$(SOURCE_PATH)/tests/latest_post.sh` ; \
	sed "s/LATEST_POST/$$LATEST_POST/" tests/_chrome.robot > tests/chrome.robot
	$(ROBOT)

deploy:
	$(AWS) -v $(SOURCE_PATH)/_site:$(AWS_WORKING_PATH) -w $(AWS_WORKING_PATH) $(AWS_CONTAINER)  s3 sync . s3://$(S3_BUCKET)/blog --delete --acl public-read --region $(S3_REGION)

invalidate:
	INVALIDATION=`$(AWS) $(AWS_CONTAINER) cloudfront create-invalidation --distribution-id $(DISTRIBUTION_ID) --paths $(INVALIDATION_PATH) --region $(S3_REGION)` ; \
	echo $$INVALIDATION ; \
	INVALIDATION_ID=`echo $$INVALIDATION | $(JQ) -r .Invalidation.Id` 
#	$(AWS) $(AWS_CONTAINER) cloudfront wait invalidation-completed --distribution-id $(DISTRIBUTION_ID) --id $$INVALIDATION_ID

clean:
	rm -rf Gemfile.lock _site .bundle .sass-cache .jekyll-cache vendor reports tests/chrome.robot blog dist

all: 
	init update build
