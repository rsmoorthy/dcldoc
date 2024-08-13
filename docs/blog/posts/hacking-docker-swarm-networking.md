---
date: 2024-05-20
categories:
  - docker
  - swarm
  - networking
tags:
  - networking
  - ingress
  - overlay
authors:
  - rsm
---

# Hacking Docker Swarm Networking

There was a deep interest in understanding Docker Swarm Networking. How it sets up iptables rules,
ipvs settings, ingress settings, overylay networking. This is a deep dive of the internals of the
Swarm networking.

The idea is to understand Swarm networking deeply so that we have a chance to hack and modify and
enhance the setup in the future.

So, as of now, nothing is promised, but a dump of various information that was collated.

<!-- more -->

## Service with no ingress and no specific network


```
host            br: docker0 (172.17)          -------------------------------------------------
                                                         ^
                br: docker_gwbridge (172.18)  -----------|-------------------------------------
                                               ^         |
                                               |         |
                                               |         |
ingress_sbox    veth:  (172.18.0.2)      -------         |
                veth:  (10.0.0.3)        -----------     |
                                                   |     |
                                                   |     |
                                                   v     |
1-abcdefghij    br: (10.0)                    -----------|-------------------------------------
                                                         |
container1      veth: (172.17.0.2)       -----------------
```


## Service with no ingress and overlay network. Service is vip. replica is 1


```
host            br: docker0 (172.17)          -------------------------------------------------

                br: docker_gwbridge (172.18)  -------------------------------------------------
                                               ^         ^
                                               |         |
                                               |         |
ingress_sbox    veth:  (172.18.0.2)      -------         |         DNAT for DNS
                veth:  (10.0.0.3)        -----------     |
                                                   |     |
                                                   |     |
                                                   v     |
1-abcdefghij    br: (10.0)                    -----------|-------------------------------------
                                                         |
1-chhv2g5nn1    br: (192.168.200)             -----------|-------------------------------------
                                                  ^      |   ^
                                                  |      |   |
lb_chhv2g5nn    veth: (192.168.200.140)   ---------      |   |     DNAT for dns
                      (192.168.200.138)                  |   |     SNAT ipvs to 200.140
                                                         |   |
container1      veth: (172.18.0.3)       -----------------   |     DNAT for DNS
                veth: (192.168.200.139)  ---------------------
```


## Service with no ingress and overlay network. Service is vip. replica is 2


```
host            br: docker0 (172.17)          -------------------------------------------------

                br: docker_gwbridge (172.18)  -------------------------------------------------
                                               ^         ^ ^
                                               |         | |
                                               |         | |
ingress_sbox    veth:  (172.18.0.2)      -------         | |       DNAT for DNS
                veth:  (10.0.0.3)        -----------     | |
                                                   |     | |
                                                   |     | |
                                                   v     | |
1-abcdefghij    br: (10.0)                    -----------|-|-----------------------------------
                                                         | |
1-chhv2g5nn1    br: (192.168.200)             -----------|-|-----------------------------------
                                                  ^      | | ^ ^
                                                  |      | | | |
lb_chhv2g5nn    veth: (192.168.200.144)   ---------      | | | |   DNAT for dns
                      (192.168.200.141)                  | | | |   ipvs 141 -> 142, 143
                                                         | | | |
replica1        veth: (172.18.0.3)       ----------------- | | |   DNAT for DNS
                veth: (192.168.200.143)  ------------------|-- |
                                                           |   |
replica2        veth: (172.18.0.4)       ------------------    |   DNAT for DNS
                veth: (192.168.200.142)  -----------------------
```

## Service with no ingress and overlay network. Service is vip. Two containers


