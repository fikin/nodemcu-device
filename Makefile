# This makefile is generating NodeMCU firmware and SPIFFS (with included LFS) binaries.

# Ensure "config" is called before running other targets
# Config provides .env-vars which contains instrumentation for firmware and LFS
MAKEFILE_CONFIG := .env-vars
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

.PHONY: all config clean prepare-firmware build

clean:
	rm -rf $(MAKEFILE_CONFIG)

# clone build scripts
#		# you can symlink it manually if you need totally different source code
nodemcu-custom-build:
	git clone --branch=${BUILD_BRANCH} ${BUILD_REPO} nodemcu-custom-build

# generate .env-vars our of build.config
config: nodemcu-custom-build build.config
	@./nodemcu-custom-build/export-env-vars.sh

# clone firware
nodemcu-firmware:
	#	you can symlink it manually if you need totally different source code
	git clone --depth=1 --branch=${X_BRANCH} --recursive ${X_REPO} nodemcu-firmware

# patch firmware files with build.config settings
prepare-firmware:
	# update firmware headers
	@./nodemcu-custom-build/run.sh -before
	#	prepare firmare/local folders
	#	TODO

build:
	@rm -rf ./nodemcu-firmware/bin/*
	$(MAKE) -C ./nodemcu-firmware LUA=${X_LUA} all spiffs-image
	# result files are located in nodemcu-firmware/bin

all: $(MAKEFILE_CONFIG) nodemcu-firmware prepare-firmware build
