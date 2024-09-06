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
called `Compose V1`. The tool that uses `Compose V1 file format` is `docker-compose` which is written in python.

Then there is `Compose specification`, called `Compose V2`, while the `Compose V2` itself has versions
from `v1.x.x` and `v2.x.x`. The tool that uses this new `Compose specification` is the commad `docker compose`.

<!-- more -->

The real challenge is for users, who have written their `compose yaml` files in the `Compose file format` version and they have upgraded
docker and installed `docker compose`, most of them are not well aware that there are running a tool `Compose V2` that expects
`Compose specification`, but they are having yaml files written in the older file format.

The problem is compounded with `Compose specification` being an evolving spec and is also backwards compatible with
`Compose file format` and the `Compose V2` tool `docker compose` **ignores** yaml spec that it does not understand, while
the user is blissfully unaware. These days users are *sophisticated* with not having enough patience to read through a
reference documentation, but go with AI and Google search (which could be a mix of `file format` and `specification`), 
which further complicates matters. It usually takes several frustrating trouble-shooting before even they realise the
difference between `file format` or `V1` and `specification` or `V2` - especially when many engineers learn in-not-so-structured-manner.

The following image shows the differences between `V1` and `V2` from [docker docs](https://docs.docker.com/compose/intro/history/)

![Image](https://docs.docker.com/compose/images/v1-versus-v2.png){ width="600" }

## Issue

The biggest issue, as on Sep 2024, is that while `docker compose` (version `v2.29.1` reflecting the `Compose Specification` too) is using
`Compose Specification`, but `docker stack` - which is for deploying Swarm services - is still limited to the older version of
`Compose file format`. And there is no clarity on if-and-when `docker stack` will be migrated over to use `Compose Specification`.

!!! quote "From the [Docker stack docs](https://docs.docker.com/engine/swarm/stack-deploy/)"
    The docker stack deploy command uses the legacy [Compose file version 3](https://docs.docker.com/reference/compose-file/legacy-versions/) 
    format, used by Compose V1. The latest format, defined by the [Compose specification](https://docs.docker.com/reference/compose-file/) 
    isn't compatible with the docker stack deploy command.

    For more information about the evolution of Compose, see [History of Compose](https://docs.docker.com/compose/history/).

So, as of now, `docker stack` does not support `Compose Specification`, but are there any plans? See a bunch of github issues

*  [Support Swarm mode / clarify its status](https://github.com/docker/roadmap/issues/175)
*  [Status of swarm and adoption of compose-spec](https://github.com/moby/moby/issues/47241)
*  [Adopt compose-specification for compose file support in docker stack command #2527](https://github.com/docker/cli/issues/2527)
*  [docker stack does not actually implement compose-spec #156](https://github.com/compose-spec/compose-spec/issues/156)
*  [Add support for extends feature in Compose v3 / docker stack deploy #31101](https://github.com/moby/moby/issues/31101)

Basically, there seems to be *no plan on the horizon so far*, until now. If you follow the above issues, you will notice that ownership of Swarm itself
is not pretty clear (`docker` or `Mirantis`). Mirantis [assured way back in 2020](https://www.mirantis.com/blog/mirantis-will-continue-to-support-and-develop-docker-swarm) that it will continue to support Docker Swarm, but their focus of [Swarm](https://www.mirantis.com/software/swarm/) seems to be
subsumed under [MKE](https://www.mirantis.com/software/mirantis-kubernetes-engine/). 

!!! warn "I am not an expert or an analyst, but it seems very unlikely to me that `docker stack` will get any support soon for `Compose Specification`."

On the bright side, I see a [PR #4863](https://github.com/docker/cli/pull/4863) which has attempted so solve part of the problem
and also a [plugin - deployx](https://github.com/aaraney/deployx) that seems to solve the current problem. However, the first
one is stuck for few months now and the second one is not (yet) updated to the latest Compose specification (v2.x).


!!! tip "I am not complaining :)"
    I understand how open source model works and the amount of great efforts spent by hundreds and thousands of contributors. I am
    forever grateful to them. This post is more pragmatic about what we can use and what we cannot at this point in time, and what
    we can do to contribute further.

## What are we missing?

So, what if the end users continue using `Compose V1 file format`, instead of the new `Compose specification V2`? What are we actually missing?

* [No support](https://docs.docker.com/compose/migrate/#can-i-still-use-compose-v1-if-i-want-to) (since May 2021). `Compose Specification V2` is
  the way forward and no point in writing new YAML files with older file formats.

* Most importantly, developers would test it with local docker using `docker compose` and the actual usage on docker swarm using `docker stack`,
  causing lots of confusion and uncertainty.

* [Differences listed](https://docs.docker.com/compose/migrate/) between `V1` and `V2` are very less and trivial. I am afraid they don't cover
  lots of things. Unfortunately, I have not been able to find out a compilation of differences between [`V1`](https://github.com/docker/compose/blob/v1/docs/Compose%20file%20reference%20(legacy)/version-3.md) and [`V2`](https://github.com/compose-spec/compose-spec/blob/main/spec.md). This is something
  I wish to fix, by creating a page on the differences.

* One of the most important new features in `V2` is about [extensions](https://github.com/compose-spec/compose-spec/blob/main/11-extension.md) and
[merge and override](https://github.com/compose-spec/compose-spec/blob/main/13-merge.md) while working with [multiple compose files](https://docs.docker.com/compose/multiple-compose-files/). In addition to that, `Compose V2` supports [Include](https://github.com/compose-spec/compose-spec/blob/main/14-include.md) and [Profiles](https://github.com/compose-spec/compose-spec/blob/main/15-profiles.md), which makes it far easier to work with multiple compose files
in a collobarative  (aka enterprise) environment.

* `Compile V1` only supports built-in YAML features, defined as [fragments](https://github.com/compose-spec/compose-spec/blob/main/10-fragments.md)
using anchors and aliases (which of course can be used with `Compose V2` too), along with variable interpolation, but `docker stack` does not support
`.env` files.


## In conclusion

It is a good idea to invest some time for supporting the new `Compose Specification V2` for `docker stack` as well.



