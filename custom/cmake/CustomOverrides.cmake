# ============================================================================
# Custom build overrides for SVP GCS
# ============================================================================

# Application branding
set(QGC_APP_NAME        "SVPGCS"                    CACHE STRING "" FORCE)
set(QGC_ORG_NAME        "SVP"                       CACHE STRING "" FORCE)
set(QGC_ORG_DOMAIN      "github.com/sher0109/svp-gcs" CACHE STRING "" FORCE)
set(QGC_APP_DESCRIPTION "SVP Ground Control Station" CACHE STRING "" FORCE)

# Custom AppStream metadata (fixes URL and developer info for AppImage validation)
set(QGC_APPIMAGE_METADATA_PATH "${CMAKE_SOURCE_DIR}/custom/res/deploy/linux/org.mavlink.qgroundcontrol.appdata.xml.in" CACHE FILEPATH "" FORCE)

# Custom AppRun: adds SVPGCS to known binary names (upstream only knows QGroundControl)
set(QGC_APPIMAGE_APPRUN_PATH "${CMAKE_SOURCE_DIR}/custom/res/deploy/linux/AppRun" CACHE FILEPATH "" FORCE)

# Platform icons (add your actual icon files to custom/res/icons/ and uncomment)
# set(QGC_MACOS_ICON_PATH        "${CMAKE_SOURCE_DIR}/custom/res/icons/custom.icns"  CACHE FILEPATH "" FORCE)
# set(QGC_APPIMAGE_ICON_SCALABLE_PATH "${CMAKE_SOURCE_DIR}/custom/res/icons/custom.svg"   CACHE FILEPATH "" FORCE)
# set(QGC_WINDOWS_ICON_PATH      "${CMAKE_SOURCE_DIR}/custom/res/icons/custom.ico"  CACHE FILEPATH "" FORCE)

# ArduPilot only — disable PX4 entirely
set(QGC_DISABLE_PX4_PLUGIN         ON CACHE BOOL "" FORCE)
set(QGC_DISABLE_PX4_PLUGIN_FACTORY ON CACHE BOOL "" FORCE)

# Disable the default APM factory so our CustomFirmwarePluginFactory is used
set(QGC_DISABLE_APM_PLUGIN_FACTORY ON CACHE BOOL "" FORCE)

# APM MAVLink and APM plugin base classes remain enabled (we extend them)
