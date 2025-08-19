include $(TOPDIR)/rules.mk

PKG_NAME:=ruvname
PKG_VERSION:=$(shell grep 'version = "' $(CURDIR)/../../Cargo.toml | cut -d'"' -f2)
PKG_RELEASE:=1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/ruvcoindev/ruvname.git
PKG_SOURCE_VERSION:=HEAD
PKG_MIRROR_HASH:=skip

PKG_MAINTAINER:=ruvcoindev <admin@ruvcha.in>
PKG_LICENSE:=MIT

# Целевая архитектура (меняется через TARGET_CROSS)
PKG_TARGET:=mipsel-unknown-linux-musl

include $(INCLUDE_DIR)/package.mk

define Package/ruvname
  SECTION:=net
  CATEGORY:=Network
  TITLE:=RUVNAME - RUVchain NAMEspace
  DEPENDS:=+libopenssl +ca-bundle
  URL:=https://ruv.name
endef

define Package/ruvname/description
  Ruvname - децентрализованный DNS и сеть для ruvchain.
  Поддерживает майнинг доменов, DEX, оракулы.
endef

# Подготовка: копируем бинарник, собранный заранее
define Build/Prepare
	mkdir -p $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
	cp $(CURDIR)/../../target/$(PKG_TARGET)/release/ruvname $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/
	cp $(CURDIR)/files/* $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/files/
endef

# Ничего не компилируем — бинарник уже есть
define Build/Compile
	$(CP) $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/ruvname $(PKG_BUILD_DIR)/
endef

# Установка в пакет
define Package/ruvname/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/ruvname $(1)/usr/sbin/ruvname

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/files/etc/init.d/ruvname $(1)/etc/init.d/ruvname

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) $(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)/files/etc/config/ruvname $(1)/etc/config/ruvname

	$(INSTALL_DIR) $(1)/etc/ruvname
	$(INSTALL_DATA) $(CURDIR)/../../ruvname.toml $(1)/etc/ruvname/ruvname.toml.example
endef

$(eval $(call BuildPackage,ruvname))
