# :fontawesome-solid-warehouse:  Setup of Volumes

DCL supports Ephemeral volumes that can support setting limits to the volume, so containers cannot use excessive disk space in a node,
bringing down the node itself.

DCL also supports two types of persistent volumes, NFS and AWS EBS. Both require the administrators to do additional setup.

## Installing docker volume plugins

All the nodes (including manager nodes and worker nodes) needs to have the following plugins related to volume management:

*  `dcl-ephemeral`
*  `dcl-nfs`
*  `dcl-awsebs`

!!! warn "These are pseudo installation steps for now"

Please ensure that `docker-ce` itself is installed on the node, before installing these `docker plugins`. Then, download and install the 
docker volume plugins on a Ubuntu server.
```console
$ curl -O dcl-ephemeral.deb https://dcl.stackpod.io/downloads/dcl-ephemeral.deb
$ curl -O dcl-nfs.deb https://dcl.stackpod.io/downloads/dcl-nfs.deb
$ curl -O dcl-awsebs.deb https://dcl.stackpod.io/downloads/dcl-awsebs.deb
$ dpkg -i dcl-ephemeral.deb dcl-nfs.deb dcl-awsebs.deb
```
The above command downloads the volume plugins and installs them, registers the systemd service and enables them as well.

You would probably need to do these in your AMI creation setup (like `packer`), so that all these plugins are installed on the worker nodes
that are brought up on demand and destroyed when not needed (auto-scaling)

## NFS setup

Identify one or more NFS servers.
