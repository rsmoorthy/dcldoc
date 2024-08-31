# Volumes / Storage

Docker has basic support for temporary and persistent storage, at a fundamental unit level, at each individual
node. Docker Swarm does not extend this support for cluster wide setup, but just relies on basic node level
storage support by Docker.

Overall, for an enterprise setup, the following features (out-of-the-box) are missing with Docker Swarm.

* An easy to access shared persistent storage across the cluster
* Quota for temporary and persistent volumes across the cluster
* Secured access to volumes (restricting based on access rules)
* Ability to connect AWS EBS volumes to containers

DCL fulfils the above needs. And make it easier for the users to create, access storage without breaking a sweat.

To accomplish this, DCL also limits only certain specific storage methods and ignores / limits all the complex and
exhaustive features that Docker Swarm itself provides. DCL is your platform engineering tool, that gives you
an opinionated set of access to storage.

## Type of volumes

DCL provides you with the following types of volumes:

* Ephemeral volumes
    - The storage is given on the same node, where the container is running. Once the container
    is removed (stopped / restarted), the storage is also removed.
    - The life cycle of the storage / volume is directly linked to the container.
* Persistent volumes
    - The data persists even after the service / container is restarted
    - The life cycle of the storage is not dependent on the life cycle of the service / container

Each volume has a specific size, unless the administrator decides to not restrict the size of the volumes.

??? info "Storage and Volumes"
    The term `storage`  is referred in a general context, while the term `volumes` is meant as the `docker volume`.
    Technically, there are these different types of storage allocated.

    * The storage given to a container image. One copy of that specific version of docker image is allocated on each
      node for all active containers.
    * The storage for the "modified files" of each container, ie the root file system of each container.
    * The logs written by a container, that uses local storage.
    * Any specific volumes created and mounted for each container.

    Docker Swarm does not support any mechanism to limit the size of the container root file system, ie the modified
    files from the docker image. Though the standalone Docker does support it via `--storage-opt` option in `docker run`.

    Hence DCL also cannot support a size limitation to the container root fs. So technically it is possible for
    a container to bring down the entire node or all the entire containers running on that node, by filling up
    space in its container fs.

    It may be interesting to note that there is no clean, complete solution by out-of-the-box Kubernetes (1.31 version,
    as on date of writing this article). See the [related blog post](../blog/posts/holy-grail-of-node-stability.md) on this.


## Ephemeral volumes

This is known as `emptyDir` volumes in Kubernetes. It is an empty volume made available to the Container when it
starts and gets removed when the Container stops / gets killed.

!!! note 
    Here we say container, and not service. A service can have many replicas, each having a container. Also if the service 
    is restarted (due to errors / update), it creates a new container. Upon every new container, a new empty volume 
    is created and the volume is available until the container is running.

