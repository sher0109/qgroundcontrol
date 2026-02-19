#include "CustomFirmwarePlugin.h"
#include "CustomAutoPilotPlugin.h"
#include "QGCLoggingCategory.h"

QGC_LOGGING_CATEGORY(SVPFirmwarePluginLog, "svp.FirmwarePlugin")

CustomFirmwarePlugin::CustomFirmwarePlugin(QObject *parent)
    : ArduCopterFirmwarePlugin(parent)
{
}

AutoPilotPlugin *CustomFirmwarePlugin::autopilotPlugin(Vehicle *vehicle) const
{
    return new CustomAutoPilotPlugin(vehicle, nullptr);
}
