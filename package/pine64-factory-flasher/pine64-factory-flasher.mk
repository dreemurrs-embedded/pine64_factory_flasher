PINE64_FACTORY_FLASHER_VERSION = 0.1
PINE64_FACTORY_FLASHER_SITE = $(BR2_EXTERNAL_P64FACTORY_BR_PATH)/package/pine64-factory-flasher/files
PINE64_FACTORY_FLASHER_SITE_METHOD = local
PINE64_FACTORY_FLASHER_LICENSE = GPL-2.0+

ifeq ($(BR2_PACKAGE_PINE64_FACTORY_FLASHER_EMMC),y)
ifeq ($(call qstrip,$(BR2_PACKAGE_PINE64_FACTORY_FLASHER_EMMC_IMAGE)),)
$(error No eMMC image specified. Check your BR2_PACKAGE_PINE64_FACTORY_FLASHER_EMMC_IMAGE setting)
endif # BR2_PACKAGE_PINE64_FACTORY_FLASHER_EMMC_IMAGE
endif # BR2_PACKAGE_PINE64_FACTORY_FLASHER_EMMC

ifeq ($(BR2_PACKAGE_PINE64_FACTORY_FLASHER_SPI),y)
ifeq ($(call qstrip,$(BR2_PACKAGE_PINE64_FACTORY_FLASHER_SPI_IMAGE)),)
$(error No SPI image specified. Check your BR2_PACKAGE_PINE64_FACTORY_FLASHER_SPI_IMAGE setting)
endif # BR2_PACKAGE_PINE64_FACTORY_FLASHER_SPI_IMAGE
endif # BR2_PACKAGE_PINE64_FACTORY_FLASHER_SPI

ifeq ($(call qstrip,$(BR2_PACKAGE_PINE64_FACTORY_FLASHER_DEVICEINFO)),)
$(error No deviceinfo file specified. Check your BR2_PACKAGE_PINE64_FACTORY_FLASHER_DEVICEINFO setting)
endif # BR2_PACKAGE_PINE64_FACTORY_FLASHER_DEVICEINFO

define PINE64_FACTORY_FLASHER_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm755 $(PINE64_FACTORY_FLASHER_SITE)/flasher.sh \
		$(TARGET_DIR)/usr/bin/pine64-factory-flasher

	$(INSTALL) -Dm755 $(PINE64_FACTORY_FLASHER_SITE)/S99flasher \
		$(TARGET_DIR)/etc/init.d/S99flasher

	# This file holds all information about our device, it is
	# required.
	$(INSTALL) -Dm444 $(BR2_PACKAGE_PINE64_FACTORY_FLASHER_DEVICEINFO) \
		$(TARGET_DIR)/etc/deviceinfo

	# Install images
	# This part here is complicated because if else doesn't seem
	# to work properly here.
	[ "$(BR2_PACKAGE_PINE64_FACTORY_FLASHER_EMMC)" = "y" ] && \
		$(INSTALL) -Dm444 $(BR2_PACKAGE_PINE64_FACTORY_FLASHER_EMMC_IMAGE) \
			$(TARGET_DIR)/root/emmc.img || :
	[ "$(BR2_PACKAGE_PINE64_FACTORY_FLASHER_SPI)" = "y" ] && \
		$(INSTALL) -Dm444 $(BR2_PACKAGE_PINE64_FACTORY_FLASHER_SPI_IMAGE) \
			$(TARGET_DIR)/root/spi.img || :

	# Generate md5 checksum
	[ -f $(TARGET_DIR)/root/emmc.img ] && \
		md5sum $(TARGET_DIR)/root/emmc.img | cut -f 1 -d ' ' > \
		$(TARGET_DIR)/root/emmc.img.md5 || :
	[ -f $(TARGET_DIR)/root/spi.img ] && \
		md5sum $(TARGET_DIR)/root/spi.img | cut -f 1 -d ' ' > \
		$(TARGET_DIR)/root/spi.img.md5 || :

	# Keymap file for devices without a keyboard
	[ "$(BR2_PACKAGE_PINE64_FACTORY_FLASHER_KEYMAP)" = "y" ] && \
		$(INSTALL) -Dm444 $(PINE64_FACTORY_FLASHER_SITE)/vol.bmap \
			$(TARGET_DIR)/vol.bmap || :
endef

$(eval $(generic-package))
