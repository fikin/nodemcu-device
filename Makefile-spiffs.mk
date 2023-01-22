## most of these are from nodemcu-firmware/tools/Makefile

## they are here in order to provide lua->lc compilation for SPIFFS
FWDIR				?= ./vendor/nodemcu-firmware

FS_DIR   			?= $(FWDIR)/local/fs
LFS_DIR  			?= $(FWDIR)/local/lua

FS_FILES	 		?= $(patsubst $(FS_DIR)/%,%,$(shell find $(FS_DIR)/ -name '*' '!' -name .gitignore ))

# determine the luac binary
LUAC_CROSS 			?= $(PWD)/$(shell ls $(FWDIR)/luac.cross*)
SPIFFSIMG			?= $(FWDIR)/tools/spiffsimg/spiffsimg

APP_DIR 			= $(FWDIR)/app
OBJDUMP 			= $(shell find $(FWDIR)/tools/toolchains -name \*-objdump)

FLASH_FS_SIZE 		?= $(shell $(CC) -E -dM - <$(APP_DIR)/include/user_config.h | grep SPIFFS_MAX_FILESYSTEM_SIZE | cut -d ' ' -f 3)
ifneq ($(strip $(FLASH_FS_SIZE)),)
FLASHSIZE 			= $(shell printf "0x%x" $(FLASH_FS_SIZE))
endif

FLASH_FS_LOC 		:= $(shell $(CC) -E -dM - <$(APP_DIR)/include/user_config.h | grep SPIFFS_FIXED_LOCATION | cut -d ' ' -f 3)
ifeq ($(strip $(FLASH_FS_LOC)),)
FLASH_FS_LOC 		:= $(shell printf "0x%x" $$((0x$(shell $(OBJDUMP) -t $(APP_DIR)/.output/eagle/debug/image/eagle.app.v6.out |grep " _flash_used_end" |cut -f1 -d" ") - 0x40200000)))
else
FLASH_FS_LOC 		:= $(shell printf "0x%x" $(FLASH_FS_LOC))
endif

.PHONY: docker-deps lfs-lc lfs-image lfs-lst spiffs-lc spiffs-md5 spiffs-lst spiffs-minify spiffs-image

docker-deps:
	docker pull tdewolff/minify

# compile local/lua into local/fs/LFS.img (LFS image)
lfs-lst:
	@rm -f ./vendor/lfs.lst
	@$(foreach f, $(shell cd $(LFS_DIR) && ls *.lc), echo "import $(f)" >> ./vendor/lfs.lst ;)

lfs-lc:
	@rm -f $(LFS_DIR)/*.lc
	@$(foreach f, $(shell cd $(LFS_DIR) && ls *.lua),(cd $(LFS_DIR) && $(LUAC_CROSS) -o $(f:.lua=.lc) $(f)) ;)
	@rm -f $(LFS_DIR)/*.lua

lfs-image: lfs-lc lfs-lst
	@cd $(LFS_DIR) && $(LUAC_CROSS) -f -o ../fs/LFS.img *.lc

# compule local/fs/*.lua to local/fs/*.lc
spiffs-lc:
	@rm -f $(FS_DIR)/*.lc
	@$(foreach f, $(shell cd $(FS_DIR) && ls *.lua),(cd $(FS_DIR) && $(LUAC_CROSS) -o $(f:.lua=.lc) $(f)) ;)
	@rm -f $(FS_DIR)/*.lua

spiffs-md5:
	@rm -f $(FS_DIR)/release
	@$(foreach f, $(FS_FILES), (cd $(FS_DIR) && md5sum $(f) >> release) ;)

spiffs-lst: spiffs-lc lfs-image spiffs-md5
	@rm -f ./vendor/spiffs.lst
	@$(foreach f, $(FS_FILES), echo "import $(FS_DIR)/$(f) $(f)" >> ./vendor/spiffs.lst ;)

spiffs-minify: spiffs-lst
	@docker run -it --rm \
		-v $(PWD)/vendor/minify:/to \
		-v $(PWD)/$(FS_DIR):/from \
		-u $(id -u ${USER}):$(id -g ${USER}) \
		tdewolff/minify -rv -o /to /from
	@cp vendor/minify/*/* $(FS_DIR)/

spiffs-image: spiffs-minify
	$(SPIFFSIMG) -f $(FWDIR)/bin/0x%x-$(FLASHSIZE).img -c $(FLASHSIZE) -U $(FLASH_FS_LOC) -r ./vendor/spiffs.lst -d
