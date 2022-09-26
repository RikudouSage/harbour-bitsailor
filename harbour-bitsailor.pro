# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
TARGET = harbour-bitsailor

CONFIG += sailfishapp
PKGCONFIG += sailfishsecrets

SOURCES += src/harbour-bitsailor.cpp \
    src/appsettings.cpp \
    src/bitwardencli.cpp \
    src/bitwardencliinstaller.cpp \
    src/pathhelper.cpp \
    src/runtimecache.cpp \
    src/secretshandler.cpp \
    src/systemauthchecker.cpp \
    src/systemchecker.cpp

polkit.path = /usr/share/polkit-1/actions
polkit.files = polkit/cz.chrastecky.bitsailor.policy

INSTALLS += polkit

DISTFILES += qml/harbour-bitsailor.qml \
    polkit/cz.chrastecky.bitsailor.policy \
    qml/components/MainPageItem.qml \
    qml/components/Toaster.qml \
    qml/cover/CoverPage.qml \
    qml/helpers.js \
    qml/pages/ConfirmSettingPage.qml \
    qml/pages/InstallBitwardenCliPage.qml \
    qml/pages/ItemDetailPage.qml \
    qml/pages/LoginCheckPage.qml \
    qml/pages/LoginPage.qml \
    qml/pages/MainPage.qml \
    qml/pages/MissingBitwardenCliPage.qml \
    qml/pages/MissingRequiredBinaryPage.qml \
    qml/pages/ResetAuthStylePage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/SetupPinPage.qml \
    qml/pages/SetupSystemAuthPage.qml \
    qml/pages/SystemCheckerPage.qml \
    qml/pages/UnknownErrorOccuredPage.qml \
    qml/pages/UnlockVaultPage.qml \
    qml/pages/VaultLoginsPage.qml \
    rpm/harbour-bitsailor.spec \
    rpm/harbour-bitsailor.yaml \
    translations/*.ts \
    harbour-bitsailor.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-bitsailor-cs.ts

HEADERS += \
    src/appsettings.h \
    src/bitwardencli.h \
    src/bitwardencliinstaller.h \
    src/pathhelper.h \
    src/runtimecache.h \
    src/secretshandler.h \
    src/systemauthchecker.h \
    src/systemchecker.h
