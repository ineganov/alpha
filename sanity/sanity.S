

.global _start

.data
_mydata:

   .quad 0x1111111111111111
   .quad 0x0011AABBCCDDEEFF
   .quad 0x0000000000000000

.text

_start:

#set up GP
   bsr  $gp, 0    #get PC
   lda  $gp, 4092($gp) #gotoff = code + 4096, minus 4 on the account of BSR
   lda  $gp, 32768($gp) #GP = gotoff + 32768

   lda  $r0, 1
   lda  $r1, 2

   ldah $r2, 0x1111($r31)
   lda  $r2, 0x2222($r2)
   sll  $r2, 32
   ldah $r2, 0x3333($r2)
   lda  $r2, 0x4444($r2)
   
   lda  $r3, -1($r31)

   ldah $r4, 0x3333($r31)
   lda  $r4, 0x3333($r4)
   sll  $r4, 32
   ldah $r4, 0x3333($r4)
   lda  $r4, 0x3333($r4)

   lda  $r5, 2

   ldah $r6, -1($r31)

   lda  $r7, 255($r31)
   sll  $r7, 29, $r7

   lda  $r8, 0xB7
   sll  $r8, 8
   lda  $r8, 0xB6($r8)
   sll  $r8, 8
   lda  $r8, 0xB5($r8)
   sll  $r8, 8
   lda  $r8, 0xB4($r8)
   sll  $r8, 8
   lda  $r8, 0xB3($r8)
   sll  $r8, 8
   lda  $r8, 0xB2($r8)
   sll  $r8, 8
   lda  $r8, 0xB1($r8)
   sll  $r8, 8
   lda  $r8, 0xB0($r8)

# r20, r21 is always a result   


# ADDL        Opr      10.00          Add longword
# ADDL/V      Opr      10.40
# ADDQ        Opr      10.20          Add quadword
# ADDQ/V      Opr      10.60

   ldah  $r25, -16162($r31) # TEST 0

   addl  $r2, $r3, $r20
   addlv $r3, $r2, $r21
   addq  $r2, $r3, $r22
   addqv $r3, $r2, $r23

# SUBL        Opr      10.09          Subtract longword
# SUBL/V      Opr      10.49          
# SUBQ        Opr      10.29          Subtract quadword
# SUBQ/V      Opr      10.69

   lda   $r25, 1($r25)  # TEST 1

   subl  $r2, $r3, $r20
   sublv $r3, $r2, $r21
   subq  $r2, $r3, $r22
   subqv $r3, $r2, $r23

# S4ADDL      Opr      10.02          Scaled add longword by 4
# S4ADDQ      Opr      10.22          Scaled add quadword by 4
# S4SUBL      Opr      10.0B          Scaled subtract longword by 4
# S4SUBQ      Opr      10.2B          Scaled subtract quadword by 4

   lda   $r25, 1($r25)  # TEST 2

   s4addl  $r0, $r31, $r20
   s4addq  $r0, $r31, $r21
   s4subl  $r0, $r31, $r22
   s4subq  $r0, $r31, $r23

   s4addl  $r2, $r3, $r20
   s4addq  $r3, $r2, $r21
   s4subl  $r2, $r3, $r22
   s4subq  $r3, $r2, $r23

# S8ADDL      Opr      10.12          Scaled add longword by 8
# S8ADDQ      Opr      10.32          Scaled add quadword by 8
# S8SUBL      Opr      10.1B          Scaled subtract longword by 8
# S8SUBQ      Opr      10.3B          Scaled subtract quadword by 8

   lda   $r25, 1($r25)  # TEST 3
   s8addl  $r2, $r3, $r20
   s8addq  $r3, $r2, $r21
   s8subl  $r2, $r3, $r22
   s8subq  $r3, $r2, $r23

# CMPBGE      Opr      10.0F          Compare byte
   lda   $r25, 1($r25)  # TEST 4
   cmpbge $r4, $r2, $r20
   cmpbge $r2, $r4, $r21


# CMPEQ       Opr      10.2D          Compare signed quadword equal
   lda   $r25, 1($r25)  # TEST 5
   cmpeq $r1, $r0, $r20
   cmpeq $r1, $r3, $r21
   cmpeq $r1, $r5, $r22

