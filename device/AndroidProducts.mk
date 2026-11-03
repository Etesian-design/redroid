# Etesian in a container: LineageOS with the Etesian experience, run like Redroid (one Docker container, no VM).
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/etesian_redroid_x86_64.mk

COMMON_LUNCH_CHOICES := \
    etesian_redroid_x86_64-bp2a-userdebug
