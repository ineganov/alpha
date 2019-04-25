
DIR_MAKE  := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

#############################################################
# compile settings

CFLAGS      = -c -Os
LFLAGS      = --static -nostdlib -Wl,-t,-script=ld_mod.script#,-verbose,
PROGRAM_ELF = dhry.elf

$(PROGRAM_ELF):
	$(LOCAL_AS) -m21264 start.S -o start.o
	$(LOCAL_CC) $(CFLAGS) iln_dhry.c -o obj1.o
	$(LOCAL_CC) $(CFLAGS) iln_dhry_2.c  -o obj2.o
	$(LOCAL_CC) $(LFLAGS) start.o obj1.o obj2.o -o $(PROGRAM_ELF)

LFLAGS_STD = --static 

std:
	$(LOCAL_CC) $(CFLAGS) iln_dhry.c -o obj1.o
	$(LOCAL_CC) $(CFLAGS) iln_dhry_2.c  -o obj2.o
	$(LOCAL_CC) $(LFLAGS_STD) obj1.o obj2.o -o $(PROGRAM_ELF)

#############################################################
# simulation settings

FILE_GOLDEN = golden.log.orig
MEMORY_HEX  = dhry.hex.orig

#############################################################
# common make targerts

include ../../common.mk
