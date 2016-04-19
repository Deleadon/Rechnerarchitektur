.data
rand_a:    .word   1103515245  ;
rand_b:    .word   12345       ;
rand_max:  .word   2147483648  ;
rand_max1: .word   2147483647  ;
qstmin:    .asciiz "Please enter the min value: "
qstmax:    .asciiz "Please enter the max value: "
qstn:      .asciiz "Choose n > 0: "
exit:      .asciiz "\nWanna more? [0=no, 1=yes] : "
exitm:     .asciiz "\nSee you next time! :)"
nl:        .asciiz "\n"
sep:       .asciiz ".\t"
unsorted:  .asciiz "The Random Number set is: \n\n"
sorted:    .asciiz "\nAfter running Mergesort over the files: \n\n"

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
            bne  $t6,$s6, loop ;

      li  $v0, 4              ;#print string
      la  $a0, unsorted       ;
      syscall

      jal printArray          ;

      move  $a0, $s7          ;
      li    $t0, 4            ;
      mul   $t1, $s6, $t0     ;
      add   $a1, $a0, $t1     ;#end position of array
      jal   storeOnStack      ;#store a0 and a1 on the stack

      jal mergesort           ;

      li  $v0, 4              ;#print string
      la  $a0, sorted         ;
      syscall
      jal printArray          ;

      j   exitsequence        ;#check if the user wants more

rand: lw    $s0, rand_a        ;
      lw    $s1, rand_b        ;
      lw    $s2, rand_max      ;
      multu $a0, $s0           ;#a*r(n-1)
      mflo  $t1
      addu  $t1, $t1, $s1      ;#(a*r(n-1)+b)
      divu  $t1, $s2           ;# mod m
      mfhi  $v0                ;#  return modulo
      jr    $ra                ;

frand:
      move      $t9, $ra       ;#Temporarily store return address
      jal       rand           ;
      move      $t0, $v0       ;

      mtc1      $t0, $f1       ;
      cvt.s.w   $f1, $f1       ;

      lw        $s3, rand_max1 ;
      mtc1      $s3, $f2       ;
      cvt.s.w   $f2, $f2       ;
      div.s     $f0, $f1, $f2  ;# return value in $f0
      jr        $t9            ;

# value between min and max = min + r*(max-min)
minmaxfloat:                     #f12=r, a0 = min, a1 = max
      mtc1      $s4, $f10      ;
      cvt.s.w   $f10, $f10     ;#f10 = min

      mtc1      $s5, $f11      ;
      cvt.s.w   $f11, $f11     ;#f11 = max

      sub.s     $f11, $f11, $f10     ;#max = max - min
      mul.s     $f11, $f12, $f11     ;#max = r * max
      add.s     $f0, $f11, $f10      ;#return = min + max in f0
      jr $ra

genrandminmax:
      move $t8, $ra         ;
      jal frand             ;
      mov.s $f12,$f0        ;#r = param1
      mov.s $f15, $f0       ;
      jal   minmaxfloat     ;
      mov.s $f12, $f0       ;#return value
      jr   $t8              ;

askforint:
      li        $v0, 4      ;#print string
      syscall               ;
      li        $v0, 5      ;#read int
      syscall               ;
      jr        $ra         ;

