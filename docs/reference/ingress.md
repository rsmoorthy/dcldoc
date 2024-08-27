# DCL Ingress Reference

This page provides the reference for configuring DCL Ingress. Please refer to [Ingress Getting Started](../getting-started/ingress.md), [Ingress Concepts](../concepts/ingress.md) and [Setup details](../setup/ingress.md) for more details.

## Configuration for HTTP Ingress

For HTTP Ingress, there are two ways of configurations possible. One is to specify the configuration in each of the
services / containers. The other is to specify the configuration via a special DCL Ingress Load Balancer. The second
method is provided, so that the deployments of services can be gracefully deployed and support an easier method of deployments
like canary and blue/green.

### Service Specs

The service specs should contain labels with the prefix as `dcl.ingress.` (which DCL will translate to the installed proxy
`traefik` or `caddy`). These labels should be mentioned on a docker swarm service or a docker container.

Supported labels are:

#### **`dcl.ingress.http.port`**

: `<portnum>`

: {++optional++} This is the port number where the service is listening on. This option specifies how the
Ingress talks to the service itself. If none provided, the default is taken as port `80`.

#### **`dcl.ingress.http.scheme`**

: `http|https`

: {++optional++} This is the scheme (http / https) where the service is listening on. Default: `http`. This option specifies
how the Ingress talk to the service itself.

??? note "`port` and `scheme` are for describing services"
    The above two options `port` and `scheme` are specific to services side. While the rest of the options`hostname`, `paths`, `ClientIP`, `headers` and `custom_rules` are about based on the requests themselves

#### **`dcl.ingress.http.hostname`**

: `<hostname | [array of hostnames]`

