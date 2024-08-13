# Containers - Reference

This page provides a reference for creating containers / services via DCL. This reference
takes the Docker reference as the base and documents the behaviour of DCL for the corresponding Docker interface.

Docker provides multiple interfaces for achieving similar things. In some cases, they are one to one mapping
and in some cases they are not.

* docker container
    - cli interface
    - docker compose (yaml)
    - API
* docker service  
    - cli interface
    - docker stack (yaml)
    - API

Essentially, DCL makes API level behavioural changes as against Docker, with few
transformations, limitations and restrictions. Hence DCL is obligated to provide the API
level differences.

Since DCL deals only with API level changes, it might have been sufficient to just
document the API level changes. In other words, DCL does not know what cli commands
were run or what compose spec was used. The docker cli / compose / stack tools translate
to the docker API, which DCL sees.

However, not all the users deal with DCL API. They mostly deal with cli / compose interface,
and these do not map similarly. Few examples:

*  A `docker run` cli actually runs multiple APIs `/containers/create`, 
`/containers/start`, `/containers/json`.
*  A `docker compose` or `docker stack` tries to create
networks (`POST /networks/create`) even though there is no spec in yaml file to create a network.
*  Many `docker compose` operations interfere with DCL transformations, limitations and restrictions,
failing that operation. For ex:
    -  DCL's support for `docker stop` and `docker start` is limited, but docker compose implicitly 
    calls them.
*  Compose file has its own syntax, as against cli and api. I cannot find any clear mapping between
all of these in official documentation or otherwise.
*  The same compose file is used for `docker compose` (which creates containers) and `docker stack`
(which creates swarm services), which adds to the confusion.

Hence, DCL is obliged to provide behavioral changes across cli, compose, stack and api usages. Each interface user
can get meaningful understanding of DCL's behaviour changes, without knowing other interfaces.

## Container Creation

This section talks about the changes made by DCL while creating a container. There are multiple parameters passed
while creating containers. There are multiple sub-sections.

!!! important "Explicit mention"

    If DCL supports those parameters, it will be explicitly mentioned in these sections. In other words, only
    the parameters mentioned here are passed along. Any new parameters added in newer versions will be ignored,
    until supported (and documn=ented here).

The order of specifying the parameters are based on the order provided by `docker run --help`.

### No changes. Pass as is

These parameters are passed as is and DCL makes no changes to these parameters. If any of these parameters are not
passed (via api, or cli or compose), DCL uses the default values, which is mentioned in the table below.


+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
|   docker run param             |  API equiv                   |  docker-compose param          |  DCL changes                                        |
+================================+==============================+================================+=====================================================+
| --annotation                   |                              |                                | Pass as is (TBImpl)                                 |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --cap-drop                     |                              |                                | Pass as is                                          |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --dns                     <br> |                              |                                | Pass as is (TBImpl) <br>                            |
| --dns-option              <br> |                              |                                | Note: In an earlier version, this was ignored       |
| --dns-search              <br> |                              |                                |                                                     |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --entrypoint                   |                              |                                | Pass as is                                          |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --env                          |                              |                                | Pass as is                                          |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --group-add                    |                              |                                | Pass as is                                          |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --health-cmd              <br> |                              |                                | Pass as is                                          |
| --health-interval         <br> |                              |                                |                                                     |
| --health-retries          <br> |                              |                                |                                                     |
| --health-start-interval   <br> |                              |                                |                                                     |
| --health-start-period     <br> |                              |                                |                                                     |
| --health-timeout          <br> |                              |                                |                                                     |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --hostname                     |                              |                                | Pass as is                                          |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --init                         |                              |                                | Pass as is                                          |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+


### Restricted

These parameters are passed by DCL, after validating that it satisfies authorisation and other reasons

+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
|   docker run param             |  API equiv                   |  docker-compose param          |  DCL changes                                        |
+================================+==============================+================================+=====================================================+
| --cap-add                      |                              |                                | If RBAC rules satisfy                               |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --cpus                         |                              |                                | Indicates how much CPU you require <br>             |
|                                |                              |                                |                                                     |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+

### Ignored

These parameters are ignored by DCL, when provided via cli or api.

+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
|   docker run param             |  API equiv                   |  docker-compose param          |  Reason                                             |
+================================+==============================+================================+=====================================================+
| --add-host                     |                              |                                | Not supported by Swarm                              |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --blockio-weight               |                              |                                | Not supported by Swarm <br>                         |
|                                |                              |                                | Not relevant for DCL                                |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --blockio-weight-device        |                              |                                | Not supported by Swarm <br>                         |
|                                |                              |                                | Not relevant for DCL                                |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --cgroup-parent                |                              |                                | Not supported by Swarm <br>                         |
|                                |                              |                                | DCL will internally specify this when               |
|                                |                              |                                |  creating a side-car container                      |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --cgroups                      |                              |                                | Not supported by Swarm <br>                         |
|                                |                              |                                | Not relevant to DCL                                 |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --cidfile                      |                              |                                | Not supported by Swarm <br>                         |
|                                |                              |                                | Not relevant to DCL                                 |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --cpu-period     <br>          |                              |                                | Not supported by Swarm <br>                         |
| --cpu-quota      <br>          |                              |                                | Not relevant to DCL                                 |
| --cpu-rt-period  <br>          |                              |                                |                                                     |
| --cpu-rt-runtime <br>          |                              |                                |                                                     |
| --cpu-shares     <br>          |                              |                                |                                                     |
| --cpuset-cpus    <br>          |                              |                                |                                                     |
| --cpuset-mems    <br>          |                              |                                |                                                     |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --device         <br>          |                              |                                | Not supported by Swarm <br>                         |
| --device-list         <br>     |                              |                                | Not relevant to DCL                                 |
| --device-cgroup-rule  <br>     |                              |                                |                                                     |
| --device-read-bps     <br>     |                              |                                |                                                     |
| --device-read-iops    <br>     |                              |                                |                                                     |
| --device-write-bps     <br>    |                              |                                |                                                     |
| --device-write-iops    <br>    |                              |                                |                                                     |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --domainname           <br>    |                              |                                | Not supported by Swarm <br>                         |
|                                |                              |                                | Also Not relevant to DCL                            |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --env-file                     |                              |                                | Does not pass to Docker. Local to the CLI           |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --expose                       |                              |                                | Not supported by Swarm <br>                         |
|                                |                              |                                | Legacy feature (link containers)                    |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+
| --interactive                  |                              |                                | Not supported by Swarm                              |
+--------------------------------+------------------------------+--------------------------------+-----------------------------------------------------+

### Unknown

These parameters are not understood yet.

+--------------------------------+------------------------------+--------------------------------+-------------------------------+
|   docker run param             |  API equiv                   |  docker-compose param          |  Reason                       |
+================================+==============================+================================+===============================+
| --attach                       |                              |                                |                               |
+--------------------------------+------------------------------+--------------------------------+-------------------------------+
| --detach  -d               <br>|                              |                                |                               |
| --detach-keys              <br>|                              |                                |                               |
| --disable-content-trust    <br>|                              |                                |                               |
+--------------------------------+------------------------------+--------------------------------+-------------------------------+
| --gpus                         |                              |                                |                               |
+--------------------------------+------------------------------+--------------------------------+-------------------------------+

