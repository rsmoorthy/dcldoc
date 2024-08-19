# Ingress Setup

This section is meant as a guide for administrators to setup Ingress and related configurations in DCL and outside of
DCL.

DCL actually uses `traefik` (for now) as the ingress proxy server. However, DCL wraps all the complexities (configuring
`traefik` can be hard job) by simplifying the configurations with an opinionated view (and thus not exposing all
possible features of `traefik` to you).

The following steps are needed to setup DCL Ingress in your cluster.

## Identify Ingress Servers

You need to identify one or more Ingress servers, that will be endpoints for all the external requests either for HTTP
or TCP. While one server is sufficient, adding more than 1 server will help in High Availability.

These Ingress servers should be part of the DCL Cluster (aka Docker Swarm Cluster), and not part of a worker node, that could
be evicted at any time.

It is an acceptable choice to setup the Docker Swarm Manager nodes as the nodes for Ingress servers. You will however
be responsible to chose the node types based on the capacity and the functionality.

DCL Ingress service can just consume < 1GB of RAM or > 12GB of RAM, which is dependent on your load. You could start with
2GB RAM for DCL Ingress service and increase/decrease based on your usage.

These Ingress servers will be listening on ports 80/443 usually, but whatever you want as the endpoints of your setup. Please
make sure that there are no other applications running on those ports.

Right now, each Ingress server will behave identically and listen/route traffic for all internal services. In the future,
we could consider multiple ingress servers handling different external endpoints.

## DNS Configuration

There will be many services that need external access, each having its own DNS name. There are two ways we can handle
this: 
* DCL could take each `hostname` (a FQDN, belonging to a domain) and create, update, delete the DNS records (like AWS Route53). This would happens at two stages: a) while creation/modification b) while deletion.
* In the simplest use case, You can assign one or more `sub-domains` entirely to the DCL cluster. And pre-assign in the
DNS via `wild card entry` for the `sub-domain`.

DCL suggests you to follow the second method.

### Identify domain name for cluster

You need to identify a domain name for the entire cluster. If your regular domain is `foo.bar`, then you could decide
on a domain name like `cluster.foo.bar` or `dcl.foo.bar` or `cl.foo.bar`. It's your choice. Let us call this `cluster.domain`
in the following text.

In addition, you may have further "network spaces" within the cluster, like `dev`, `stage`, `prod`. And you could decide
(you don't need to necessarily do so) map the internal network spaces to the Ingress cluster domain too. If you decide so,
then your domain names can be `dev.cluster.domain`, `stage.cluster.domain` and so on.

### Create wildcard entry in DNS

For your `cluster.domain`, please create wildcard A entry/entries in your DNS, pointing to the ingress server(s).

Assuming your `cluster.domain` is `cl.foo.bar`, the wild card record would look like this:

*.cl.foo.bar   IN  A     <IP of ingress server1>
*.cl.foo.bar   IN  A     <IP of ingress server2>

Please note that depending on your DNS server, you may not have to specify your base domain ( `foo.bar`  here). The
essential thing is to specify `*.cl`

??? note "Alternatively, you could specify multiple DNS wild card entries, based on your network spaces."

    *.dev.cl.foo.bar  IN  A   <IP of ingress server1>
    *.dev.cl.foo.bar  IN  A   <IP of ingress server2>

    *.stage.cl.foo.bar  IN  A   <IP of ingress server1>
    *.stage.cl.foo.bar  IN  A   <IP of ingress server2>

    This has no added benefits as of now, other than the fact, that the hostnames (in dcl.ingress record) will be restricted to the additional network space (`dev`, `stage`). In the future, this division could be helpful, when DCL supports partitioning
    the DCL Ingress servers, so you may have separate ingress servers for `prod`, for ex, with HA.


## Install DCL Ingress service

First setup the config file, certificates

### Config file

!!! warning "This is very likely to change"
``` { yaml title="./dcl-ingress-config.yaml" }
endpoints:
  web:
    address: ":80"
    requestTimeout: 120
    idleTimeout: 0
    keepAliveMaxTime: 600
  secure:
    address: ":443"
    requestTimeout: 120
    idleTimeout: 0
    keepAliveMaxTime: 600
    cacerts: <path to file or certificate as text>
    cert: <path to file or certificate as text>
    key: <path to file or certificate as text>
```

### Start DCL Ingress

!!! warning "This is very likely to change"

As dictated by `traefik`, any change in the configuration file requires a restart of the ingress service.

```yaml
configs:
  dcl-ingress-config:
    file: ./dcl-ingress-config.yaml
services:
  dcl-ingress:
    image: dcl/ingress:latest
    configs:
    - source: dcl-ingress-config
      target: /etc/dcl/ingress-config.yaml
    deploy:
      placement:
        constraints:
          role: manager
      restart_policy: any
```

!!! note "Please note that you need to create your own placement constraints, as per your needs"
