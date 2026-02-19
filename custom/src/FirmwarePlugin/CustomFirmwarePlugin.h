#pragma once

#include "ArduCopterFirmwarePlugin.h"

Q_DECLARE_LOGGING_CATEGORY(SVPFirmwarePluginLog)

/// SVP custom firmware plugin.
///
/// Extends ArduCopter with company-specific behaviour.
/// Add your mission command overrides, flight mode restrictions,
/// custom parameter handling, etc. here.
///
/// Key extension points (all inherited from FirmwarePlugin):
///   - supportedMissionCommands()  — add/remove mission item types in Plan view
///   - updateAvailableFlightModes() — restrict the flight modes exposed in the UI
///   - autopilotPlugin()           — returns CustomAutoPilotPlugin (already overridden below)
///   - missionCommandOverrides()   — path to a JSON file with custom MAV_CMD metadata

class CustomFirmwarePlugin : public ArduCopterFirmwarePlugin
{
    Q_OBJECT

public:
    explicit CustomFirmwarePlugin(QObject *parent = nullptr);

    /// Returns our CustomAutoPilotPlugin so vehicle-setup pages can be customised.
    AutoPilotPlugin *autopilotPlugin(Vehicle *vehicle) const final;

    // TODO: override supportedMissionCommands() to add/remove mission commands
    // TODO: override updateAvailableFlightModes() to restrict flight modes
};
