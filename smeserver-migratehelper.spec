%define version 1.0
%define release 11
Summary: Set up a migration helper script for SME Server.
Name: smeserver-migratehelper
Version: %{version}
Release: %{release}%{?dist}
License: GNU GPL version 2
URL: http://www.contribs.org
Group: SMEserver/addon
#Source: %{name}-%{version}.tar.gz
Source: migratehelper.sh
BuildRoot: /var/tmp/%{name}-%{version}-%{release}-buildroot
BuildArchitectures: noarch
BuildRequires: e-smith-devtools >= 1.13.1-03
Requires: e-smith-release >= 8.0
AutoReqProv: no

%description
rpm backup all contribs data and bare essential to have a working system and then rsync data while the new system is up

%changelog
* Sat Sep 07 2024 cvs2git.sh aka Brian Read <brianr@koozali.org> 1.0-11.sme
- Roll up patches and move to git repo [SME: 12338]

* Sat Sep 07 2024 BogusDateBot
- Eliminated rpmbuild "bogus date" warnings due to inconsistent weekday,
  by assuming the date is correct and changing the weekday.

* Thu Dec 02 2021 Jean-Philippe Pialasse <tests@pialasse.com> 1.0-10.sme
- remove non existing standard path /home/e-smith/home

* Sun Nov 14 2021 John Crisp <jcrisp@safeandsoundit.co.uk> 1.0-9.sme
- Fix JPs typo

* Sun Nov 14 2021 John Crisp <jcrisp@safeandsoundit.co.uk> 1.0-8.sme
- fix mangled fail2ban conf backup lines

* Sun Nov 14 2021 John Crisp <jcrisp@safeandsoundit.co.uk> 1.0-7.sme
- remove debug line left by mistake
 
* Fri Oct 29 2021 John Crisp <jcrisp@safeandsoundit.co.uk> 1.0-6.sme
- add check/create for a /mnt/backup dir
- Fix typos
- Fix bash syntax errors via the IDE plugin
- Add some switches for help, test, no confirm

* Thu Oct 21 2021 Jean-Philippe Pialasse <tests@pialasse.com> 1.0-5.sme
- fix missing samba domain user [SME: 11706]
- fix missing user cron jobs [SME: 11664]

* Tue Jun 01 2021 Jean-Philippe Pialasse <tests@pialasse.com> 1.0-4.sme
- fix fail2ban listing  [SME: 11576]

* Sun Apr 25 2021 Jean-Philippe Pialasse <tests@pialasse.com> 1.0-3.sme
- reduce noise for tar [SME: 11576]

* Thu Apr 01 2021 Jean-Philippe Pialasse <tests@pialasse.com> 1.0-2.sme
- add backup of spamassassin admin config
- add search for non rpm owned folder in /usr/local

* Sat Jan 05 2019 Jean-Philipe Pialasse <tests@pialasse.com> 1.0-1.sme
- initial release [SME: 11275]
- TODO use SME 10 includes / excludes

%prep
#%setup
pwd  >&2
ls >&2
mkdir -p  %{name}-%{version}-%{release}/root/usr/bin 
cp %{SOURCE0} %{name}-%{version}-%{release}/root/usr/bin
cd %{name}-%{version}-%{release}

%build
#perl createlinks

%install

rm -rf $RPM_BUILD_ROOT
(cd %{name}-%{version}-%{release}/root ; find . -depth -print | cpio -dump $RPM_BUILD_ROOT)
rm -f %{name}-%{version}-filelist
/sbin/e-smith/genfilelist $RPM_BUILD_ROOT \
     > %{name}-%{version}-filelist

%clean
rm -rf $RPM_BUILD_ROOT

%post

%postun

%files -f %{name}-%{version}-filelist
%defattr(-,root,root)
