---
date: 2024-08-31
categories:
  - docker
  - swarm
tags:
  - ext4
  - xfs
  - quota
authors:
  - rsm
---

# Validating XFS and Ext4 Project Quota

While using xfs or ext4 filesystems, we can enable Project Quota (similar to user quota / group quota). DCL uses this
to limit both persistent nfs volumes and ephemeral volumes.

This post shows how to setup and validate both xfs and ext4 for project quota (or quota for a directory) and provide
an indication of which filesystem is better.

While a user quota refers to a quota for a user for the entire filesystem, and similarly for group, the project quota
refers to a quota for a directory and all files beneath that.

<!-- more -->

## ext4 project quota setup

Let us setup ext4 project quota on a temporary filesystem.

First, let us install needed software
```console title="Install software"
$ sudo apt install e2fsprogs quota
```

Then, create a FS with `prjqota` enabled
```console title="Create ext4 FS"
$ fallocate -l 100M $HOME/ext4_fs
$ mkfs.ext4 -O quota -E quotatype=prjquota $HOME/ext4_fs
$ sudo mkdir /mnt/efs
$ sudo mount -o prjquota $HOME/ext4_fs /mnt/efs
```

Then create a project and an id, along with the designated directory/folder within the fs. Let us say, we want to
create a folder `vol1` in the new filesystem and set a quota for all files in that folder.

```console title="Set project id for a folder"
$ echo "vol1:101" | sudo tee -a /etc/projid
$ echo "101:/mnt/efs/vol1" | sudo tee -a /etc/projects
```

Then set the quota itself
```console title="Set the quota"
$ sudo mkdir /mnt/efs/vol1
$ sudo chattr +P -p 101 /mnt/efs/vol1
$ sudo setquota -P vol1 10M 10M 0 0 /mnt/efs  # Setting both softlimit and hardlimit as the same
$ sudo setquota -P vol1 -t 0 0 /mnt/efs  # Disable grace period
```

Now check quotas
```console title="Check quotas"
$ sudo repquota -Ps /mnt/efs
Block grace time: 00:00; Inode grace time: 00:00
                        Space limits                File limits
Project         used    soft    hard  grace    used  soft  hard  grace
----------------------------------------------------------------------
vol1      --      4K  10240K  10240K              1     0     0       
#0        --     20K      0K      0K              2     0     0       
```

See write data to that folder and check if the quota is being respected.
```console title="Write data to folder"
$ sudo dd if=/dev/zero of=/mnt/efs/vol1/f1 bs=100K count=150
150+0 records in
150+0 records out
15360000 bytes (15 MB, 15 MiB) copied, 0.0154948 s, 991 MB/s
$ ls -lh /mnt/efs/vol1/f1 
-rw-r--r-- 1 root root 15M Aug 31 13:03 /mnt/efs/vol1/f1
$ echo "Oh no, it allowed exceeding the quota. FAILED!!"
$ sudo rm /mnt/efs/vol1/f1
```

Instead of writing as `root` user, let us repeat the same as normal user.
```console title="Write data as normal user"
$ sudo chown $USER /mnt/efs/vol1
$ dd if=/dev/zero of=/mnt/efs/vol1/f1 bs=100K count=150
dd: error writing '/mnt/efs/vol1/f1': Disk quota exceeded
103+0 records in
102+0 records out
10481664 bytes (10 MB, 10 MiB) copied, 0.00855252 s, 1.2 GB/s
$ ls -lh /mnt/efs/vol1/
-rw-rw-r-- 1 rsm rsm 10M Aug 31 13:08 /mnt/efs/vol1/f1
$ echo "hello" > /mnt/efs/vol1/f2
bash: echo: write error: Disk quota exceeded
$ echo "Success!!!"
```

!!! warning "ext4 overrides quota for root user"

## xfs project quota setup

Let us setup xfs project quota on a temporary filesystem.

First, let us install needed software
```console title="Install software"
$ sudo apt install xfsprogs
```

Then, create a FS with `prjqota` enabled
```console title="Create ext4 FS"
$ fallocate -l 400M $HOME/xfs_fs
$ mkfs.xfs $HOME/xfs_fs
$ sudo mkdir /mnt/xfs
$ sudo mount -t xfs -o prjquota $HOME/xfs_fs /mnt/xfs
```

Then create a project and an id, along with the designated directory/folder within the fs. Let us say, we want to
create a folder `vol2` in the new filesystem and set a quota for all files in that folder.

```console title="Set project id for a folder"
$ echo "vol2:102" | sudo tee -a /etc/projid
$ echo "102:/mnt/xfs/vol2" | sudo tee -a /etc/projects
```

Then set the quota itself
```console title="Set the quota"
$ sudo mkdir /mnt/xfs/vol2
$ # sudo chattr +P -p 101 /mnt/xfs/vol2
$ sudo xfs_quota -x -c 'project -s vol2' /mnt/xfs
$ sudo xfs_quota -x -c 'limit -p bsoft=10m bhard=10m vol2' /mnt/xfs  # Setting both softlimit and hardlimit as the same
$ sudo xfs_quota -x -c 'timer -p 1m vol2' /mnt/xfs # Disable grace period
```

Now check quotas
```console title="Check quotas"
$ sudo xfs_quota -x -c 'report -pbih' /mnt/xfs
Project quota on /mnt/xfs (/dev/loop24)
                        Blocks                            Inodes              
Project ID   Used   Soft   Hard Warn/Grace     Used   Soft   Hard Warn/Grace  
---------- --------------------------------- --------------------------------- 
#0              0      0      0  00 [0 days]      3      0      0  00 [0 days]
vol2            0    10M    10M  00 [------]      1      0      0  00 [------]
```

See write data to that folder and check if the quota is being respected.
```console title="Write data to folder"
$ sudo dd if=/dev/zero of=/mnt/xfs/vol2/f1 bs=100K count=150
dd: error writing '/mnt/xfs/vol2/f1': No space left on device
103+0 records in
102+0 records out
10485760 bytes (10 MB, 10 MiB) copied, 0.0215818 s, 486 MB/s
$ ls -lh /mnt/xfs/vol2/f1 
-rw-r--r-- 1 root root 10M Aug 31 13:24 /mnt/xfs/vol2/f1
$ echo "hello" | sudo tee /mnt/xfs/vol2/f2
tee: /mnt/xfs/vol2/f2: No space left on device
$ echo "Success as root user also"
$ sudo rm /mnt/xfs/vol2/f1
```

Let us repeat it for a normal user also.
```console title="Write data as normal user as well"
$ sudo chown $USER /mnt/xfs/vol2
$ dd if=/dev/zero of=/mnt/xfs/vol2/f1 bs=100K count=150
dd: error writing '/mnt/xfs/vol2/f1': No space left on device
103+0 records in
102+0 records out
10485760 bytes (10 MB, 10 MiB) copied, 0.0234818 s, 447 MB/s
$ ls -lh /mnt/xfs/vol2/f1 
-rw-rw-r-- 1 rsm rsm 10M Aug 31 13:29 /mnt/xfs/vol2/f1
$ echo "hello" > /mnt/xfs/vol2/f2
bash: /mnt/xfs/vol2/f2: No space left on device
$ echo "Success!!!"
```
