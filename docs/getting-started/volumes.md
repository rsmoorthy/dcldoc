# Volumes

Docker has basic support for temporary and persistent storage, at a fundamental unit level, at each individual
node. Docker Swarm does not extend this support for cluster wide setup, but just relies on basic node level
storage support by Docker.

DCL combines other technologies and packages storage solutions. As a platform engineering solution, DCL provides
opinionated solutions where the users (developers) can just get what they need, with minimal interface. While
the administrators can control and manage as they want.

DCL provides two type of storage solutions.

* Ephemeral volumes
  - Volumes that is available during the life cycle of the services / containers. No data is persistent across
    service / container restarts. Data is stored on the nodes, where the services / containers created.
* Persistent volumes
  - Small and large volumes that persist the data, even across the life-cycle of the services / containers.
  - The data is stored either on NFS volumes or on AWS EBS volumes.

This page describes many examples of how a DCL user can define and make use of these storage solutions. Also
providing examples of defining and using via `CLI` or via `Compose`, while using standalone `containers` or
`services`.

Please refer to [volume concepts](../concepts/volumes.md) for a high level overview and [reference](../reference/volumes.md)
for specific details.

??? info "DCL packages the underlying solutions in a simplistic / meaningful way"
    Of course, DCL is making use of Docker and Docker Swarm extensively, while also using NFS volumes and AWS EBS volumes.
    But Docker has had a lot of baggage as it *grew* over a period of time, catering to a wide variety of users. In an
    effort to be as a platform engineering solution, DCL packages in an opinionated way. The terms such as `Ephemeral` and
    `Persistent` volumes is packaged in a way for the end user to easily make use of what they need, and is opinionated to
    hide several options that are not relevant anymore or not relevant to the audience of DCL.

## Ephemeral volumes

Ephemeral volumes are also called as anonymous volumes. The contents of the volumes are **empty** when the containers / services
start accessing. When the service restarts (on the same node or another node), these ephemeral volumes are recreated fresh. This
is synonymous to `emptyDir` of Kubernetes.

These ephemeral volumes do not need an explicit volume creation / destruction. They are part of the service spec, created while
service starts and deleted when the service gets destroyed.

Please see the following examples on how to make use of ephemeral volumes.

### Create ephemeral volumes

=== "docker run"
    ```console
    $ docker run --name alp1 -v /data alpine
    ...
    $ docker run --name alp1 --mount type=volume,target=/data alpine
    ...
    ```
=== "docker service create"
    ```console
    $ docker service create --name alp1 --mount type=volume,target=/data alpine:latest
    ```
=== "Compose"
    ```yaml
    services:
      alp1:
        image: alpine
        volumes:
        - type: volume
          target: /data
    ```

