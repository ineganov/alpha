

help::
	$(info Top level build targets:)
	$(info `   make help       - show this message)
	$(info `   make distclean  - delete 'build' folder)
	$(info `   make toolchain  - download and build toolchain)
	$(info `   make gem5       - download and build gem5)
	$(info `   make software   - download and build toolchain & gem5)
	$(info )

NPROCS:=1
OS:=$(shell uname -s)

ifeq ($(OS),Linux)
  NPROCS:=$(shell grep -c ^processor /proc/cpuinfo)
endif

include common.mk

#############################################################
# toolchain

DIR_BUILD_PKG  = $(DIR_BUILD)/pkg
CROSSTOOL_TAR_PATH = $(DIR_BUILD_PKG)/$(CROSSTOOL_TAR_NAME)
CROSSTOOL_SRC_PATH = $(DIR_BUILD)/$(CROSSTOOL_VER_NAME)

# download ct-ng
$(CROSSTOOL_TAR_PATH):
	mkdir -p $(DIR_BUILD_PKG)
	wget -O $(CROSSTOOL_TAR_PATH) $(CROSSTOOL_URL_CTNG)

# build a toolchain
$(TOOLCHAIN_PATH): $(CROSSTOOL_TAR_PATH)
	tar -xf $(CROSSTOOL_TAR_PATH) -C $(DIR_BUILD)
	cd $(CROSSTOOL_SRC_PATH) && ./configure --enable-local
	cd $(CROSSTOOL_SRC_PATH) && MAKELEVEL=0 make
	cd $(CROSSTOOL_SRC_PATH) && ./ct-ng $(TOOLCHAIN_NAME)
	cd $(CROSSTOOL_SRC_PATH) && CT_PREFIX=$(abspath $(DIR_BUILD)) ./ct-ng -j$(NPROCS) build

#############################################################
# gem 5 simulator

# download gem5 simulator
$(SIMULATOR_GEM5_SRC):
	cd $(DIR_BUILD) && git clone $(SIMULATOR_GEM5_URL)

# build gem5 simulator
$(SIMULATOR_GEM5_BIN): $(SIMULATOR_GEM5_SRC)
	cd $(SIMULATOR_GEM5_SRC) && scons -j$(NPROCS) $(SIMULATOR_GEM5_BIN)

#############################################################
# commot targets

distclean:
	rm -rf $(DIR_BUILD)

toolchain: $(TOOLCHAIN_PATH)

gem5: $(SIMULATOR_GEM5_BIN)

software: toolchain gem5