```
host            br: docker0 (172.17)          -------------------------------------------------

                br: docker_gwbridge (172.18)  -------------------------------------------------
                                               ^         ^ ^
                                               |         | |
                                               |         | |
ingress_sbox    veth:  (172.18.0.2)      -------         | |       DNAT for DNS
                veth:  (10.0.0.3)        -----------     | |
                                                   |     | |
                                                   |     | |
                                                   v     | |
1-abcdefghij    br: (10.0)                    -----------|-|-----------------------------------
                                                         | |
1-chhv2g5nn1    br: (192.168.200)             -----------|-|-----------------------------------
                                                  ^      | | ^ ^
                                                  |      | | | |
lb_chhv2g5nn    veth: (192.168.200.147)   ---------      | | | |   DNAT for dns
                      (192.168.200.150)                  | | | |   ipvs 150 -> 151
                      (192.168.200.152)                  | | | |   ipvs 152 -> 153
                                                         | | | |
container1      veth: (172.18.0.3)       ----------------- | | |   DNAT for DNS
                veth: (192.168.200.151)  ------------------|-- |
                                                           |   |
container2      veth: (172.18.0.4)       ------------------    |   DNAT for DNS
                veth: (192.168.200.153)  -----------------------
```

## Service with no ingress and overlay network. Service is dnsrr. Multiple containers


```
host            br: docker0 (172.17)          -------------------------------------------------

                br: docker_gwbridge (172.18)  -------------------------------------------------
                                               ^         ^ ^
                                               |         | |
                                               |         | |
ingress_sbox    veth:  (172.18.0.2)      -------         | |       DNAT for DNS
                veth:  (10.0.0.7)        -----------     | |
                                                   |     | |
                                                   |     | |
                                                   v     | |
1-abcdefghij    br: (10.0)                    -----------|-|-----------------------------------
                                                         | |
1-chhv2g5nn1    br: (192.168.200)             -----------|-|-----------------------------------
                                                  ^      | | ^ ^
                                                  |      | | | |
lb_chhv2g5nn    veth: (192.168.200.10)    ---------      | | | |   DNAT for dns
                                                         | | | |   no ipvs
                                                         | | | |
container1      veth: (172.18.0.3)       ----------------- | | |   DNAT for DNS
                veth: (192.168.200.9)    ------------------|-- |
                                                           |   |
container2      veth: (172.18.0.4)       ------------------    |   DNAT for DNS
                veth: (192.168.200.11)   -----------------------

container3      veth: (172.18.0.5)       ------------------    |   DNAT for DNS
                veth: (192.168.200.12)   -----------------------
```

## Service with ingress and overlay network. Ingress service is vip (80:80/ingress). Regular service in dnsrr


```
host            br: docker0 (172.17)          -------------------------------------------------

                br: docker_gwbridge (172.18)  -------------------------------------------------
                                               ^         ^ ^
                                               |         | |
                                               |         | |
ingress_sbox    veth:  (172.18.0.2)      -------         | |       DNAT for DNS
                veth:  (10.0.0.7)        -----------     | |       ipvs SNAT to: 10.0.0.7
                       (10.0.0.10)                 |     | |
                                                   |     | |
                                                   v     | |
1-abcdefghij    br: (10.0)                    -----------|-|-----------------------------------
                                                     ^   | |
1-chhv2g5nn1    br: (192.168.200)             -------|---|-|-----------------------------------
                                                  ^  |   | | ^ ^
                                                  |  |   | | | |
lb_chhv2g5nn    veth: (192.168.200.20)    ---------  |   | | | |   DNAT for dns
                      (192.168.200.18)               |   | | | |   ipvs SNAT to: 192.168.200.20
                                                     |   | | | |
ingress1        veth: (172.18.0.3)       ------------|---- | | |   DNAT for DNS
                veth: (192.168.200.9)    ------------|-----|-- |
                veth: (10.0.0.11)        -------------     |   |   REDIRECT to: 10.0.0.11 port 80
                                                           |   |
container1      veth: (172.18.0.4)       ------------------    |   DNAT for DNS
                veth: (192.168.200.21)   -----------------------
```

### Tracing how ingress mesh configured

