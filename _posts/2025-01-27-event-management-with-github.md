---
layout: post
category: software
title: Event planning using YAML and the command line
description: Event planning using YAML and the command line
image: assets/mereth.jpg
---

# Overview

With the migration away from centralized social media platforms I've been wanting
an easy way to send out invites to my tabletop gaming group. I haven't been able to find anything
that fits the following criteria (open source): 

* Contact list and events managed via YAML
* Notification via SMS/RCS BCC message
* Accept or decline invite via URL in text message
* Ability to see who or accepted or declined via SMS/RCS and CLI
* Create events via CLI

# Project

The project is named "mereth" which is the Elvish (Sindarin) word for "festival". The repo
exists [here](https://github.com/replicant0wnz/mereth) although it currently just links
back to here while I'm in the prototyping stage.

# Workflow

I basically live in terminal so I want to manage all this in my preferred editor (heavily
modified Neovim) via YAML. Single YAML that contains config info and contacts along with
individual files for each event.

### Create

```
        Create new event YAML
                  ⇩
           Execute command
                  ⇩
               API call
                  ⇩
      Notifications to invitees
```

### Accept

```
          Invitee recives text
                   ⇩
       Selects ACCEPT or DECLINE
                   ⇩
    Option to recive notifications
                   ⇩
                API call
                   ⇩
Notification to event planner and invities
```

# Technology

* FastAPI via Python
* CLI via Docker / Makefile
* [Clicksend](https://developers.clicksend.com/sms-quickstart/?lang=python) for SMS interaction

