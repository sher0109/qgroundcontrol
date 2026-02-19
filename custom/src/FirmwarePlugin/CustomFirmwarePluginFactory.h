#pragma once

#include "FirmwarePluginFactory.h"
#include "QGCMAVLink.h"

class CustomFirmwarePlugin;

/// Registers CustomFirmwarePlugin as the handler for all ArduPilot vehicles.
/// PX4 is disabled entirely via CustomOverrides.cmake.

class CustomFirmwarePluginFactory : public FirmwarePluginFactory
{
    Q_OBJECT

public:
    explicit CustomFirmwarePluginFactory(QObject *parent = nullptr);

    QList<QGCMAVLink::FirmwareClass_t> supportedFirmwareClasses() const final;
    FirmwarePlugin *firmwarePluginForAutopilot(MAV_AUTOPILOT autopilotType,
                                               MAV_TYPE      vehicleType) final;

private:
    CustomFirmwarePlugin *_pluginInstance = nullptr;
};
