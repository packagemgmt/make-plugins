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


Some examples what it can do:
-----------------------------

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
You will need https://pypi.python.org/pypi/repositorytools >=4.2.1 to make this work
```
REPOSITORY_URL=https://repository.eng.mycompany.com
REPOSITORY_USER=jdoe
REPOSITORY_PASSWORD=mysecretpassword

make uploadrpms GROUP=com.mycompany
```
