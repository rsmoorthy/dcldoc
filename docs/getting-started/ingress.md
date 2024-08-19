# DCL Ingress

The Docker Swarm networks, the internal overlay networks, are internal and not exposed to outside by default. DCL provides
Ingress setup (using the underlying `traefik`), which can be used to connect to services inside the cluster, from the outside.

Since all of the services are HTTP and TCP based, DCL Ingress provides a default HTTPS and TCP/TLS based reverse proxy as the
default ingress mechanism and expose them as `named services`, that can be accessed by the clients using DNS names via HTTPS or
TCP/TLS.

The Ingress will be using port 80/443 for HTTPS, where we will setup more than one Ingress hosts (for HA). HTTPS on the Ingress
hosts will be terminated at those endpoints (running `traefik` proxy), while the proxy will connect to services inside the
cluster to make the connection.

Similarly the Ingress will use the same port 443 for TCP/TLS for TCP connections (such as connecting to a database inside
the cluster, from outside).

The configuration for DCL Ingress is done via `dcl.ingress.` labels in the service specs. Example usage is shared below.

This page provides details on how an user could configure Ingress for their services. Almost all the examples here show
the syntax using docker compose/stack `yaml` file. The same examples via CLI will be more complex to use, while trying to
use the yaml syntax (or using JSON syntax) and hence left out.

Please refer to [Ingress Concepts](../concepts/ingress.md) and [Ingress Reference](../reference/ingress.md) for more details.


## HTTP Ingress Configuration

### Simple Example

This is the simplest example, where you just specify the DNS host name (accessible from outside the cluster). This assumes
that the service itself exposes the default port 80 using scheme http (and not https).

=== "docker compose"
   ```yaml
   services:
     web:
       image: nginx:latest
       labels:
         dcl.ingress.http.hostname: www.example.com
   ```

### Custom port / scheme

The next example builds on that, by specifying that service exposes itself on port 8443 via https scheme.

??? note "Example with custom service port and scheme"
    === "docker compose"
        ```yaml
        services:
          web:
            image: nginx:latest
            labels:
              dcl.ingress.http.port: 8443
              dcl.ingress.http.scheme: https
              dcl.ingress.http.hostname: www.example.com
        ```

### Multiple services for the same host with auto priority

The following example shows how you can access the same domain, where the access is redirected to different services
based on the path prefix used. Any access to www.example.com/api/ will route the request to `api-service`, while any
access to www.example.com/docs/ will route the request to `docs-servicce` and the rest of the requests will go to
`other-service` (the catch all).

??? note "Example showing multiple services with auto calculated priority"
    === "docker compose"
        ```yaml
        services:
          api-service:
            image: api-service
            labels:
              dcl.ingress.http.hostname: www.example.com
              dcl.ingress.http.paths:
              - /api/
          docs-service:
            image: nginx:latest
            labels:
              dcl.ingress.http.hostname: www.example.com
              dcl.ingress.http.paths:
              - /docs/
          other-service:
            image: nginx:latest
            labels:
              dcl.ingress.http.hostname: www.example.com
        ```
        !!! note "Here the priority is auto calculated, with highest priority to docs-service, then api-service and then to other-service. Request will evaluated in that order, so other-services will get lowest priority and serves as catch all service"

### Manual priority

While it is not required in most cases, you can set a priority of rule for the above example, to ensure that
the `other-service` is not getting a priority over others. As the default computed priority for the hostname `www.example.com`
will give a lower priority for `other-service`, as it does not have `ClientIP` or `headers` or `paths`

??? note "Example showing manual priority"
    === "docker compose"
        ```yaml
        services:
          api-service:
            image: api-service
            labels:
              dcl.ingress.http.hostname: www.example.com
              dcl.ingress.http.paths:
              - /api/
              dcl.ingress.http.priority: 10
          docs-service:
            image: nginx:latest
            labels:
              dcl.ingress.http.hostname: www.example.com
              dcl.ingress.http.paths:
              - /docs/
              dcl.ingress.http.priority: 10
          other-service:
            image: nginx:latest
            labels:
              dcl.ingress.http.hostname: www.example.com
              dcl.ingress.http.priority: 1
        ```

### Blue / Green deployment and Testing Green

The following example shows a blue green deployment with ability to test a new version of deployment
(green) before wide-basing to every one. 

