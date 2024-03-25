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
MOCKS_REPO								?= https://github.com/fikin/nodemcu-lua-mocks
MOCKS_BRANCH							?= master
# only SPIFFS lua files are here (lua_moduesl/*/fs/*lua) + external dependencies
LUA_SPIFFS_PATH						?= $(shell ls -f lua_modules/*/fs/*.lua | xargs -n1 dirname | sort -u | xargs -IA echo "A/?.lua;" | awk '{printf("%s",$$0)}')
LUA_LFS_PATH							?= $(shell ls -f lua_modules/*/lua/*.lua | xargs -n1 dirname | sort -u | xargs -IA echo "A/?.lua;" | awk '{printf("%s",$$0)}')
# only LFS lua files are here (lua_modules/*/lua/*.lua)
NODEMCU_LFS_FILES					?= $(wildcard lua_modules/*/lua/*.lua)
UNIT_TEST_CASES						?= $(wildcard lua_modules/*/test/*est*.lua)
INTEGRATION_TEST_CASES		?= $(wildcard integration-tests/lua/*est*.lua)
# dir containing all SPIFFS files except *.lua/lc
NODEMCU_MOCKS_SPIFFS_DIR	?=  vendor/tests-spiffs
###

LUAOPTS										:=

###################

.PHONY: all config clean 
.PHONY: prepare-firmware prepare-firmware-esp32 prepare-firmware-esp8266 
.PHONY: build build-esp32 build-esp8266 
.PHONY: spiffs-image lfs-image 
.PHONY: test integration-test mock_spiffs_dir
.PHONY: flash flash-esp32 flash-esp8266
.PHONY: $(UNIT_TEST_CASES)
.PHONY: $(INTEGRATION_TEST_CASES)

###################
### dependencies and other tools and sources

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

vendor/hererocks:
	@mkdir vendor/hererocks
	curl -sLo vendor/hererocks/hererocks.py https://github.com/mpeterv/hererocks/raw/master/hererocks.py
	python vendor/hererocks/hererocks.py vendor/lua53 -l5.3 -rlatest
	@source vendor/lua53/bin/activate \
		&& luarocks install luacheck \
		&& luarocks install luacov \
		&& luarocks install luacov-console

###################
###

help:  													## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nExample:\n  \033[36mmake test\033[0m\n  Run unit tests.\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
 
clean:													## clears firmware config and mock SPIFFS
	rm -rf $(MAKEFILE_CONFIG) $(NODEMCU_MOCKS_SPIFFS_DIR) vendor/*.lst vendor/minify luacov.stats.* luacov.report.*

###################
### configuring build of firmware

# generate .env-vars our of build.config
vendor/.env-vars: build.config vendor/nodemcu-custom-build 
	@./vendor/nodemcu-custom-build/export-env-vars.sh vendor/.env-vars

config: vendor/.env-vars								## call it FIRST or after build.config change, before prepare-firmware 

###################
### preparing firmware

prepare-firmware-esp32: vendor/nodemcu-firmware
	@mkdir -p vendor/nodemcu-firmware/local/fs vendor/nodemcu-firmware/local/lua
	@cd ./vendor/nodemcu-firmware/ && ./install.sh
	@$(MAKE) -C ./vendor/nodemcu-firmware reconfigure

prepare-firmware-esp8266: vendor/nodemcu-firmware

prepare-firmware: prepare-firmware-$(X_BRANCH_NATURE)	## patch firmware files with build.config settings, no need to call it directly
	@rm -rf ./vendor/nodemcu-firmware/local/fs/*
	@rm -rf ./vendor/nodemcu-firmware/local/lua/*
	cd ./vendor && ./nodemcu-custom-build/run.sh -before

###################
### building and flashing

build-esp32:
	$(MAKE) -C ./vendor/nodemcu-firmware all
	@echo FIXME

build-esp8266:
	$(MAKE) -C ./vendor/nodemcu-firmware LUA=${X_LUA} all spiffs-image
	$(MAKE) -f Makefile-spiffs.mk spiffs-image

build: prepare-firmware	build-$(X_BRANCH_NATURE)		## builds firmware, SPIFFS and LFS images. Result files are located in nodemcu-firmware/bin and nodemcu-firmware/local/fs/LFS.img.

spiffs-image: prepare-firmware							## builds only SPIFFS and LFS images. Result files are located in nodemcu-firmware/bin/*.img and nodemcu-firmware/local/fs/LFS.img
	$(MAKE) -f Makefile-spiffs.mk spiffs-image

lfs-image: prepare-firmware								## builds LFS image only. Result file is located in nodemcu-firmware/local/fs/LFS.img.
	$(MAKE) -f Makefile-spiffs.mk lfs-image

all: build test											## builds images and runs unit tests

flash-esp32:
	@echo FIXME

flash-esp8266:
	@tools/flash_it.sh vendor/nodemcu-firmware/bin/*.bin vendor/nodemcu-firmware/bin/*.img

flash:	flash-$(X_BRANCH_NATURE)						## flashes all images from nodemcu-firmware/bin to /dev/ttyUSB0

###################
### unit testing

$(UNIT_TEST_CASES):
	@echo [INFO] : Running tests in $@ ...
	export LUA_PATH="$(LUA_PATH);$(LUA_SPIFFS_PATH);$(LUA_LFS_PATH);vendor/nodemcu-lua-mocks/lua/?.lua" \
		&& export NODEMCU_MOCKS_SPIFFS_DIR="$(NODEMCU_MOCKS_SPIFFS_DIR)" \
		&& export NODEMCU_LFS_FILES="$(NODEMCU_LFS_FILES)" \
		&& export PATH="vendor/lua53/bin:${PATH}" \
		&& lua -lluacov $@
# difference with integration tests is presence of LUA_LFS_PATH in lua path, integration tests simulate node.LFS better while unit tests not.

mock_spiffs_dir: 										## prepares vendor/test-spiffs folder, used in running tests
	@mkdir -p $(NODEMCU_MOCKS_SPIFFS_DIR)
	@rm -rf $(NODEMCU_MOCKS_SPIFFS_DIR)/*
	@cp ./vendor/nodemcu-firmware/local/fs/* $(NODEMCU_MOCKS_SPIFFS_DIR)/
	@touch $(NODEMCU_MOCKS_SPIFFS_DIR)/LFS.img
	@[ -d ./integration-tests/fs ] && cp ./integration-tests/fs/* $(NODEMCU_MOCKS_SPIFFS_DIR)/ || return 0

test: vendor/nodemcu-lua-mocks mock_spiffs_dir $(UNIT_TEST_CASES) coverage	## runs unit tests

###################
### integration testing

$(INTEGRATION_TEST_CASES):
	@echo [INFO] : Running tests in $@ ...
	export LUA_PATH="$(LUA_PATH);$(LUA_SPIFFS_PATH);vendor/nodemcu-lua-mocks/lua/?.lua" \
		&& export NODEMCU_MOCKS_SPIFFS_DIR="$(NODEMCU_MOCKS_SPIFFS_DIR)" \
		&& export NODEMCU_LFS_FILES="$(NODEMCU_LFS_FILES)" \
		&& export PATH="vendor/lua53/bin:${PATH}" \
		&& lua -lluacov $@

integration-test: vendor/nodemcu-lua-mocks mock_spiffs_dir $(INTEGRATION_TEST_CASES) coverage	## runs integration tests

###################
### linting

lint/%: vendor/hererocks
	@echo [INFO] : Running lint for $@ ...
	@export PATH="vendor/lua53/bin:${PATH}" \
		&& luacheck $(LUAOPTS) "${*}"

lint-lua: ${NODEMCU_LFS_FILES:%=lint/%}									## lint all source files

lint-test: LUAOPTS = -g																	# disable globals related linting rules
lint-test: ${UNIT_TEST_CASES:%=lint/%} ${INTEGRATION_TEST_CASES:%=lint/%}	## lint all test files

lint: vendor/hererocks lint-lua lint-test 							## lint all lua files

###################
### coverage report

coverage:		## prints coverage report, collected when running unit and integration tests
	export export PATH="vendor/lua53/bin:${PATH}" \
		&& luacov-console lua_modules -s

###################
