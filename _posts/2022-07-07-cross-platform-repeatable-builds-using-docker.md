---
layout: post
category: devops
title: Cross-platform repeatable builds using Docker and Make
description: Using Docker and GNU Make for repeatable builds across multiple platforms
image: assets/makefile.jpg
custom_js: prism
professional: true
toc: true
twitter: replicant0wnz/status/1545175730685870089
---

# Background

During the stint at my last company I was put in the unique situation of having 
to migrate pipelines from 3 different CI systems. I had originally 
deployed **[Drone Enterprise](https://drone.io/)** while it was still in its 
infancy and, at the time, it fulfilled our needs for build and deploy 
automation.

We eventually outgrew **Drone** and after some evaluation I settled 
on **[CircleCI Enterprise](https://circleci.com/)** as a replacement. While 
migrating some of our pipelines from **Drone** to **CircleCI** , though, we 
noticed that **[Github Actions](https://github.com/features/actions)** was now 
included in our existing license for **[Github 
Enterprise](https://github.com/enterprise)**, our primary source repo.

> What happens if we decided to migrate to another CI/CD system? I’m going to 
> have to migrate from one system's plug-in structure to another. Can I simplify 
> what the builds and deploys look like from a local and automated perspective?

**Github Actions** was the platform (for the time) we eventually stuck with.

# Analysis 

Take this simple (generic pipeline) **golang** example:

{% prism yaml %}some_vendor_plugin:
    vendor_specific_option: foo
    another_specific_option: bar
    build:
      - GOARCH=amd64
      - GO111MODULE=on
      - go mod vendor
      - go build -o main
{% endprism %}

### Disadvantages
#### Plugins

* **Vendor lock-in**

    The main reason I started down this path is vendor lock-in. Whether it's 
    **Drone**, **CircleCI**, or **Github Actions**, folks will normally use said 
    vendor's plug-in structure. Note that this isn't necessarily a bad thing and 
    normally the quickest way to get your pipeline up and running.

* **Difficult to repeat in other environments**

    Using a vendor specific plug-in in your pipeline makes it difficult to 
    repeat pipeline steps in other environments; locally, for example.

* **No fine grained control**

    When using a vendor plug-in you normally don't know what's going on under 
    the hood -- unless you delve into the vendors code.

#### Build steps

> The pipeline should list the steps to build, test, and deploy an application. 
> It should _not_ describe **how** to build, test, and deploy the application.

* **Developers and Devops relying on the pipeline for building applications**

    There have been numerous occasions where I’ve seen teams using the pipeline 
    as documentation on how to build. Heck, I’ve done it myself!

* **YAML cruft**

    The pipeline should be treated as any other piece of code. Just like messy 
    code, a messy pipeline can be hard to troubleshoot and maintain.

# Alternative approach using Docker and GNU Make

By using **Docker** we can avoid having to install the needed tooling across 
multiple local and remote systems. This can include simple items like `jq` and 
especially something like Terraform when versioning can really muck things up.

Provided that your platform allows straight `docker` commands the `Makefile` 
examples should be applicable.

Let's us my [blog](https://github.com/replicant0wnz/blog) as an example. Here's 
a condensed snippet from the `Makefile`:

{% prism makefile %}DOCKER=/usr/bin/docker
SOURCE_PATH := $(shell pwd)
WORKING_PATH=/srv/jekyll
DOCKER_RUN=$(DOCKER) run -v $(SOURCE_PATH):$(WORKING_PATH) -w $(WORKING_PATH)
JEKYLL_CONTAINER=jekyll/jekyll:4.2.0

.PHONY init
init:
	$(DOCKER_RUN) -e JEKYLL_ROOTLESS=1 $(JEKYLL_CONTAINER) bundle

.PHONY build
build:
	$(DOCKER_RUN) -e JEKYLL_ROOTLESS=1 $(JEKYLL_CONTAINER) jekyll build
{% endprism %}

With the above `Makefile` we can execute the same steps to build both locally 
and remote. So for local:

{% prism bash %}make init build{% endprism %}

Then to build in a pipeline you'd execute the same thing:

{% prism yaml %}run: |
    make init build
{% endprism %}

Full Github actions example:

{% prism yaml %}jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@master

      - name: build
        run: |
          make init build
{% endprism %}

I’d like to note that a **Github** action 
already [exists](https://github.com/marketplace/actions/build-jekyll) to build 
Jekyll using a single line, but this issue is discussed in 
the [**Analysis**](#analysis) above.  We would be using two separate methods to 
build both locally and remote without complete control over the tooling.

# Final thoughts

This has been a condensed overview of the method I've been using both 
professionally and personally. In the coming weeks I'll be giving an overview of 
the more detailed workflows I'm currently using in my projects. This will 
include building, testing, and deploying. In the meantime if you'd like to look 
at them directly:

* [`ecr-template`](https://github.com/replicant0wnz/ecr-template) **Github** 
    template for creating **Docker** images and pushing them to **ECR**. My most 
    basic implementation of the above concepts.

* [`build-python`](https://github.com/replicant0wnz/build-python) Python image 
    built using [ecr-template](https://github.com/replicant0wnz/ecr-template) 
    that I use in various projects. 

* [`ses-send`](https://github.com/replicant0wnz/ses-send) Simple Python wrapper 
    for **AWS SES** built using the above 
    [build-python](https://github.com/replicant0wnz/build-python) image.
    Includes formatting using `black`, testing using `pytests`, and deploying to 
    PyPI via `twine`.

* [`blog`](https://github.com/replicant0wnz/blog) This blog which is built with 
    `Jekyll`. Contains all the steps to get into production including testing 
    with `robot`, deploying to `s3`, and then invalidating the **Cloud Front** 
    deployment. 
