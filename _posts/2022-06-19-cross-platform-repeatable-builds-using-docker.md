---
layout: post
category: devops
title: Cross-platform repeatable builds using Docker
description: Using Docker for repeatable builds across multiple platforms
image: assets/makefile.jpg
custom_js: prism
hidden: true
---

![Makefile](/blog/assets/makefile.jpg)

# Background

During the stint at my last company I was put in the unique situation of having 
to migrate pipelines from 3 different CI systems. I had originally deployed 
[Drone Enterprise](https://drone.io/) while it was still in it's infancy and at 
the time it fulfilled our needs for build and deploy automation.

We eventually outgrew **Drone** so after some evaluation I settled on [CircleCI 
Enterprise](https://circleci.com). During the migration for some pipelines from 
**Drone** to **CircleCI** we noticed that [Github 
Actions](https://github.com/features/actions) was now included in [Github 
Enterprise](https://github.com/enterprise), which we used as our primary source 
repo, in our existing license. 

We finally settled on **Github Actions** as our integration and delivery 
platform.  This got me thinking:

> What happens if we decided to migrate to another CI/CD system? I'm going to 
> have to migrate from one systems plug-in structure to another. Can I simplify 
> what the build and deploys are going to look like from a local and automated 
> perspective?

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

    The main reason I started down this path is vendor lock-in. Whether is be 
    Drone, CircleCI, or Github Actions folks will normally use said vendors 
    plug-in structure. **Note** that this is not necessarily a bad thing and 
    normally the quickest way to get your pipeline up and running.

* **Difficult to repeat in other environments**

    Using a vendor specific plug-in in your pipeline makes it difficult to 
    repeat pipeline steps in another environments, locally for example. 

* **Duplicate methods to execute a single task**

    In order to test locally you need to execute a different task to build a 
    binary than you would in the CI/CD system.

#### Build steps

> The pipeline should list the steps to build, test, and deploy an application.
> It should not describe **how** to build, test, and deploy the application.

* **Developers and Devops relying on the pipeline for building applications**

    There have been numerous occasions where I've seen teams using the pipeline 
    as documentation on how to build. Heck, I've done it myself! 

* **YAML cruft**

    The pipeline should be treated as any other piece of code: `messy == bad`.
    Just like messy code, a messy pipeline can be hard to troubleshoot and 
    maintain.
