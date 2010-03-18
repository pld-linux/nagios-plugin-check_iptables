%define		plugin	check_iptables
Summary:	Nagios plugin to check count of iptables rules
Name:		nagios-plugin-%{plugin}
Version:	0.1
Release:	2
License:	GPL v2
Group:		Networking
Source0:	%{plugin}
Source1:	%{plugin}.cfg
BuildRequires:	rpmbuild(macros) >= 1.552
Requires:	iptables
Requires:	nagios-common
Requires:	nagios-plugins-libs
Requires:	sudo
BuildArch:	noarch
BuildRoot:	%{tmpdir}/%{name}-%{version}-root-%(id -u -n)

%define		_sysconfdir	/etc/nagios/plugins
%define		plugindir	%{_prefix}/lib/nagios/plugins

%description
Nagios plugin to check count of iptables rules.

%prep
%setup -qcT
cp -p %{SOURCE0} %{plugin}

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT{%{_sysconfdir},%{plugindir}}
install -p %{plugin} $RPM_BUILD_ROOT%{plugindir}/%{plugin}
sed -e 's,@plugindir@,%{plugindir},' %{SOURCE1} > $RPM_BUILD_ROOT%{_sysconfdir}/%{plugin}.cfg

%clean
rm -rf $RPM_BUILD_ROOT

%post
if [ "$1" = 1 ]; then
	# setup sudo rules on first install
	%{plugindir}/%{plugin} -S || :
fi

%postun
if [ "$1" = 0 ]; then
	# remove all sudo rules related to us
	%{__sed} -i -e '/CHECK_IPTABLES/d' /etc/sudoers
fi

%triggerin -- nagios-nrpe
%nagios_nrpe -a %{plugin} -f %{_sysconfdir}/%{plugin}.cfg

%triggerun -- nagios-nrpe
%nagios_nrpe -d %{plugin} -f %{_sysconfdir}/%{plugin}.cfg

%files
%defattr(644,root,root,755)
%attr(640,root,nagios) %config(noreplace) %verify(not md5 mtime size) %{_sysconfdir}/%{plugin}.cfg
%attr(755,root,root) %{plugindir}/%{plugin}
