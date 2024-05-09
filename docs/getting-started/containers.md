# Containers

DCL allows you to create regular containers, created via CLI (using `docker run`) or via docker-compose, in the cluster. It gives
you the flexibility of using the regular docker commands, where the containers are created somewhere in a cluster (on any other node).

## Docker vs Swarm vs DCL

Specifically the interface to creating and managing containers (using `docker run` etc) is provided by DCL (as supposed to using only `docker service...`), so
that DCL can achieve the following:

*    Allow docker users to directly exec / attach to containers running in the cluster (on another node) via `docker exec`
*    Allow docker users to directly copy files from/to containers running in the cluster (on another node) via `docker cp`
*    Provide sidecar containers (similar to Kubernetes) support to Docker Swarm cluster

To illustrate the differences between Docker, Docker Swarm and DCL, here is a quick summary:

+------------------------+----------------------------------+--------------------------+---------------------------------+
|  Task                  |           Docker                 |            Docker Swarm  |      DCL                        |
+========================+==================================+==========================+=================================+
| Create containers      | `docker run` <br>                | `docker service` <br>    |`docker run` or `docker service` |
|                        | create locally in                | create in any node in    |<br> create in any node in the   |
|                        | the same node                    | the cluster              |cluster                          |
+------------------------+----------------------------------+--------------------------+---------------------------------+
| Exec / Attach          | `docker exec` <br>               | _Not Available_          |`docker exec`                    |
| to container           | exec to the                      |                          |<br> exec to the container in    |
|                        | container in same                |                          |the cluster in any node          |
|                        | node                             |                          |                                 |
+------------------------+----------------------------------+--------------------------+---------------------------------+
| Copy files from/       | `docker cp` <br>                 | _Not Available_          |`docker cp`                      |
| to container           | copy from/to the                 |                          |<br> cp from/to the container in |
|                        | container in same                |                          |the cluster in any node          |
|                        | node                             |                          |                                 |
+------------------------+----------------------------------+--------------------------+---------------------------------+
| Sidecar containers     | `docker run` <br>                | _Not Available_          |`docker run` or `docker service` |
| like K8S               | `--net=container:<name>` <br>    |                          |<br> Use env `DCL_SIDECAR=` with |
|                        | `--pid=container:<name>` <br>    |                          |`<svcId|svcName|cntName|cndId>`  |
|                        | Runs on the same node            |                          |<br>OR<br>                       |
|                        |                                  |                          |sidecar containers defined       |
|                        |                                  |                          |using labels.<br>                |
|                        |                                  |                          |[Learn More](sidecars.md)        |
+------------------------+----------------------------------+--------------------------+---------------------------------+

## Container Transformations / Translations

Creating and managing containers in DCL is done by few transformations. Essentially, DCL is a `docker proxy` for a Docker Swarm
in the backend and DCL transforms and translates requests / responses of Containers to Swarm mode on the fly.

+------------------------+----------------------------------+--------------------------+---------------------------------+
|  Task                  | Request Transformation           | Response Transformation  | Remarks                         |
+========================+==================================+==========================+=================================+
| docker run             | DCL transforms to                | Waits for service to     |                                 |
|                        | `docker service create` equiv    | start <br> Responds with |                                 |
|                        |                                  |service id as containerId |                                 |
+------------------------+----------------------------------+--------------------------+---------------------------------+
| docker ps              | DCL Sends request to all nodes   | Collates all responses   |                                 |
|                        | with command `docker ps`         |                          |                                 |
|                        |                                  |                          |                                 |
+------------------------+----------------------------------+--------------------------+---------------------------------+
| docker exec / cp       | DCL identifies the node          | Proxies (tcp tunnels)    |                                 |
|                        | issues the request to that node  | all comm between client  |                                 |
|                        |                                  | and the node             |                                 |
+------------------------+----------------------------------+--------------------------+---------------------------------+
| docker inspect / top   | DCL identifies the node          | Pass the info back as is |                                 |
|        stats           | issues the request to that node  |                          |                                 |
|                        |                                  |                          |                                 |
+------------------------+----------------------------------+--------------------------+---------------------------------+
| docker stop            | Transforms to                    | Pass the info back as is | TBImpl                          |
|                        | `service update --replicas 0`    |                          |                                 |
|                        |                                  |                          |                                 |
+------------------------+----------------------------------+--------------------------+---------------------------------+
| docker start           | If `replicas 0` then transforms  | Pass the info back as is | TBImpl                          |
|                        | `service update --replicas 1`    |                          |                                 |
|                        | Else NoOp                        |                          |                                 |
+------------------------+----------------------------------+--------------------------+---------------------------------+

## Limitations in DCL for Containers

Creating and managing containers in DCL has few limitations. As the DCL's back-end is a Docker Swarm cluster, mapping
containers to services cannot be done for all use cases. So DCL limits several functionalities, when you access via
docker container interface.

If these limitations are an issue, you can switch over to a Docker Swarm interface (`docker service`, instead of `docker
container`), which has better support than containers. If you use `docker compose`, you can switch over to the
equivalent `docker stack`.

+-----------------------------------------------------------+------------------------------------------------------------+
|  Limitation                                               | Remarks                                                    |
+===========================================================+============================================================+
| Create containers      | `docker run` <br>                | `docker service` <br>    |`docker run` or `docker service` |
|                        | create locally in                | create in any node in    |<br> create in any node in the   |
|                        | the same node                    | the cluster              |cluster                          |
+-----------------------------------------------------------+------------------------------------------------------------+
| Exec / Attach          | `docker exec` <br>               | _Not Available_          |`docker exec`                    |
| to container           | exec to the                      |                          |<br> exec to the container in    |
|                        | container in same                |                          |the cluster in any node          |
|                        | node                             |                          |                                 |
+------------------------+----------------------------------+--------------------------+---------------------------------+

