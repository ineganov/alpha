
DIR_MAKE  := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

#############################################################
# compile settings

CFLAGS     = -c -O0
LFLAGS     = --static -nostdlib -Wl,-t,-script=ld.script#,-verbose,

PROGRAM_ELF = gpio.elf

$(PROGRAM_ELF):
	$(LOCAL_AS) -m21264 start.S -o start.o
	$(LOCAL_CC) $(CFLAGS) main.c -I../include -o main.o
	$(LOCAL_CC) $(LFLAGS) start.o main.o -o $(PROGRAM_ELF)

#############################################################
# simulation settings




#############################################################
# common make targerts

include ../../common.mk
