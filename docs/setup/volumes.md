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

Identify one or more NFS servers. In most cases, 1 NFS server per cluster is good enough. But 
depending on the volumes size and network bandwidth, you may need more than 1 NFS server per cluster.
In addition, you may want to have different NFS servers for production and development, even if 
bandwidth is not an issue.


In addition, the following aspects need to be considered:

* The NFS server(s) should be located in the same subnet as the docker nodes.
* You can co locate the NFS services on an existing server, like one of the Swarm Manager
  servers, on the DCL server etc. For small setups, the Swarm Manager, DCL and NFS servers
  can all be located on the same server.
* DCL server (server where the DCL software is running) should have the NFS volumes mounted.
* As this [post](blog/posts/validating-ext4-xfs-quotas.md) recommends, you need to setup XFS
  filesystem on the NFS volume, so that the quota works very well even for root users.

### NFS FS setup

!!! warning "These are  very rough installation steps for setting up the NFS disk and the NFS server.
Please fine tune as per your needs."

NFS Disk Setup:

```console
$ # Assume the disk device is /dev/nvme0n1. Modify accordingly
$ sudo mkfs -t xfs /dev/nvme0n1
$ sudo mkdir /nfs   # The mount point. Change accordingly.
$ # Add the disk volume to /etc/fstab to mount automatically
$ echo "/dev/nvme0n1  /nfs  xfs  defaults,prjquota  0 0" | sudo tee -a /etc/fstab
$ sudo mount -a
$ # Verify by running "mount". Ensure `prjquota` is turned on
```

NFS server setup:

```console
$ # Install NFS server software and enable
$ sudo apt-get install nfs-kernel-server
$ sudo systemctl enable nfs-kernel-server
$ sudo systemctl start nfs-kernel-server
$ # Add to /etc/exports. The Subnet IP is setup according to your network setup
$ echo "/nfs   10.x.x.x/24(rw,root_squash,sync)" | sudo tee -a /etc/exports
$ # Run exportfs to reflect changes in /etc/exports
$ sudo exportfs -av
```

Please consider the following aspects:

*  The export option `root_squash` is suggested rather than `no_root_squash`, as many blogs
   refer. This ensures that files written by root user are not actually written as root user.
   This discourages services writing files as `root` user.
*  The option `sync` ensures that files are written to disk immediately, with a hit on slight
   performance. Prioritising integrity of files over performance.
*  Please limit access to the IP range, as you wish. Or allow to all IPs (by '*'), based on
   your security policy.

### Multiple NFS shares / folders

It may be convenient to divide a single NFS volume into multiple folders. Perhaps one for
NFS volumes and another for configs and secrets. And you could set a separate quota
for each folder and export them separately.

Or you could create multiple disks, each for a separate purpose - where each of them
can be exported and expanded independently.

In such cases, ensure `/etc/fstab` is updated (for multiple disks) and `/etc/exports`
is updated for multiple NFS shares.

### NFS Server High Availability

Two different aspects of High Availability for NFS can be achieved:

* Disk HA:
  - The best solution is to setup multiple disks (one or more) using either RAID 1 or RAID 4
    method. Setting up a RAID solution is outside of the scope of this article.
  - With this solution, any single disk failure can be tolerated and the data continues
  be available.
* NFS Server HA:
  - This is harder to achieve. 