DCL ensures that these ephemeral volumes have a size limit, even when a user has not specified. And also limits the max
size, even if the user has provided a higher value. This is administered by DCL Config options 
[`storage.ephemeral.defaultSize`](../reference/configuration.md#storageephimeraldefaultsize) and [`storage.ephemeral.maxSize`](../reference/configuration.md#storageephimeralmaxsize)

??? info "Implicit vs Explicit Volumes"
    Docker allows certain volumes to be created implicitly, by defining the volume spec in a service / container
    spec. In which case, the life cycle of the volumes are tied directly to the Service / Container life cycle
    themselves.

    In another model, Docker allows you to create volumes explicitly by `docker volume create`. And then associate
    the created volume with any service / container. Thus the life cycle of the volume is independent of the service /
    container and needs to be destroyed explicitly by `docker volume rm`.

All ephemeral volumes are implicitly created in the DCL environment. Any volume created explicitly (except for `local-`, explained below) fall in the bucket of persistent volumes.

All these ephemeral volumes are **unnamed**, in the sense, if you do `docker volume ls` on the specific node, where the container is running, the volumes created will not have
a name associated with it.

Ephemeral volumes are created as follows. For other examples, see [here](../getting-started/volumes.md).

!!! example "How to use ephemeral volumes"
    === "docker run -v"
        ```console
        $ docker run -v /data alpine
        ```
        !!! note ""
            An ephemeral volume is created implicitly without a name. This can also be referred as
            `Anonymous` volume. DCL will ensure that the volume is destroyed (as it implicitly passes `--rm`)
            after the container / service is destroyed.

            The size of the volume is limited to [`storage.ephemeral.defaultSize`](../reference/configuration.md#storageephimeraldefaultsize), if that configuration is defined. Else, it does not have any limits.
    === "docker run --mount"
        ```console
        $ docker run --mount type=volume,target=/data alpine
        ```
        !!! note ""
            An ephemeral volume is created implicitly without a name. This can also be referred as
            `Anonymous` volume. DCL will ensure that the volume is destroyed (as it implicitly passes `--rm`)
            after the container / service is destroyed.

            The size of the volume is limited to [`storage.ephemeral.defaultSize`](../reference/configuration.md#storageephimeraldefaultsize), if that configuration is defined. Else, it does not have any limits.
    === "docker run with size"
        ```console
        $ docker run --mount type=volume,target=/data,volume-opt=size=80M alpine
        ```
        !!! note ""
            An ephemeral volume is created implicitly without a name. This can also be referred as
            `Anonymous` volume. DCL will ensure that the volume is destroyed (as it implicitly passes `--rm`)
            after the container / service is destroyed.

            The size of the volume is limited to 80MB in this case or [`storage.ephemeral.maxSize`](../reference/configuration.md#storageephimeralmaxsize) whichever is lower.

??? info "Unnamed ephemeral volumes cannot be shared with other services"
    These **unnamed** ephemeral volumes cannot be shared between other services, if even they are in the same node.

???+ note "Sidecar containers can access all the volumes from the parent container"
    By default, all the [sidecar containers](../concepts/sidecar.md) can access all the volumes of the parent container, including the ephemeral volumes.
    Please note that this is only one way, where the sidecar containers can access volumes from the main container / service, and not the other way around.

### Named ephemeral volumes

There is a special case of ephemeral volume, that requires it to be shared between services. You would typically do this only when you are sure that the services
in question are created on the same node.

If in case, the services in question are sharing the same volume, but end up in different nodes, they are provided different volumes, that are not shared.

DCL requires that you need to prefix the volume name by `local-` for all the volume names, to indicate that this is a local volume, but named and hence can be shared.
DCL itself will still keep the prefix `local-`, while passing it to Docker.

!!! example "How to use named ephemeral volumes"
    === "docker run -v"
        ```console
        $ docker run --name c1 -v local-vol1:/data --label dcl.constraint.node.hostname=mynode alpine
        ...
        $ docker run --name c2 -v local-vol1:/data --label dcl.constraint.node.hostname=mynode alpine
        ```
        !!! note "Life cycle and Quota"
            An ephemeral volume is created with a name as "local-vol1" on the remote node. Same volume "local-vol1" is shared between the two services `c1` and `c2`. 
            DCL will ensure that the volume is destroyed (as it implicitly passes `--rm`) after the last container / service is destroyed.

            The label [dcl.constraint.](../reference/containers.md) provides a mechanism for containers (unlike services) to provide the `constraints`.
    === "docker service create --mount"
        ```console
        $ docker service create --name c1 --mount type=volume,name=local-vol1,target=/data --constraint node.hostname==mynode alpine
        ...
        $ docker service create --name c2 --mount type=volume,name=local-vol1,target=/data --constraint node.hostname==mynode alpine
        ```
        !!! note "Life cycle and Quota"
            An ephemeral volume is created with a name as "local-vol1" on the remote node. Same volume "local-vol1" is shared between the two services `c1` and `c2`. 
            DCL will ensure that the volume is destroyed (as it implicitly passes `--rm`) after the last container / service is destroyed.

!!! warning "This should be a special case"
    You should only pursue this, only when you are very clear. You can easily get this wrong, where the two services could go into two different nodes, but you
    would have relied on a shared volume. There will be no warnings or errors, if it so happens.

???+ warning "More corner cases can make this vulnerable"
    Suppose you create a service c1, and then c2, both using a volume `local-vol1`. And then delete c1 and recreate c1 again. In this example, the service c2
    is not removed and hence the volume `local-vol1` is still available. If the service c1 expects a clean volume, it might result in an error as the service
    c1 will get the volume with existing data.

    Two separate sets of services may use the same name `local-vol1`. If they happen to get scheduled on the same node, the same volume will get shared between
    two different set of services, causing catastrophic errors. It is the users responsibility to ensure that there is no clash of volume names and chose
    as unique names as possible.

???+ warning "Does not work well with replicas"
    In most cases, if your services are using more than 1 replicas, this named volumes will only lead to catastrophic errors.

??? bug "TODO - DCL needs to ensure a named volume is deleted after the last service exits"
    Right now, Docker Swarm does not seem to delete a named ephemeral volume. But does it for unnamed ephemeral volumes.

## Persistent volumes

You want volumes that persist than the life cycle of the services (like a database or any persistent storage). You want to have full control over when
the data should be created and then destroyed, and is not tied to the services themselves (like an abrupt service restart or service upgrade or similar).

You also want to have persistent volumes managed by security controls, authorisation rules and quota management, so you can create / remove and access volumes based on
who has access to the volume.

DCL provides support for persistent volumes. It provides two different methods of persistent volumes:

* NFS volume
    - Users can create a docker volume that actually maps to a NFS folder.
    - The [NFS server etc](../setup/nfs-setup.md) needs to be setup by the administrator.
    - Data in the NFS share is expected to be persistent.
    - It is normally advised that the size of such NFS volume be smaller in size. Typical suggestion is to keep the volume size smaller than 1GB. But you can decide
      based on the number of services, number of volumes and how much network bandwidth you have.
    - Multiple services can attach the same volume, but it is the user's responsibility to ensure that there are no synchronisation issues.
* AWS EBS volume
    - Users can create a docker volume that actually maps to an EBS volume.
    - An EBS volume gets created on `docker volume create` either as an empty volume or prefilled with some data.
    - It makes sense to use AWS EBS volumes for larger volume sizes, as the overhead of creating a EBS volume is higher.
    - Only one service can attach a volume at a given time.

??? tip "Persistent does not mean highly available :) "
    For a highly available or a fault tolerant setup, the basic disks should be setup with appropriate RAID technologies and suitable regular backups.

You create a persistent volume using `docker volume create`. After that, you can attach it to services / containers. All data written during this time is persistent.
The volume gets deleted only when you issue a `docker volume rm`.

### NFS volumes

DCL is positioned as a Platform engineering tool, where the users are shielded from many complex configurations and the administrator sets up an opinionated setup.

Hence the end users need to provide only the following input to setup a NFS volume:

* An unique Volume name, that also indicates it is of type `NFS`
* Size of the volume
* (optional) user/group id of the root mount path (default will be `0:0`)
* (optional) permissions of the root mount path (default will be `0755`)

While the administrators are expected fill-in the rest of the information, in DCL's configuration:

* The NFS server IP/name and the path of the root share that is exposed
  - You could setup multiple NFS server paths, if you have multiple NFS servers. But a given volume will get located only in a given NFS server and
    it stays there for its lifetime.
  - You could setup simple rules to allocate a separate NFS servers for specific users or purpose.  (Like production using a separate NFS server, if you wish so)

DCL will create folders corresponding to volume names in the corresponding NFS server root path, when `docker volume create` is done, and it sets up quota, folder
ownership and permissions. DCL will also update the labels for `volume` to store the meta data of the volume itself (like the owner, namespace etc)

When a service uses the `volume`, the volume is attached by the `dcl-nfs` docker volume plugin, that is installed on all the workers and manager nodes. The `dcl-nfs`
will actually do the NFS mounting. If configured so, the `dcl-nfs` plugin will only mount a particular server only once, to reduce the amount of NFS mounts
on a given server. Please refer to the [NFS setup](../setup/nfs-setup.md) for more details.

A simple example is given below. Please see [here](../getting-started/volumes.md) for more examples.

!!! example "Simple NFS example"
    ```console
    $ docker volume create \
        -o size=10M \
        -o owner=1000 \
        -o permissions=0700 \
        nfs-vol1
    ...
    $ docker run --mount src=nfs-vol1,target=/data alpine 
    ...
    $ docker volume rm nfs-vol1
    ```

#### High level Implementation

DCL accomplishes this by a Docker Volume Plugin `dcl-nfs` that needs to be installed on all the docker nodes, including the manager nodes. DCL automatically injects the `--driver dcl-nfs` option when it sees the volume name prefixed with `nfs-`. All the `opts` 
(including `size`, `owner` etc) is defined by the `dcl-nfs` volume plugin.

DCL automatically injects additional labels and opts, that is required for the `dcl-nfs` plugin on the node, to actually mount the volume.
Thus the volume will have all the opts needed to actually create the volume and mount the volume, and it need not depend on any communication
with DCL to get details, while creating / mounting the nfs volume.

The additional labels and opts, that are internally managed, are described in the [DCL Config](../reference/configuration.md)

### AWS EBS Volumes

Continuing the same philosophy, as described in the previous section, AWS EBS volumes are also configured in the same fashion.

Hence the end users need to provide only the following input to setup a AWS EBS volume:

* An unique volume name,  that also indicates that is of type `awsebs`
* Size of the volume
* (optional) user/group id of the root mount path (default will be `0:0`)
* (optional) permissions of the root mount path (default will be `0755`)
* (optional) A snapshot name from which this volume should be cloned (default is none)
* (optional) The AZ that this should be placed in, which is one of A, B, C, ... If none provided, it takes the value of
  [`storage.persistent.awsebs.defaultZone`](../reference/volumes.md#storagepersistentawsebsdefaultzone). The zone name is converted
  to lowercase and then appended to [`storage.persistent.awsebs.region`](../reference/volumes.md#storagepersistentawsebsregion) before
  creating the volume.
* (optional) The type of the volume. One of `gp2`, `gp3`, `st1`. The default is [`storage.persistent.awsebs.type`](../reference/configuration.md#storagepersistentawsebstype)
* (optional) The max throughput of a gp3 volume, throughput is defined as MB/sec. Default is defined by the value of [`storage.persistent.awsebs.throughput`](../reference/configuration.md#storagepersistentawsebsthroughput)

The administrators are expected to have created the setup before hand, so that appropriate permissions are in place for DCL to create
EBS volumes and snapshot names are in place to clone from.

It is important that if the EBS volume is in zone A, then a node in zone B or C cannot mount the volume. The service should get scheduled
on a node that is on the same AZ as the EBS volume.

It is the user's and administrator's responsibility to ensure that the service, which uses the `awsebs` volume also belongs to the same AZ as the
volume. This can be ensured by service constraints (`dcl.constraint.node.zone`). The administrator responsibility is to ensure that
the user can indeed specify the appropriate AZ for the volume and for the service constraints in the Auth rules, so that the administrator
is in full control of where the volumes and nodes are getting created for most dev needs (where you may not need AZ level spread), while
a production setup could be spread around different AZ levels.

The configuration administrators need to do include:

*  Set the following DCL configurations
  - [`storage.persistent.awsebs.defaultZone`](../reference/volumes.md#storagepersistentawsebsdefaultzone)
  - [`storage.persistent.awsebs.region`](../reference/volumes.md#storagepersistentawsebsregion)
* If you want to limit the AZ where the EBS volume can be setup and allow the service to be scheduled on a node on different AZ, set up
  the [auth rules](../setup/auth-rules.md) so that the users can set the AZ for the volume and the node.
  - [`storage.persistent.awsebs.zones`](../setup/auth-rules.md#storagepersistentawsebszones)
  - [`dcl.constraint.node.zones`](../setup/auth-rules.md#dclconstraintnodezones)

A simple example is given below. Please see [here](../getting-started/volumes.md) for more examples.

!!! example "Simple AWSEBS example"
    ```console
    $ docker volume create \
        -o size=100G \
        -o az=A \
        -o snapshot=postgres-db-snapshot1 \
        -o type=gp3 \
        -o throughput=250 \
        awsebs-vol1
    ...
    $ docker run --mount src=awsebs-vol1,target=/data alpine 
    ...
    $ docker volume rm awsebs-vol1
    ```

#### Life cycle of a AWS EBS volume

The actual EBS volume is created when the `docker volume create` is issued. You will be billed from this moment on, for the given
volume. Even if the volume is not used by any service, the EBS volume is billed. Until you delete the volume using `docker volume rm`.

So, DCL actually creates the EBS volume, when the `docker volume create` command is issued. And DCL deletes the EBS volume when the
command `docker volume rm` is issued.

#### EBS volume High level Implementation

DCL accomplishes this by a Docker Volume Plugin `dcl-awsebs` that needs to be installed on all the docker nodes, including the manager nodes. DCL automatically injects the `--driver dcl-awsebs` option when it sees the volume name prefixed with `awsebs-`. All the `opts` 
(including `size`, `owner` etc) is defined by the `dcl-awsebs` volume plugin.

DCL automatically injects additional labels and opts, that is required for the `dcl-awsebs` plugin on the node, to actually mount the volume.
Thus the volume will have all the opts needed to actually create the volume and mount the volume, and it need not depend on any communication
with DCL to get details, while creating / mounting the aws ebs volume.

The additional labels and opts, that are internally managed, are described in the [DCL Config](../reference/configuration.md)

### RAID volumes based on AWS EBS Volumes

This is a future feature, where DCL will automatically setup a RAID volume based on more than one AWS EBS volumes. This will help
improve High availability and protect against a single failure. This feature can also be helpful to have a RAID/LV volume that
combines multiple EBS volumes to a single higher volume.

## Modifying Persistent Volumes

It's often a requirement to modify certain aspects of persistent volumes like increasing / decreasing the size of the volume,
or increasing/decreasing the throughput of the `awsebs` volume. Once created, many other parameters may not be modified, including
`owner`, `permissions` etc.

DCL allows you to modify the following parameters of a volume:

For NFS volumes:

* `size` - Can be increased or decreased. It actually sets the FS level quota on that volume. So if you decrease :> 