Tracing how the ingress mesh is configured. On all the hosts.

1. On the host NS, check netstat on port 80. This is not understood properly, as I don't understand
   why is dockerd listening on port 80
   _Note: (as can be seen in the next section, this listening on the port is
   not required. Because there is a redirection happening based on iptables and ipvs rules, it does not
   even hit dockerd for port 80. Perhaps, it is needed to prevent another service from listening on
   the same port)_
```console
$ netstat -tunlap | grep ":80"
tcp        0      0 :::80                   :::*                    LISTEN      28/dockerd
```

2. On the host NS, check the iptables. This shows the port 80 (on the host) is redirected to (DNAT) 172.18.0.2 (via bridge `docker_gwbridge`,
and to `ingress_sbox` NS )
```iptables
*nat
...
-A PREROUTING -m addrtype --dst-type LOCAL -j DOCKER-INGRESS
-A OUTPUT -m addrtype --dst-type LOCAL -j DOCKER-INGRESS
-A DOCKER-INGRESS -p tcp -m tcp --dport 80 -j DNAT --to-destination 172.18.0.2:80
...
```

3. On `ingress_sbox` NS, we have iptables that sets the mark for dpt 80, and also for dest 10.0.0.10. It also sets the SNAT IP
```iptables
*mangle
-A PREROUTING -p tcp -m tcp --dport 80 -j MARK --set-xmark 0x108/0xffffffff
-A INPUT -d 10.0.0.10/32 -j MARK --set-xmark 0x108/0xffffffff
*nat
-A POSTROUTING -d 10.0.0.0/24 -m ipvs --ipvs -j SNAT --to-source 10.0.0.7
```

4. On `ingress_sbox` NS, further checking ipvsadm shows the redirection.
```console
$ ip netns exec ingress_sbox ipvsadm --save
-A -f 264 -s rr
-a -f 264 -r 10.0.0.11:0 -m -w 1
```

### Simulating ingress mesh for fun

1. RUN these iptables rules in `ingress_sbox` NS
```console
$ ip netns exec ingress_sbox iptables -t nat -I DOCKER-INGRESS -p tcp -m tcp --dport 8000 -j DNAT --to-destination 172.18.0.2:80
$ ip netns exec ingress_sbox iptables -t mangle -A PREROUTING -p tcp -m tcp --dport 80 -j MARK --set-xmark 0x101/0xffffffff
$ ip netns exec ingress_sbox iptables -t mangle -A INPUT -d 10.0.0.10/32 -j MARK --set-xmark 0x101/0xffffffff
```

2. Run these ipvs commands.
```console
$ ip netns exec ingress_sbox ipvsadm -A -f 257 -s rr
$ ip netns exec ingress_sbox ipvsadm -a -f 257 -r 10.0.0.11:0 -m -w 1
```

3. That's it. Now running `curl hostip:8000` reaches the nginx container running and gets you the response!!


## Service with no ingress and overlay network. Service has replicas:3 and VIP


```
host            br: docker0 (172.17)          -------------------------------------------------

                br: docker_gwbridge (172.18)  -------------------------------------------------
                                               ^         ^ ^
                                               |         | |
                                               |         | |
ingress_sbox    veth:  (172.18.0.2)      -------         | |       DNAT for DNS
                veth:  (10.0.0.2)        -----------     | |       ipvs SNAT to: 10.0.0.7
                                                   |     | |
                                                   |     | |
                                                   v     | |
1-abcdefghij    br: (10.0)                    -----------|-|-----------------------------------
                                                         | |
1-chhv2g5nn1    br: (192.168.200)             -----------|-|-----------------------------------
                                                  ^      | | ^ ^
                                                  |      | | | |
lb_chhv2g5nn    veth: (192.168.200.38)    ---------      | | | |   DNAT for dns
                      (192.168.200.34)                   | | | |   ipvs SNAT to: 192.168.200.20
                                                         | | | |
replica1        veth: (172.18.0.4)       ----------------- | | |   DNAT for DNS
                veth: (192.168.200.37)   ------------------|-- |
                                                           |   |
replica2        veth: (172.18.0.3)       ------------------    |   DNAT for DNS
                veth: (192.168.200.35)   -----------------------

replica3        on another host
```

