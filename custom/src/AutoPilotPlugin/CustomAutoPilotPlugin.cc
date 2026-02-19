#include "CustomAutoPilotPlugin.h"
#include "QGCLoggingCategory.h"

QGC_LOGGING_CATEGORY(SVPAutoPilotPluginLog, "svp.AutoPilotPlugin")

CustomAutoPilotPlugin::CustomAutoPilotPlugin(Vehicle *vehicle, QObject *parent)
    : APMAutoPilotPlugin(vehicle, parent)
{
}