??? note "Example routing requests based on ClientIP, Headers"
    === "ClientIP / Headers"
        ```yaml
        services:
          myservice-blue:
            image: myservice:v1.1
            labels:
              dcl.ingress.http.hostname: www.example.com
          myservice-green:
            image: myservice:v1.2
            labels:
              dcl.ingress.http.hostname: www.example.com
              dcl.ingress.http.ClientIP: 10.2.0.0/24
          myservice-green2:
            image: myservice:v1.2
            labels:
              dcl.ingress.http.hostname: www.example.com
              dcl.ingress.http.headers: |
                X-Deploy: v1.2
        ```
        !!! note "In this use case, you have 2 separate green services which is not a real use case. Here requests coming from ClientIP `10.2.0.0/24` will be routed to `myservice-green`. Any requests coming with HTTP headers `X-Deploy: v1.2` (and not from IP `10.2.0.0/24`) will be routed to `myservice-green2`. "
    === "ClientIP *and* Headers"
        ```yaml
        services:
          myservice-blue:
            image: myservice:v1.1
            labels:
              dcl.ingress.http.hostname: www.example.com
          myservice-green:
            image: myservice:v1.2
            labels:
              dcl.ingress.http.hostname: www.example.com
              dcl.ingress.http.ClientIP: 10.2.0.0/24
              dcl.ingress.http.headers: |
                X-Deploy: v1.2
        ```
        !!! note "This is more practical, which is based on ClientIP AND HTTP headers."

### Custom routing with AND / OR / NOT conditions

What if you want to route based on ClientIP **or** headers (or for that matter *paths*)? The default logic combination
of the rules are using AND condition. To use a combination of AND or OR conditions, use the `custom_rules` option

??? note "Example routing requests based on custom_rules"
    === "ClientIP or Headers"
        ```yaml
        services:
          myservice-blue:
            image: myservice:v1.1
            labels:
              dcl.ingress.http.hostname: www.example.com
          myservice-green:
            image: myservice:v1.2
            labels:
              dcl.ingress.http.hostname: www.example.com
              dcl.ingress.http.custom_rules: |
                - or:
                  - ClientIP: 10.2.0.0/24
                  - headers:
                      X-Deploy: Green
        ```
        !!! note "In this use case, you are exercising the OR option, so that either ClientIP(10.2.0.0/24) or headers(X-Deploy: Green) will route the request to the Green service.

### Blue/Green deployment and Zero downtime

The following example shows how to achieve blue/green deployment and zero downtime during upgrades, entirely using
ingress configuration using service specs.

??? note "Blue/Green deployment and Zero downtime using service specs"
    === "Initial state"
        ```yaml
        services:
          svc1:
            image: svc1:v1.1
            labels:
              dcl.ingress.http.hostname: www.example.com
        ```
    === "New version Up (blue/green)"
        ```yaml
        services:
          svc11:
            image: svc:v1.1
            labels:
              dcl.ingress.http.hostname: www.example.com
          svc12:
            image: svc:v1.2
            labels:
              dcl.ingress.http.hostname: www.example.com
              dcl.ingress.http.custom_rules: |
                - or:
                  - ClientIP: 10.2.0.0/24
                  - headers:
                      X-Deploy: Green
        ```
        !!! note
            Now you can test the new version either from that IP spec or if you use those client headers.
    === "Switch to new version"
        ```yaml
        services:
          svc11:
            image: svc:v1.1
            labels:
              dcl.ingress.http.hostname: www.example.com
              dcl.ingress.http.custom_rules: |
                - or:
                  - ClientIP: 10.2.0.0/24
                  - headers:
                      X-Deploy: Green
          svc12:
            image: svc:v1.2
            labels:
              dcl.ingress.http.hostname: www.example.com
        ```
        !!! note
            Now you have to update both the service definitions almost at the same time. Preferably update `svc12` first, so that all the requests will be routed to both (issue!) and then immediately update `svc11` with certain restrictions.

## HTTP Ingress using dcl/ingress-lb

DCL supports a custom service `dcl/ingress-lb` (where `dcl/ingress-lb` is the image name) provided by DCL. This custom
services supports the following two additional major functionalities:

* Ability to define ingress configuration for a given service independent of the service itself (similar to kubernetes `ingress` record)
* Supports a load balancer (that uses IPVS) to support more methods of load balancing than round robin. Including weighted
round robin.

Please note that for a given service, do not configure it via both `dcl/ingress-lb` method and configuring via the
service spec. The results are undefined.

### Simple Ingress/LB Configuration

Configuring a `dcl/ingress-lb` for a service is accomplished by:
```yaml
services:
  ingress-mysvc:
    image: dcl/ingress-lb:latest
    labels:
      http.hostname: www.example.com
      http.services: |
        mysvc:
          paths:
          - /api/
        authsvc:
          paths:
          - /auth/
```