# CMPLE       Opr      10.6D          Compare signed quadword less than or equal
   lda   $r25, 1($r25)  # TEST 6
   cmple $r1, $r0, $r20
   cmple $r1, $r3, $r21
   cmple $r1, $r5, $r22

# CMPLT       Opr      10.4D          Compare signed quadword less than
   lda   $r25, 1($r25)  # TEST 7
   cmplt $r1, $r0, $r20
   cmplt $r1, $r3, $r21
   cmplt $r1, $r5, $r22

# CMPULE      Opr      10.3D          Compare unsigned quadword less than or equal
   lda   $r25, 1($r25)  # TEST 8
   cmpule $r1, $r0, $r20 # 2 <= 1 ?
   cmpule $r1, $r3, $r21 # 2 <= FFFFFFFF ?
   cmpule $r1, $r5, $r22 # 2 <= 2 ?
   cmpule $r0, $r1, $r20 # 1 <= 2 ?
   cmpule $r3, $r1, $r21 # FFFFFFFF < 2 ?
   cmpule $r5, $r1, $r22 # 2 <= 2?

# CMPULT      Opr      10.1D          Compare unsigned quadword less than
   lda   $r25, 1($r25)  # TEST 9
   cmpult $r1, $r0, $r20 # 2 < 1 ?
   cmpult $r1, $r3, $r21 # 2 < FFFFFFFF ?
   cmpult $r1, $r5, $r22 # 2 < 2 ?
   cmpult $r0, $r1, $r20 # 1 < 2 ?
   cmpult $r3, $r1, $r21 # FFFFFFFF < 2 ?
   cmpult $r5, $r1, $r22 # 2 < 2 ?


# MULL        Opr      13.00          Multiply longword
# MULL/V      Opr      13.40          
   lda   $r25, 1($r25)  # TEST A
   mull $r1, $r1, $r20 # 2 * 2
   mull $r1, $r3, $r21 # 2 * -1
   mull $r3, $r3, $r22 # -1 * -1
   mull $r2, $r4, $r23 # 0х11112222_33334444 * 0х33333333_33333333
#   mullv $r1, $r1, $r20 # 2 * 2
#   mullv $r2, $r4, $r23 # 0х11112222_33334444 * 0х33333333_33333333

# MULQ        Opr      13.20          Multiply quadword
# MULQ/V      Opr      13.60          
   lda   $r25, 1($r25)  # TEST B
   mulq $r1, $r1, $r20 # 2 * 2
   mulq $r1, $r3, $r21 # 2 * -1
   mulq $r3, $r3, $r22 # -1 * -1
   mulq $r2, $r4, $r23 # 0х11112222_33334444 * 0х33333333_33333333
   mulq $r2, $r4, $r23 # 0х11112222_33334444 * 0х33333333_33333333

# UMULH       Opr      13.30          Unsigned multiply quadword high
   lda   $r25, 1($r25)  # TEST C
   umulh $r1, $r1, $r20 # 2 * 2
   umulh $r3, $r3, $r21 # -1 * -1
   umulh $r2, $r4, $r22 # 0х11112222_33334444 * 0х33333333_33333333
   umulh $r1, $r3, $r23 # 2 * 0хFFFFFFFF_FFFFFFFF

# Count Extension (CIX)
# CTLZ        Opr      1C.32          Count leading zero
# CTPOP       Opr      1C.30          Count population
# CTTZ        Opr      1C.33          Count trailing zero
   lda   $r25, 1($r25)  # TEST D
   ctlz   $r31, $r20 #  '0
   ctpop  $r31, $r21 #  '0
   cttz   $r31, $r22 #  '0

   ctlz   $r3,  $r20  #  '1
   ctpop  $r3,  $r21  #  '1
   cttz   $r3,  $r22  #  '1
   
   ctlz   $r1,  $r20  #  2
   ctpop  $r1,  $r21  #  2
   cttz   $r1,  $r22  #  2

   ctlz   $r6,  $r20  #  FFFF0000
   ctpop  $r6,  $r21  #  FFFF0000
   cttz   $r6,  $r22  #  FFFF0000

   ctlz   $r7,  $r20  #  FF << 29
   ctpop  $r7,  $r21  #  FF << 29
   cttz   $r7,  $r22  #  FF << 29