: {++required++} This is the hostname with which it will be accessed from outside. The DNS should be configured, please see [DNS Config](../setup/ingress.md#dns-configuration) for details. If none provided, the default hostname will be `<service>.<network>.<cluster-name>`.

: Either you can provide a single hostname (FQDN) or an array of hostnames (FQDN). If array is provided, the service can be accessed
from outside, using all the hostnames provided.

#### **`dcl.ingress.http.paths`**

: `[ only for these paths ]`

: {++optional++} If this `paths` is provided, then the service will be reached only for these given paths. This can be regex. For
all paths provided, any URL matching these paths as prefix will be allowed.

: Example: `[ "/api/", "/docs/", "/query/(\S+)/(search|find) ]` will allow only URLs with these prefixes be sent to this service.

: Default: If none provided, allow all URLs to access this service.

#### **`dcl.ingress.http.ClientIP`**

: `[!] <hostIP/mask>`

: {++optional++} This allows to specify whether requests coming from a particular IP range (or other than a IP range, when `!` is specified as a prefix) should be routed to this service or not.

: Default: If none provided, then request from all IPs will be routed to this service.

: Example: if `10.2.0.0/24` is used, then only requests from this IP range can
use this service. If `!10.2.0.0/24` is used, then all requests from other IPs
alone (other than this range) can use this service.

#### **`dcl.ingress.http.headers`**

: `<JSON Object of key-value pairs>`

: {++optional++} This allows to route requests based on the presence of specific HTTP header value.

: Default: If none provided, then the request is routed with any HTTP header value will be routed to this service.

: Example: This will route only requests with the HTTP header `X-Deploy: Green` to this service.
```yaml
labels:
  dcl.ingress.http.headers: |
    X-Deploy: Green
```

#### **`dcl.ingress.http.priority`**

: `<number>`

: {++optional++} This allows to specify priority among multiple services matching the same `hostname`. This will ensure
that you can route path prefixes get priority over services that handle no path prefixes.

: A higher number indicates a higher priority. So a rule with a priority of 100 will be considered first when compared
with a rule with a priority of 10.

: Default: If none provided, the priority is computed automatically based on the presence of `ClientIP`, `header`, `paths`
in the same order. Presence of `ClientIP` adds a priority of `1000`, while presence of `header` adds a priority of `100`
and presence of `paths` adds a priority of `10`. 

??? note "Default combination is AND condition"
    In the above set of configuration, all the criteria (`hostname`, `ClientIP`, `headers`, `paths`) are combined using an AND condition. If you want a combination of AND / OR / NOT conditions, use the `custom_rules` below.

#### **`dcl.ingress.http.custom_rules`**

: `[ rules (multiple rules are specified in the YAML format, but as a string) ]`

: {++optional++} This is an advanced option, where you can specify a combination of AND / OR / NOT conditions, with
as much nesting as you would like. You can use this, if the other configuration options are insufficient for you. If this is specified, any of the following label prefixes will be combined using AND condition. <br>
*  `dcl.ingress.http.hostname` <br>
*  `dcl.ingress.http.paths` <br>
*  `dcl.ingress.http.headers` <br>
*  `dcl.ingress.http.ClientIP` <br>
You may typically use this, if you want to combine the above options in a different logic. You can also use this if
you want to specify *multiple rules* in one go.

: Syntax:
    === "`custom_rules` requires an array"
        ```yaml
        labels:
          dcl.ingress.http.custom_rules: |
            - <rule1>
            - <rule2>
        ```
        !!! note "The above indicates TWO rules"
            In most cases, you may not need multiple rules. But if you want, this is the way to specify
    === "`or` condition"
        ```yaml
        labels:
          dcl.ingress.http.custom_rules: |
            - or:  // requires an array with at least 2 items
              - key1: value  // where keyn is one of `paths`, `headers`, `ClientIP` or another `or`
              - key2: value 
        ```
        !!! note "OR is applied inside!!"
            Please note that even though `or` is specified outside, but applies between key1 and key2. ie (key1 || key2)
    === "implicit *and* condition"
        ```yaml
        labels:
          dcl.ingress.http.custom_rules: |
            - key1: value // where keyn is one of `paths`, `headers`, `ClientIP` or another `or`
              key2: value
              - or:
                - key3: value
                  key4: value
                - key5: value
                  key6: value
        ```
        !!! note "Implicit AND conditions"
            Here both key1 and key2 are combined using AND condition. And key3 and key4 are combined using AND, so similarly key5 and key6. So it translates to (key1 && key2) && ((key3 && key4) || (key5 && key6))
    === "`not` condition"
        ```yaml
        labels:
          dcl.ingress.http.custom_rules: |
            - key1: value // where keyn is one of `paths`, `headers`, `ClientIP` or another `or`
              not:
                key2: value
            - key3: value
              not:
                key4: value
                key5: value
            - not:
              - or:
                - key6: value
                - key7: value
        ```
        !!! note "`not` requires an object"
            `not` requires an object containing `paths`, `headers`, `ClientIP` or `or`. Here rule 1 evaluates as key1=value && key2!=value (same as !(key2=value) or simply !key2 for easier expression).  And rule2 evaluates as key3 && !(key4 && key5). And rule3 evaluates as !(key6 || key7).

: Examples:
    === "Simple OR condition"
        ```yaml
        labels:
          dcl.ingress.http.hostname: www.example.com
          dcl.ingress.http.custom_rules: |
            - or:
              - headers:
                  X-Deploy: Green
              - ClientIP: 10.2.0.0/24
        ```
        !!! note "A single rule with Host(www.example.com) && (Headers(X-Deploy: Green) || ClientIP(10.2.0.0/24))"
    === "A Combo of AND / OR conditions"
        ```yaml
        labels:
          dcl.ingress.http.hostname: www.example.com
          dcl.ingress.http.custom_rules: |
            - or:
              - or:
                - headers:
                    X-Deploy: Green
                  ClientIP: 10.2.0.0/24
                - paths: /api/v2
                  ClientIP: 10.3.0.0/24
              - headers:
                  Content-type: application/json
        ```
        !!! note "Not sure if this rule makes practical sense!!!"
            But the rule is <br>
            Host(www.example.com) && <br>
              (<br>
              &nbsp;(<br>
              &nbsp;&nbsp;(Headers(X-Deploy: Green) && ClientIP: 10.2.0.0/24) || <br>
              &nbsp;&nbsp;(Paths(/api/v2) && ClientIP: 10.3.0.0/24)<br>
              &nbsp;) ||<br>
              &nbsp;Headers(Content-type: application/json)<br>
              )


creates two rules with the first rule having highest priority. These rules allow requests from a certain IP range to this service or those with a specific header request and not from that IP range.

## Configuration for HTTP Ingress using Ingress-LB

DCL supports a custom service `dcl/ingress-lb` (where `dcl/ingress-lb` is the image name) provided by DCL. This custom
services supports the following two additional major functionalities:

* Ability to define ingress configuration for a given service independent of the service itself (similar to kubernetes `ingress` record)
* Supports a load balancer (that uses IPVS) to support more methods of load balancing than round robin. Including weighted
round robin.

#### **`http.hostname`**

: `<hostname>`

: {++required++} This is the hostname with which it will be accessed from outside. The DNS should be configured, please see [DNS Config](../setup/ingress.md#dns-configuration) for details. If none provided, the default hostname will be `<service>.<network>.<cluster-name>`.

: Unlike [`dcl.ingress.http.hostname`](#dclingresshttphostname), you need to provide only a single hostname (FQDN). If there are multiple hostnames (or aliases) you would like to configure, you can specify more than one `ingress-lb` service. Otherwise, this is similar to [`dcl.ingress.http.hostname`](#dclingresshttphostname)

#### **`http.services`**

: `<services as object>`

: {++required++} One or more services are specified. If none are provided, then this entire `ingress-lb` configuration is
ignored. You specify the service names (exactly as defined in the service specs), and the value should be an object
containing the following options:<br>
* `paths` - Same as [`dcl.ingress.http.paths`](#dclingresshttppaths) <br>
* `ClientIP` - Same as [`dcl.ingress.http.ClientIP`](#dclingresshttpclientip) <br>
* `headers` - Same as [`dcl.ingress.http.headers`](#dclingresshttpheaders) <br>
* `priority` - Same as [`dcl.ingress.http.priority`](#dclingresshttppriority) <br>
* `custom_rules` - Same as [`dcl.ingress.http.custom_rules`](#dclingresshttpcustom_rules) <br>
* `weight` - Provides a weight for each service. If none specified for a service, it is taken an `1`

: Priority of services is automatically computed, based on the order of services 

: A service can provide zero or more of the above options, and they act exactly as the options work as per their [service specs config](#service-specs)

: Syntax:
    === "syntax definition"
        ```yaml
        services:
          ingress-svc:
            image: dcl/ingress-lb
            labels:
              http.hostname: <a single FQDN string>
              http.services: // an object
                <service name>:
                  <options>:   // options are `paths`, `ClientIP`, `headers`, `priority`, `custom_rules`, `weight`
                <service2 name>:
                  <options>:   // options are `paths`, `ClientIP`, `headers`, `priority`, `custom_rules`, `weight`
        ```
        !!! note "The above indicates TWO services are handling the same endpoint"
            This indicates a complex setup where an endpoint is served by multiple services, usually by different path prefixes

: Examples:
    === "Single service"
        ```yaml
        services:
          ingress-svc:
            image: dcl/ingress-lb
            labels:
              http.hostname: www.example.com
              http.services:
                svc1: {}
        ```
        !!! note "A single service for Host(www.example.com)"
    === "Weight round-robin with two services"
        ```yaml
        services:
          ingress-svc:
            image: dcl/ingress-lb
            labels:
              http.hostname: www.example.com
              http.services:
                svc1:
                  weight: 3
                svc2:
                  weight: 1
        ```
        !!! note "Sets weighted round robin, where the requests are distributed in 3:4 and 1:4 ratios respectively"
    === "Two services routed based on paths"
        ```yaml
        services:
          ingress-svc:
            image: dcl/ingress-lb
            labels:
              http.hostname: www.example.com
              http.services:
                svc1:
                  paths:
                  - /api/
                  priority: 1
                svc2:
                  paths:
                  - /docs/
                  priority: 2
        ```
        !!! note "Routing based on different paths"
            Here priority is set higher for `svc2`, which means that if there is any other path, other than
            `/docs` and `/api`, it will be caught by `svc1`

## Configuration for TCP Ingress

For TCP Ingress, DCL supports only one way of configuration, which is to mention the configuration under each
each services / containers.

Supported labels are:

#### **`dcl.ingress.tcp.port`**

: `<portnum>`

: {++required++} This is the port number that is being exposed by the service.

#### **`dcl.ingress.tcp.hostname`**

: `<hostname aka FQDN>`

: {++required++} This is the unique hostname that is to be referred by the external client, that needs to be talk to the
service. External clients will connect to this hostname on port 443, while the proxy service will route the request
to the service on the port referred above.

