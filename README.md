How to incorporate it
---------------------

Add these lines to your Makefile so you can use this plugin
```
all:
        curl -k https://raw.githubusercontent.com/stardust85/make-plugins/master/make-rpm.mk > make-rpm.mk

-include make-rpm.mk
```

Some examples what it can do:
-----------------------------

Create rpm from content in current working directory
```
make rpmcwd
```

Override version mentioned in specfile - good for continuous integration
```
make rpmcwd VERSION=1.2.3
```

Upload to artifact repository. This will also build the rpm before.
You will need https://github.com/stardust85/repositorytools to make this work
```
REPOSITORY_URL=https://repository.eng.mycompany.com
REPOSITORY_USER=jdoe
REPOSITORY_PASSWORD=mysecretpassword

make upload GROUP=com.mycompany
```