# Logical

# AND         Opr      11.00          Logical product
# EQV         Opr      11.48          Logical equivalence
# ORNOT       Opr      11.28          Logical sum with complement
# XOR         Opr      11.40          Logical difference

   lda   $r25, 1($r25)  # TEST E
   and  $r2, $r1,  $r20
   and  $r2, 0xFF, $r21
   and  $r7, $r3 , $r22
   and  $r2, $r4 , $r23 

   eqv  $r2, $r1,  $r20
   eqv  $r2, 0xFF, $r21
   eqv  $r7, $r3 , $r22
   eqv  $r2, $r4 , $r23 

   ornot  $r2, $r1,  $r20
   ornot  $r2, 0xFF, $r21
   ornot  $r7, $r3 , $r22
   ornot  $r2, $r4 , $r23 

   xor  $r2, $r1,  $r20
   xor  $r2, 0xFF, $r21
   xor  $r7, $r3 , $r22
   xor  $r2, $r4 , $r23 

# BIC         Opr      11.08          Bit clear
# BIS         Opr      11.20          Logical sum
   lda   $r25, 1($r25)  # TEST F
   bis   $r2,  0xFF, $r20
   bis   $r31,  $r2, $r21
   bis   $r1,   $r7, $r22
   bis   $r7,   $r1, $r23
   bic   $r2,  0xFF, $r20
   bic   $r31,  $r2, $r21
   bic   $r1,   $r3, $r22
   bic   $r3,   $r1, $r23

# CMOVEQ      Opr      11.24          CMOVE if = zero
# CMOVGE      Opr      11.46          CMOVE if >= zero
# CMOVGT      Opr      11.66          CMOVE if > zero
# CMOVLBC     Opr      11.16          CMOVE if low bit clear
# CMOVLBS     Opr      11.14          CMOVE if low bit set
# CMOVLE      Opr      11.64          CMOVE if <= zero
# CMOVLT      Opr      11.44          CMOVE if < zero
# CMOVNE      Opr      11.26          CMOVE if ! zero
   lda   $r25, 1($r25)  # TEST 10

   mov    $r31, $r20
   mov    $r31, $r21
   mov    $r31, $r22
   cmoveq $r31, $r3, $r20 # Should move
   cmoveq $r1,  $r3, $r21 # Should not
   cmoveq $r0,  $r3, $r22 # Should not

   mov    $r31, $r20
   mov    $r31, $r21
   mov    $r31, $r22
   cmovne $r31, $r3, $r20 # Should not
   cmovne $r1,  $r3, $r21 # Should move
   cmovne $r0,  $r3, $r22 # Should move

   mov    $r31, $r20
   mov    $r31, $r21
   mov    $r31, $r22
   cmovge $r31, $r3, $r20 # Should move
   cmovge $r1,  $r3, $r21 # Should move
   cmovge $r3,  $r3, $r22 # Should not

   mov    $r31, $r20
   mov    $r31, $r21
   mov    $r31, $r22
   cmovgt $r31, $r3, $r20 # Should not
   cmovgt $r1,  $r3, $r21 # Should move
   cmovgt $r3,  $r3, $r22 # Should not

   mov    $r31, $r20
   mov    $r31, $r21
   mov    $r31, $r22
   cmovle $r31, $r3, $r20 # Should move
   cmovle $r1,  $r3, $r21 # Should not
   cmovle $r3,  $r3, $r22 # Should move

   mov    $r31, $r20
   mov    $r31, $r21
   mov    $r31, $r22
   cmovlt $r31, $r3, $r20 # Should not
   cmovlt $r1,  $r3, $r21 # Should not
   cmovlt $r3,  $r3, $r22 # Should move

   mov     $r31, $r20
   mov     $r31, $r21
   cmovlbc $r0,  $r3, $r20 # Should not
   cmovlbc $r1,  $r3, $r21 # Should move

   mov     $r31, $r20
   mov     $r31, $r21
   cmovlbs $r0,  $r3, $r20 # Should move
   cmovlbs $r1,  $r3, $r21 # Should not

   # cmove bypass case   
   lda     $r20, 0x1987($r31)
   cmovlbs $r1, $r3, $r20 # should leave r20 intact
   sll     $r20, 16       # should read 0x19870000
   cmovlbc $r1, $r3, $r20 # should move all ones
   sll     $r20, 16       # should read 0xFFFFFFFFFF0000

   lda     $r20, 0x1987($r31)
   cmovlbs $r1, $r3, $r20 # should leave r20 intact
   nop
   sll     $r20, 16       # should read 0x19870000
   cmovlbc $r1, $r3, $r20 # should move all ones
   nop
   sll     $r20, 16       # should read 0xFFFFFFFFFF0000


