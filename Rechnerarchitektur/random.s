.data
seed:      .word   42          ;
rand_a:    .word   1103515245  ;
rand_b:    .word   12345       ;
rand_max:  .word   2147483648  ;
anw:       .asciiz "The Random number is: "
anwf:      .asciiz "\nA floating point random value would be: "
qst:       .asciiz "Please enter the start value: "
.text
.globl main

main: lw  $t0, seed         ;#Initalize seed in $t0
li  $v0, 4            ;#Print string
la  $a0, qst          ;
syscall               ;
li  $v0, 5            ;#Read int
syscall
move $t0, $v0         ;#Temporarily store the value

li  $v0, 4            ;#Print string
la  $a0, anw          ;
syscall

move $a0, $t0         ;
jal rand              ;#return value is in a0
move $a0, $v0         ;
li  $v0, 1            ;#Print int
syscall

jal frand
mov.s $f12, $f0       ;
la  $a0, anwf         ;
li  $v0, 4            ;#print string
syscall               ;

li  $v0, 2            ;#print float
syscall

li  $v0, 10           ;#exit
syscall               ;

rand: lw   $s0, rand_a        ;
      lw   $s1, rand_b        ;
      lw   $s2, rand_max      ;
      multu $a0, $s0          ;#a*r(n-1)
      mflo  $t1
      addu  $t1, $t1, $s1     ;#(a*r(n-1)+b)
      divu  $t1, $s2          ;# mod m
      mfhi $v0                ;#  return modulo
      jr   $ra                ;

frand:
      move $t9, $ra                 ;#Temporarily store return address
      jal       rand                ;
      move      $t0, $a0            ;

      mtc1      $t0, $f1
      cvt.s.w   $f1, $f1
      mtc1      $s0, $f2
      cvt.s.w   $f2, $f2
      div.s     $f0, $f1, $f2       ;# return value in $f0
      jr        $t9
