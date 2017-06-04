.global _start
.global __divl

.text

_start:

#set up GP
   bsr  $r0, 0          # get PC
   zap  $r0, 3          # kill 16-bit offset
   ldq  $gp, 136($r0)   # this hack loads the VA of a second segment, conveniently starting with GOT
   lda  $gp, 32768($gp) # GP = gotoff+32768

   #hack to have same stack behavior in hw and gem5
   lda  $sp, stack
   lda  $sp, 8192($sp)

   lda $r27, main 
   jmp $r26, ($r27)

   callsys



__divl:
   # for whatever reason, GCC is using t12 = t10 / t11 instead of a normal calling convention
   # t0, t1, t2 are assumed saved. R23(!!) is used as RA for __divl
   # r27 = r24 / r25
   lda $sp, -56($sp)
   stq $r0,   0($sp)
   stq $r1,   8($sp)
   stq $r2,  16($sp)
   stq $r3,  24($sp)
   stq $r16, 32($sp)
   stq $r17, 40($sp)
   stq $r26, 48($sp)

   mov $r24, $r16
   mov $r25, $r17
   bsr $r26,  my_divqu
   mov $r0,  $r27

   ldq $r0,   0($sp)
   ldq $r1,   8($sp)
   ldq $r2,  16($sp)
   ldq $r3,  24($sp)
   ldq $r16, 32($sp)
   ldq $r17, 40($sp)
   ldq $r26, 48($sp)
   lda $sp,  56($sp)

   ret ($r23)


my_divqu:
   # a0/r16 -- divisor
   # a1/r17 -- dividend
   # t0/r1  -- calc temp (clz, step result)
   # t1/r2  -- calc temp (clz, step result)
   # t2/r3  -- calc temp (num iterations)
   clr  $r0
   ctlz $r16, $r1          # leading zeroes a0 -> t0
   ctlz $r17, $r2          # leading zeroes a1 -> t1
   subq $r2, $r1, $r3      # number of iterations + 1
   bge  $r3, my_divqu_goahead # if negative, return zero straight away
   ret

my_divqu_goahead:
   sll $r17, $r3, $r17     # align divisor to dividend

my_divqu_step:
   subq   $r16, $r17, $r1  # subtract and check sign
   srl    $r1,    63, $r2  # set r2 to 1/0 depending on sign  
   xor    $r2,     1, $r2  # set r2 to 1/0 depending on sign
   cmovge $r1,   $r1, $r16 # update divisor if >= 0
   or     $r0,   $r2, $r0  # set one bit of the result

   bne    $r3, my_divqu_continue # iterate if r3 != 0
   ret                           # else return

my_divqu_continue:
   sll    $r0,  1
   srl    $r17, 1
   subq   $r3,  1
   br     my_divqu_step
   ret
