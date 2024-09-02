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
    $ docker run --name alp1 -v /data -itd alpine
    ...
    $ docker run --name alp1 --mount type=volume,target=/data -itd alpine
    ...
    ```
=== "docker service create"
    ```console
    $ docker service create -td --name alp1 --mount type=volume,target=/data alpine:latest
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
    $ docker run --name alp1 --mount type=volume,target=/data,volume-opt=size=100M -itd alpine
    ```
=== "docker service create"
    ```console
    $ docker service create -td --name alp1 --mount type=volume,target=/data,volume-opt=size=100M alpine
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
    $ docker run --name alp1 -v {==local-vol1:==}/data -itd alpine
    ...
    $ docker run --name alp1 --mount type=volume,{==src=local-vol1==},target=/data,volume-opt=size=100M -itd alpine
    ```
=== "docker service create"
    ```console
    $ docker service create -td --name alp1 --mount type=volume,{==src=local-vol1==},target=/data,volume-opt=size=100M alpine
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
           -itd alpine
        $ docker run --name c2 -v {==local-vol1:==}/data
           --label dcl.constraint.node.hostname=mynode \
           -itd alpine
        ...
        ```
    === "docker service create"
        ```console
        $ docker service create -td --name c1 --mount type=volume,{==src=local-vol1==},target=/data,volume-opt=size=100M \
            --constraint node.hostname==mynode \
            alpine
        $ docker service create -td --name c2 --mount type=volume,{==src=local-vol1==},target=/data,volume-opt=size=100M \
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
        $ docker run --name c1 --mount type=volume,{==src=local-vol1==},target=/data -itd alpine:latest
        $ docker exec -it c1 sh
        # echo "hello" > /data/file.txt
        #
        $ docker restart c1
        $ docker exec -it c1 cat /data/file.txt
        hello
        ```
    === "docker service create"
        ```console
        $ docker service create -td --name c1 --mount type=volume,{==src=local-vol1==},target=/data,volume-opt=size=100M alpine
        $ docker exec -it c1 sh
        # echo "hello" > /data/file.txt
        #
        $ docker service update --force c1
        $ docker exec -it c1 cat /data/file.txt
        hello

### Create ephemeral volumes on RAM

You can create your ephemeral volumes on RAM (`tmpfs volume`), which may be needed in few select use cases.

* Ability to keep certain keys and other sensitive files in a filesystem, which never gets written on a disk.
* You need to use shared memory between processes in the same container. For example, Elastic search needs a higher shared memory.

The amount of memory allocated to such RAM volumes (or `tmpfs` volumes) is 1MB, unless specified explicitly by the users. All memory
allocated via the RAM/tmpfs volumes is considered for your memory quota.

