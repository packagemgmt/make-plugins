# --- Variables ---
ifndef PKGNAME
PKGNAME:=$(shell test -f *.spec && basename *.spec .spec)
endif

# works only on gnu make >= 4.2 :(
#ifneq ($(.SHELLSTATUS), 0)
#    $(error Missing specfile!)
#endif

ifndef PKGNAME
    $(error Missing specfile?!)
endif


VERSION_MAJOR ?= 0
VERSION_MINOR ?= 0
VERSION_BUGFIX ?= 0

# assign zeros only if not specified from cmdline by make {target} VERSION=1.2.3
VERSION?=$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_BUGFIX)
GROUP?=com.example# used when uploading to artifact repository
WORKDIR:=/tmp/
RELEASE ?= 1
BUILDARCH=$(shell grep -oP '(?<=^BuildArch:\s).*' $(PKGNAME).spec)
RPMDIR=$(shell rpm --eval %{_rpmdir})
prefix=$(DESTDIR)$(shell rpm --eval %{_prefix})
bindir=$(DESTDIR)$(shell rpm --eval %{_bindir})
datadir_short=$(shell rpm --eval %{_datadir})
datadir=$(DESTDIR)$(datadir_short)
pkgdatadir_short=$(datadir_short)/$(PKGNAME)
pkgdatadir=$(datadir)/$(PKGNAME)
libdir=$(DESTDIR)$(shell rpm --eval %{_libdir})
defaultdocdir=$(DESTDIR)$(shell rpm --eval %{_defaultdocdir})
initrddir=$(DESTDIR)$(shell rpm --eval %{_initrddir})
sysconfdir:=$(DESTDIR)$(shell rpm --eval %{_sysconfdir})
pythonsitedir:=$(DESTDIR)$(shell python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")
SRPMDIR=$(shell rpm --eval '%{_srcrpmdir}')
OS_VERSIONS?=5 6 7
RESULTDIR = $(PWD)
MOCK ?= $(shell which mock)

ON_PREPARE_CMD ?= echo No prepare cmd. Lucky you.

# without this, repositorytools >= 4.2.1 would harm the filename so it would miss arch and dist tag
UPLOAD_EXTRA_PARAMS=--use-direct-put

REPO_PREFIX?=packages-el
RELEASE_REPOSITORY?=$(REPO_PREFIX)$(os_version)
SNAPSHOT_REPOSITORY?=$(REPO_PREFIX)$(os_version)-snapshots

ifeq ($(RELEASE), SNAPSHOT)
UPLOAD_REPOSITORY?=$(SNAPSHOT_REPOSITORY)
UPLOAD_OPTIONS?=$(SNAPSHOT_UPLOAD_OPTIONS)
else
UPLOAD_REPOSITORY?=$(RELEASE_REPOSITORY)
UPLOAD_OPTIONS?=$(RELEASE_UPLOAD_OPTIONS)
endif

# --- Helper functions ---
# They are functions so they can be overrided
# takes the content of current working directory and packs it to tgz
define do-distcwd
	# make --no-print-directory -s changelog | grep -v '^$$' > ChangeLog
	rm -f $(WORKDIR)/$(PKGNAME).tgz
	tar cvzf $(WORKDIR)/$(PKGNAME).tgz --transform "s,^\.,$(PKGNAME)-$(VERSION)," . || :
endef

# --- TARGETS ---
distcwd:
	$(do-distcwd)

# Builds RPM package only for your OS version. Much faster than make rpms, good for basic testing of your spec/makefile
rpm: distcwd
	rpmbuild -ta $(WORKDIR)/$(PKGNAME).tgz \
		--define "VERSION $(VERSION)" \
		--define "RELEASE $(RELEASE)" \
		--define "PACKAGE_NAME $(PKGNAME)"

srpm: distcwd
ifndef NOWIPETREE
	rpmdev-wipetree
endif
	# we need to specify old digest algorithm to support el5
	rpmbuild $(SRPMOPTIONS) \
		--define "_source_filedigest_algorithm md5" \
		--define "VERSION $(VERSION)" \
		--define "RELEASE $(RELEASE)" \
		--define "PACKAGE_NAME $(PKGNAME)" \
		-ts ${WORKDIR}/$(PKGNAME).tgz

# Build RPMs for all os versions defined on OS_VERIONS
# we use three phases (init, chroot, rebuild) to allow user to modify the chrooted system as needed
rpms: srpm
	set -e && for os_version in $(OS_VERSIONS); do \
	    mkdir -p $(RESULTDIR)/$${os_version} && \
	    rm -f $(RESULTDIR)/$${os_version}/* && \
	    $(MOCK) \
	      --resultdir $(RESULTDIR)/$${os_version} \
	      --init \
	      -r epel-$${os_version}-x86_64 $(MOCKOPTIONS) && \
	    $(MOCK) \
	      --resultdir $(RESULTDIR)/$${os_version} \
	      -r epel-$${os_version}-x86_64 $(MOCKOPTIONS) \
	      --chroot $(ON_PREPARE_CMD) && \
	    $(MOCK) \
	      --resultdir $(RESULTDIR)/$${os_version} \
	      --define "dist .el$${os_version}" \
	      --define "VERSION $(VERSION)" \
	      --define "RELEASE $(RELEASE)" \
	      --define "PACKAGE_NAME $(PKGNAME)" \
	      --rebuild \
	      -r epel-$${os_version}-x86_64 $(MOCKOPTIONS) \
	      --no-clean \
	      --no-cleanup-after \
	      $(SRPMDIR)/*.src.rpm || \
	    false; \
	done

# Upload RPMs for all os versions to Sonatype Nexus
# Requires package repository-tools
uploadrpms: rpms
	$(foreach os_version, $(OS_VERSIONS), \
	    artifact upload $(UPLOAD_EXTRA_PARAMS) --artifact $(PKGNAME) --version $(VERSION)-$(RELEASE) \
	      $(UPLOAD_OPTIONS) \
	      $(RESULTDIR)/$(os_version)/$(PKGNAME)-$(VERSION)-*$(BUILDARCH).rpm \
	      $(UPLOAD_REPOSITORY) \
	      $(GROUP); \
	)

# Shows VCS changes, can be used to generate changelog
changelog:
	git log --pretty=format:"%d%n    * %s [%an, %ad]"  --date=short

# Adds changelog to package
installChangelog:
	mkdir -p $(defaultdocdir)/$(PKGNAME)-$(VERSION)
	install -m 644 ChangeLog $(defaultdocdir)/$(PKGNAME)-$(VERSION)


.PHONY: distcwd rpm srpm rpms upload uploadrpms changelog installChangelog
