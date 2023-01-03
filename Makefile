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
# Lua mocks used in test target
MOCKS_REPO			?= https://github.com/fikin/nodemcu-lua-mocks
MOCKS_BRANCH		?= master

.PHONY: all config clean prepare-firmware build build-firmware spiffs-image lfs-image 
.PHONY: test integration-test mock_spiffs_dir flash

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
build: prepare-firmware
	$(MAKE) -C ./vendor/nodemcu-firmware LUA=${X_LUA} all 
	$(MAKE) -f Makefile-spiffs.mk spiffs-image

spiffs-image: prepare-firmware
	$(MAKE) -f Makefile-spiffs.mk spiffs-image

lfs-image: prepare-firmware
	$(MAKE) -f Makefile-spiffs.mk lfs-image

all: prepare-firmware build test

flash:
	@tools/flash_it.sh vendor/nodemcu-firmware/bin/*.bin vendor/nodemcu-firmware/bin/*.img
### testing related

vendor/nodemcu-lua-mocks:
	git clone --branch=${MOCKS_BRANCH} --recursive  ${MOCKS_REPO} vendor/nodemcu-lua-mocks

# only SPIFFS lua files are here (lua_moduesl/*/fs/*lua) + external dependencies
LUA_SPIFFS_PATH				?= $(shell ls -f lua_modules/*/fs/*.lua | xargs -n1 dirname | sort -u | xargs -IA echo "A/?.lua;" | awk '{printf("%s",$$0)}')

LUA_LFS_PATH				?= $(shell ls -f lua_modules/*/lua/*.lua | xargs -n1 dirname | sort -u | xargs -IA echo "A/?.lua;" | awk '{printf("%s",$$0)}')

# only LFS lua files are here (lua_modules/*/lua/*.lua)
NODEMCU_LFS_FILES			?= $(wildcard lua_modules/*/lua/*.lua)

UNIT_TEST_CASES				?= $(wildcard lua_modules/*/test/*est*.lua)
INTEGRATION_TEST_CASES		?= $(wildcard integration-tests/lua/*est*.lua)
# dir containing all SPIFFS files except *.lua/lc
NODEMCU_MOCKS_SPIFFS_DIR   	?=  vendor/tests-spiffs

$(UNIT_TEST_CASES):
	@echo [INFO] : Running tests in $@ ...
	export LUA_PATH="$(LUA_PATH);$(LUA_SPIFFS_PATH);$(LUA_LFS_PATH);vendor/nodemcu-lua-mocks/lua/?.lua" \
		&& export NODEMCU_MOCKS_SPIFFS_DIR="$(NODEMCU_MOCKS_SPIFFS_DIR)" \
		&& export NODEMCU_LFS_FILES="$(NODEMCU_LFS_FILES)" \
		&& lua5.3 $@
.PHONY: $(UNIT_TEST_CASES)

mock_spiffs_dir:
	@mkdir -p $(NODEMCU_MOCKS_SPIFFS_DIR)
	@rm -rf $(NODEMCU_MOCKS_SPIFFS_DIR)/*
	@cp lua_modules/*/lua/* lua_modules/*/fs/* $(NODEMCU_MOCKS_SPIFFS_DIR)/
	@rm -f $(NODEMCU_MOCKS_SPIFFS_DIR)/*.lua
	@rm -f $(NODEMCU_MOCKS_SPIFFS_DIR)/*.lc
	@touch $(NODEMCU_MOCKS_SPIFFS_DIR)/LFS.img

test: vendor/nodemcu-lua-mocks mock_spiffs_dir $(UNIT_TEST_CASES)


##################################

$(INTEGRATION_TEST_CASES):
	@echo [INFO] : Running tests in $@ ...
	export LUA_PATH="$(LUA_PATH);$(LUA_SPIFFS_PATH);vendor/nodemcu-lua-mocks/lua/?.lua" \
		&& export NODEMCU_MOCKS_SPIFFS_DIR="$(NODEMCU_MOCKS_SPIFFS_DIR)" \
		&& export NODEMCU_LFS_FILES="$(NODEMCU_LFS_FILES)" \
		&& lua5.3 $@
.PHONY: $(INTEGRATION_TEST_CASES)

integration-test: vendor/nodemcu-lua-mocks mock_spiffs_dir $(INTEGRATION_TEST_CASES)
