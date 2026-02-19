#include "CustomPlugin.h"
#include "AppSettings.h"
#include "BrandImageSettings.h"
#include "QGCLoggingCategory.h"
#include "QGCMAVLink.h"

#include <QtCore/QApplicationStatic>
#include <QtCore/QFile>
#include <QtQml/QQmlApplicationEngine>

QGC_LOGGING_CATEGORY(CustomLog, "svp.CustomPlugin")

Q_APPLICATION_STATIC(CustomPlugin, _customPluginInstance)

// ---------------------------------------------------------------------------
// CustomFlyViewOptions
// ---------------------------------------------------------------------------

CustomFlyViewOptions::CustomFlyViewOptions(CustomOptions *options, QObject *parent)
    : QGCFlyViewOptions(options, parent)
{
}

// ---------------------------------------------------------------------------
// CustomOptions
// ---------------------------------------------------------------------------

CustomOptions::CustomOptions(CustomPlugin *plugin, QObject *parent)
    : QGCOptions(parent)
    , _flyViewOptions(new CustomFlyViewOptions(this, this))
{
    Q_UNUSED(plugin)
}

// ---------------------------------------------------------------------------
// CustomPlugin
// ---------------------------------------------------------------------------

CustomPlugin::CustomPlugin(QObject *parent)
    : QGCCorePlugin(parent)
    , _options(new CustomOptions(this, this))
{
    qCDebug(CustomLog) << "SVP CustomPlugin created";
}

QGCCorePlugin *CustomPlugin::instance()
{
    return _customPluginInstance();
}

void CustomPlugin::cleanup()
{
    if (_qmlEngine && _interceptor) {
        _qmlEngine->removeUrlInterceptor(_interceptor);
    }
    delete _interceptor;
    _interceptor = nullptr;
}

bool CustomPlugin::overrideSettingsGroupVisibility(const QString &name)
{
    // Hide the "Brand Image" settings page — branding is fixed to SVP assets.
    if (name == BrandImageSettings::name) {
        return false;
    }
    return true;
}

void CustomPlugin::adjustSettingMetaData(const QString &settingsGroup,
                                         FactMetaData   &metaData,
                                         bool           &visible)
{
    QGCCorePlugin::adjustSettingMetaData(settingsGroup, metaData, visible);

    if (settingsGroup == AppSettings::settingsGroup) {
        // Lock offline planning to ArduPilot / MultiRotor so the Plan view
        // never asks the user to pick firmware or vehicle type.
        if (metaData.name() == AppSettings::offlineEditingFirmwareClassName) {
            metaData.setRawDefaultValue(QGCMAVLink::FirmwareClassArduPilot);
            visible = false;
        } else if (metaData.name() == AppSettings::offlineEditingVehicleClassName) {
            metaData.setRawDefaultValue(QGCMAVLink::VehicleClassMultiRotor);
            visible = false;
        }
    }
}

QQmlApplicationEngine *CustomPlugin::createQmlApplicationEngine(QObject *parent)
{
    _qmlEngine   = QGCCorePlugin::createQmlApplicationEngine(parent);
    _interceptor = new CustomOverrideInterceptor();
    _qmlEngine->addUrlInterceptor(_interceptor);
    return _qmlEngine;
}

// ---------------------------------------------------------------------------
// CustomOverrideInterceptor
// ---------------------------------------------------------------------------

QUrl CustomOverrideInterceptor::intercept(const QUrl &url,
                                           QQmlAbstractUrlInterceptor::DataType type)
{
    if ((type == QQmlAbstractUrlInterceptor::QmlFile ||
         type == QQmlAbstractUrlInterceptor::UrlString) &&
        url.scheme() == QStringLiteral("qrc"))
    {
        const QString overridePath = QStringLiteral(":/Custom%1").arg(url.path());
        if (QFile::exists(overridePath)) {
            QUrl result;
            result.setScheme(QStringLiteral("qrc"));
            result.setPath('/' + overridePath.mid(2));
            return result;
        }
    }
    return url;
}
