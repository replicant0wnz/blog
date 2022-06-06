SHELL := /bin/bash

# Global stuff
DOCKER=docker
SOURCE_PATH := $(shell pwd)/blog
WORKING_PATH=/srv/jekyll/srv/jekyll
CONFIG="makefile.json"
UID := $(shell id -u)

# Docker config
DOCKER_RUN=$(DOCKER) run -v $(SOURCE_PATH):$(WORKING_PATH) -w $(WORKING_PATH)

# Jekyll config
JEKYLL_CONTAINER=jekyll/jekyll:4.2.0

# jq config
JQ_CONTAINER=imega/jq
JQ=$(DOCKER) run -i $(JQ_CONTAINER) -c

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

init:
	$(DOCKER_RUN) $(JEKYLL_CONTAINER) bundle

update:
	$(DOCKER_RUN) $(JEKYLL_CONTAINER) bundle update

build:
	$(DOCKER_RUN) $(JEKYLL_CONTAINER) jekyll build

deploy:
	$(AWS) -v $(SOURCE_PATH)/_site:$(AWS_WORKING_PATH) -w $(AWS_WORKING_PATH) $(AWS_CONTAINER)  s3 sync . s3://$(S3_BUCKET)/blog --delete --acl public-read --region $(S3_REGION)

invalidate:
	$(AWS) $(AWS_CONTAINER) cloudfront create-invalidation --distribution-id $(DISTRIBUTION_ID) --paths $(INVALIDATION_PATH) --region $(S3_REGION)

all: 
	init update build
