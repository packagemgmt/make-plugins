# --- Variables ---
PKGNAME=$(shell basename *.spec .spec)

VERSION_MAJOR ?= 0
VERSION_MINOR ?= 0
VERSION_BUGFIX ?= 0

# # assign zeros only if not specified from cmdline by make {target} VERSION=1.2.3
VERSION?=$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_BUGFIX)
GROUP?=com.example# used when uploading to artifact repository
WORKDIR:=/tmp/
RELEASE ?= 1
BUILDARCH=$(shell grep -oP '(?<=^BuildArch: ).*' $(PKGNAME).spec)
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

ON_PREPARE_CMD ?= echo No prepare cmd. Lucky you.

ifeq ($(RELEASE), SNAPSHOT)
REPO_SUFFIX=-snapshots
UPLOAD_EXTRA_PARAMS=--use-direct-put
else
REPO_SUFFIX=
endif

# --- Deprecated variables ---
DISTTAG?=$(shell rpm --eval '%{dist}' | tr -d '.')

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
	rpmbuild --define "VERSION $(VERSION)" -ta $(WORKDIR)/$(PKGNAME).tgz

srpm: distcwd
	rpmdev-wipetree
	# we need to specify old digest algorithm to support el5
	rpmbuild --define "_source_filedigest_algorithm md5" --define "VERSION $(VERSION)" --define "RELEASE $(RELEASE)" -ts ${WORKDIR}/$(PKGNAME).tgz

# Build RPMs for all os versions defined on OS_VERIONS
# we use three phases (init, chroot, rebuild) to allow user to modify the chrooted system as needed
rpms: srpm
	set -e && for os_version in $(OS_VERSIONS); do \
	    mkdir -p $(RESULTDIR)/${os_version} && \
	    rm -f $(RESULTDIR)/${os_version}/* && \
	    /usr/bin/mock \
	      --resultdir $(RESULTDIR)/${os_version} \
	      --init \
	      -r epel-${os_version}-x86_64 && \
	    /usr/bin/mock \
	      --resultdir $(RESULTDIR)/${os_version} \
	      -r epel-${os_version}-x86_64 \
	      --chroot $(ON_PREPARE_CMD) && \
	    /usr/bin/mock \
	      --resultdir $(RESULTDIR)/${os_version} \
	      --define "dist .el${os_version}" \
	      --define "VERSION $(VERSION)" \
	      --define "RELEASE $(RELEASE)" \
	      --rebuild \
	      -r epel-${os_version}-x86_64 $(MOCKOPTIONS) \
	      --no-clean \
	      --no-cleanup-after \
	      $(SRPMDIR)/*.src.rpm; \
	done

# Upload RPMs for all os versions to Sonatype Nexus
# Requires package repository-tools
uploadrpms: rpms
	$(foreach os_version, $(OS_VERSIONS), \
	    artifact upload $(UPLOAD_EXTRA_PARAMS) --artifact $(PKGNAME) --version $(VERSION)-$(RELEASE) \
	      $(UPLOAD_OPTIONS) \
	      $(RESULTDIR)/$(os_version)/$(PKGNAME)-$(VERSION)-*$(BUILDARCH).rpm \
	      packages-el$(os_version)$(REPO_SUFFIX) \
	      $(GROUP); \
	)

# Shows VCS changes, can be used to generate changelog
changelog:
	git log --pretty=format:"%d%n    * %s [%an, %ad]"  --date=short

# Adds changelog to package
installChangelog:
	mkdir -p $(defaultdocdir)/$(PKGNAME)-$(VERSION)
	install -m 644 ChangeLog $(defaultdocdir)/$(PKGNAME)-$(VERSION)

# ----- deprecated targets ---
# requires repository-tools for uploading to Sonatype Nexus
define do-upload
	artifact upload $(UPLOAD_OPTIONS) $(RPMDIR)/$(BUILDARCH)/$(PKGNAME)-$(VERSION)-$(RELEASE).$(BUILDARCH).rpm packages-$(DISTTAG) $(GROUP)
endef

upload: rpm
	$(do-upload)


.PHONY: distcwd rpm srpm rpms upload uploadrpms changelog installChangelog
