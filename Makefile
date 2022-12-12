# This makefile is generating NodeMCU firmware and SPIFFS (with included LFS) binaries.

# Ensure "config" is called before running other targets
# Config provides .env-vars which contains instrumentation for firmware and LFS
MAKEFILE_CONFIG := vendor/.env-vars
ifeq ($(filter $(MAKECMDGOALS),config clean),)
    ifeq ($(strip $(wildcard $(MAKEFILE_CONFIG))),)
        $(error Config file '$(MAKEFILE_CONFIG)' does not exist. Please, use 'make config' before)
    else
        ifneq ($(MAKECMDGOALS),config)
            include $(MAKEFILE_CONFIG)
        endif
    endif
endif

# build scripts, used for preparing firmware modules and other options
BUILD_REPO     ?= https://github.com/fikin/nodemcu-custom-build
#		### the repo fork contains more functionality than upstream, use that for now
BUILD_BRANCH   ?= master
# firmware repo
X_REPO         ?= https://github.com/nodemcu/nodemcu-firmware

.PHONY: all config clean prepare-firmware build build-firmware

clean:
	rm -rf $(MAKEFILE_CONFIG)

# clone build scripts
#	you can symlink it manually if you need totally different source code
vendor/nodemcu-custom-build:
	git clone --branch=${BUILD_BRANCH} ${BUILD_REPO} vendor/nodemcu-custom-build

# generate .env-vars our of build.config
vendor/.env-vars: build.config vendor/nodemcu-custom-build 
	@./vendor/nodemcu-custom-build/export-env-vars.sh vendor/.env-vars

config: vendor/.env-vars

# clone firware
#		you can symlink it manually if you need totally different source code
# 	BEWARE local/ and app/include files are being modified !
vendor/nodemcu-firmware:
	git clone --depth=1 --branch=${X_BRANCH} --recursive ${X_REPO} vendor/nodemcu-firmware

# patch firmware files with build.config settings
prepare-firmware: vendor/nodemcu-firmware
	cd ./vendor && ./nodemcu-custom-build/run.sh -before

# build images
#		depends on "prepare-firmware"
# 	compile firmware, then LFS and SPIFFS
# 	result files are located in nodemcu-firmware/bin
build:
	$(MAKE) -C ./vendor/nodemcu-firmware LUA=${X_LUA} all 
#spiffs-image
	$(MAKE) -f Makefile.spiffs spiffs-image

all: prepare-firmware build
