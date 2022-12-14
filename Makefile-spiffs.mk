## most of these are from nodemcu-firmware/tools/Makefile

## they are here in order to provide lua->lc compilation for SPIFFS

FWDIR						?= ./vendor/nodemcu-firmware

FSSOURCE   			?= $(FWDIR)/local/fs
LFSSOURCE  			?= $(FWDIR)/local/lua

SPIFFSFILES 		?= $(patsubst $(FSSOURCE)/%,%,$(shell find $(FSSOURCE)/ -name '*' '!' -name .gitignore '!' -name '*.lua' ))

# determine the luac binary
LUAC_CROSS 			?= $(shell ls $(FWDIR)/luac.cross*)
SPIFFSIMG				?= $(FWDIR)/tools/spiffsimg/spiffsimg

APP_DIR 				= $(FWDIR)/app
OBJDUMP 				= $(shell find $(FWDIR)/tools/toolchains -name \*-objdump)

FLASH_FS_SIZE 	?= $(shell $(CC) -E -dM - <$(APP_DIR)/include/user_config.h | grep SPIFFS_MAX_FILESYSTEM_SIZE | cut -d ' ' -f 3)
ifneq ($(strip $(FLASH_FS_SIZE)),)
FLASHSIZE = $(shell printf "0x%x" $(FLASH_FS_SIZE))
endif

FLASH_FS_LOC := $(shell $(CC) -E -dM - <$(APP_DIR)/include/user_config.h | grep SPIFFS_FIXED_LOCATION | cut -d ' ' -f 3)
ifeq ($(strip $(FLASH_FS_LOC)),)
FLASH_FS_LOC := $(shell printf "0x%x" $$((0x$(shell $(OBJDUMP) -t $(APP_DIR)/.output/eagle/debug/image/eagle.app.v6.out |grep " _flash_used_end" |cut -f1 -d" ") - 0x40200000)))
else
FLASH_FS_LOC := $(shell printf "0x%x" $(FLASH_FS_LOC))
endif

.PHONY: lfs-lc lfs-image spiffs-lc version-json spiffs-lst spiffs-image

# compile local/lua into local/fs/LFS.img (LFS image)
lfs-lc:
	@rm -f $(LFSSOURCE)/*.lc
	@$(foreach f, $(shell ls $(LFSSOURCE)/*.lua), $(LUAC_CROSS) -o $(f:.lua=.lc) $(f) ;)

lfs-image: lfs-lc
	$(LUAC_CROSS) -f -o $(FSSOURCE)/LFS.img $(LFSSOURCE)/*.lc

# compule local/fs/*.lua to local/fs/*.lc
spiffs-lc:
	@rm -f $(FSSOURCE)/*.lc
	@$(foreach f, $(shell ls $(FSSOURCE)/*.lua), $(LUAC_CROSS) -o $(f:.lua=.lc) $(f) ;)

# generate new local/fs/_version.json
version-json:
	@echo '{ "version": "$(shell date +"%FT%T")" }' > $(FSSOURCE)/_sw_version.json

spiffs-lst:
	@rm -f ./vendor/spiffs.lst
	@$(foreach f, $(SPIFFSFILES), echo "import $(FSSOURCE)/$(f) $(f)" >> ./vendor/spiffs.lst ;)

spiffs-image: lfs-image spiffs-lc version-json spiffs-lst
	$(SPIFFSIMG) -f $(FWDIR)/bin/0x%x-$(FLASHSIZE).img -c $(FLASHSIZE) -U $(FLASH_FS_LOC) -r ./vendor/spiffs.lst -d