### Ingress/LB with Weighted routing

You can also accomplish weighted round robin using `dcl/ingress-lb`. In this example, requests are routed using the weights 2 and 10 (ie. one out of 5 requests are routed to mysvc-v12, while mysvc-v11 gets the remaining). Please note that this is
service level load balancing. If each service has replicas, internally each service will have its own round-robin based
load distribution. Please refer to the example [here](../getting-started/ingress.md#xxx)
```yaml
services:
  ingress-mysvc:
    image: dcl/ingress-lb:latest
    labels:
      http.hostname: www.example.com
      http.services: |
        mysvc-v11:
          weight: 10
        mysvc-v12:
          weight: 2
```

### Easy Blue/Green deployment with Zero downtime

This is easy and elegant zero downtime solution, as the switch over is done in an atomic way.

??? note "Easy Blue/Green deployment and Zero downtime using ingress-lb"
    === "Initial state"
        ```yaml
        services:
          svc11:
            image: svc:v1.1
          ingress-svc:
            image: dcl/ingress-lb:latest
            labels:
              http.hostname: www.example.com
              http.services: |
                svc11:
                  paths:
                  - /
        ```
    === "New version Up (blue/green)"
        ```yaml
        services:
          svc11:
            image: svc:v1.1
          svc12:
            image: svc:v1.2
          ingress-svc:
            image: dcl/ingress-lb:latest
            labels:
              http.hostname: www.example.com
              http.services: |
                svc11:
                  paths:
                  - /
                svc12:
                  custom_rules: |
                    - or:
                      - ClientIP: 10.2.0.0/24
                      - headers:
                          X-Deploy: Green
        ```
        !!! note
            Now you can test the new version either from that IP spec or if you use those client headers.
    === "Switch to new version"
        ```yaml
        services:
          svc11:
            image: svc:v1.1
          svc12:
            image: svc:v1.2
          ingress-svc:
            image: dcl/ingress-lb:latest
            labels:
              http.hostname: www.example.com
              http.services: |
                svc11:
                  custom_rules: |
                    - or:
                      - ClientIP: 10.2.0.0/24
                      - headers:
                          X-Deploy: Green
                svc12:
                  paths:
                  - /
        ```
        !!! note
            The advantage is that you can update the rule **once** only (in `ingress-svc` record) and both values are updated in an atomic way.
    === "Remove old version"
        ```yaml
        services:
          svc12:
            image: svc:v1.2
          ingress-svc:
            image: dcl/ingress-lb:latest
            labels:
              http.hostname: www.example.com
              http.services: |
                svc12:
                  paths:
                  - /
        ```
        !!! note
            You can preferably update `ingress-svc` record first and then remove the service `svc11`

## Configuring TCP Ingress

Configuring TCP ingress is pretty simple. Just specify the two properties `dcl.ingress.tcp.port` and `dcl.ingress.tcp.hostname`
in the service spec, and you are done. 

```yaml
services:
  mydb:
    image: postgres:14
    labels:
      dcl.ingress.tcp.port: 5432
      dcl.ingress.tcp.hostname: mydb.example.com
  mydb2:
    image: postgres:16
    labels:
      dcl.ingress.tcp.port: 5432
      dcl.ingress.tcp.hostname: mydb2.example.com
```

After this, accessing the database from externally can be achieved by connecting via TLS on mydb.example.com on port 443.
Repeat, the external client should connect on port 443 only, but the DNS names will keep changing for each service.

The proxy will automatically tunnel the requests to the port 5432 of the respective service.

As discussed earlier, if the client cannot directly connect via TLS, then a local proxy is required at the client side.
DCL provides a `dcl_tcpproxy` for this purpose.

### Configuring `dcl_tcpproxy`

The `dcl_tcpproxy` typically runs on the developer's laptop or it could be anywhere. It is assumed that the user
who runs `dcl_tcpproxy` may not have root privileges and will use arbitrary ports to listen to.

The `dcl_tcpproxy` reads a configuration file `dcl_tcpproxy.yaml` on startup and when the contents of the file is changed.

The configuration file `dcl_tcpproxy.yaml` looks like:
```yaml
ports:
- 11000: mydb.example.com
- 11001: tcp://mydb2.example.com:443/
```

Each item in the `ports` array contains an object, with a single key value equal to the `local port number` and the value
being the service name. The service name can be simple DNS name, in which case, it is taken as `tcp://fqdn:443`. Or it
can be specified in the format as `tcp://fqdn:<port>`

Applications can connect to the local port number for each service that you are interested to connect to.
