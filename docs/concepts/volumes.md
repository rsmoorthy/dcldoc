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

## Type of storage

DCL provides you with the following types of storage:

* Ephemeral storage
    - The storage is given on the same node, where the container is running. Once the container
    is removed (stopped / restarted), the storage is also removed.
    - The life cycle of the storage / volume is directly linked to the container.
* Persistent storage
    - The data persists even after the service / container is restarted
    - The life cycle of the storage is not dependent on the life cycle of the service / container

Each volume has a specific size, unless the administrator decides to not restrict the size of the volumes.

??? info "Storage vs Volumes"
    The term `storage`  is referred in a general context, while the term `volumes` is meant as the `docker volume`.
    Technically, there are three different types of storage allocated.

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

DCL ensures that these ephemeral volumes have a size, even when a user has not specified. And also limits the max
size, even if the user has provided a higher value. This is administered by DCL Config options 
`storage.ephemeral.defaultSize` and `storage.ephemeral.maxSize`








