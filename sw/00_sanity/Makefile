
DIR_MAKE  := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

#############################################################
# compile settings

CFLAGS     = -c -O0
LFLAGS     = --static -nostdlib -Wl,-t,-script=ld.script#,-verbose,

PROGRAM_ELF = sanity.elf

$(PROGRAM_ELF):
	$(LOCAL_AS) sanity.S -m21264 -F -o sanity.o
	$(LOCAL_LD) -o $(PROGRAM_ELF) sanity.o -T ld.script

#############################################################
# simulation settings



#############################################################
# simulate in gem5

#GEM5_IMG = $(GEM5_DIR)/tests/test-progs/hello/bin/alpha/linux/hello
FILE_GOLDEN = golden.log.orig

#############################################################
# common make targerts

include ../../common.mk
