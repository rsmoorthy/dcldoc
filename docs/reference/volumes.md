# DCL Volumes

This page directly dives into the reference of DCL storage configuration, Please refer to [concepts](../concepts/volumes.md) and 
[using examples](../getting-started/volumes.md) for further details.

## Using Volumes

### CLI

While creating services / containers, DCL allows you to use the volumes in one of the following ways:

#### **`-v / --volume`**

:  `/<target>[:<options>]`<br>
    `<src>/<target>[:<options>]`

: where `<target>` is the path where the volume should be mounted within the container

: where `:<options>` are the options are optional, and is a comma separated list of options, such as `ro`. For details, refer [docker docs](https://docs.docker.com/engine/storage/volumes/)

: where `<src>` can only be one of:
    
    * Empty ie not specified, in which an unnamed anonymous volume is mounted.
    * `local-<volname>` which creates and mounts a local named ephemeral volume. The volume should not be created before hand.
    * `nfs-<volname>` which mounts a NFS persistent volume, which should have been created before hand.
    * `awsebs-<volname>` which mounts a AWS EBS persistent volume, which should have been created before hand.

: Using this format of `-v / --volume` there is no way to specify the size of the volume and is automatically defined by the default, configured
  by `storage.ephemeral.defaultSize`. Using this option, you cannot create a RAM based ephemeral volume (aka `tmpfs`)

: This option is available only for `docker run`
  
#### **`--mount`**

:  `--type=(volume|bind|tmpfs),src=<val>,target=<val>,readonly,volume-driver=(dcl-nfs|dcl-awsebs),volume-opt=....`

: where the format exactly follows [docker docs](https://docs.docker.com/engine/storage/volumes/). {==Except for the following caveats.==}
  Consists of multiple key-value pairs, separated by commas.

: where the `type` has to be one of `volume|bind|tmpfs`. If none provided, the value is taken to be `volume`.
  If `tmpfs` is given, then `src` is ignored. If `bind` is given, then `src` has to be path on the host filesystem.

: where the `src` (or alternatively `source`) can be absent, in which case an unnamed anonymous volume is mounted<br>
  If `src` is present and `type=volume`, it has to be one of `local-<volname>`, `nfs-<volname>`, `awsebs-<volname>`. See above for details.<br>
  If `src` is present and `type=bind`, then src has to be path on the host filesystem.<br>
  If `src` is present and `type=tmpfs`, then src is ignored.

: where the `target` (or alternatively `destination`, `dst`) must be present and takes as its value the path where the file or directory
  is mounted in the container.

: where `readonly` (or alternatively `ro`) is optional, makes the mount as read only.

: where `volume-driver` is optional and automatically detected. If present, it must be one of `dcl-local` (then the `src` should have 
  prefix as `local-`), dcl-nfs` (then the `src` should have prefix as `nfs-`) or `dcl-awsebs` (then the `src` should have prefix as `awsebs-`).
  Any other value throws an error.

: where `volume-opt` is optional and can be repeated multiple times to specify different options. The following are the ONLY accepted
  options:

    * For local named volumes (where `src` begins with `local-`) and unnamed anonymous volumes (where src is omitted and type=volume),
        - `size` indicates the size of the local volume (such as `volume-opt=size=10M`). This value can be a numeric, indicating the number of bytes.
        It can be suffixed with `kb`, `k`, `mb`, `m`, `gb`, `g` (or its uppercase values) to indicate kilobytes, megabytes, gigabytes respectively.
        If not provided, the default value is taken from DCL config `storage.ephemeral.defaultSize`
    * For `type=tmpfs`, 
        - `tmpfs-size` indicates the size of the RAM ephemeral volume (such as `volume-opt=tmpfs-size=10M`). This value can be a numeric, indicating 
        the number of bytes. It can be suffixed with `kb`, `k`, `mb`, `m`, `gb`, `g` (or its uppercase values) to indicate kilobytes, megabytes, 
        gigabytes respectively. If not provided, the default value is taken from DCL config `storage.ephemeral.defaultSize`
    * {==All other values are ignored.==}

: This option is available for `docker run` and `docker service create`

### Compose

The Compose definition for volumes is same as the CLI, but just has the values defined in YAML and syntax is different (but the structure is still
the same).

Please refer to [docker docs](https://docs.docker.com/reference/compose-file/services/#volumes) for finer details. The description is given
as comments below in the YAML spec, but for all the details, you can refer to the CLI section above.

```yaml
services:
  service_name:
    image: <some image>
    volumes:
    - type: volume          # Can be one of volume | tmpfs | bind
      src: (<local-volname>|<nfs-volname>|<awsebs-volname>)   # For type=volume. For type=tmpfs, src is not defined.
                                                              # For type=volume src can be undefined, resulting in anonymous volume
      target: <path inside container>   # Key can also be dst or destination
      readonly: <true or false>         # If undefined, it is false
      tmpfs:                            # Entire structure only valid if type is tmpfs
        size: numeric or bytes unit     # See above for `size` definition
      volume:                           # Entire structure below is only valid if type is volume
        size: numeric or bytes unit     # See above for `size` definition
```

## Creating Volumes

While creating volumes, DCL allows you to create the volumes as usual, but has restrictions in terms of the volumes and options.

To create volumes, DCL restrictions are below. The following are the options accepted for `docker volume create` for different types of volumes.

### CLI

CLI general definition:

!!! note "CLI definition for volumes"
    === "NFS"
        ```console
        $ docker volume create \
          -o size=10M \
          -o owner=1000 \
          -o group=1000 \
          -o mode=0700 \
          nfs-vol1
        ```
    === "AWS EBS"
        ```console
        $ docker volume create \
          -o size=10G \
          -o owner=1000 \
          -o group=1000 \
          -o mode=0700 \
          -o az=A \
          -o snapshot=db-snapshot-ason-lastweek \
          -o type=gp3 \
          -o throughput=128 \
          awsebs-vol1
        ```

### Compose

Compose general definition below. See [docker docs](https://docs.docker.com/reference/compose-file/volumes/) for details:

!!! note "Compose definition for volumes"
    === "NFS"
        ```yaml
        volumes:
          <volname>:                                 # Has to be prefixed with nfs-
            driver: <dcl-nfs>                         # Best case is not to define. DCL will autofill this, based on volume name
            driver_opts:
              size: numeric or bytes unit            # See below for definition for all of the following
              owner: numeric
              group: numeric
              mode: numeric in octal
        ```
    === "AWS EBS"
        ```yaml
        volumes:
          <volname>:                                 # Has to be prefixed with awsebs-
            driver: <dcl-awsebs>                         # Best case is not to define. DCL will autofill this, based on volume name
            driver_opts:
              size: numeric or bytes unit            # See below for definition for all of the following
              owner: numeric
              group: numeric
              mode: numeric in octal
              az:   AZ value
              snapshot:   string                     # name of snapshot to copy from
              type:   <gp2|gp3|st1>
              throughput:   128
        ```

### NFS volumes

For NFS volumes, the volume name should begin with `nfs-`.

#### **size**

: `size` indicates the size of the NFS volume (such as `volume-opt=size=10M`). This value can be a numeric, indicating the number of bytes.
  It can be suffixed with `kb`, `k`, `mb`, `m`, `gb`, `g` (or its uppercase values) to indicate kilobytes, megabytes, gigabytes respectively.

: If not provided, the default value is taken from DCL config `storage.persistent.nfs.defaultSize`

#### **owner**

: `owner` indicates the ownership of the root path directory (such as `volume-opt=owner=1000`). Only a numeric value (aka id of the user)
  is accepted, where values can be higher than 500. It is highly recommended that owner is not set to 0 (ie root). However, the default
        value is indeed set to `0`, if this option is not provided.

#### **group**

: `group` indicates the group of the root path directory (such as `volume-opt=group=1000`). Only a numeric value (aka id of the group)
  is accepted, where recommended values can be higher than 500. It is highly recommended that owner is not set to 0 (ie root). However,
  the default value is indeed set to `0`, if this option is not provided.

#### **mode**

: `mode` indicates the mode of the root path directory (such as `volume-opt=mode=0700`). Only an octal numeric
  value is accepted such as `0700` or `0644`. If not provided, the default would be `0755`.

### AWS EBS volumes

For AWS EBS volumes, the volume name should begin with `awsebs-`.

#### **size**

: `size` indicates the size of the NFS volume (such as `volume-opt=size=10G`). This value can be a numeric, indicating the number of bytes.
        It can be suffixed with `kb`, `k`, `mb`, `m`, `gb`, `g` (or its uppercase values) to indicate kilobytes, megabytes, gigabytes respectively.
        If not provided, the default value is taken from DCL config `storage.persistent.awsebs.defaultSize`. The min and max size is dependent
        on the DCL configurations [`storage.persistent.awsebs.minSize`](../reference/configuration.md#storagepersistentawsebsminsize) and 
        [`storage.persistent.awsebs.maxSize`](../reference/configuration.md#storagepersistentawsebsmaxsize).

#### **owner**

: `owner` indicates the ownership of the root path directory (such as `volume-opt=owner=1000`). Only a numeric value (aka id of the user)
        is accepted, where values can be higher than 500. It is highly recommended that owner is not set to 0 (ie root). However, the default
        value is indeed set to `0`, if this option is not provided.

#### **group**

: `group` indicates the group of the root path directory (such as `volume-opt=group=1000`). Only a numeric value (aka id of the group)
        is accepted, where recommended values can be higher than 500. It is highly recommended that owner is not set to 0 (ie root). However,
        the default value is indeed set to `0`, if this option is not provided.

#### **mode**

: `mode` indicates the mode of the root path directory (such as `volume-opt=mode=0700`). Only an octal numeric
        value is accepted such as `0700` or `0644`. If not provided, the default would be `0755`.

#### **snapshot**

: `snapshot` indicates the AWS EBS snapshot name that should be used to clone and create this AWS EBS volume from. If none is provided,
        an empty volume is created for you. If provided and if the name is incorrect or you don't have access to this snapshot etc, then the
        AWS EBS volume is not created and an error is thrown.

#### **az**

: `az` indicates the AWS zone (usually one of A|B|C) where the EBS volume needs to be created (such as `volume-opt=az=A`). This will be 
        validated against DCL configuration [`storage.persistent.awsebs.zones`](../reference/configuration.md#storagepersistentawsebszones) and/or the same
        available in auth rules for the config `storage.persistent.awsebs.zones`. If it is not validated, an error will be thrown. If this value
        is not provided, then the default value from DCL configuration `storage.persistent.awsebs.defaultZone` is taken.

#### **type**

: `type` indicates the type of the AWS EBS volume. It takes a value from one of `gp2`, `gp3`, `st1` (other values are not accepted right now).
        The default is from DCL configuration [`storage.persistent.awsebs.type`](../reference/configuration.md#storagepersistentawsebstype).

#### **throughput**

: `throughput` indicates the throughput supported to this EBS volume from the node, valid only if the type is `gp3` 
        (such as `volume-opt=throughput=256`).  The unit of this value is MB/sec, however this value is purely a numeric value. For some 
        high performance requirements, you can set a higher throughput of the EBS volume. The default is 128MB/sec or set by 
        [`storage.persistent.awseb.throughput`](../reference/configuration.md#storagepersistentawsebsthroughput). As with the size, the max size 
        is dictated by [`storage.persistent.awseb.maxThroughput`](../reference/configuration.md#storagepersistentawsebsmaxthroughput).
