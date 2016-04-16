.data
rand_a:    .word   1103515245  ;
rand_b:    .word   12345       ;
rand_max:  .word   2147483648  ;
rand_max1: .word   2147483647  ;
anwf:      .asciiz "\nA floating point random value would be: "
qstmin:    .asciiz "Please enter the min value: "
qstmax:    .asciiz "Please enter the max value: "
qstn:      .asciiz "Choose n > 0: "
exit:      .asciiz "\nWanna more? [1=no, 0=yes] : "
exitm:     .asciiz "\nSee you next time! :)"
nl:        .asciiz "\n"
sep:       .asciiz ".\tnumber:\t"

.text
.globl main
#used s-register: $s0-3 for a,b,m,m-1 ; $s4 + $s5: min max range ; $s6: n
# $s0: a
# $s1: b
# $s2: m
# $s3: m-1
# $s4: min-range
# $s5: max-range
# $s6: n
# $s7: start adress of array
main:
      la    $a0, qstmin     ;
      jal   askforint       ;
      move  $s4, $v0        ;#$s4 = min
      la    $a0, qstmax     ;
      jal    askforint      ;
      move  $s5, $v0        ;#$s5 = max
      la    $a0, qstn       ;
      jal   askforint       ;
      move  $s6, $v0        ;#$s6 = n
      li    $t0, 4          ;
      mul   $a0, $s6, $t0   ;# needed space
      li    $v0, 9          ;#allocate memory
      syscall
      move $s7, $v0         ;#store adress

      li   $t1, 9           ;#get count from coprocessor
      mfc0 $a0, $t1         ;#Execution time as seed

      li    $t6, 0          ;#init loop variant
      #loop and generate n-random numbers
      loop: jal   genrandminmax     ;#main subroutine to generate a value between min and max
            move $t0, $v0     ;#save seed for next iteration

            li   $t5, 4       ;#4 bytes
            mul  $t5, $t5, $t6 ;#index = 4*iterator
            add  $t5, $s7, $t5 ;#adress = startadress + 4*iterator

            swc1 $f0, 0($t5)   ;#save float at array position
            addi $t6, $t6, 1  ;
            move $a0, $t0     ;# set new seed
            bne $t6,$s6, loop ;

      jal printArray          ;

      j     exitsequence        ;#check if the user wants more

rand: lw    $s0, rand_a        ;
      lw    $s1, rand_b        ;
      lw    $s2, rand_max      ;
      multu $a0, $s0          ;#a*r(n-1)
      mflo  $t1
      addu  $t1, $t1, $s1     ;#(a*r(n-1)+b)
      divu  $t1, $s2          ;# mod m
      mfhi  $v0                ;#  return modulo
      jr    $ra                ;

frand:
      move      $t9, $ra           ;#Temporarily store return address
      jal       rand          ;
      move      $t0, $v0      ;

      mtc1      $t0, $f1
      cvt.s.w   $f1, $f1

      lw        $s3, rand_max1 ;
      mtc1      $s3, $f2
      cvt.s.w   $f2, $f2
      div.s     $f0, $f1, $f2  ;# return value in $f0
      jr        $t9

# value between min and max = min + r*(max-min)
minmaxfloat:                     #f12=r, a0 = min, a1 = max
      mtc1      $s4, $f10
      cvt.s.w   $f10, $f10 #f10 = min

      mtc1      $s5, $f11
      cvt.s.w   $f11, $f11  #f11 = max

      sub.s     $f11, $f11, $f10     ;#max = max - min
      mul.s     $f11, $f12, $f11     ;#max = r * max
      add.s     $f0, $f11, $f10      ;#return = min + max in f0
      jr $ra

genrandminmax:
      move $t8, $ra         ;
      jal frand
      mov.s $f12,$f0        ;#r = param1
      mov.s $f15, $f0
      jal   minmaxfloat     ;
      mov.s $f12, $f0       ;#return value
      jr   $t8              ;

askforint:
      li        $v0, 4            ;#print string
      syscall
      li        $v0, 5            ;#read int
      syscall
      jr        $ra

printArray:
  li $t0, 0           ;#index
  printloop: beq   $t0, $s6, endOfLoop ;#head controlled: index == n?
        li    $v0, 1      ;#print int
        move  $a0, $t0    ;
        syscall           ;
        li    $v0, 4      ;#print string
        la $a0, sep       ;
        syscall           ;
        li $v0, 2         ;#print float

        li   $t2, 4       ;#4 bytes
        mul  $t2, $t2, $t0 ;#index = 4*iterator
        add  $t2, $s7, $t2 ;#adress = startadress + 4*iterator
        lwc1 $f12, 0($t2)   ;
        syscall             ;

        li    $v0, 4         ;#print string
        la    $a0, nl        ;
        syscall              ;

        addi  $t0, 1         ;
        j     printloop           ;
  endOfLoop:
        jr $ra;



exitsequence:
      li  $v0, 4            ;
      la  $a0, exit         ;
      syscall               ;

      li  $v0, 5            ;
      syscall               ;
      beqz $v0, main        ;

      li  $v0, 4            ;
      la  $a0, exitm        ;
      syscall
      li  $v0, 10           ;#exit
      syscall               ;
