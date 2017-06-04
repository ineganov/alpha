#!/bin/sh
vsim work.testbench -c -do "log -r /*; log /uut/regfile/rf; run -all" -l log +MEM="sanity/sanity.hex" +LOG="trace.log"

