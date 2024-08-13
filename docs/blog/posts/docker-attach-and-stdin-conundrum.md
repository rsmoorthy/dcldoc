---
date: 2024-05-11
categories:
  - docker
  - swarm
tags:
  - attach
  - stdin
authors:
  - rsm
---

# Docker Attach and STDIN conundrum

When we are only dealing with docker containers, docker provided many features where you run a program inside the container, whose `stdin` can be
`attach`ed from outside the container. This included both:

*   synchronous attachment like `docker run -it --rm alpine sh` where the shell (the main process) is attached to your console and kills the container, when you exit from the shell.
*   asynchronous attachment like `docker run -itd --name alpine alpine sh` followed by `docker attach alpine` where you attach to the shell (the main process). In this mode, the
shell process has opened its stdin, along with a _pseudo tty_ and waiting for some process to attach to its stdin.

<!-- more -->

Please read through [this excellent blog](https://www.baeldung.com/linux/docker-run-interactive-tty-options) about `-i` (interactive) and `-t` (tty) flag.

Please note that this is very different from `docker exec` which creates a __new shell__ and a __new pseudo tty__ for the duration of the command and is not connecting to your
main process.

## The issue

With the introduction of docker swarm, the interactive part of a container (via stdin) is moot. So `docker service create` has done away with
`-i --interactive` flag completely, but for some strange reasons, kept `-t --tty` flag. However, the Swarm API `POST /services/create` has still
kept `OpenStdin` parameter (equiv for `-i` flag), so you can still pass interactive option via API, but not via `docker service create` cli.

Since DCL does transformations of a container request to a Swarm service, DCL passes your `docker run -i` flag to service creation (since DCL deals
with APIs). So, it is good, right? Possibly.

While no serious service will require the _interactive_ aspect of the main process, there are two scenarious, where it could be:

* Casual alpine / busybox / ubuntu containers created for testing
* There are still applications which uses `docker attach` equiv for interacting with the containers (like Jenkins Docker plugin for communicating with dynamic Jenkins agents created).

So, this post just provides enough tips on when and how the _interactive_ flag makes its impact, while also sharing how DCL behaves.

## Plain Docker and Swarm

Continuing from the [blog](https://www.baeldung.com/linux/docker-run-interactive-tty-options), the following usage with __plain docker and swarm__ does NOT work:

=== "docker run"

    ```console
    $ docker run -d --name alpine alpine
    fc35feaf4ee224198be5fd414a1c150db8d81af4e4311b3a706407b10fdd7d1f
    $ docker ps -a
    CONTAINER ID   IMAGE     COMMAND     CREATED         STATUS                     PORTS     NAMES
    fc35feaf4ee2   alpine    "/bin/sh"   7 seconds ago   Exited (0) 6 seconds ago             alpine
    $ docker rm alpine
    alpine
    $ docker run -id --name alpine alpine
    8ce14210cde8037061402a29ac3a00029828b3c698d8e37b66e47c689268a63b
    $ docker ps -a
    CONTAINER ID   IMAGE     COMMAND     CREATED         STATUS         PORTS     NAMES
    8ce14210cde8   alpine    "/bin/sh"   4 seconds ago   Up 3 seconds             alpine
    $ docker attach alpine
    

    # In another terminal
    $ docker stop alpine; docker rm alpine
    ```

=== "docker compose"

    ```yaml
    version: "3.7"
    services:
      alpine:
        image: alpine
        hostname: alpine
        network_mode: bridge
    ```

    ```console
    $ docker compose -f c2.yaml up -d
    [+] Running 1/1
     ✔ Container root-alpine-1  Started  0.5s
    $ docker compose -f c2.yaml ps -a
    NAME                IMAGE               COMMAND             SERVICE             CREATED             STATUS                     PORTS
    root-alpine-1       alpine              "/bin/sh"           alpine              5 seconds ago       Exited (0) 4 seconds ago
    $
    ```

=== "(swarm) docker service create"

    ```console
    jbipuat1oo4fw64tgpekj3if5
    $ docker service ls
    ID             NAME      MODE         REPLICAS   IMAGE           PORTS
    jbipuat1oo4f   alpine    replicated   0/1        alpine:latest
    $ docker service ps alpine
    ID             NAME       IMAGE           NODE      DESIRED STATE   CURRENT STATE             ERROR     PORTS
    uurbflixqwc9   alpine.1   alpine:latest   swarm1    Shutdown        Complete 14 seconds ago
    $
    ```

=== "(swarm) docker stack deploy"

    ```yaml
    services:
      alpine:
        image: alpine
        hostname: alpine
        networks:
        - default
        deploy:
          restart_policy:
            condition: none

    networks:
      default:
        external: true
        name: dev
    ```

    ```console
    $ docker stack deploy -c stack_c2.yaml p2
    Creating service p2_alpine
    $ docker stack ps p2
    ID             NAME          IMAGE           NODE      DESIRED STATE   CURRENT STATE            ERROR     PORTS
    oy5htwzkpba2   p2_alpine.1   alpine:latest   swarm1    Shutdown        Complete 6 seconds ago
    $
    ```



