#include "CustomFirmwarePluginFactory.h"
#include "CustomFirmwarePlugin.h"
#include "QGCMAVLink.h"

CustomFirmwarePluginFactory::CustomFirmwarePluginFactory(QObject *parent)
    : FirmwarePluginFactory(parent)
{
}

QList<QGCMAVLink::FirmwareClass_t> CustomFirmwarePluginFactory::supportedFirmwareClasses() const
{
    return { QGCMAVLink::FirmwareClassArduPilot };
}

FirmwarePlugin *CustomFirmwarePluginFactory::firmwarePluginForAutopilot(MAV_AUTOPILOT autopilotType,
                                                                         MAV_TYPE      vehicleType)
{
    Q_UNUSED(vehicleType)

    if (QGCMAVLink::firmwareClass(autopilotType) == QGCMAVLink::FirmwareClassArduPilot) {
        if (!_pluginInstance) {
            _pluginInstance = new CustomFirmwarePlugin(this);
        }
        return _pluginInstance;
    }

    return nullptr;
}
