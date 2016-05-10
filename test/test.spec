Name: test
Version: %{VERSION}
Release: %{RELEASE}%{?dist}
Summary:	test
Source0:  %{name}.tgz
License: GPL
Group: test
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

%description
%{summary}

%prep
%setup -q

%install
%make_install


%files
/usr/bin/helloworld
