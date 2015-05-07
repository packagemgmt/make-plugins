Add these lines to your Makefile so you can use this plugin

all:
        curl -k https://raw.githubusercontent.com/stardust85/make-plugins/master/make-rpm > make-rpm.mk

-include make-rpm.mk

Some examples how to use it:
```
make rpmcwd # create rpm from content in current working directory

make rpmcwd VERSION=1.2.3 # override version mentioned in specfile

# Upload to artifact repository.
# These variables can be also specified as environment variables.
# You will need https://github.com/stardust85/repositorytools to make this work
make upload REPOSITORY_URL=https://repository.eng.mycompany.com REPOSITORY_USER=jdoe REPOSITORY_PASSWORD=mysecretpassword GROUP=com.mycompany
```
