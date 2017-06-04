#/bin/sh

/root/gem5/gem5/build/ALPHA/gem5.opt --debug-flags=CCRegs /root/gem5/gem5/configs/example/se.py -c ./sanity > golden_log
/root/gem5/gem5/build/ALPHA/gem5.opt --debug-flags=Exec,CCRegs /root/gem5/gem5/configs/example/se.py -c ./sanity 


