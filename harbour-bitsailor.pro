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
CONFIG += sailfishapp c++20
PKGCONFIG += sailfishsecrets sailfishcrypto
QT += dbus concurrent

GO_LIBDIR = /usr/share/$$TARGET/lib
INCLUDEPATH += $$PWD/core
LIBS += -L$$PWD/core -lbw
QMAKE_RPATHDIR += $$GO_LIBDIR
libbw.path = $$GO_LIBDIR
libbw.files = $$PWD/core/libbw.so
INSTALLS += libbw

harbour_store {
    DEFINES += HARBOUR_STORE
    DEFINES += BITSAILOR_STORE_BUILD=1
} else {
    polkit.path = /usr/share/polkit-1/actions
    polkit.files = polkit/cz.chrastecky.bitsailor.policy

    dbus.path = /usr/share/dbus-1/services
    dbus.files = dbus/*

    INSTALLS += polkit dbus
}

bw-logo.path = /usr/share/harbour-bitsailor/icons
bw-logo.files = icons/bw/*

INSTALLS += bw-logo

SOURCES += src/harbour-bitsailor.cpp \
    src/appsettings.cpp \
    src/bitsailorcore.cpp \
    src/cachekey.cpp \
    src/clipboardhandler.cpp \
    src/encryptor.cpp \
    src/fileaccessor.cpp \
    src/parsedurl.cpp \
    src/random-helper.cpp \
    src/randompingenerator.cpp \
    src/secretshandler.cpp \
    src/systemauthchecker.cpp \
    otp/onetimepasswordgenerator.cpp \
    src/urlparser.cpp \
    src/runtimecache.cpp

DISTFILES += qml/harbour-bitsailor.qml \
    icons/bw/* \
    polkit/cz.chrastecky.bitsailor.policy \
    dbus/* \
    qml/components/BottomMenu.qml \
    qml/components/BottomMenuItem.qml \
    qml/components/GeneratePassphraseContent.qml \
    qml/components/GeneratePasswordContent.qml \
    qml/components/GeneratePasswordSections.qml \
    qml/components/GeneratePasswordTabs.qml \
    qml/components/IntValueMenuItem.qml \
    qml/components/MainPageItem.qml \
    qml/components/PercentageCircle.qml \
    qml/components/StringValueMenuItem.qml \
    qml/components/Toaster.qml \
    qml/cover/CoverPage.qml \
    qml/helpers.js \
    qml/pages/CleanupPage.qml \
    qml/pages/ConfirmOptionsSettingPage.qml \
    qml/pages/ConfirmSettingPage.qml \
    qml/pages/ConfirmStringSettingPage.qml \
    qml/pages/CreateSendChooseTypePage.qml \
    qml/pages/CreateSendPage.qml \
    qml/pages/EditItemPage.qml \
    qml/pages/GeneratePasswordDialog.qml \
    qml/pages/GeneratePasswordPage.qml \
    qml/pages/IgnoreInvalidCertsPage.qml \
    qml/pages/InvalidCertificatePage.qml \
    qml/pages/ItemDetailPage.qml \
    qml/pages/LoginCheckPage.qml \
    qml/pages/LoginPage.qml \
    qml/pages/MainPage.qml \
    qml/pages/ResetAuthStylePage.qml \
    qml/pages/SendListPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/SetupPinPage.qml \
    qml/pages/SetupSystemAuthPage.qml \
    qml/pages/UnlockVaultPage.qml \
    qml/pages/VaultPage.qml \
    rpm/harbour-bitsailor.spec \
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
    src/appsettings.h \
    src/bitsailorcore.h \
    src/cache-keys.h \
    src/cachekey.h \
    src/clipboardhandler.h \
    src/consts.h \
    src/encryptor.h \
    src/fileaccessor.h \
    src/parsedurl.h \
    src/random-helper.h \
    src/randompingenerator.h \
    src/secretshandler.h \
    src/systemauthchecker.h \
    otp/onetimepasswordgenerator.h \
    src/urlparser.h \
    core/libbw.h \
    core/bw_common.h \
    core/bw_errors.h \
    core/bw_generator.h \
    core/bw_item.h \
    core/bw_send.h \
    core/bw_notifications.h \
    src/runtimecache.h
