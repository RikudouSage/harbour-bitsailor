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
PKGCONFIG += sailfishsecrets sailfishcrypto
QT += dbus

SOURCES += src/harbour-bitsailor.cpp \
    src/accountmanager.cpp \
    src/appsettings.cpp \
    src/bitwardenapi.cpp \
    src/bitwardencli.cpp \
    src/bitwardencliinstaller.cpp \
    src/cachekey.cpp \
    src/cli-api-common-parts.cpp \
    src/encryptor.cpp \
    src/fileaccessor.cpp \
    src/parsedurl.cpp \
    src/pathhelper.cpp \
    src/random-helper.cpp \
    src/randompingenerator.cpp \
    src/runtimecache.cpp \
    src/secretshandler.cpp \
    src/systemauthchecker.cpp \
    src/systemchecker.cpp \
    otp/onetimepasswordgenerator.cpp \
    src/urlparser.cpp

polkit.path = /usr/share/polkit-1/actions
polkit.files = polkit/cz.chrastecky.bitsailor.policy

bw-logo.path = /usr/share/harbour-bitsailor/icons
bw-logo.files = icons/bw/*

patches.path = /usr/share/harbour-bitsailor/patches
patches.files = patch/*

dbus.path = /usr/share/dbus-1/services
dbus.files = dbus/*

INSTALLS += polkit bw-logo patches dbus

DISTFILES += qml/harbour-bitsailor.qml \
    icons/bw/* \
    polkit/cz.chrastecky.bitsailor.policy \
    patch/* \
    dbus/* \
    qml/components/BottomMenu.qml \
    qml/components/BottomMenuItem.qml \
    qml/components/GeneratePassphraseContent.qml \
    qml/components/GeneratePasswordContent.qml \
    qml/components/GeneratePasswordTabs.qml \
    qml/components/IntValueMenuItem.qml \
    qml/components/MainPageItem.qml \
    qml/components/PercentageCircle.qml \
    qml/components/StringValueMenuItem.qml \
    qml/components/Toaster.qml \
    qml/cover/CoverPage.qml \
    qml/cover/CoverPageCard.qml \
    qml/cover/CoverPageLogin.qml \
    qml/cover/CoverPageLoginTotp.qml \
    qml/cover/CoverPageNote.qml \
    qml/helpers.js \
    qml/pages/CleanupPage.qml \
    qml/pages/ConfirmSettingPage.qml \
    qml/pages/ConfirmStringSettingPage.qml \
    qml/pages/CreateSendChooseTypePage.qml \
    qml/pages/CreateSendPage.qml \
    qml/pages/EditItemPage.qml \
    qml/pages/GeneratePasswordDialog.qml \
    qml/pages/GeneratePasswordPage.qml \
    qml/pages/IgnoreInvalidCertsPage.qml \
    qml/pages/InstallBitwardenCliPage.qml \
    qml/pages/InvalidCertificatePage.qml \
    qml/pages/ItemDetailPage.qml \
    qml/pages/LoginCheckPage.qml \
    qml/pages/LoginPage.qml \
    qml/pages/MainPage.qml \
    qml/pages/MissingBitwardenCliPage.qml \
    qml/pages/MissingRequiredBinaryPage.qml \
    qml/pages/PatchServerPage.qml \
    qml/pages/ResetAuthStylePage.qml \
    qml/pages/SendListPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/SetupPinPage.qml \
    qml/pages/SetupSystemAuthPage.qml \
    qml/pages/SystemCheckerPage.qml \
    qml/pages/UnknownErrorOccuredPage.qml \
    qml/pages/UnlockVaultPage.qml \
    qml/pages/UpdateBitwardenCliPage.qml \
    qml/pages/VaultPage.qml \
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
TRANSLATIONS += translations/harbour-bitsailor-*.ts

HEADERS += \
    src/accountmanager.h \
    src/appsettings.h \
    src/bitwardenapi.h \
    src/bitwardencli.h \
    src/bitwardencliinstaller.h \
    src/cache-keys.h \
    src/cachekey.h \
    src/cli-api-common-parts.h \
    src/encryptor.h \
    src/fileaccessor.h \
    src/parsedurl.h \
    src/pathhelper.h \
    src/random-helper.h \
    src/randompingenerator.h \
    src/runtimecache.h \
    src/secretshandler.h \
    src/systemauthchecker.h \
    src/systemchecker.h \
    otp/onetimepasswordgenerator.h \
    src/urlparser.h
