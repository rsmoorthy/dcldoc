# :fontawesome-solid-gears: Configs and Secrets

Docker Swarm has support for [Configs](https://docs.docker.com/engine/swarm/configs/) and [Secrets](https://docs.docker.com/engine/swarm/secrets/),
while the same is not available for regular containers. However, `Configs` and `Secrets` suffer the following disadvantages:

* Once a `Config` or `Secret` is created, you can NOT update them.
* Any Service which relies on a `Config` or `Secret` has to be restarted to make use of changed configuration.

This is a huge drawback, for any serious application deployment setup. For example, Kubernetes does not have these challenges
with `configmaps` and `secrets`.

From the start, it was clear that DCL has to provide a meaningful and manageable solution for managing `Configs` and `Secrets`,
where updates to them can happen anytime and they can still be reflected to the application in real time.

## DCL approach

DCL's approach is simple and pragmatic. Use NFS for storing configs and secrets and mount it on the node appropriately. This is
not a great solution, if you think of a product like `docker`. But DCL is a product, that is deployed as a platform engineering
solution and hence this approach makes sense.

`Dynamic Configs` - How it works?

*  During `docker config create` API call, if the `config` name is prefixed with  `dynamic-`, then in
addition, to storing the contents with `docker swarm`, DCL also stores this in a separate NFS volume.
  - The size of the NFS volume is fixed to be twice of the contents of the config.
*  When a service is using a `config` with the name prefixed as `dynamic-`, then the service will be modified to
mount it from NFS (behind the scenes).
*  To update the contents of the `config`, the user is expected to run again `docker config create` (even though it exists already).
If the `config` name is prefixed with `dynamic-`, then the new contents are updated in the NFS volume and returns success.
Else an error is thrown that the `config` already exists.
*  When the contents of the `config` is updated, since the values are on the NFS share, the service sees those changes instantly.
*  Please note that the contents stored in `docker swarm` is ignored and not used, if the `config` name is prefixed with ``dynamic-`.

`Dynamic Secrets` - How it works?

* The process is similar to `config`, but the contents in the NFS share are encrypted at rest.
* When the service mounts, it will use a docker volume plugin by name `dcl-secrets`, instead of directly mounting the NFS share
  inside the container. The docker plugin `dcl-secrets` will decrypt the contents and mount it as a tmpfs volume inside a container.
  The tmpfs volume (ie. mounting on RAM) ensures that the secrets are never stored on disk in an unencrypted format.
* To update the `secret`, the same process of `docker secret create` is followed, where you ensure that the name of the secret is 
  prefixed with `dynamic-`. `dcl-secrets` will keep monitoring for any changes in the contents and automatically will update the
  contents within the container (in the tmpfs volume).

So, we have TWO mechanisms:

1.  The original one with `docker swarm`, where the `configs` and `secrets` are immutable, once created. For every change, you 
    end up creating new `configs` and `secrets` entries. And make the service restart to take notice of the change.
2.  The modified `dynamic` one, where if the name is prefixed with `dynamic-`, then DCL intercepts and reroutes the contents
    to be updated via NFS share. In this case, the changes are instantly reflected in the service and there is no need to
    recreate new `configs` or `secrets` entries.

Please refer to few examples [here](../getting-started/configs.md), the reference [here](../reference/configs.md) and the setup details
[here](../setup/configs.md)
