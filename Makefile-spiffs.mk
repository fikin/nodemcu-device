## most of these are from nodemcu-firmware/tools/Makefile

## they are here in order to provide lua->lc compilation for SPIFFS
FWDIR				?= ./vendor/nodemcu-firmware

FS_DIR   			?= $(FWDIR)/local/fs
LFS_DIR  			?= $(FWDIR)/local/lua

FS_FILES	 		?= $(patsubst $(FS_DIR)/%,%,$(shell find $(FS_DIR)/ -name '*' '!' -name .gitignore ))

#############################
### branch specific settings
ifeq ($(strip $(X_BRANCH_NATURE)),esp8266) ### ESP8266 specific settings

APP_DIR 			= $(FWDIR)/app

LFS_SIZE_TMP 		?= $(shell $(CC) -E -dM - <$(APP_DIR)/include/user_config.h | grep SPIFFS_MAX_FILESYSTEM_SIZE | cut -d ' ' -f 3)
ifneq ($(strip $(LFS_SIZE_TMP)),)
LFS_SIZE 			= $(shell printf "0x%x" $(LFS_SIZE_TMP))
endif

LFS_LOC 			?= $(shell $(CC) -E -dM - <$(APP_DIR)/include/user_config.h | grep SPIFFS_FIXED_LOCATION | cut -d ' ' -f 3)
ifeq ($(strip $(LFS_LOC)),)
OBJDUMP 			= $(shell find $(FWDIR)/tools/toolchains -name \*-objdump)
LFS_LOC 			:= $(shell printf "0x%x" $$((0x$(shell $(OBJDUMP) -t $(APP_DIR)/.output/eagle/debug/image/eagle.app.v6.out |grep " _flash_used_end" |cut -f1 -d" ") - 0x40200000)))
else
LFS_LOC 			:= $(shell printf "0x%x" $(LFS_LOC))
endif

LUAC_CROSS 			?= $(PWD)/$(FWDIR)/luac.cross
SPIFFSIMG			?= $(FWDIR)/tools/spiffsimg/spiffsimg

#############################
else	### ESP32 specific settings

LUAC_CROSS 			?= $(PWD)/$(FWDIR)/build/luac_cross/luac.cross
SPIFFSIMG			?= $(FWDIR)/sdk/esp32-esp-idf/components/spiffs/spiffsgen.py

SPIFFS_SIZE			?= $(shell grep spiffs $(FWDIR)/components/platform/partitions.csv | awk -F, '{printf $$5}')

#############################
endif ### end of branch nature settings

.PHONY: docker-deps 
.PHONY: lfs-lc lfs-image lfs-lst 
.PHONY: spiffs-lc spiffs-md5 spiffs-lst spiffs-minify 
.PHONY: spiffs-image spiffs-image-esp8266 spiffs-image-esp32

# minifies static files in SPIFFS
docker-deps:
	docker pull tdewolff/minify

# compile local/lua into local/fs/LFS.img (LFS image)
lfs-lc:
	@rm -f $(LFS_DIR)/*.lc
	@$(foreach f, $(shell cd $(LFS_DIR) && ls *.lua),(cd $(LFS_DIR) && $(LUAC_CROSS) -o $(f:.lua=.lc) $(f)) ;)
	@rm -f $(LFS_DIR)/*.lua

lfs-lst:
	@rm -f ./vendor/lfs.lst
	@$(foreach f, $(shell cd $(LFS_DIR) && ls *.lc), echo "import $(f)" >> ./vendor/lfs.lst ;)

lfs-image: lfs-lc lfs-lst
	@cd $(LFS_DIR) && $(LUAC_CROSS) -f -o $(PWD)/$(FS_DIR)/LFS.img *.lc

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

spiffs-image-esp32:
	$(SPIFFSIMG) $(SPIFFS_SIZE) $(FS_DIR) $(FWDIR)/build/spiffs.img 

spiffs-image-esp8266: 
	$(SPIFFSIMG) -f $(FWDIR)/bin/0x%x-$(LFS_SIZE).img -c $(LFS_SIZE) -U $(LFS_LOC) -r ./vendor/spiffs.lst -d

spiffs-image: spiffs-minify spiffs-image-$(X_BRANCH_NATURE)
