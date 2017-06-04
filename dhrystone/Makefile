AS         = alphaev67-unknown-linux-gnu-as
CC         = alphaev67-unknown-linux-gnu-gcc 
ODUMP      = alphaev67-unknown-linux-gnu-objdump 
OCOPY      = /root/gcc-4.6.3-nolibc/alpha-linux/bin/alpha-linux-objcopy
CFLAGS     = -c -Os
LFLAGS     = --static -nostdlib -Wl,-t,-script=ld_mod.script#,-verbose,
LFLAGS_STD = --static 

all:
	$(AS) -m21264 start.S -o start.o
	$(CC) $(CFLAGS) iln_dhry.c -o obj1.o
	$(CC) $(CFLAGS) iln_dhry_2.c  -o obj2.o
	$(CC) $(LFLAGS) start.o obj1.o obj2.o -o dhry
	$(ODUMP) -S dhry > listing.lst
	$(OCOPY) -I elf64-alpha -O verilog dhry dhry.hex

std:
	$(CC) $(CFLAGS) iln_dhry.c -o obj1.o
	$(CC) $(CFLAGS) iln_dhry_2.c  -o obj2.o
	$(CC) $(LFLAGS_STD) obj1.o obj2.o -o dhry
	$(ODUMP) -S dhry > listing.lst


clean:
	rm start.o obj1.o obj2.o dhry listing.lst

run:
	/root/gem5/gem5/build/ALPHA/gem5.opt    /root/gem5/gem5/configs/example/se.py -c ./dhry

rund:
	/root/gem5/gem5/build/ALPHA/gem5.opt    --debug-flags=Exec,CCRegs /root/gem5/gem5/configs/example/se.py -c ./dhry