# SLL         Opr      12.39          Shift left logical
# SRA         Opr      12.3C          Shift right arithmetic
# SRL         Opr      12.34          Shift right logical
   lda   $r25, 1($r25)  # TEST 11
   sll   $r1,  0,    $r20
   sll   $r1,  1,    $r21
   lda   $r20, 30
   sll   $r1,  $r20, $r22
   sll   $r1,  65,   $r23
   lda   $r20, 258
   sll   $r1,  $r20, $r23
   sll   $r1,  62, $r24

   sra   $r24, 0, $r20
   sra   $r24, 5, $r20
   lda   $r20, 7
   sra   $r24, $r20, $r20
   sra   $r20, 8
   sra   $r20, 8
   sra   $r24, 65, $r21
   sra   $r24, 63, $r22

   srl   $r24, 0, $r20
   srl   $r24, 5, $r20
   lda   $r20, 7
   srl   $r24, $r20, $r20
   srl   $r24, 65, $r21
   srl   $r24, 63, $r22


# EXTBL       Opr      12.06          Extract byte low
# EXTLH       Opr      12.6A          Extract longword high
# EXTLL       Opr      12.26          Extract longword low
# EXTQH       Opr      12.7A          Extract quadword high
# EXTQL       Opr      12.36          Extract quadword low
# EXTWH       Opr      12.5A          Extract word high
# EXTWL       Opr      12.16          Extract word low

   lda   $r25, 1($r25)  # TEST 12

   extbl $r8, 0,   $r20
   extbl $r8, 6,   $r20
   extbl $r8, 7,   $r20
   extbl $r8, 8,   $r20
   extbl $r8, $r1, $r20

   extwh $r8, 0,   $r21
   extwl $r8, 0,   $r21
   extwh $r8, 5,   $r21
   extwl $r8, 5,   $r21
   extwh $r8, $r1, $r21
   extwl $r8, $r1, $r21

   extlh $r8, 0,   $r22
   extll $r8, 0,   $r22
   extlh $r8, 5,   $r22
   extll $r8, 5,   $r22
   extlh $r8, $r1, $r22
   extll $r8, $r1, $r22

   extqh $r8, 0,   $r23
   extql $r8, 0,   $r23
   extqh $r8, 5,   $r23
   extql $r8, 5,   $r23
   extqh $r8, $r1, $r23
   extql $r8, $r1, $r23


# INSBL       Opr      12.0B          Insert byte low
# INSLH       Opr      12.67          Insert longword high
# INSWH       Opr      12.57          Insert word high
# INSWL       Opr      12.1B          Insert word low
# INSLL       Opr      12.2B          Insert longword low
# INSQH       Opr      12.77          Insert quadword high
# INSQL       Opr      12.3B          Insert quadword low

   lda   $r25, 1($r25)  # TEST 13

   insbl $r8, 0,   $r20
   insbl $r8, 6,   $r20
   insbl $r8, 7,   $r20
   insbl $r8, 8,   $r20
   insbl $r8, $r1, $r20

   inswh $r8, 0,   $r21
   inswl $r8, 0,   $r21
   inswh $r8, 5,   $r21
   inswl $r8, 5,   $r21
   inswh $r8, $r1, $r21
   inswl $r8, $r1, $r21

   inslh $r8, 0,   $r22
   insll $r8, 0,   $r22
   inslh $r8, 5,   $r22
   insll $r8, 5,   $r22
   inslh $r8, $r1, $r22
   insll $r8, $r1, $r22

   insqh $r8, 0,   $r23
   insql $r8, 0,   $r23
   insqh $r8, 5,   $r23
   insql $r8, 5,   $r23
   insqh $r8, $r1, $r23
   insql $r8, $r1, $r23

