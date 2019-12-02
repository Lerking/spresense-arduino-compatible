#
# Makefile for creating Arduino boards manager package
#

ifeq ($(V),1)
export Q :=
else
ifeq ($(V),2)
export Q :=
else
export Q := @
endif
endif

BASE_VERSION       = $(shell cat tools/version)
VERSION           ?= $(shell echo $(BASE_VERSION) | cut -d "." -f -2).$(shell expr $(shell echo $(BASE_VERSION) | cut -d "." -f 3) + 1)
RELEASE_NAME       = v$(VERSION)
VERSION_PATTERN    = ^[0-9]{1}.[0-9]{1}.[0-9]+$$

OUT               ?= out
INSTALLED_VERSION  = 1.0.0
ARCHIVEDIR         = $(OUT)/staging/packages
SPR_LIBRARY        = $(ARCHIVEDIR)/spresense-$(RELEASE_NAME).tar.gz
SPR_SDK            = $(ARCHIVEDIR)/spresense-sdk-$(RELEASE_NAME).tar.gz
SPR_TOOLS          = $(ARCHIVEDIR)/spresense-tools-$(RELEASE_NAME).tar.gz
PWD                = $(shell pwd)

BOARD_MANAGER_URL ?= https://github.com/sonydevworld/spresense-arduino-compatible/releases/download/generic/package_spresense_index.json
JSON_NAME          = package_spresense_index.json
INSTALL_JSON       = $(OUT)/$(JSON_NAME)
TEMP_JSON          = /tmp/$(JSON_NAME)

SDK_PREBUILT_OUT  ?= tools/out
SDK_PREBUILTS     := $(shell ls $(SDK_PREBUILT_OUT)/*.zip 2> /dev/null | sed s/$$/\'/ | sed s/^/\'/)

.phony: check packages clean

packages: check $(SPR_LIBRARY) $(SPR_SDK) $(SPR_TOOLS) $(INSTALL_JSON)
	$(Q) echo "Done."

check:
	$(Q) echo $(VERSION) | grep -E $(VERSION_PATTERN) > /dev/null \
		|| (echo "ERROR: Invalid version name $(VERSION) (expected pattern is x.y.z)." &&  exit 1)

prebuilt:
	$(Q) if [ "$(SDK_PREBUILTS)" ]; then \
			./tools/prepare_arduino.sh -p; \
			for PREBUILT_ZIP in $(SDK_PREBUILTS); \
			do \
				./tools/sdk_import.sh $${PREBUILT_ZIP}; \
			done \
	fi

$(INSTALL_JSON):
	$(Q) wget $(BOARD_MANAGER_URL) -O $(TEMP_JSON)
	$(Q) tools/python/update_package_json.py -a $(ARCHIVEDIR) -i $(TEMP_JSON) -o $@ -v $(VERSION) -b $(BASE_VERSION)
	$(Q) rm $(TEMP_JSON)

$(SPR_LIBRARY): $(ARCHIVEDIR)
	$(Q) echo "Creating spresense.tar.gz ..."
	$(Q) tar -C Arduino15/packages/SPRESENSE/hardware/spresense/ -czf $@ $(INSTALLED_VERSION)

$(SPR_SDK): $(ARCHIVEDIR)
	$(Q) if [ -d Arduino15/packages/SPRESENSE/tools/spresense-sdk ]; then \
		echo "Creating spresense-sdk.tar.gz ..."; \
		tar -C Arduino15/packages/SPRESENSE/tools/spresense-sdk/ -czf $@ $(INSTALLED_VERSION); \
	fi

$(SPR_TOOLS): $(ARCHIVEDIR)
	$(Q) echo "Creating spresense-tools.tar.gz ..."
	$(Q) tar -C Arduino15/packages/SPRESENSE/tools/spresense-tools/ -czf $@ $(INSTALLED_VERSION)

$(OUT):
	$(Q) mkdir -p $@

$(ARCHIVEDIR): $(OUT)
	$(Q) mkdir -p $@

clean:
	$(Q) -rm -rf $(OUT)

