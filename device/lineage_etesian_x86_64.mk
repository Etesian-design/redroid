# x86_64 only, and no ARM translation: only apps with x86_64 code install (as Cloud Companion's image does today).
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)

# The container device: Redroid's (device/redroid, hardware/redroid, vendor/redroid, device/redroid-prebuilts)
$(call inherit-product, device/redroid/redroid_64only.mk)
REDROID_DISABLE_OMX := true
$(call inherit-product, device/redroid/redroid.mk)
$(call inherit-product, device/redroid/redroid_x86_64_only/device.mk)
DEVICE_PACKAGE_OVERLAYS += device/redroid/overlay device/etesian/redroid/overlay
PRODUCT_COPY_FILES += \
    device/redroid/mediacodec.policy.x86:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediacodec.policy
$(call inherit-product, device/redroid-prebuilts/prebuilts_x86.mk)

# LineageOS, then Etesian. A container starts provisioned (overlay) and has no setup wizard.
PRODUCT_NO_SETUPWIZARD := true
# Cloud Companion's bridge drives the phone over adb on TCP 5555 as root: Lineage's userdebug would make it non-debuggable with adb off (persist.sys.usb.config=none).
WITH_ADB_INSECURE := true
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
$(call inherit-product, vendor/etesian/etesian.mk)

PRODUCT_NAME := lineage_etesian_x86_64
PRODUCT_DEVICE := redroid_x86_64_only
PRODUCT_BRAND := Etesian
PRODUCT_MANUFACTURER := Etesian
PRODUCT_MODEL := Etesian (container)
