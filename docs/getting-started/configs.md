# :fontawesome-solid-gears: Configs and Secrets

`Configs` allow you to store application configuration information, while `Secrets` allow you to store application secrets and keys. While
these are standard features of `docker swarm`, DCL adds a dynamic feature that allows the contents of the `Config` and `Secret` to be
updated any number of times (`docker swarm` does not allow that) and the application can pickup the new changes instantly, without
any restart of the containers.

## How to use `Configs`

Here are few examples on how to use them, including `dynamic` ones. The examples are similar to the ones provided by [`docker`](https://docs.docker.com/engine/swarm/configs/) itself.

??? example "Standard usage of configs"
    === "CLI"
        ```console
        $ echo "This is a config" | docker config create my-config -
        $ docker service create --name c1 --config src=my-config,target=/run/configs/my-config -td alpine:latest
        $ docker exec -it c1 sh
        # cat /run/configs/my-config
        This is a config
        ```
    === "Compose"
        ```yaml title=./compose.yaml
        configs:
          my-config:
            content: |
              This is a config
        services:
          c1:
            image: alpine:latest
            configs:
            - src: my_config
              target: /run/configs/my-config
        ```

        ```console
        $ # Note: `docker stack` does not support configs with `content` attribute. So you have to create the config
          # manually via `docker config create` and use `external: true` here and remove `content` attribute.
        $ echo "This is a config" | docker config create my-config -
        $ docker stack deploy -c compose.yaml p1
        $ docker exec -it p1_c1 sh
        # cat /run/configs/my-config
        This is a config
        ```

??? example "Usage of dynamic configs"
    === "CLI"
        ```console
        $ echo "This is a config" | docker config create dynamic-my-config -
        $ docker service create --name c1 --config src=dynamic-my-config,target=/run/configs/dynamic-my-config -td alpine:latest
        $ docker exec -it c1 sh
        # cat /run/configs/dynamic-my-config
        This is a config
        $ echo "This is new config" | docker config create dynamic-my-config -
        $ docker exec -it c1 sh
        # cat /run/configs/dynamic-my-config
        This is new config
        ```
    === "Compose"
        ```yaml title=./compose.yaml
        configs:
          dynamic-my-config:
            content: |
              This is a config
        services:
          c1:
            image: alpine:latest
            configs:
            - src: dynamic-my_config
              target: /run/configs/dynamic-my-config
        ```

        ```console
        $ # Note: `docker stack` does not support configs with `content` attribute. So you have to create the config
          # manually via `docker config create` and use `external: true` here and remove `content` attribute.
        $ echo "This is a config" | docker config create my-config -
        $ docker stack deploy -c compose.yaml p1
        $ docker exec -it p1_c1 sh
        # cat /run/configs/dynamic-my-config
        This is a config
        $ echo "This is new config" | docker config create dynamic-my-config -
        $ docker exec -it p1_c1 sh
        # cat /run/configs/dynamic-my-config
        This is new config
        ```

## How to use `Secrets`

Secrets are similar to Configs, here are few examples on how to use them, including `dynamic` ones. The examples are similar to the ones provided by [`docker`](https://docs.docker.com/engine/swarm/configs/) itself.

??? example "Standard usage of secrets"
    === "CLI"
        ```console
        $ echo "This is a secret" | docker secret create my-secret -
        $ docker service create --name c1 --secret src=my-secret,target=/run/secrets/my-secret -td alpine:latest
        $ docker exec -it c1 sh
        # cat /run/secrets/my-secret
        This is a secret
        ```
    === "Compose"
        ```yaml title=./compose.yaml
        secrets:
          my-secret:
            content: |
              This is a secret
        services:
          c1:
            image: alpine:latest
            secrets:
            - src: my_secret
              target: /run/secrets/my-secret
        ```

        ```console
        $ # Note: `docker stack` does not support secrets with `content` attribute. So you have to create the secret
          # manually via `docker secret create` and use `external: true` here and remove `content` attribute.
        $ echo "This is a secret" | docker secret create my-secret -
        $ docker stack deploy -c compose.yaml p1
        $ docker exec -it p1_c1 sh
        # cat /run/secrets/my-secret
        This is a secret
        ```

??? example "Usage of dynamic secrets"
    === "CLI"
        ```console
        $ echo "This is a secret" | docker secret create dynamic-my-secret -
        $ docker service create --name c1 --secret src=dynamic-my-secret,target=/run/secrets/dynamic-my-secret -td alpine:latest
        $ docker exec -it c1 sh
        # cat /run/secrets/dynamic-my-secret
        This is a secret
        $ echo "This is new secret" | docker secret create dynamic-my-secret -
        $ docker exec -it c1 sh
        # cat /run/secrets/dynamic-my-secret
        This is new secret
        ```
    === "Compose"
        ```yaml title=./compose.yaml
        secrets:
          dynamic-my-secret:
            content: |
              This is a secret
        services:
          c1:
            image: alpine:latest
            secrets:
            - src: dynamic-my_secret
              target: /run/secrets/dynamic-my-secret
        ```

        ```console
        $ # Note: `docker stack` does not support secrets with `content` attribute. So you have to create the secret
          # manually via `docker secret create` and use `external: true` here and remove `content` attribute.
        $ echo "This is a secret" | docker secret create my-secret -
        $ docker stack deploy -c compose.yaml p1
        $ docker exec -it p1_c1 sh
        # cat /run/secrets/dynamic-my-secret
        This is a secret
        $ echo "This is new secret" | docker secret create dynamic-my-secret -
        $ docker exec -it p1_c1 sh
        # cat /run/secrets/dynamic-my-secret
        This is new secret
        ```
