# This makefile is generating NodeMCU firmware and SPIFFS (with included LFS) binaries.

.DEFAULT_GOAL                   := help

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

### building related
# build scripts, used for preparing firmware modules and other options
BUILD_REPO     ?= https://github.com/fikin/nodemcu-custom-build
#		### the repo fork contains more functionality than upstream, use that for now
BUILD_BRANCH   ?= master
# firmware repo
X_REPO         ?= https://github.com/nodemcu/nodemcu-firmware
###

### testing related
# Lua mocks used in test target
MOCKS_REPO			?= https://github.com/fikin/nodemcu-lua-mocks
MOCKS_BRANCH		?= master
# only SPIFFS lua files are here (lua_moduesl/*/fs/*lua) + external dependencies
LUA_SPIFFS_PATH				?= $(shell ls -f lua_modules/*/fs/*.lua | xargs -n1 dirname | sort -u | xargs -IA echo "A/?.lua;" | awk '{printf("%s",$$0)}')
LUA_LFS_PATH				?= $(shell ls -f lua_modules/*/lua/*.lua | xargs -n1 dirname | sort -u | xargs -IA echo "A/?.lua;" | awk '{printf("%s",$$0)}')
# only LFS lua files are here (lua_modules/*/lua/*.lua)
NODEMCU_LFS_FILES			?= $(wildcard lua_modules/*/lua/*.lua)
UNIT_TEST_CASES				?= $(wildcard lua_modules/*/test/*est*.lua)
INTEGRATION_TEST_CASES		?= $(wildcard integration-tests/lua/*est*.lua)
# dir containing all SPIFFS files except *.lua/lc
NODEMCU_MOCKS_SPIFFS_DIR   	?=  vendor/tests-spiffs
###

.PHONY: all config clean prepare-firmware build build-firmware spiffs-image lfs-image 
.PHONY: test integration-test mock_spiffs_dir flash

# clone build scripts
#	you can symlink it manually if you need totally different source code
vendor/nodemcu-custom-build:
	git clone --branch=${BUILD_BRANCH} ${BUILD_REPO} vendor/nodemcu-custom-build

# clone testing mocks
#	you can symlink it manually if you need totally different source code
vendor/nodemcu-lua-mocks:
	git clone --branch=${MOCKS_BRANCH} --recursive  ${MOCKS_REPO} vendor/nodemcu-lua-mocks

# clone firmware
#	you can symlink it manually if you need totally different source code
# 	BEWARE local/ and app/include files are being modified !
vendor/nodemcu-firmware:
	git clone --depth=1 --branch=${X_BRANCH} --recursive ${X_REPO} vendor/nodemcu-firmware

###################

help:  													## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nExample:\n  \033[36mmake test\033[0m\n  Run unit tests.\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
 
clean:
	rm -rf $(MAKEFILE_CONFIG) $(NODEMCU_MOCKS_SPIFFS_DIR) vendor/*.lst vendor/minify

###################

# generate .env-vars our of build.config
vendor/.env-vars: build.config vendor/nodemcu-custom-build 
	@./vendor/nodemcu-custom-build/export-env-vars.sh vendor/.env-vars

config: vendor/.env-vars								## call it FIRST or after build.config change, before prepare-firmware 

###################

prepare-firmware: vendor/nodemcu-firmware				## patch firmware files with build.config settings, no need to call it directly
	@rm -rf ./vendor/nodemcu-firmware/local/fs/*
	@rm -rf ./vendor/nodemcu-firmware/local/lua/*
	cd ./vendor && ./nodemcu-custom-build/run.sh -before

###################

build: prepare-firmware									## builds firmware, SPIFFS and LFS images. Result files are located in nodemcu-firmware/bin and nodemcu-firmware/local/fs/LFS.img.
	$(MAKE) -C ./vendor/nodemcu-firmware LUA=${X_LUA} all spiffs-image
	$(MAKE) -f Makefile-spiffs.mk spiffs-image

spiffs-image: prepare-firmware							## builds only SPIFFS and LFS images. Result files are located in nodemcu-firmware/bin/*.img and nodemcu-firmware/local/fs/LFS.img
	$(MAKE) -f Makefile-spiffs.mk spiffs-image

lfs-image: prepare-firmware								## builds LFS image only. Result file is located in nodemcu-firmware/local/fs/LFS.img.
	$(MAKE) -f Makefile-spiffs.mk lfs-image

all: build test											## builds images and runs unit tests

flash:													## flashes all images from nodemcu-firmware/bin to /dev/ttyUSB0
	@tools/flash_it.sh vendor/nodemcu-firmware/bin/*.bin vendor/nodemcu-firmware/bin/*.img

###################
### unit testing

$(UNIT_TEST_CASES):
	@echo [INFO] : Running tests in $@ ...
	export LUA_PATH="$(LUA_PATH);$(LUA_SPIFFS_PATH);$(LUA_LFS_PATH);vendor/nodemcu-lua-mocks/lua/?.lua" \
		&& export NODEMCU_MOCKS_SPIFFS_DIR="$(NODEMCU_MOCKS_SPIFFS_DIR)" \
		&& export NODEMCU_LFS_FILES="$(NODEMCU_LFS_FILES)" \
		&& lua5.3 $@
.PHONY: $(UNIT_TEST_CASES)

mock_spiffs_dir: 										## prepares vendor/test-spiffs folder, used in running tests
	@mkdir -p $(NODEMCU_MOCKS_SPIFFS_DIR)
	@rm -rf $(NODEMCU_MOCKS_SPIFFS_DIR)/*
	@cp ./vendor/nodemcu-firmware/local/fs/* $(NODEMCU_MOCKS_SPIFFS_DIR)/
	@[ -d ./integration-tests/fs ] && cp ./integration-tests/fs/* $(NODEMCU_MOCKS_SPIFFS_DIR)/ || return 0

test: vendor/nodemcu-lua-mocks mock_spiffs_dir $(UNIT_TEST_CASES)						## runs unit tests


### integration testing

$(INTEGRATION_TEST_CASES):
	@echo [INFO] : Running tests in $@ ...
	export LUA_PATH="$(LUA_PATH);$(LUA_SPIFFS_PATH);vendor/nodemcu-lua-mocks/lua/?.lua" \
		&& export NODEMCU_MOCKS_SPIFFS_DIR="$(NODEMCU_MOCKS_SPIFFS_DIR)" \
		&& export NODEMCU_LFS_FILES="$(NODEMCU_LFS_FILES)" \
		&& lua5.3 $@
.PHONY: $(INTEGRATION_TEST_CASES)

integration-test: vendor/nodemcu-lua-mocks mock_spiffs_dir $(INTEGRATION_TEST_CASES)	## runs integration tests