### Tracing how replicas and vip is setup

Tracing how the replicas is setup and VIP is setup

1. Get the VIP of the service
```console
$ docker service inspect alp2 | grep -i Addr
                    "Addr": "192.168.200.34/24"
```

2. On host1, in `lb_chhv2g5nn` NS, we have iptables that sets the mark for 192.168.200.34
```iptables
*mangle
-A INPUT -d 192.168.200.34/32 -j MARK --set-xmark 0x10c/0xffffffff
*nat
-A POSTROUTING -d 192.168.200.0/24 -m ipvs --ipvs -j SNAT --to-source 192.168.200.38
```

3. On host1, in `lb_chhv2g5nn` NS, further checking ipvsadm shows the redirection.
```console
$ ip netns exec lb_chhv2g5nn ipvsadm --save
-A -f 268 -s rr
-a -f 268 -r 192.168.200.35:0 -m -w 1
-a -f 268 -r 192.168.200.36:0 -m -w 1
-a -f 268 -r 192.168.200.37:0 -m -w 1
```

4. On host2, in its own `lb_xxxxxx` NS, we have iptables that sets the mark for 192.168.200.34
```iptables
*mangle
-A INPUT -d 192.168.200.34/32 -j MARK --set-xmark 0x10d/0xffffffff
*nat
-A POSTROUTING -d 192.168.200.0/24 -m ipvs --ipvs -j SNAT --to-source 192.168.200.39 # another IP on `lb_xxxxxx`
```

5. On host2, in its own `lb_xxxxxxx` NS, further checking ipvsadm shows the SAME redirection.
```console
$ ip netns exec lb_xxxxxx ipvsadm --save
-A -f 269 -s rr
-a -f 269 -r 192.168.200.35:0 -m -w 1
-a -f 269 -r 192.168.200.36:0 -m -w 1
-a -f 269 -r 192.168.200.37:0 -m -w 1
```

## Service with ingress(mode=host) and overlay network. Replicas=2. Ingress service is vip (8080:80/host)


```
host            br: docker0 (172.17)          -------------------------------------------------
                                                                   DNAT 8080 -> 172.18.0.3:80

                br: docker_gwbridge (172.18)  -------------------------------------------------
                                               ^         ^ ^
                                               |         | |
                                               |         | |
ingress_sbox    veth:  (172.18.0.2)      -------         | |       DNAT for DNS
                veth:  (10.0.0.2)        -----------     | |       ipvs SNAT to: 10.0.0.2
                                                   |     | |
                                                   |     | |
                                                   v     | |
1-abcdefghij    br: (10.0)                    -----------|-|-----------------------------------
                                                         | |
1-chhv2g5nn1    br: (192.168.200)             -----------|-|-----------------------------------
                                                  ^      | | ^ ^
                                                  |      | | | |
lb_chhv2g5nn    veth: (192.168.200.56)    ---------      | | | |   DNAT for dns
                      (192.168.200.52)                   | | | |   ipvs SNAT to: 192.168.200.56
                                                         | | | |   ipvs fwm 0x107 --> 192.168.200.53, 192.168.200.54
                                                         | | | |
replica1        veth: (172.18.0.3)       ----------------- | | |   DNAT for DNS
                veth: (192.168.200.54)   -----------------------   service ip: 192.168.200.52 (mark set 0x10f)

replica2        on another host                                    service ip: 192.168.200.53
```



#### Interesting commands

