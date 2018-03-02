How to incorporate it
---------------------

1. Add these lines to your Makefile so you can use this plugin
```
mkplugin:
        curl https://raw.githubusercontent.com/packagemgmt/make-plugins/master/make-rpm.mk > make-rpm.mk

-include make-rpm.mk
```

2. Then call 'make mkplugin' to download it.
3. (if you like it) git add mkplugin.mk && git commit mkplugin.mk && git push 


Some examples what it can do
----------------------------

Create rpm from content in current working directory
```
make rpm
```

Override version mentioned in specfile - good for continuous integration
```
make rpm VERSION=1.2.3
```

Create RPMs for all os versions (el6, el7)
```
make rpms
```

Upload to artifact repository. This will also build the rpms before.
(Note: https://pypi.python.org/pypi/repositorytools >=4.2.1 are needed)
```
REPOSITORY_URL=https://repository.eng.mycompany.com
REPOSITORY_USER=jdoe
REPOSITORY_PASSWORD=mysecretpassword

make uploadrpms GROUP=com.mycompany
```


Build Configuration
-------------------

### Package name, version and release

Package name is taken from spec file's base name and passed to `rpmbuild` or `mock`
as `PACKAGE_NAME` macro.

Version is loaded from environment variable `VERSION` and made available in the spec
file as `VERSION` macro. If the variable `VERSION` is not defined, its value is
built up from `VERSION_MAJOR`, `VERSION_MINOR` and `VERSION_BUGFIX` variables.

Release is analogically loaded from variable named `RELEASE` and passed into the
spec file as `RELEASE` macro. The default value is 1.

These three calls are equivalent:

```
make rpm VERSION=1.2.3
make rpm VERSION=1.2.3 RELEASE=1
make rpm VERSION_MAJOR=1 VERSION_MINOR=2 VERSION_BUGFIX=3 RELEASE=1
```


### Target OS versions

Target OS versions can be defined in environment variable `OS_VERSIONS`.

The default value is `5 6 7`, so `mock` will be called with `epel-5-x86_64`,
`epel-6-x86_64` and `epel-7-x86_64` chroot configs.

To build RPM package, for example, only for EL6 and 7 call:

```
make rpm OS_VERSIONS='6 7'
```


Upload configuration
--------------------

You need to install *repositorytools* of version 4.2.1 or higher for upload
to Nexus repository manager to work. The *repositorytools* can be found at
https://pypi.python.org/pypi/repositorytools.


### Connection to the repository manager

Connection to the repository manager must be configured by **environment variables**
`REPOSITORY_URL`, `REPOSITORY_USER` and `REPOSITORY_PASSWORD`. They are then processed
directly by the `artifact upload` command from repository tools.

The `REPOSITORY_URL` variable must contain URL to the Nexus service, not
to a specific repository.

```
REPOSITORY_URL=https://repository.eng.mycompany.com
REPOSITORY_USER=jdoe
REPOSITORY_PASSWORD=mysecretpassword

make uploadrpms GROUP=com.mycompany
```


### Target repository

The repository ID where RPM packages will be uploaded can be configured
by `RELEASE_REPOSITORY` and `SNAPSHOT_REPOSITORY` variables. The latter
is used if the `RELEASE` variable contains the value `SNAPSHOT`.

If the specified repository ID contains a string `$(os_version)` it will
be replaced by individual values from the `OS_VERSIONS` variable.

This command will upload RPMs to `rpms-el6` and `rpms-el7` repositories:

```
RELEASE_REPOSITORY='rpms-el$(os_version)'

make uploadrpms OS_VERSIONS='6 7'
```


### Additional upload options

If you need to specify additional options for the `artifact upload` command,
you can do so be defining `RELEASE_UPLOAD_OPTIONS` and `SNAPSHOT_UPLOAD_OPTIONS`
variables instead.

A typical use case is uploading non-snapshot artifacts to a staging profile
(notice that `RELEASE_REPOSITORY` contains staging profile name):

```
RELEASE_REPOSITORY='rpms-profile-el$(os_version)'
RELEASE_UPLOAD_OPTIONS='--staging --description "My description"'

make uploadrpms
```

Note: If you don't need separate upload options for release and snapshot
repositories, you can define `UPLOAD_OPTIONS` instead. This variable overrides
values of `RELEASE_UPLOAD_OPTIONS` and `SNAPSHOT_UPLOAD_OPTIONS`.
