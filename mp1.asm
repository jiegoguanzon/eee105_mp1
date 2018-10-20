    .data
    .word   0x4426AA3D  0x44A42434
    .text
main:
    lui     $t0, 0x1001
    lw		$s1, 0($t0)         # opA
    lw		$s2, 4($t0)         # opB
    lui     $s7, 0x0080         # implied 1

    jal     catchSpecial

    add     $a0, $s1, $zero
    jal		getMantissa
    add     $t1, $v0, $zero     # temporarily save mantissa
    jal     getExponent
    add     $t2, $v0, $zero     # temporarily save exponent
    jal     getSign
    add     $t3, $v0, $zero     # temporarily save sign

    add     $a0, $s2, $zero
    jal		getMantissa
    add     $t4, $v0, $zero     # temporarily save mantissa
    jal     getExponent
    add     $t5, $v0, $zero     # temporarily save exponent 
    jal     getSign
    add     $t6, $v0, $zero     # temporarily save sign

    jal     sum
    jal     subtract
    jal     multiply
    jal     divide

    j       end

sum:
    add     $a0, $t2, $zero         # load opA exponent as argument
    add     $a1, $t5, $zero         # load opB exponent as argument
    sw		$ra, 0($sp)
    jal     getExponentDifference
    add     $a0, $t1, $zero         # load opA mantissa as argument
    add     $a1, $t4, $zero         # load opB mantissa as argument
    add     $a2, $v0, $zero         # load exponent difference as argument
    jal     alignMantissa
    add     $t1, $v0, $zero
    add     $t4, $v1, $zero         
    add     $t9, $t1, $t4           # add aligned mantissas
    sub     $t9, $t9, $s7           # remove implied one
    clz     $t8, $t9                # count leading number of zeroes
    addi	$t8, $t8, 128           # add 127 + 1
    sll     $t8, $t8, 23            # place exponent in 2nd to 9th bit
    add     $t8, $t8, $t9           # add the exponent and mantissa
    sw		$t8, 32($t0)            # store answer
    lw      $ra, 0($sp)
    jr      $ra
    
subtract:
    jr      $ra
    
multiply:
    jr      $ra
    
divide:
    jr      $ra

catchSpecial:
    jr      $ra

getMantissa:
    sll     $v0, $a0, 9
    srl     $v0, $v0, 9         # filter mantissa
    add		$v0, $v0, $s7		# add implied 1
    jr		$ra

alignMantissa:
    bltz    $a2, alignOpA       # if exponent difference is negative then align opA
    srlv    $v1, $a1, $a2       # shift opB mantissa and store as return value
    add     $v0, $zero, $a0     # store opA mantissa as return value
    jr      $ra
alignOpA:
    sub     $a2, $zero, $a2     # negate exponent difference
    srlv    $v0, $a0, $a2       # shift opA mantissa and store as a return value
    add     $v1, $zero, $a1     # store opB mantissa as return value
    jr      $ra

getExponent:
    sll     $v0, $a0, 1
    srl     $v0, $v0, 24        # filter exponent
    addi	$v0, $v0, -127      # remove offset
    jr		$ra

getExponentDifference:
    sub     $v0, $a0, $a1       # opA exponent - opB exponent
    jr      $ra

getSign:
    srl     $v0, $a0, 31        # filter sign
    jr      $ra

end: