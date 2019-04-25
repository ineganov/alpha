.global _start

.text

_start:

#set up GP
   bsr  $r0, 0          # get PC
   zap  $r0, 3          # kill 16-bit offset
   #ldq  $gp, 136($r0)   # this hack loads the VA of a second segment, conveniently starting with GOT
   #lda  $gp, 32768($gp) # GP = gotoff+32768

   #hack to have same stack behavior in hw and gem5
   #lda  $sp, stack
   #lda  $sp, 8192($sp)
   lda  $sp, (1<<12)

   lda $r27, main 
   jmp $r26, ($r27)

   callsys
