    .data
#    .word   0x7F7FFFFF  0x73800000
    .word   0x789ABCDE  0x800ABCDE
#    .word   0x4426AA3D  0x44A42434  
#    .word   0xC426EA3D  0x45870B71
#    .float 0.5625 9.75
    .text
main:
    lui     $t0, 0x1001
    lw		$s1, 0($t0)         # opA
    lw		$s2, 4($t0)         # opB
    lui     $s6, 0x8000         # sign bit inverter
    lui     $s7, 0x0080         # implied 1

    add     $a0, $s1, $zero
    jal     absoluteValue
    add     $t1, $zero, $v0
    add     $a0, $s2, $zero
    jal     absoluteValue
    add     $a0, $zero, $t1
    add     $a1, $zero, $v0
    jal     checkOrder
    add     $a1, $v0, $zero
    add     $a2, $v1, $zero
    jal     spliceOperands
    jal     catchSpecial
    jal     sum
    sw		$v0, 32($t0)

    add     $a0, $s1, $zero
    jal     absoluteValue
    add     $t1, $zero, $v0
    add     $a0, $s2, $zero
    jal     absoluteValue
    add     $a0, $zero, $t1
    add     $a1, $zero, $v0
    jal     checkOrder
    add     $a1, $v0, $zero
    add     $a2, $v1, $zero
    bne     $a1, $s2, invertOpASign
    xor     $a1, $s2, $s6
    j		splice
invertOpASign:
    xor     $a2, $s2, $s6
splice:
    jal     spliceOperands
    jal     subtract
    sw		$v0, 36($t0)
    
    jal     multiply
    jal     divide

    jal     spliceOperands

    j       end

subtract:
    sw		$ra, 0($sp)
    addi     $sp, $sp, 4
    jal     sum
    addi     $sp, $sp, -4
    lw      $ra, 0($sp)

    jr      $ra

sum:
    sw		$ra, 0($sp)

    add     $a0, $t2, $zero         # load opA exponent as argument
    add     $a1, $t5, $zero         # load opB exponent as argument
    jal     getExponentDifference

    add     $a0, $t1, $zero         # load opA mantissa as argument
    add     $a1, $t4, $zero         # load opB mantissa as argument
    add     $a2, $v0, $zero         # load exponent difference as argument
    jal     alignMantissa
    add     $t1, $v0, $zero
    add     $t4, $v1, $zero         

    bne     $t3, $t6, subtractMantissa
    add     $t7, $t1, $t4           # add aligned mantissas
    j		countLeadingZeroes
subtractMantissa:
    sub     $t7, $t1, $t4

countLeadingZeroes:
    clz     $t8, $t7                # count leading number of zeroes
    sub     $t7, $t7, $s7           # remove implied one
    addi    $t6, $t8, -8            # check if normalization is needed
    bne		$t6, $zero, normalize	# if $t0 != $t1 then target
returnAdderAnswer:
    add     $t8, $t2, $zero         # E3 = E1
    add     $t9, $t3, $zero
    sll     $t9, $t9, 8
    add     $t9, $t9, $t8           # add sign and exponent
    addi	$t9, $t9, 127           # add 127
    sll     $t9, $t9, 23            # place sign and exponent in the upper 9 bits
    add     $t9, $t9, $t7           # add the mantissa
    add		$v0, $t9, $zero         # store in  return variable
    
    lw      $ra, 0($sp)
    jr      $ra

normalize:
    bltz    $t6, normalizeRight
    sllv    $t7, $t7, $t6
    sub     $t8, $t2, $t6
    j       returnAdderAnswer
normalizeRight:
    add     $a0, $t6, $zero
    jal     absoluteValue
    add     $t6, $zero, $v0
    srlv    $t7, $t7, $t6
    add     $t8, $t2, $t6
    j       returnAdderAnswer

checkOrder:
    slt     $t9, $a1, $a0
    beq     $t9, $zero, switcheroo
    add     $v0, $s1, $zero
    add     $v1, $s2, $zero
    jr      $ra
switcheroo:
    add     $v0, $s2, $zero
    add     $v1, $s1, $zero
    jr      $ra

absoluteValue:
    bltz    $a0, negateOp
    add     $v0, $a0, $zero
    jr      $ra
negateOp:
    xor     $v0, $a0, $s6
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
    srlv    $v1, $a1, $a2       # shift opB mantissa and store as return value
    add     $v0, $zero, $a0     # store opA mantissa as return value
    jr      $ra

spliceOperands:
    sw		$ra, 0($sp)
    add     $a0, $a1, $zero
    jal		getMantissa
    add     $t1, $v0, $zero     # temporarily save mantissa
    jal     getExponent
    add     $t2, $v0, $zero     # temporarily save exponent
    jal     getSign
    add     $t3, $v0, $zero     # temporarily save sign

    add     $a0, $a2, $zero
    jal		getMantissa
    add     $t4, $v0, $zero     # temporarily save mantissa
    jal     getExponent
    add     $t5, $v0, $zero     # temporarily save exponent 
    jal     getSign
    add     $t6, $v0, $zero     # temporarily save sign
    lw      $ra, 0($sp)
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