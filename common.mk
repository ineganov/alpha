
# config start

DIR_TOP  := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
DIR_MAKE ?= $(DIR_TOP)

DIR_BUILD = $(abspath $(DIR_TOP)/build)

CROSSTOOL_VER_NAME = crosstool-ng-1.23.0
CROSSTOOL_TAR_NAME = $(CROSSTOOL_VER_NAME).tar.xz
CROSSTOOL_URL_CTNG = http://crosstool-ng.org/download/crosstool-ng/$(CROSSTOOL_TAR_NAME)

TOOLCHAIN_NAME = alphaev67-unknown-linux-gnu
TOOLCHAIN_PATH = $(DIR_BUILD)/$(TOOLCHAIN_NAME)

SIMULATOR_GEM5_URL = https://gem5.googlesource.com/public/gem5
SIMULATOR_GEM5_SRC = $(DIR_BUILD)/gem5
SIMULATOR_GEM5_BIN = $(DIR_BUILD)/gem5/build/ALPHA/gem5.opt

# config end

#############################################################
# help

help::
	$(info Program level build targets (run in program dir))
	$(info `   make help     - show this message)
	$(info `   make hex      - compile program and create memory image)
	$(info `   make image    - copy memory image to Quartus project folder)
	$(info `   make clean    - delete all the created objects)
	$(info `   make all      - compile, disasm, create hex )
	$(info `   make rebuild  - the same as 'clean' and 'all')
	$(info `   make log      - run simulation in Modelsim (console mode))
	$(info `   make sim      - run simulation in Modelsim (gui mode))
	$(info `   make gem5_run - run simulation in Gem5)
	$(info `   make gem5_log - run simulation in Gem5 and create a golden log)
	$(info `   make diff     - compare Modelsim log and golden log)
	$(info )
	$(info Open and read the Makefile for details)
	@true

#############################################################
# common compilation targets (run in program dir)

LOCAL_GCC_PREFIX ?= $(TOOLCHAIN_PATH)/bin/$(TOOLCHAIN_NAME)

LOCAL_AS    = $(LOCAL_GCC_PREFIX)-as
LOCAL_CC    = $(LOCAL_GCC_PREFIX)-gcc
LOCAL_LD    = $(LOCAL_GCC_PREFIX)-ld
LOCAL_ODUMP = $(LOCAL_GCC_PREFIX)-objdump
LOCAL_OCOPY = $(LOCAL_GCC_PREFIX)-objcopy

PROGRAM_ELF   ?=
PROGRAM_NAME  ?= $(basename $(PROGRAM_ELF))
PROGRAM_LST   ?= $(PROGRAM_NAME).lst
PROGRAM_HEX   ?= $(PROGRAM_NAME).hex
PROGRAM_BIN   ?= $(PROGRAM_NAME).bin
PROGRAM_HEX64 ?= $(PROGRAM_NAME).hex64

$(PROGRAM_LST): $(PROGRAM_ELF)
	$(LOCAL_ODUMP) -S $(PROGRAM_ELF) > $(PROGRAM_LST)

$(PROGRAM_HEX): $(PROGRAM_ELF)
	$(LOCAL_OCOPY) -I elf64-alpha -O verilog $(PROGRAM_ELF) $(PROGRAM_HEX)

$(PROGRAM_BIN): $(PROGRAM_ELF)
	$(LOCAL_OCOPY) -I elf64-alpha -O binary $(PROGRAM_ELF) $(PROGRAM_BIN)

$(PROGRAM_HEX64): $(PROGRAM_BIN)
	# not the best way to get hex64, but works
	echo @00000000 >$(PROGRAM_HEX64)
	od -tx8 -v -An $(PROGRAM_BIN) >> $(PROGRAM_HEX64)

hex: $(PROGRAM_HEX) $(PROGRAM_HEX64)

image: $(PROGRAM_HEX64)
	cp $(PROGRAM_HEX64) $(DIR_TOP)/board/image/bram.hex64

clean:
	rm -f $(PROGRAM_ELF) 
	rm -f *.lst *.hex *.hex64 *.bin *.o
	rm -f *.log *.diff
	rm -rf m5out

all: $(PROGRAM_ELF) $(PROGRAM_LST) $(PROGRAM_HEX) $(PROGRAM_ELF) $(PROGRAM_HEX64)

rebuild: clean all

#############################################################
# common RTL simultion targets (run in program dir)

DIR_SIM  = $(DIR_BUILD)/sim
VSIM_BIN = cd $(DIR_SIM) && vsim

FILE_TRACE  ?= $(DIR_MAKE)/trace.log
FILE_DIFF   ?= $(DIR_MAKE)/trace.diff
FILE_GOLDEN ?= $(DIR_MAKE)/golden.log
MEMORY_HEX  ?= $(PROGRAM_HEX)
MEMORY_HEX64?= $(PROGRAM_HEX64)

# options passed to modelsim.tcl
VLOG_OPT += -sv $(DIR_TOP)/rtl/core/*.sv
VLOG_OPT += -sv $(DIR_TOP)/rtl/modules/*.sv
VLOG_OPT +=     $(DIR_TOP)/rtl/modules/uart16550/*.v
VLOG_OPT += -sv $(DIR_TOP)/tb/*.sv
VLOG_OPT += +incdir+$(DIR_TOP)/rtl/core
VLOG_OPT += +incdir+$(DIR_TOP)/rtl/modules
VLOG_OPT += +incdir+$(DIR_TOP)/rtl/modules/uart16550
VLOG_OPT += +define+MEM64="$(abspath $(MEMORY_HEX64))"
export VLOG_OPT

VSIM_OPT += work.testbench
VSIM_OPT += +MEM8=$(abspath $(MEMORY_HEX))
VSIM_OPT += +LOG=$(abspath $(FILE_TRACE))
export VSIM_OPT

VSIM_TCL ?= $(DIR_TOP)/run/wave.do
export VSIM_TCL

# args passed to vsim
VSIM_ARG += -l log
VSIM_ARG += -do $(DIR_TOP)/run/modelsim.tcl 

simdir:
	rm -rf $(DIR_SIM)
	mkdir  $(DIR_SIM)

log: simdir hex
	$(VSIM_BIN) $(VSIM_ARG) -c

sim: simdir hex
	$(VSIM_BIN) $(VSIM_ARG)

#############################################################
# simulate in gem5

GEM5_BIN ?= $(SIMULATOR_GEM5_BIN)
GEM5_DIR ?= $(SIMULATOR_GEM5_SRC)

GEM5_CFG = $(GEM5_DIR)/configs/example/se.py
GEM5_IMG = $(PROGRAM_ELF)

GEM_OPT_COMMON += $(GEM5_DIR)/configs/example/se.py
GEM_OPT_COMMON += -c $(GEM5_IMG)

GEM_OPT_RUN += --debug-flags=Exec,CCRegs
GEM_OPT_LOG += --debug-flags=CCRegs

gem5_run: $(GEM5_IMG)
	$(GEM5_BIN) $(GEM_OPT_RUN) $(GEM_OPT_COMMON)

gem5_log: $(GEM5_IMG)
	$(GEM5_BIN) $(GEM_OPT_LOG) $(GEM_OPT_COMMON) > $(FILE_GOLDEN)

diff:
	diff $(FILE_TRACE) $(FILE_GOLDEN) | grep Starting -A 1000 | grep Exiting -B 1000 | tee $(FILE_DIFF)
