.data
menuOptionLabel1: .asciiz "Enter the knapsack size: "
menuOptionLabel2: .asciiz "Enter the path for the input file: "
errorStringLabel1: .asciiz "File reading error"

inputDataFileName: .space 1024
outputFileName: .asciiz "output.txt"
inputData: .space 1024
valuesArray: .float 0.0 : 100 
weightsArray: .float 0.0 : 100
ratiosArray: .float 0.0 : 100
indicesArray: .word 0:100
sizeOfArrays: .word 0
knapsackWeight: .float 15.0
knapsackSize: .word 0
knapsack: .word 0:100
totalValues: .float 0.0
totalWeights: .float 0.0
itemLabel: .asciiz "Item"
totalValuesLabel: .asciiz "Total Value: "
totalWeightsLabel: .asciiz "Total Size: "
itemsPackedLabel: .asciiz "List of items packed: "
errorStringLabel2: .asciiz "Check your input and try again"
bufferSpace: .space 128
.text

mainProgram:
    li $v0, 4
    la $a0, menuOptionLabel1
    syscall
    
    li $v0, 6 # read float
    syscall
    mov.s $f0, $f0 #  move single precision float
    
    li $v0, 4
    la $a0, errorStringLabel1
    c.le.s $f0, $f12 # cc = ($f0<= $f12)
    bc1t terminateProgram # branch if (terminateProgram == 1)
    swc1 $f0, knapsackWeight
    
    li $v0, 4
    la $a0, menuOptionLabel2
    syscall

    li $v0, 8 # read string
    la $a0, inputDataFileName
    li $a1, 1024
    syscall
    
    jal deleteNewLineFunc1
    
    move $t0, $v0
    li   $t1, -1
    beq  $t0, $t1, errorFileRead
    
    move $a0, $t0
    li   $v0, 16
    syscall
    
    jal readInputFile # jal jump and link
    jal convertToArrays
    jal calculateRatios
    jal displayArrays
    jal sortRatios
    jal fillKnapsack
    jal displayPackedItems
    j exitProgram

terminateProgram:
    li $v0, 4
    la $a0, errorStringLabel2
    syscall
    li $v0, 10
    syscall


readInputFile:
	li $v0, 13
	la $a0, inputDataFileName	#read this file
	li $a1, 0
	syscall
	move $s0, $v0
	
	li $v0, 14
	move $a0, $s0
	la $a1, inputData		#input data is here
	li $a2, 1024
	syscall
	
	li $v0, 16                 # System call to close a file
	move $a0, $s0              # Load file descriptor
	syscall
	jr $ra

displayPackedItems:
    li $v0, 11
    li $a0, 10
    syscall
    
    li $v0, 4
    la $a0, itemsPackedLabel
    syscall
    
    la $t0, knapsack
    lw $t1, knapsackSize
    
displayPackedItemsLoop:
    beqz $t1, endDisplayKnapsack
    
    li $v0, 4
    la $a0, itemLabel
    syscall
    
    li $v0, 1
    lw $a0, 0($t0)
    syscall
    
    addi $t0, $t0, 4
    subi $t1, $t1, 1
    
    beqz $t1, endDisplayKnapsack
    
    li $v0, 11
    li $a0, 44
    syscall
    
    li $v0, 11
    li $a0, 32
    syscall
    
    j displayPackedItemsLoop

endDisplayKnapsack:
    li $v0, 11
    li $a0, 10
    syscall
    
    li $v0, 4
    la $a0, totalWeightsLabel
    syscall
    
    lwc1 $f1, totalWeights
    lwc1 $f2, totalValues
    li $v0, 2
    mov.s $f12, $f1
    syscall
    
    li $v0, 11
    li $a0, 10
    syscall
    
    li $v0, 4
    la $a0, totalValuesLabel
    syscall
    
    li $v0, 2
    mov.s $f12, $f2
    syscall
    jr $ra

fillKnapsack:
    la $t0, weightsArray
    la $t8, valuesArray
    la $t1, indicesArray
    lwc1 $f2, knapsackWeight
    lw $t3, sizeOfArrays
    li $t4, 0
    la $t5, knapsack

fillKnapsackLoop:
    beq $t3, 0, endFillingKnapsack
    subi $t3, $t3, 1
    lw $s0, 0($t1)
    li $s1, 4
    mul $s1, $s1, $s0
    move $s2, $t0
    add $s2, $s2, $s1
    lwc1 $f3, 0($s2)
    move $s2, $t8
    add $s2, $s2, $s1
    lwc1 $f4, 0($s2)
    c.lt.s $f3, $f2
    bc1t addToKnapsack
    addi $t1, $t1, 4
    j fillKnapsackLoop

addToKnapsack:
    sub.s $f2, $f2, $f3
    sw $s0, 0($t5)
    addi $t5, $t5, 4
    add.s $f6, $f6, $f3
    add.s $f7, $f7, $f4
    c.eq.s $f2, $f5
    bc1t endFillingKnapsack
    addi $t1, $t1, 4
    addi $t4, $t4, 1
    j fillKnapsackLoop

endFillingKnapsack:
    sw $t4, knapsackSize
    swc1 $f6, totalWeights
    swc1 $f7, totalValues
    jr $ra

sortRatios:
    lw $t8, sizeOfArrays
    li $t9, 0

sortRatiosOuterLoop:
    beq $t9, $t8, sortRatiosExit
    la $s0, ratiosArray
    la $s1, indicesArray
    li $t6, 0

