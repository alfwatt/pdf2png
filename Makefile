
BUILD = build
TARGET := pdf2png
PRODUCT := $(TARGET)
CONFIGURATION := Release
INSTALL_PREFIX := /usr/local/bin

.PHONY: build
build:
	xcodebuild -target $(TARGET) -configuration $(CONFIGURATION) build

.PHONY: clean
clean: clean-build

.PHONY: clean-build
clean-build:
	rm -fr $(BUILD)

.PHONY: install
install:
	sudo install $(BUILD)/$(CONFIGURATION)/$(PRODUCT) $(INSTALL_PREFIX)

.PHONY: uninstall
uninstall:
	sudo rm $(INSTALL_PREFIX)/$(PRODUCT)