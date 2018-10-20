    .data
#    .word   0x7F7FFFFF  0x73800000
#    .word   0x789ABCDE  0x800ABCDE
#    .word   0x4426AA3D  0x44A42434  
#    .word   0xC426EA3D  0x45870B71
#    .float 0.5625 9.75
#    .float  125.125 12.0625
    .float  127.03125 16.9375
    .text
main:
    lui     $t0, 0x1001
    lw		$s1, 0($t0)         # opA
    lw		$s2, 4($t0)         # opB
    lui     $s6, 0x8000         # sign bit inverter
    lui     $s7, 0x0080         # implied 1
    addi	$s5, $zero, 24      # 24 bits

    add     $a0, $s1, $zero
    jal     floatAbsoluteValue
    add     $t1, $zero, $v0
    add     $a0, $s2, $zero
    jal     floatAbsoluteValue
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
    jal     floatAbsoluteValue
    add     $t1, $zero, $v0
    add     $a0, $s2, $zero
    jal     floatAbsoluteValue
    add     $a0, $zero, $t1
    add     $a1, $zero, $v0
    jal     checkOrder
    add     $a1, $v0, $zero
    add     $a2, $v1, $zero
    bne     $a1, $s2, invertOpASign
    xor     $a1, $s2, $s6           # invert sign bit of opB
    j		splice
invertOpASign:
    xor     $a2, $s2, $s6           # invert sign bit of opB
splice:
    jal     spliceOperands
    jal     subtract
    sw		$v0, 36($t0)
    
    add     $a1, $s1, $zero
    add     $a2, $s2, $zero
    jal     spliceOperands
    jal     multiply
    sw		$v0, 40($t0)

    add     $a1, $s1, $zero
    add     $a2, $s2, $zero
    jal     spliceOperands
    jal     divide
    sw		$v0, 44($t0)

#    jal     spliceOperands

    j       end

divide:
    sw      $ra, 0($sp)
    xor     $t9, $t3, $t6           # get the product sign bit
    add     $t3, $zero, $zero       # initialize upper remainder-quotient array (RQA) as zero
    add     $t6, $zero, $t1         # initialize lower remainder-quotient array (RQA) with opA mantissa
    sll     $t6, $t6, 8             
    lw      $ra, 0($sp)
    jr      $ra

multiply:
    sw      $ra, 0($sp)
    xor     $t9, $t3, $t6           # get the product sign bit
    add     $t8, $zero, $zero       # initialize product high with zero
    add     $t7, $zero, $t4         # initialize product low with opB mantissa
    add     $t6, $zero, $zero       # initialize counter to zero 
sequentialMultiplication:
    beq     $t6, $s5, sequentialMultiplicationEnd
    andi    $t3, $t7, 1
    beq		$t3, $zero, skipAddOpB	# if product low lsb is zero, skip addition
    add     $t8, $t8, $t1           # add opA mantissa to product high
skipAddOpB:
    andi    $t3, $t8, 1             # get product high lsb
    sll     $t3, $t3, 23            # shift to 24-bit msb position
    srl     $t7, $t7, 1             # shift product low to the right once
    srl     $t8, $t8, 1             # shift product high to the right once
    add     $t7, $t7, $t3           # add pre-shifted product high lsb to shifted product low as msb
    addi    $t6, $t6, 1             # increment counter by one
    j		sequentialMultiplication
sequentialMultiplicationEnd:
    clz     $t6, $t8
    addi    $t6, $t6, -8
    and     $t3, $t8, $s7           # get msb of product high
    srl     $t3, $t3, 23
    sll     $t8, $t8, 9
    srl     $t8, $t8, 9             # truncate msb of product high
    sllv    $t8, $t8, $t6           # shift product high to the left x times
    sub     $t6, $s5, $t6           # get number of shifts needed
    srlv    $t7, $t7, $t6           # shift product low to the left x times
    add     $t7, $t8, $t7           # join product high and product low
    add     $t8, $t2, $t5           # add exponents of opA and opB to get exponent of product
    add     $t8, $t8, $t3           # add the msb of product high to the exponent
    addi    $t8, $t8, 127           # add exponent offset
    sub     $t6, $s5, $t6           # get number of shifts needed
    sub     $t8, $t8, $t6           # subtract normalization offset
    add     $v0, $t9, $zero         # insert sign bit into return value
    sll     $v0, $v0, 8
    add     $v0, $v0, $t8           # insert exponent bits into return value
    sll     $v0, $v0, 23
    addu    $v0, $v0, $t7           # insert mantissa bits into return value
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
    bne		$t6, $zero, adderNormalize	# if $t0 != $t1 then target
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

subtract:
    sw		$ra, 0($sp)
    addi     $sp, $sp, 4
    jal     sum
    addi     $sp, $sp, -4
    lw      $ra, 0($sp)
    jr      $ra

adderNormalize:
    bltz    $t6, adderNormalizeRight
    sllv    $t7, $t7, $t6
    sub     $t8, $t2, $t6
    j       returnAdderAnswer
adderNormalizeRight:
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

floatAbsoluteValue:
    bltz    $a0, floatNegateOp
    add     $v0, $a0, $zero
    jr      $ra
floatNegateOp:
    xor     $v0, $a0, $s6
    jr      $ra

absoluteValue:
    bltz    $a0, negateOp
    add     $v0, $a0, $zero
    jr      $ra
negateOp:
    sub     $v0, $zero, $a0
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