??? example "Creating RAM ephemeral volumes"
    === "docker run"
        ```console
        $ docker run --name alp1 --mount {==type=tmpfs,target=/memfs==} -itd alpine
        ```
    === "docker service create"
        ```console
        $ docker service create -td --name alp1 --mount {==type=tmpfs,target=/memfs==} alpine
        ```
    === "Compose"
        ```yaml
        services:
          alp1:
            image: alpine
            volumes:
            - type: tmpfs
              target: /memfs
        ```
    !!! note ""
        An ephemeral volume on RAM is created, the default size of this volume is based on [`storage.ephemeral.tmpfs.defaultSize`](../reference/configuration.md#storageephimeraltmpfsdefaultsize). If that configuration is not present, then the size is taken to be 1MB.

??? example "Creating RAM ephemeral volumes with size"
    === "docker run"
        ```console
        $ docker run --name alp1 --mount {==type=tmpfs,target=/memfs,tmpfs-size=1G==} -itd alpine
        ```
    === "docker service create"
        ```console
        $ docker service create -td --name alp1 --mount {==type=tmpfs,target=/memfs,tmpfs-size=1G==} alpine
        ```
    === "Compose"
        ```yaml
        services:
          alp1:
            image: alpine
            volumes:
            - type: tmpfs
            ""  target: /memfs
              tmpfs:
                size: 1G
        ```
    !!! note ""
        An ephemeral volume on RAM is created, with the size as mentioned. This size is accounted in your quota for total memory consumed.

        The size is the lower value of the requested one or [`storage.ephemeral.tmpfs.maxSize`](../reference/configuration.md#storageephimeraltmpfsmaxsize)

## Persistent volumes

You want volumes that persist than the life cycle of the services (like a database or any persistent storage). You want to have full control over when
the data should be created and then destroyed, and is not tied to the services themselves (like an abrupt service restart or service upgrade or similar).

DCL provides support for persistent volumes. It provides two different methods of persistent volumes:

* NFS volume
    - Users can create a docker volume that actually maps to a NFS folder.
    - Data in the NFS share is expected to be persistent.
    - It is normally advised that the size of such NFS volume be smaller in size. Typical suggestion is to keep the volume size smaller than 
      1GB. But you can decide based on the number of services, number of volumes and how much network bandwidth you have.
    - Multiple services can attach the same volume, but it is the user's responsibility to ensure that there are no synchronisation issues.
* AWS EBS volume
    - Users can create a docker volume that actually maps to an EBS volume.
    - An EBS volume gets created on `docker volume create` either as an empty volume or prefilled with some data.
    - It makes sense to use AWS EBS volumes for larger volume sizes, as the overhead of creating a EBS volume is higher.
    - Only one service can attach a volume at a given time.

With persistent volumes, the creation / destruction of volumes is done independent of service creation, which makes use of the volumes. The said
volumes are actually created "physically", when a `docker volume create` is issued and the quota comes into effect, the moment it is created, even
if it is not being used.

### NFS volumes

Data is stored in a NFS server, independent of the nodes where the services run. DCL ensures that the NFS volume is automatically mounted, while
also ensuring that the access to mount the volumes is restricted and based on RBAC via auth rules.

The name of the volume should be prefixed with `nfs-`

??? example "Creating and using NFS volumes"
    === "docker run"
        ```console
        $ docker volume create \
            -o size=10M \
            -o owner=1000 \
            -o mode=0700 \
          nfs-vol1
        $ docker run --name c1 -v nfs-vol1:/data -itd alpine:latest
        ```
    === "docker service create"
        ```console
        $ docker volume create \
            -o size=10M \
            -o owner=1000 \
            -o mode=0700 \
          nfs-vol1
        $ docker service create -td --name c1 --mount type=volume,src=nfs-vol1,target:/data alpine:latest
        ```
    === "Compose"
        ```yaml
        volumes:
          nfs-vol1:
            driver_opts:
              size: 10M
              owner: 1000
              mode: 0700
        services:
          c1:
            image: alpine
            volumes:
            - type: volume
              src: nfs-vol1
              target: /data
        ```
    !!! note ""
        A docker volume is created with the name `nfs-vol1`. Unless deleted with `docker volume rm` or via `docker compose down -v`, the volume
        remains persistent.

        The volume `nfs-vol1` is accessible from any node within the cluster.

        It uses size of 10MB, the root path ownership is changed to id `1000` and the mode of the root path is set to `rwx------`

??? example "Example of persistency with NFS volume"
    === "docker run"
        ```console
        $ docker volume create \
            -o size=10M \
            -o owner=1000 \
            -o mode=0700 \
          nfs-vol1
        $ docker run --name c1 -v nfs-vol1:/data -itd alpine:latest
        $ docker exec -it c1 sh
        # echo "hello" > /data/f1
        $ docker stop c1; docker rm c1
        $ docker run --name c2 -v nfs-vol1:/data -itd alpine:latest
        $ docker exec -it c2 sh
        # cat /data/f1
        hello
        ```
    === "docker service create"
        ```console
        $ docker volume create \
            -o size=10M \
            -o owner=1000 \
            -o mode=0700 \
          nfs-vol1
        $ docker service create -td --name c1 --mount type=volume,src=nfs-vol1,target:/data alpine:latest
        $ docker exec -it c1 sh
        # echo "hello" > /data/f1
        $ docker stop c1; docker rm c1
        $ docker service create -td --name c2 --mount type=volume,src=nfs-vol1,target:/data alpine:latest
        $ docker exec -it c2 sh
        # cat /data/f1
        hello
        ```

??? example "Example of deleting NFS volume"
    === "docker service create"
        ```console
        $ docker volume create \
            -o size=10M \
            -o owner=1000 \
            -o mode=0700 \
          nfs-vol1
        $ docker service create -td --name c1 --mount type=volume,src=nfs-vol1,target:/data alpine:latest
        $ # Now let us try deleting the NFS volume
        $ docker volume rm nfs-vol1
        Error response from daemon: remove nfs-vol1: volume is in use - [xxxxxxxxxxx]
        $ # Cannot delete as the service c1 is still using. Now let us delete service c1 and then delete the volume
        $ docker service rm c1
        $ docker volume rm nfs-vol1
        $ # This time it is successful

        $ # Trying to use volume that does not exist
        $ docker service create -td --name c1 --mount type=volume,src=nfs-vol1,target:/data alpine:latest
        Error response from daemon: DCL the volume nfs-vol1 does not exist.
        ```

??? example "Example of quota of NFS volume"
    === "docker service create"
        ```console
        $ docker volume create \
            -o size=10M \
            -o owner=1000 \
            -o mode=0700 \
          nfs-vol1
        $ docker service create -td --name c1 --mount type=volume,src=nfs-vol1,target:/data alpine:latest
        $ # Now let us check the size of volume and the limit
        $ docker exec -it c1 sh
        / # df -h | grep data
        Filesystem                    Size      Used Available Use% Mounted on
        :/nfs-vol1                   10.0M         0     10.0M   0% /data
        / # dd if=/dev/zero of=/data/f1 bs=100k count=150  # Try to write 15MB file
        dd: /data/f1: No space left on device
        / # 
        / # df -h | grep data
        Filesystem                    Size      Used Available Use% Mounted on
        :/nfs-vol1                   10.0M     10.0M         0 100% /data
        / # ls -lh /data/
        total 10M    
        -rw-r--r--    1 root     root       10.0M Sep  2 10:45 f1
        $
        $ # now do cleanup
        $
        $ docker service rm c1
        $ docker volume rm nfs-vol1
        ```

??? example "Modifying NFS volumes size"
    ```console
    $ docker volume create -o size=10M nfs-vol1
    $ docker run --name c1 --mount src=nfs-vol1,target=/data -itd alpine 
    $ docker exec -it c1 sh
    / # df -h | grep data
    Filesystem                    Size      Used Available Use% Mounted on
    :/nfs-vol1                   10.0M         0     10.0M   0% /data
    $ # Later
    $ docker volume create -o size=20M nfs-vol1
    $ docker exec -it c1 sh
    / # df -h | grep data
    Filesystem                    Size      Used Available Use% Mounted on
    :/nfs-vol1                   20.0M         0     20.0M   0% /data
    ```

### AWS EBS volumes

Data is stored in an actual AWS EBS volume. A EBS volume is created, when you request via `docker volume create` and destroyed when you 
issue `docker volume rm` CLI command. The life cycle of this EBS volume is independent of the services themselves. The quota for a EBS volume
starts when you issue the volume create command, as from this time, AWS starts billing for this volume. So even though you create a volume and
do not use it, it will not deter AWS from continuing to bill.

When you create a service and attach this volume, then DCL will ensure that the actual EBS volume is attached to the container running
on that node, all in the background. The EBS volume can be attached to only one service at a time. If you kill the service, and create another
service (running on another node) and attach this volume, DCL will automatically move the EBS volume to the new node.

!!! info "Volume and Node on the same AZ"
    It is also important for you to know that the AWS can attach a volume to a node (aka server), if both belong to the same AZ. The administrator
    would have configured DCL so that you can create volumes and then services to a default zone, so in most cases, you do not have worry about it.
    But if the administrator has given you option to create volumes and services in multiple AZ, then you need to ensure that the volume and the
    service is on the same AZ. See below for details.

!!! info "You can pre-populate the EBS volume"
    Unlike NFS volume, which creates an empty directory when created, EBS volumes can be boot-strapped with data/contents from a snapshot.
    For ex, if you are using a database, you can pre-populate a EBS volume with a base database, from among many snapshots that the administrator
    has setup for you.

    You have to ensure that the size of EBS volume is greater than the snapshot size.

??? info "You can set the size and throughput of EBS volume"
    You can set the size of the EBS volume, while creating the volume. The min and max size is dependent on the DCL configurations 
    [`storage.persistent.awsebs.minSize`](../reference/configuration.md#storagepersistentawsebsminsize) and 
    [`storage.persistent.awsebs.maxSize`](../reference/configuration.md#storagepersistentawsebsmaxsize) and 

    The size is also restricted by the quota of disk sizes allocated to you by your administrator.

    For some high performance requirements, you can set a higher throughput of the EBS volume. The default is 128MB/sec or set by
    [`storage.persistent.awseb.throughput`](../reference/configuration.md#storagepersistentawsebsthroughput). As with the size, the max size 
    is dictated by [`storage.persistent.awseb.maxThroughput`](../reference/configuration.md#storagepersistentawsebsmaxthroughput).

The name of the volume should be prefixed with `awsebs-`

??? example "Creating and using AWS EBS volumes"
    === "docker run"
        ```console
        $ docker volume create \
            -o size=10G \
            -o owner=1000 \
            -o mode=0700 \
          awsebs-vol1
        $ docker run --name c1 -v awsebs-vol1:/data -itd alpine:latest
        ```
    === "docker service create"
        ```console
        $ docker volume create \
            -o size=10G \
            -o owner=1000 \
            -o mode=0700 \
          awsebs-vol1
        $ docker service create -td --name c1 --mount type=volume,src=awsebs-vol1,target:/data alpine:latest
        ```
    === "Compose"
        ```yaml
        volumes:
          awsebs-vol1:
            driver_opts:
              size: 10G
              owner: 1000
              mode: 0700
        services:
          c1:
            image: alpine
            volumes:
            - type: volume
              src: awsebs-vol1
              target: /data
        ```
    !!! note ""
        A docker volume is created with the name `awsebs-vol1` with the actual EBS volume created in AWS. 
        Unless deleted with `docker volume rm` or via `docker compose down -v`, the volume remains persistent.

        The volume `awsebs-vol1` is accessible from any node within the cluster.

        It uses size of 10GB, the root path ownership is changed to id `1000` and the mode of the root path is set to `rwx------`

??? example "Example of deleting AWS EBS volume"
    === "cli"
        ```console
        $ docker volume rm awsebs-vol1
        ```

??? example "Can only attach to one service at a time"
    === "cli"
        ```console
        $ docker volume create -o size=10G awsebs-vol1
        $ docker run --name c1 -v awsebs-vol1:/data -itd alpine:latest
        # Later
        $ docker run --name c2 -v awsebs-vol1:/data -itd alpine:latest
        Error response from daemon: DCL The volume 'awsebs-vol1' is already mounted. Failed.
        ```

??? example "Modifying EBS volume size / throughput"
    ```console
    $ docker volume create -o size=10G awsebs-vol1
    $ docker run --name c1 --mount src=awsebs-vol1,target=/data -itd alpine 
    $ docker exec -it c1 sh
    / # df -h | grep data
    Filesystem                    Size      Used Available Use% Mounted on
    :/awsebs-vol1                   10.0G         0     10.0G   0% /data
    $ # Later
    $ docker volume create -o size=20G -o throughput=256 awsebs-vol1
    $ docker exec -it c1 sh
    / # df -h | grep data
    Filesystem                    Size      Used Available Use% Mounted on
    :/awsebs-vol1                   20.0G         0     20.0G   0% /data
    ```