mergesort:    #stack1 = start of array, stack2 = end of array
      lw      $a0, 4($sp)   ;
      lw      $a1, 0($sp)   ;#load arguments from stack
      li      $t0, 4        ;
      sub     $sp, $sp, $t0 ;
      sw      $ra, 0($sp)   ;#store return address on the stack

      sub     $t1, $a1, $a0 ;#end - start
      move    $s1, $t1      ;#store end-start to s1
      ble     $t1, $t0, upwards ;#if start-end <= 4: There is only 1 item left

      li      $t2, 4        ;# offset for interval 1 = ((end-start / 4)/2) * 4
      div     $t1, $t2      ;#length / 4
      mflo    $t1           ;#$t1 = l/4
      li      $t3, 2        ;
      div     $t1, $t3      ;#quarter / 2
      mflo    $t3
      mul     $t3, $t2, $t3 ;#offset1 = ((end-start/4)/2) * 4
      add     $t3, $t3, $a0 ;#end1 = offset1 + start
      move    $t2, $a0      ;
      move    $t4, $t3      ;
      move    $t5, $a1      ;# first interval: $t2-$t3, second interval: $t4-$t5

      move    $a0, $t4      ;# store the latter arguments before the active ones
      move    $a1, $t5      ;
      jal     storeOnStack  ;
      move    $a0, $t2      ;
      move    $a1, $t3      ;
      jal     storeOnStack
      jal     mergesort     ;
      jal     mergesort     ;

      upwards:
      lw  $a0, 8($sp)       ;
      lw  $a1, 4($sp)       ;#load arguments from stack (They are behind the $ra adress)
      sub $t2, $a1, $a0     ;
      sub $s2, $a0, $s7     ;
      add $s2, $s2, $s7     ;#s2 = variable start position
      li  $t3, 4            ;
      ble $t2, $t3, endOfMerge;  #if there is only 1 element, ignore the sorting

      move    $t2, $a0      ;
      move    $t3, $a1      ;# save a0 and a1
      move    $t5, $a0      ;# t5 = temp start of array
      li      $v0, 9        ;#allocate memory
      sub     $a0, $a1, $a0 ;#end - start
      move    $t6, $a0      ;# t6 = end-start = length
      syscall
      move    $s0, $v0      ;#overwrite a with the start adress of the new array
      move    $t0, $v0      ;# t1 = start of help array as index
      add     $t2, $t6, $v0 ;# t2 = end of help array = start + (end-start)
      move    $s1, $t2      ;# s1 = end of help array
      copyLoop: #copy everything into the help array
          beq     $t0,$t2, endOfCopy       ;#start == end?
          lwc1  $f1, 0($t5)   ;#load active value
          swc1 $f1, 0($t0)   ;#save float at array position
          addi $t0, $t0, 4    ;
          addi $t5, $t5, 4   ;#increment both array pointer
          j copyLoop        ;
      endOfCopy:
      li      $t4, 4        ;
      li      $t2, 2        ;
      # offset for interval 1 = ((end-start / 4)/2) * 4
      div     $t6, $t4      ;#length / 4
      mflo    $t3           ;
      div     $t3,$t2       ;#((end-start)/4)/2
      mflo    $t3
      mul     $t3, $t3, $t4 ;#t3 = offset
      add     $t3, $s0, $t3 ;# add offset to start adress of help array
      move $t2, $s0         ;#start1
      move $t4, $t3         ;#end1
      move $t5, $s1         ;#end2
      move $t0, $s2         ;#relative start of original adress
  # t0: start active adress
  # t2: start1 #will be incremented when a value is taken
  # t3: start2 #
  # t4: end1
  # t5: end2
  # s0: start of help Array
  # s1: end of help Array
  #    move  $t0, $s0      ; #active adress in actual array
      uploop:
        lwc1  $f1, 0($t2)   ;#load first value of interval 1
        lwc1  $f2, 0($t3)   ;#load first value of interval 2
        c.le.s $f1, $f2     ;#value1 <= value2?
        bc1t  val1smaller   ;
        #write f2 to position and increment t3
        swc1 $f2, 0($t0)   ;#set position in "real" array
        addi $t3, $t3, 4   ;#increment start2
        j endIf             ;
        val1smaller:
          #write f1 to position and increment t2
          swc1 $f1, 0($t0)   ;#set position in "real" array
          addi $t2, $t2, 4   ;#increment start1
        endIf:
        addi  $t0, $t0, 4   ;#increment active adress

        bge   $t2,$t4, firstIntervalFinished;
        bge   $t3, $t5, secondIntervalFinished; # TODO: is it possible to have an tail-controlled loop?
        j uploop        ;

      firstIntervalFinished:
        # Loop through the rest items of interval 2
        move $a0, $t3     ;
        move $a1, $t5     ;

        j startGarbageCollecting
      secondIntervalFinished:
        # TODO: Set loop parameter for garbage col.
        move $a0, $t2     ;
        move $a1, $t4     ;
      startGarbageCollecting:
        lwc1 $f1, 0($a0)   ;#load first value of interval 1
        swc1 $f1, 0($t0)   ;#set position in "real" array
        addi $a0, $a0, 4   ;#increment pointer
        addi $t0, $t0, 4   ;#increment position in "real" array
        bge  $a0, $a1, endOfMerge ;
        j startGarbageCollecting    ;

      endOfMerge:
      lw      $t0, 0($sp)   ;#load $ra from stack
      jal     releaseFromStack  ;#release a0 and a1 from stack
      addi    $sp, $sp, 4   ;#release $ra from current stack
      jr      $t0           ;

storeOnStack:
  li      $t0, 4        ;
  sub     $sp, $sp, $t0 ;
  sw      $a0, 0($sp)   ;#store arguments on stack
  sub     $sp, $sp, $t0 ;
  sw      $a1, 0($sp)   ;

  jr $ra;
releaseFromStack:
  addi    $sp, $sp, 8   ;#release arguments from current stack
  jr      $ra           ;

  printArray:
    li $t0, 0           ;#index
    printloop: beq   $t0, $s6, endOfPrintLoop ;#head controlled: index == n?
          li    $v0, 1      ;#print int
          addi  $a0, $t0, 1 ;
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
          j     printloop      ;
    endOfPrintLoop:
          jr $ra;

exitsequence:
      li  $v0, 4            ;
      la  $a0, exit         ;
      syscall               ;

      li  $v0, 5            ;
      syscall               ;
      li  $t0, 1            ;
      beq $v0, $t0, main    ;

      li  $v0, 4            ;
      la  $a0, exitm        ;
      syscall
      li  $v0, 10           ;#exit
      syscall               ;
