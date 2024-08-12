
BUILD_DIR = ./build
TARGET := pdf2png
PRODUCT := $(TARGET)
CONFIGURATION := Release
INSTALL_PREFIX := /usr/local/bin
PDF2PNG_VERSION := 1.1.1
LS := ls -lF
ZIP := tar cjvf
ZIP_EXT := tbz
ZIP_LS := tar tvf

BUILT_PRODUCT = $(BUILD_DIR)/$(CONFIGURATION)/$(PRODUCT)
PACKED_PRODUCT = $(BUILD_DIR)/$(TARGET)-$(PDF2PNG_VERSION).$(ZIP_EXT)

.PHONY: all
all: $(BUILT_PRODUCT)

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

$(BUILT_PRODUCT): $(BUILD_DIR)
	xcodebuild -target $(TARGET) -configuration $(CONFIGURATION) build

.PHONY: target
target: $(BUILT_PRODUCT)

.PHONY: clean
clean: clean-build

.PHONY: clean-build
clean-build:
	rm -fr $(BUILD_DIR)

.PHONY: install
install:
	sudo install $(BUILT_PRODUCT) $(INSTALL_PREFIX)

.PHONY: uninstall
uninstall:
	sudo rm $(INSTALL_PREFIX)/$(PRODUCT)

$(PACKED_PRODUCT): $(BUILT_PRODUCT)
	$(ZIP) $(PACKED_PRODUCT) $(BUILT_PRODUCT)
	
.PHONY: pack-port
pack-port: $(PACKED_PRODUCT)
	$(LS) $(PACKED_PRODUCT)
	$(ZIP_LS) $(PACKED_PRODUCT)
