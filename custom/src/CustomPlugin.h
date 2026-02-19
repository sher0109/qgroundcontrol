#pragma once

#include <QtQml/QQmlAbstractUrlInterceptor>

#include "QGCCorePlugin.h"
#include "QGCOptions.h"

class CustomOptions;
class CustomPlugin;
class QQmlApplicationEngine;

Q_DECLARE_LOGGING_CATEGORY(CustomLog)

// ---------------------------------------------------------------------------

class CustomFlyViewOptions : public QGCFlyViewOptions
{
    Q_OBJECT
public:
    explicit CustomFlyViewOptions(CustomOptions *options, QObject *parent = nullptr);
};

// ---------------------------------------------------------------------------

class CustomOptions : public QGCOptions
{
    Q_OBJECT
public:
    explicit CustomOptions(CustomPlugin *plugin, QObject *parent = nullptr);

    QGCFlyViewOptions *flyViewOptions() const final { return _flyViewOptions; }

private:
    CustomFlyViewOptions *_flyViewOptions = nullptr;
};

// ---------------------------------------------------------------------------

class CustomPlugin : public QGCCorePlugin
{
    Q_OBJECT
public:
    explicit CustomPlugin(QObject *parent = nullptr);

    static QGCCorePlugin *instance();

    // QGCCorePlugin overrides
    void        cleanup() final;
    QGCOptions *options() final { return _options; }

    // Branding: paths inside custom.qrc (/custom/img prefix)
    QString brandImageIndoor()  const final { return QStringLiteral("/custom/img/logo-dark.svg");  }
    QString brandImageOutdoor() const final { return QStringLiteral("/custom/img/logo-light.svg"); }

    bool overrideSettingsGroupVisibility(const QString &name) final;
    void adjustSettingMetaData(const QString &settingsGroup, FactMetaData &metaData, bool &visible) final;
    QQmlApplicationEngine *createQmlApplicationEngine(QObject *parent) final;

private:
    CustomOptions         *_options     = nullptr;
    QQmlApplicationEngine *_qmlEngine   = nullptr;
    class CustomOverrideInterceptor *_interceptor = nullptr;
};

// ---------------------------------------------------------------------------
// Transparent QML file override:
//   any qrc:/some/file.qml is silently replaced by qrc:/Custom/some/file.qml
//   if that path exists in custom.qrc.  Works for Image sources too.
// ---------------------------------------------------------------------------

class CustomOverrideInterceptor : public QQmlAbstractUrlInterceptor
{
public:
    QUrl intercept(const QUrl &url, QQmlAbstractUrlInterceptor::DataType type) final;
};