```console
$ NSS=$(ip netns list 2>/dev/null | awk '{print $1}')
$ for ns in $NSS; do echo $ns; echo "------------------------------------------"; ip netns exec $ns ip a; echo ""; echo ""; done | grep -vE "lo:|veth|vxlan|link/ether|valid_lft|link/loopback|127.0.0.1"
$ for ns in $NSS; do echo $ns; echo "------------------------------------------"; ip netns exec $ns ipvsadm -L -n; echo ""; echo ""; done
$ for ns in $NSS; do echo $ns; echo "------------------------------------------"; ip netns exec $ns iptables-save; echo ""; echo ""; done
```

## Ok, so what?

Haha, I hear you. What are we doing by these observations?

Here are few examples

### Extensible Load Balancer

Suppose you have created multiple services (each of them performing the same thing, but created by multiple `docker service create`),
and you want to create a Load Balancer that can use any of the other ipvsadm schedulers (like `weighted round robin` and many others).

This is the simplest way to run a Load Balancer (not all details are shown, but just the basics)

```console
$ sysctl -w net.ipv4.vs.conntrack=1
$ docker service create --name lb2 --endpoint-mode dnsrr custom-lb-image
$ NS=$(docker inspect lb2 | grep SandboxKey | awk '{print $2}' | awk -F '"' '{print $2}' | awk -F "/" '{print $6}')
$ LBIP=$(docker inspect lb2 | grep "IPv4Address" | awk '{print $2}' | awk -F '"' '{print $2}')
$ TARGET=192.168.200.73
$ PORT=80
$ ip netns exec $NS ipvsadm -A -t $LBIP:$PORT -s rr
$ ip netns exec $NS ipvsadm -a -t $LBIP:$PORT -r $TARGET -m -w 1
$
$ ip netns exec $NS iptables -t nat -A POSTROUTING -d $TARGET/24 -o eth0 -j MASQUERADE
```

Now, if you connect to `$LBIP:$PORT`, you are redirected (with NAT) to the actual destination. With that being the basics,
you can now add more targets, with different weights etc.

Managing the ipvsadm rules are done via mechanisms of your choice (like labels/annotations of the LB service itself.

### Retiring old services gracefully

By default, upgrades are based on `update rollouts`, where new images are created and after a short `stop-grace-period`, the
old services are removed. Sometimes you don't want that, as your existing services may be holding long running tasks or
long running connections, which will take several minutes (>15) to expire.

So, instead of doing update rollout, you create two services (existing Av1, Av2 with new version) and use this Load Balancer at the
front. The Load Balancer was initially pointing to Av1 with weight 1, now you can add the destination Av2 with weight 1 and
move Av1's weight to 0. This will retain the existing connections to Av1 as long as it takes for connections / tasks to complete. At
which point, the service Av1 can be removed manually (and removed from LB records too).

### Controlled Deployments

You can create your own implementation of blue / green deployment. By default, update rollouts do not allow you to
create two versions to be active at the same time, allow you to do testing and then migrate gracefully. Similar to the above, you can create
multiple services (with each service pointing to a different version). Use the Load balancer to switch (weight as 1:0 to 0:1), use the
Load balancer to send reduced traffic to the new version (weights as, 10:1), and similarly the load balancer configured to redirect
to the new version based on IP address.

_Note: This LB cannot switch based on HTTP headers, as this is purely a L3 LB._

## Egress implementation

This exercise has given enough inputs on how docker networking is setup. So, to control the Egress traffic, where all overlay networks are
routed via custom IP, we may need to do multiple changes.

1. Create the overlay network with `--internal` flag, so that each container is only created with one interface (the overlay network) and
the `docker_gwbridge`  network is not created. Also, the default gateway is removed.
2. Then create a container as the router, with appropriate ip address and forwarding iptables rules. NAT rules are set so that all outgoing
traffic is routed via a specific host IP
3. Then add additional default gateway routing on all containers to point to this new container.

## Network Policy

The same router can be used to setup iptables rules to restrict traffic between overlay networks and also egress traffic.