!!! note ""
    An ephemeral volume is created implicitly without a name. This can also be referred as
    `Anonymous` volume.

    {== 
    If a service / container is destroyed, the volume gets automatically destroyed. If a service
    or a container is restarted, the volume that was attached gets destroyed and a new volume is made available.
    ==}

    The size of the volume is limited to DCL Configuration [`storage.ephemeral.defaultSize`](../reference/configuration.md#storageephimeraldefaultsize), if that configuration is defined. Else, it does not have any limits.


### Create ephemeral volumes with a size

=== "docker run"
    ```console
    $ docker run --name alp1 --mount type=volume,target=/data,volume-opt=size=100M alpine
    ```
=== "docker service create"
    ```console
    $ docker service create --name alp1 --mount type=volume,target=/data,volume-opt=size=100M alpine
    ```
=== "Compose"
    ```yaml
    services:
      alp1:
        image: alpine
        volumes:
        - type: volume
          target: /data
          volume:
            driver_opts:
              size: 100M
    ```

!!! note ""
    An ephemeral volume is created implicitly without a name. This can also be referred as
    `Anonymous` volume.

    {==The quota for this volume is set to 100MB.==} If exceeded, you will receive an error.

    If a service / container is destroyed, the volume gets automatically destroyed. If a service
    or a container is restarted, the volume that was attached gets destroyed and a new volume is made available.

    The size of the volume is limited to 10MB in this case or [`storage.ephemeral.maxSize`](../reference/configuration.md#storageephimeralmaxsize) whichever is lower.


### Create named ephemeral volumes

You can name your ephemeral volumes,which can give you two advantages:

* Ability to share the volumes across services running on the same node
* Ability to retain data, even if that instance of the service restarts itself (on failures) or manually restarted.

The name of the volume must be prefixed with `local-` and the entire name of the volume should be as unique as possible.

=== "docker run"
    ```console
    $ docker run --name alp1 -v {==local-vol1:==}/data
    ...
    $ docker run --name alp1 --mount type=volume,{==src=local-vol1==},target=/data,volume-opt=size=100M alpine
    ```
=== "docker service create"
    ```console
    $ docker service create --name alp1 --mount type=volume,{==src=local-vol1==},target=/data,volume-opt=size=100M alpine
    ```
=== "Compose"
    ```yaml
    services:
      alp1:
        image: alpine
        volumes:
        - type: volume
          {==src: local-vol1==}
          target: /data
          volume:
            driver_opts:
              size: 100M
    ```

!!! note ""
    An ephemeral volume {==with the same name is created==} on the node where the service gets created.

    If a service is destroyed, the volume gets automatically destroyed. If a service
    is restarted, {==the volume retains the data across the restart of the service==}

??? example "Examples below to show how multiple services can share the same local ephemeral volume, `if they are scheduled on the same node`"
    === "docker run"
        ```console
        $ docker run --name c1 --mount type=volume,{==src=local-vol1==},target=/data,volume-opt=size=100M \
           --label dcl.constraint.node.hostname=mynode \
           alpine
        $ docker run --name c2 -v {==local-vol1:==}/data
           --label dcl.constraint.node.hostname=mynode \
           alpine
        ...
        ```
    === "docker service create"
        ```console
        $ docker service create --name c1 --mount type=volume,{==src=local-vol1==},target=/data,volume-opt=size=100M \
            --constraint node.hostname==mynode \
            alpine
        $ docker service create --name c2 --mount type=volume,{==src=local-vol1==},target=/data,volume-opt=size=100M \
            --constraint node.hostname==mynode \
            alpine
        ```
    === "Compose"
        ```yaml
        services:
          c1:
            image: alpine
            volumes:
            - type: volume
              {==src: local-vol1==}
              target: /data
              volume:
                driver_opts:
                  size: 100M
            deploy:
              placement:
                constraints:
                - "node.hostname==mynode"
          c2:
            image: alpine
            volumes:
            - type: volume
              {==src: local-vol1==}
              target: /data
            deploy:
              placement:
                constraints:
                - "node.hostname==mynode"
        ```
    !!! note ""
        An ephemeral volume {==with the same name is created==} on the SAME node where both the services get scheduled.

        The volume gets destroyed (on that node), when the last service referencing that volume gets deleted.

        The volume is local to the node and any other node is **not aware** of this volume. The same volume name can be
        used (but please do not), in other nodes independently.

    ???+ warning "Corner cases can make this vulnerable"
        Use this option carefully. You have to ensure that the services get scheduled on the SAME node, which is most likely
        only possible with the constraints `node.hostname`.

        Beware of scenarios like this: Suppose you create a service c1, and then c2, both using a volume `local-vol1`. And then 
        delete c1 and recreate c1 again. In this example, the service c2 is not removed and hence the volume `local-vol1` is 
        still available. If the service c1 expects a clean volume when it starts, it might result in an error as the service
        c1 will get the volume with existing data.

        Two separate sets of services may use the same name `local-vol1`. If they happen to get scheduled on the same node, the same
        volume will get shared between two different set of services, causing catastrophic errors. It is the users responsibility
        to ensure that there is no clash of volume names and chose as unique names as possible.

??? example "Example to show restart of the service still retains the named volume contents"
    === "docker run"
        ```console
        $ docker run --name c1 --mount type=volume,{==src=local-vol1==},target=/data alpine:latest
        $ docker exec -it c1 sh
        # echo "hello" > /data/file.txt
        #
        $ docker restart c1
        $ docker exec -it c1 cat /data/file.txt
        hello
        ```
    === "docker service create"
        ```console
        $ docker service create --name c1 --mount type=volume,{==src=local-vol1==},target=/data,volume-opt=size=100M alpine
        $ docker exec -it c1 sh
        # echo "hello" > /data/file.txt
        #
        $ docker service update --force c1
        $ docker exec -it c1 cat /data/file.txt
        hello
