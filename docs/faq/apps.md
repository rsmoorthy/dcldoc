# FAQ - Applications

#### [How to get the service name from within the container?](#service-name-from-within){ #service-name-from-within }

Docker accepts templated variables, where the values are substituted by Docker automatically.

!!! note "Example with ENV"
    === "docker run"
        ```console
        $ dcladmin docker run --name alpine -h alpine \
          --env "SERVICE_NAME={{.Service.Name}}" \
          -itd alpine
        ```
    === "docker compose"
        ```yaml
        services:
          alpine:
            image: alpine
            hostname: alpine
            environment:
              SERVICE_NAME: '{{.Service.Name}}'
        ```

    === "output"
        ```console
        $ dcl admin docker exec -it alpine sh
        / # env
        HOME=/root
        TERM=xterm
        SERVICE_NAME=alpine
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        PWD=/
        / #
        $
        ```

??? note "Example with templated hostname"
    You can not only pass env variables, you can also change some of the values passed in command line (for ex: `hostname`)

    === "docker run"
        ```console
        $ dcladmin docker run --name alpine -h "alpine-{{.Task.Slot}}" \
          --env "SERVICE_NAME={{.Service.Name}}" \
          -itd alpine
        ```
    === "docker compose"
        ```yaml
        services:
          alpine:
            image: alpine
            hostname: 'alpine-{{.Task.Slot}}'
            environment:
              SERVICE_NAME: '{{.Service.Name}}'
        ```

    === "output"
        ```console
        $ dcl admin docker exec -it alpine sh
        / # echo $SERVICE_NAME
        alpine
        / # hostname
        alpine-1
        / # ping -c1 alpine-1
        PING alpine-1 (192.168.200.63): 56 data bytes
        64 bytes from 192.168.200.63: seq=0 ttl=64 time=0.144 ms

        --- alpine-1 ping statistics ---
        1 packets transmitted, 1 packets received, 0% packet loss
        round-trip min/avg/max = 0.144/0.144/0.144 ms
        ```


??? note "Large example with several templated variables"
    === "docker compose"
        ```yaml
        services:
          alpine:
            image: alpine
            hostname: 'alpine-{{.Task.Slot}}'
            command: sleep 10000
            environment:
              X_NODE_ID: '{{.Node.ID}}'
              X_NODE_HOSTNAME: '{{.Node.Hostname}}'
              X_NODE_PLATFROM: '{{.Node.Platform}}'
              X_NODE_PLATFROM_ARCHITECTURE: '{{.Node.Platform.Architecture}}'
              X_NODE_PLATFROM_OS: '{{.Node.Platform.OS}}'
              X_SERVICE_ID: '{{.Service.ID}}'
              X_SERVICE_NAMES: '{{.Service.Name}}'
              X_SERVICE_LABELS: '{{.Service.Labels}}'
              X_SERVICE_LABEL_STACK_NAMESPACE: '{{index .Service.Labels "com.docker.stack.namespace"}}'
              X_SERVICE_LABEL_STACK_IMAGE: '{{index .Service.Labels "com.docker.stack.image"}}'
              X_SERVICE_LABEL_CUSTOM: '{{index .Service.Labels "service.label"}}'
              X_TASK_ID: '{{.Task.ID}}'
              X_TASK_NAME: '{{.Task.Name}}'
              X_TASK_SLOT: '{{.Task.Slot}}'
        ```

    === "output"
        ```console
        $ dcl admin docker compose -f c.yaml -p my up -d
        [+] Running 1/1
         ✔ Container my-alpine-1  Created  4.6s
        $
        $
        $
        $ dcl admin docker exec -it my-alpine-1 sh
        / # env
        X_SERVICE_LABEL_STACK_NAMESPACE=
        X_NODE_PLATFROM_OS=linux
        HOSTNAME=alpine-1
        SHLVL=1
        HOME=/root
        X_NODE_HOSTNAME=swarm2
        X_SERVICE_NAMES=my-alpine-1
        X_TASK_SLOT=1
        X_NODE_ID=h4de846tqqkahigkbet9ln6wq
        X_SERVICE_LABEL_STACK_IMAGE=
        X_SERVICE_ID=f3e9yb8art4un5bvzoaill1v9
        X_SERVICE_LABEL_CUSTOM=
        TERM=xterm
        X_NODE_PLATFROM={x86_64 linux}
        X_TASK_NAME=my-alpine-1.1.j98fv7oxms2r0irvsohwlt8ip
        PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        X_TASK_ID=j98fv7oxms2r0irvsohwlt8ip
        PWD=/
        X_SERVICE_LABELS=map[com.docker.compose.config-hash:22659e2972c3c1da8c8ba9a617474ac0653b5f94cabfad6673208cf9f940356e com.docker.compose.container-number:1 com.docker.compose.depends_on: com.docker.compose.image:sha256:05455a08881ea9cf0e752bc48e61bbd71a34c029bb13df01e40e3e70e0d007bd com.docker.compose.oneoff:False com.docker.compose.project:my com.docker.compose.project.config_files:/root/c.yaml com.docker.compose.project.working_dir:/root com.docker.compose.service:alpine com.docker.compose.version:2.17.3 com.docker.swarm.service.name:my-alpine-1 dcl.division:CorePlat dcl.space:dev dcl.user:admin]
        X_NODE_PLATFROM_ARCHITECTURE=x86_64
        / #
        / # hostname
        alpine-1
        / # exit
        $ dcl admin docker service ls
        ID             NAME          MODE         REPLICAS   IMAGE     PORTS
        f3e9yb8art4u   my-alpine-1   replicated   1/1        alpine
        $ dcl admin docker service ps my-alpine-1
        ID             NAME            IMAGE     NODE      DESIRED STATE   CURRENT STATE            ERROR     PORTS
        j98fv7oxms2r   my-alpine-1.1   alpine    swarm2    Running         Running 56 seconds ago
        $
        ```





