include $(TOPDIR)/rules.mk

PKG_NAME:=ruvname
PKG_VERSION:=$(shell grep 'version = "' Cargo.toml | cut -d'"' -f2)
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ruvcoindev/ruvname.git
PKG_SOURCE_VERSION:=HEAD
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=ruvcoindev <admin@ruvcha.in>
PKG_LICENSE:=MIT

include $(INCLUDE_DIR)/package.mk

define Package/ruvname
  SECTION:=net
  CATEGORY:=Network
  TITLE:=RUVNAME - RUVchain NAMEspace
  DEPENDS:=+libopenssl +ca-bundle
endef

define Package/ruvname/description
  Ruvname - RUVchain NAMEspace
endef

define Build/Prepare
	mkdir -p $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
	$(CP) ./src/* $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/
endef

define Build/Compile
	$(TARGET_CC) $(TARGET_CFLAGS) -o $(PKG_BUILD_DIR)/ruvname $(PKG_BUILD_DIR)/ruvname.c
endef

define Package/ruvname/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ruvname $(1)/usr/sbin/ruvname
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/ruvname $(1)/etc/init.d/ruvname
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/etc/config/ruvname $(1)/etc/config/ruvname
endef

$(eval $(call BuildPackage,ruvname))