# MSKBL       Opr      12.02          Mask byte low
# MSKLH       Opr      12.62          Mask longword high
# MSKLL       Opr      12.22          Mask longword low
# MSKQH       Opr      12.72          Mask quadword high
# MSKQL       Opr      12.32          Mask quadword low
# MSKWH       Opr      12.52          Mask word high
# MSKWL       Opr      12.12          Mask word low

   mskbl $r8, 0,   $r20
   mskbl $r8, 6,   $r20
   mskbl $r8, 7,   $r20
   mskbl $r8, 8,   $r20
   mskbl $r8, $r1, $r20

   mskwh $r8, 0,   $r21
   mskwl $r8, 0,   $r21
   mskwh $r8, 5,   $r21
   mskwl $r8, 5,   $r21
   mskwh $r8, $r1, $r21
   mskwl $r8, $r1, $r21

   msklh $r8, 0,   $r22
   mskll $r8, 0,   $r22
   msklh $r8, 5,   $r22
   mskll $r8, 5,   $r22
   msklh $r8, $r1, $r22
   mskll $r8, $r1, $r22

   mskqh $r8, 0,   $r23
   mskql $r8, 0,   $r23
   mskqh $r8, 5,   $r23
   mskql $r8, 5,   $r23
   mskqh $r8, $r1, $r23
   mskql $r8, $r1, $r23

# ZAP         Opr      12.30          Zero bytes
# ZAPNOT      Opr      12.31          Zero bytes not
   zap    $r8, 0xAA, $r20
   zap    $r8, 0x55, $r20
   zap    $r8, $r1,  $r20
   zapnot $r8, 0xAA, $r20
   zapnot $r8, 0x55, $r20
   zapnot $r8, $r1,  $r20


# Branches

# BEQ         Bra      39             Branch if = zero
__test_14_beq_mark_0:
   lda   $r25, 1($r25)  # TEST 14
   beq   $r31, __test_14_beq_mark_1 #should be taken
   lda   $r20, 0x666($r31)     #should not execute
__test_14_beq_mark_1:
   beq   $r1,  __test_14_beq_mark_0 #should not be taken
   beq   $r31, __test_14_beq_mark_2 #should be taken
__test_14_beq_mark_2:
   lda   $r20, 0x777($r31)  #should be executed

# BGE         Bra      3E             Branch if >= zero
__test_14_bge_mark_0:
   bge   $r31, __test_14_bge_mark_1 #should be taken
   lda   $r20, 0x666($r31)     #should not execute
__test_14_bge_mark_1:
   bge   $r3, __test_14_bge_mark_0 #should not be taken
   bge   $r2, __test_14_bge_mark_2 #should be taken
__test_14_bge_mark_2:
   lda   $r20, 0x777($r31)  #should be executed

# BGT         Bra      3F             Branch if > zero
__test_14_bgt_mark_0:
   bgt   $r0, __test_14_bgt_mark_1 #should be taken
   lda   $r20, 0x666($r31)     #should not execute
__test_14_bgt_mark_1:
   bgt   $r31, __test_14_bgt_mark_0 #should not be taken
   bgt   $r1, __test_14_bgt_mark_2 #should be taken
__test_14_bgt_mark_2:
   lda   $r20, 0x777($r31)  #should be executed

# BLBC        Bra      38             Branch if low bit clear
__test_14_blbc_mark_0:
   blbc   $r31, __test_14_blbc_mark_1 #should be taken
   lda   $r20, 0x666($r31)     #should not execute
__test_14_blbc_mark_1:
   blbc   $r0, __test_14_blbc_mark_0 #should not be taken
   blbc   $r2,  __test_14_blbc_mark_2 #should be taken
__test_14_blbc_mark_2:
   lda   $r20, 0x777($r31)  #should be executed

