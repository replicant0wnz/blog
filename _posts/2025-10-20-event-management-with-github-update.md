---
layout: post
category: software
title: mereth planning
description: Mereth planning
image: assets/mereth.jpg
---

# Overview

In my [previous](event-management-with-github.html) post I jotted down some ideas 
on how to achieve event planning via SMS that allows the admin to create groups with
a list of receipients, BCC the list, allow the receipients to accept or deny, allow them
to via the current status of all by name, not number, and completely unsubscribe from
all future contancts. 

# YAML configuration example


### config.yaml
```
config:
  mereth:
    url: https://blagh/mereth
    key: 122344565e23454666234523

  clicksend:
    config_item: sdfgsfdg
    key: sdfgdsgfdgsdfg
    
  rolodex:
      admin: 
        - Glenn
        - 214-234-5422
      users:
        - name: John Docker
          number: 214-555-1212
        - name: Joe Linus
          number: 214-224-2444
        - name: Amber Torvalis
          number: 972-224-2444
      groups:
        - mork_borg
          users:
            - John Docker
            - Amber Torvalis
        - cy_borg
          users:
            - Amber Torvalis
            - Joe Linus
            - John Docker
```

### event_some_name.yaml

```
event:
  name: CY_BORG 
  date: 12/05/25
  time: 20:00
  group: cy_borg
  message: |
      CY_BORG session at my place on Saturday! 
```

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

