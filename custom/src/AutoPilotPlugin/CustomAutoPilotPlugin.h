#pragma once

#include "APMAutoPilotPlugin.h"

Q_DECLARE_LOGGING_CATEGORY(SVPAutoPilotPluginLog)

/// SVP custom autopilot plugin.
///
/// Extends APMAutoPilotPlugin to control which vehicle-setup pages are shown.
///
/// To customise setup pages, override vehicleComponents() and filter or extend
/// the list returned by APMAutoPilotPlugin::vehicleComponents().

class CustomAutoPilotPlugin : public APMAutoPilotPlugin
{
    Q_OBJECT

public:
    explicit CustomAutoPilotPlugin(Vehicle *vehicle, QObject *parent = nullptr);

    // TODO: override vehicleComponents() to add / remove setup pages
};
