# :fontawesome-solid-gears: Configs and Secrets

There is no DCL specific references for `Configs` and `Secrets`. The `docker config` and `docker secret` commands works the same way as the docker.

Except for the fact, that if the `Config` name or `Secret` name is prefixed with `dynamic-`, then the `docker config create` or
the `docker secret create` can be called any number of times for the same name, which will actually do the update. There is no
change in behaviour if the name is NOT prefixed with `dynamic-`.

