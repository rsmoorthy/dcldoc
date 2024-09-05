---
date: 2024-09-05
categories:
  - docker
  - swarm
  - compose
tags:
  - stack
authors:
  - rsm
---

# Compose Spec and Docker Swarm

If there is one thing, that can be confusing even to the authors, then it is the different versions of Compose and the
way they have named it or versioned it. There is this `Compose file format` versioned as 1, 2.x and 3.x, which is now 
called `Compose V1`. Then there is `Compose specification`, now called `Compose V2`, while the `Compose V2` has versions
from `v1.x.x` and `v2.x.x`. If you run the command `docker-compose` (written in python), then you are dealing with `Compose V1`
(with versions 1, 2.x and 3.x present in compose yaml file. If you are running the commad `docker compose`, then you
are running `Compose V2` with yaml files conforming to `Compose specification`.

<!-- more -->

The real challenge is for users, who have written their `compose yaml` files in the `Compose file format` version and they have upgraded
docker and installed `docker compose`, most of them are not well aware that there are running a tool `Compose V2` that expects
`Compose specification`, but you are having yaml files written in the older file format.

The problem is compounded with `Compose specification` being an evolving spec and is also backwards compatible with
`Compose file format` and the `Compose V2` tool `docker compose` **ignores** yaml spec that it does not understand, while
the user is blissfully unaware. These days users are *sophisticated* with not having enough patience to read through a
reference documentation, but go with AI and Google search (which could be a mix of `file format` and `specification`), 
which further complicates matters.