# BLBS        Bra      3C             Branch if low bit set
__test_14_blbs_mark_0:
   blbs   $r0, __test_14_blbs_mark_1 #should be taken
   lda   $r20, 0x666($r31)     #should not execute
__test_14_blbs_mark_1:
   blbs   $r1, __test_14_blbs_mark_0 #should not be taken
   blbs   $r3, __test_14_blbs_mark_2 #should be taken
__test_14_blbs_mark_2:
   lda   $r20, 0x777($r31)  #should be executed

# BLE         Bra      3B             Branch if <= zero
__test_14_ble_mark_0:
   ble   $r3, __test_14_ble_mark_1 #should be taken
   lda   $r20, 0x666($r31)     #should not execute
__test_14_ble_mark_1:
   ble   $r0, __test_14_ble_mark_0 #should not be taken
   ble   $r31, __test_14_ble_mark_2 #should be taken
__test_14_ble_mark_2:
   lda   $r20, 0x777($r31)  #should be executed

# BLT         Bra      3A             Branch if < zero
__test_14_blt_mark_0:
   blt   $r3, __test_14_blt_mark_1 #should be taken
   lda   $r20, 0x666($r31)     #should not execute
__test_14_blt_mark_1:
   blt   $r31, __test_14_blt_mark_0 #should not be taken
   blt   $r8, __test_14_blt_mark_2 #should be taken
__test_14_blt_mark_2:
   lda   $r20, 0x777($r31)  #should be executed

# BNE         Bra      3D             Branch if ! zero
__test_14_bne_mark_0:
   bne   $r0, __test_14_bne_mark_1 #should be taken
   lda   $r20, 0x666($r31)     #should not execute
__test_14_bne_mark_1:
   bne   $r31, __test_14_bne_mark_0 #should not be taken
   bne   $r1, __test_14_bne_mark_2 #should be taken
__test_14_bne_mark_2:
   lda   $r20, 0x777($r31)  #should be executed


# BR          Bra      30             Unconditional branch
   lda   $r25, 1($r25)  # TEST 15
__test_15_br_mark0:
   br    $r20, __test_15_br_mark_1 #should be taken, PC in r20
   lda   $r21, 0x666($r31)         #should not execute
__test_15_br_mark_1:
   lda   $r21, 0x777($r31)         #should execute

# BSR         Mbr      34             Branch to subroutine
__test_15_bsr_mark0:
   bsr    $r20, __test_15_bsr_mark_1 #should be taken, PC in r20
   lda   $r21, 0x666($r31)         #should not execute
__test_15_bsr_mark_1:
   lda   $r21, 0x777($r31)         #should execute


# JMP         Mbr      1A.0           Jump
   lda   $r25, 1($r25)  # TEST 16
__test_16_jmp_mark0:
   jmp    $r20, __test_16_jmp_mark_1 #should be taken, PC in r20
   lda   $r21, 0x666($r31)           #should not execute
__test_16_jmp_mark_1:
   lda   $r21, 0x777($r31)           #should execute

# JSR         Mbr      1A.1           Jump to subroutine
__test_16_jsr_mark0:
   jsr   __test_16_jsr_mark_1 #should be taken, PC in RA (r26)
   lda   $r21, 0x666($r31)           #should not execute
__test_16_jsr_mark_1:
   lda   $r21, 0x777($r31)           #should execute

# RET         Mbr      1A.2           Return from subroutine
__test_16_ret_mark_0:
   lda  $r26, __test_16_ret_mark_1    #set RA
   ret
   lda   $r21, 0x666($r31)           #should not execute
__test_16_ret_mark_1:
   lda   $r21, 0x777($r31)           #should execute

# JSR_CRE     Mbr      1A.3           Jump to subroutine return
# CALL_PAL    Pcd      00             Trap to PALcode


# LSU

# these two are tested extensively above
# LDA         Mem      08             Load address
# LDAH        Mem      09             Load address high

# LDL         Mem      28             Load sign-extended longword
   lda   $r25, 1($r25)  # TEST 16
   lda   $r20, __test_16_jsr_mark0  # loading known data from code segment
   ldl   $r21,  0($r20)
   ldl_l $r21,  4($r20)
   ldl   $r21,  8($r20)
   ldl   $r21, 12($r20)
   ldl   $r21, 16($r20)