sortRatiosInnerLoop:
    addi $t7, $t8, -1
    beq $t6, $t7, sortRatiosSkipInner

    lwc1 $f0, 0($s0)
    lwc1 $f1, 4($s0)
    c.lt.s $f1, $f0
    bc1t sortRatiosNoSwap

    swc1 $f0, 4($s0)
    swc1 $f1, 0($s0)
    lw $t4, 0($s1)
    lw $t5, 4($s1)
    sw $t4, 4($s1)
    sw $t5, 0($s1)

sortRatiosNoSwap:
    addi $t6, $t6, 1
    addi $s0, $s0, 4
    addi $s1, $s1, 4
    j sortRatiosInnerLoop

sortRatiosSkipInner:
    addi $t9, $t9, 1
    j sortRatiosOuterLoop

sortRatiosExit:
    jr $ra

calculateRatios:
    la $t1, valuesArray
    la $t0, weightsArray
    la $s0, ratiosArray
    la $s1, indicesArray
    li $t2, 0

    lw $t3, sizeOfArrays

calculateRatiosLoop:
    beq $t2, $t3, exitCalculateRatios

    lwc1 $f0, 0($t0) # floting point load 
    lwc1 $f1, 0($t1)
    div.s $f2, $f1, $f0
    swc1 $f2, 0($s0) # store floting point 
    sw $t2, 0($s1)

    addi $t0, $t0, 4 # next pc 
    addi $t1, $t1, 4
    addi $s0, $s0, 4
    addi $s1, $s1, 4
    addi $t2, $t2, 1

    j calculateRatiosLoop

exitCalculateRatios:
    jr $ra

displayArrays:
    la $t0, valuesArray
    la $t1, weightsArray
    la $s2, ratiosArray
    la $s3, indicesArray
    li $t2, 0
    lw $t3, sizeOfArrays

displayLoop:
    beq $t2, $t3, exitDisplay

    li $v0, 1 # print integer
    lw $a0, 0($s3)
    syscall

    li $v0, 11 # print char
    li $a0, 46 # this is the point "."
    syscall

    li $v0, 11
    li $a0, 32 #this is space
    syscall

    lwc1 $f0, 0($t0)
    li $v0, 2
    mov.s $f12, $f0
    syscall

    li $v0, 11
    li $a0, 32
    syscall

    li $v0, 11
    li $a0, 47 # 
    syscall

    li $v0, 11
    li $a0, 32
    syscall

    lwc1 $f0, 0($t1)
    li $v0, 2
    mov.s $f12, $f0
    syscall

    li $v0, 11
    li $a0, 32
    syscall

    lwc1 $f0, 0($s2)
    li $v0, 2
    mov.s $f12, $f0
    syscall

    li $v0, 11
    li $a0, 10
    syscall

    addi $t0, $t0, 4
    addi $t1, $t1, 4
    addi $s2, $s2, 4
    addi $s3, $s3, 4
    addi $t2, $t2, 1

    j displayLoop

exitDisplay:
    jr $ra

convertToArrays:
    la $s0, inputData
    la $t1, valuesArray
    la $t0, weightsArray
    li $t2, 10
    li $t7, 0

nextPair:
    li $s1, 0
    li $s2, 0

parseValue:
    lb $t3, 0($s0)
    blt $t3, 46, errorFileRead
    bgt $t3, 57, errorFileRead
    beq $t3, 46, dotFound1
    subi $t3, $t3, 48
    add $s1, $s1, $t3
    mul $s1, $s1, $t2
    addi $s0, $s0, 1
    j parseValue

dotFound1:
    addi $s0, $s0, 1
    lb $t3, 0($s0)
    subi $t3, $t3, 48
    add $s1, $s1, $t3
    mtc1 $s1, $f0
    cvt.s.w $f0, $f0
    mtc1 $t2, $f1
    cvt.s.w $f1, $f1
    div.s $f0, $f0, $f1
    swc1 $f0, 0($t0)
    addi $t0, $t0, 4
    addi $s0, $s0, 2

parseWeight:
    lb $t3, 0($s0)
    blt $t3, 46, errorFileRead
    bgt $t3, 57, errorFileRead
    beq $t3, 46, dotFound2
    subi $t3, $t3, 48
    add $s2, $s2, $t3
    mul $s2, $s2, $t2
    addi $s0, $s0, 1
    j parseWeight

dotFound2:
    addi $s0, $s0, 1
    lb $t3, 0($s0)
    subi $t3, $t3, 48
    add $s2, $s2, $t3
    mtc1 $s2, $f0
    cvt.s.w $f0, $f0
    mtc1 $t2, $f1
    cvt.s.w $f1, $f1
    div.s $f0, $f0, $f1
    swc1 $f0, 0($t1)
    addi $t1, $t1, 4
    addi $s0, $s0, 3

    lb $t3, 0($s0)
    addi $t7, $t7, 1
    beq $t3, $0, endParsing
    j nextPair

endParsing:
    sw $t7, sizeOfArrays
    jr $ra

errorFileRead:
    li $v0, 4
    la $a0, errorStringLabel1
    syscall
    j exitProgram



exitProgram:
    li $v0, 10
    syscall

deleteNewLineFunc:
    la $a0, inputData

deleteNewLineFunc1:
    lb $s3, ($a0)
    beq $s3, 10, deleteNewLineFunc2
    beq $s3, 0, returnToFunc
    addi $a0, $a0, 1
    j deleteNewLineFunc1

deleteNewLineFunc2:
    li $s2, 0
    sb $s2, ($a0)
    j returnToFunc

returnToFunc:
    jr $ra


