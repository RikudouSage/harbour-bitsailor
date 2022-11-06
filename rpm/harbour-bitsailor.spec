# 
# Do NOT Edit the Auto-generated Part!
# Generated by: spectacle version 0.32
# 

Name:       harbour-bitsailor

# >> macros
# << macros

Summary:    BitSailor
Version:    0.2.3
Release:    1
Group:      Applications/Productivity
License:    MIT
URL:        http://example.org/
Source0:    %{name}-%{version}.tar.bz2
Source100:  harbour-bitsailor.yaml
Requires:   sailfishsilica-qt5 >= 0.10.9
Requires:   sailfishsecretsdaemon-secretsplugins-default
Requires:   sailfish-polkit-agent
BuildRequires:  pkgconfig(sailfishapp) >= 1.0.2
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(sailfishsecrets)
BuildRequires:  pkgconfig(sailfishcrypto)
BuildRequires:  desktop-file-utils

%description
A Sailfish OS Bitwarden client using the official Bitwarden CLI


%prep
%setup -q -n %{name}-%{version}

# >> setup
# << setup

%build
# >> build pre
# << build pre

%qmake5 

make %{?_smp_mflags}

# >> build post
# << build post

%install
rm -rf %{buildroot}
# >> install pre
# << install pre
%qmake5_install

# >> install post
# << install post

desktop-file-install --delete-original       \
  --dir %{buildroot}%{_datadir}/applications             \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
%{_datadir}/polkit-1/actions/cz.chrastecky.bitsailor.policy
# >> files
# << files
