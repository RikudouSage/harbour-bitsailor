#include "clipboardhandler.h"

#include <QClipboard>
#include <QGuiApplication>
#include <QDebug>

ClipboardHandler::ClipboardHandler(QClipboard *clipboard, AppSettings *settings, QObject *parent)
    : QObject(parent), clipboard(clipboard), settings(settings)
{
}

void ClipboardHandler::clearClipboard()
{
    clipboard->clear();
#ifdef QT_DEBUG
    qDebug() << "Clipboard cleared";
#endif
}

void ClipboardHandler::clearIfMatches(const QString &value)
{
    if (clipboard->text() != value) {
#ifdef QT_DEBUG
        qDebug() << "The clipboard text does not equal to the expected one";
#endif
        return;
    }


#ifdef QT_DEBUG
        qDebug() << "The clipboard text equals the expected one";
#endif
    clearClipboard();
}

QString ClipboardHandler::textToClear()
{
    return mTextToClear;
}

void ClipboardHandler::setTextToClear(const QString &value)
{
    if (value == mTextToClear) {
        return;
    }

    mTextToClear = value;
    emit textToClearChanged();
}

void ClipboardHandler::clearOnClose()
{
    if (!settings->clearClipboardOnClosing()) {
#ifdef QT_DEBUG
        qDebug() << "Clearing clipboard on close disabled";
#endif
        return;
    }

#ifdef QT_DEBUG
    qDebug() << "Clearing clipboard on close";
#endif
    clearIfMatches(textToClear());
}
