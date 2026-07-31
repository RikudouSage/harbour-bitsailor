#ifndef CLIPBOARDHANDLER_H
#define CLIPBOARDHANDLER_H

#include <QObject>
#include <QClipboard>

#include "appsettings.h"

class ClipboardHandler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString textToClear READ textToClear WRITE setTextToClear NOTIFY textToClearChanged)
public:
    explicit ClipboardHandler(QClipboard *clipboard, AppSettings *settings, QObject *parent = nullptr);
    void clearClipboard();
    Q_INVOKABLE void clearIfMatches(const QString &value);

    QString textToClear();
    void setTextToClear(const QString &value);

signals:
    void textToClearChanged();

public slots:
    void clearOnClose();

private:
    QClipboard *clipboard;
    AppSettings *settings;

    QString mTextToClear;
};

#endif // CLIPBOARDHANDLER_H