# LDQ         Mem      29             Load quadword
#   lda   $r20, __test_15_br_mark0
   bic   $r20, 0x7
   ldq   $r21,  0($r20)
   ldq_l $r21,  8($r20)
   ldq   $r21, 16($r20)
   ldq   $r21, 24($r20)
   ldq   $r21, 32($r20)

   

# STL         Mem      2C             Store longword
   lda   $r20, _mydata
   stl   $r2, 0($r20)
   stl   $r8, 4($r20)
   ldq   $r21, 0($r20)

# STQ         Mem      2D             Store quadword
   stq   $r8,  0($r20)
   ldq   $r21, 0($r20)

# LDBU        Mem      0A             Load zero-extended byte
# SEXTB       Opr      1C.00          Sign extend byte
   xor  $r22, $r22
   addq $r20, 8, $r23

ldbu_mark:
   sll   $r22, 8
   ldbu  $r21, 0($r20)
   sextb $r21, $r25
   or    $r21, $r22, $r22
   addq  $r20, 1
   cmpeq $r23, $r20, $r24
   beq   $r24, ldbu_mark

   stq   $r22, -8($r20)

# LDWU        Mem      0C             Load zero-extended word
# SEXTW       Opr      1C.01          Sign extend word
   ldwu  $r21, -6($r20)
   sextw $r21
   ldwu  $r22, -8($r20)
   sextw $r22
   sextw $r2, $r22
   sextb $r2, $r22

# STB         Mem      0E             Store byte
   addq $r31, 0x10, $r21
   subq $r20, 8, $r23

stb_mask:
   subq  $r20, 1
   stb   $r21, 0($r20)
   addq  $r21, 0x10
   cmpeq $r23, $r20, $r24
   beq   $r24, stb_mask

   ldq   $r21, 0($r20)

# STW         Mem      0D             Store word
   extwl $r2,  0, $r21
   stw   $r21, 6($r20)
   extwl $r2,  2, $r21
   stw   $r21, 4($r20)
   extwl $r2,  4, $r21
   stw   $r21, 2($r20)
   extwl $r2,  6, $r21
   stw   $r21, 0($r20)

   ldq   $r21, 0($r20)


# LDQ_U       Mem      0B             Load unaligned quadword
# STQ_U       Mem      0F             Store unaligned quadword
   stq_u $r8, 1($r20)
   ldq_u $r21, 7($r20)


# LDL_L       Mem      2A             Load sign-extended longword locked
# STL_C       Mem      2E             Store longword conditional
   mov   $r2, $r25
   stl_c $r25,  0($r20)  # should fail and will not issue a bus request
   ldl_l $r21,  0($r20)
   stl_c $r2,   0($r20)  # should pass and update memory
   ldl   $r21,  0($r20)

# LDQ_L       Mem      2B             Load quadword locked
# STQ_C       Mem      2F             Store quadword conditional
   mov   $r2, $r25
   stq_c $r25,  0($r20) # should fail and will not issue a bus request
   ldq_l $r21,  0($r20)
   stq_c $r2,   0($r20) # should pass and update memory
   ldq   $r21,  0($r20)

#uncached
   lda   $r25, 1($r25)  # TEST 17
   lda   $r20, __test_16_jsr_mark0
   lda   $r21, 1
   sll   $r21, 63
   or    $r21, $r20, $r20
   bic   $r20, 7
   ldq   $r22, 0($r20)
   ldl   $r22, 4($r20)
   ldw   $r22, 6($r20)
   ldb   $r22, 7($r20)

   lda   $r25, 1($r25)  # TEST 18
   lda   $r20, _mydata
   lda   $r21, 1
   sll   $r21, 63
   or    $r21, $r20, $r21
   stq   $r8,  0($r21)
   stl   $r8,  4($r21)
   stw   $r8,  6($r21)
   stb   $r8,  7($r21)
   ldq   $r22, 0($r20)


   nop
   nop

_exit:
#   lda	$v0, 1
#   lda	$a0, 0
   callsys
