
all:
	alpha-linux-as sanity.S -m21264 -F -o sanity.o
	alpha-linux-ld -o sanity sanity.o -T ld.script
	alpha-linux-objcopy -I elf64-alpha -O verilog sanity sanity.hex
	alpha-linux-objdump -S sanity > sanity.lst
	
