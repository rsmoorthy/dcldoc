# DCL Configuration



## Storage Configuration


### `storage.ephemeral.defaultSize`

: `<size in MB>`

: Default size of the ephemeral volumes created. If none specified, there is no default size. If specified and
the user does not specify a size, this value is used as the volume size.

### `storage.ephemeral.maxSize`

: `<size in MB>`

: Maximum size of the ephemeral volumes created. If none specified, there is no limitation on the maximum size
of an ephemeral volume. If specified, then this will override the volume size, in case, if the provides a
higher value than this.
