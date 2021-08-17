#-------------------- MEMORY Mapped I/O -----------------------
#define PORT_LEDG[7-0] 0x800 - LSB byte (Output Mode)
#define PORT_LEDR[7-0] 0x804 - LSB byte (Output Mode)
#define PORT_HEX0[7-0] 0x808 - LSB byte (Output Mode)
#define PORT_HEX1[7-0] 0x80C - LSB byte (Output Mode)
#define PORT_HEX2[7-0] 0x810 - LSB byte (Output Mode)
#define PORT_HEX3[7-0] 0x814 - LSB byte (Output Mode)
#define PORT_SW[7-0]   0x818 - LSB byte (Input Mode)
#--------------------------------------------------------------

.data 
	ID: 		.word 4,3,8,2,7,2,9,3 
	sortedID: 	.word 0,0,0,0,0,0,0,0
	IDsize: 	.word 8 
	D:		.word 0x3D0900
	
.text
	sw   $0,0x800 # write to PORT_LEDG[7-0]
	sw   $0,0x804 # write to PORT_LEDR[7-0]
	sw   $0,0x808 # write to PORT_HEX0[7-0]
	sw   $0,0x80C # write to PORT_HEX1[7-0]
	sw   $0,0x810 # write to PORT_HEX2[7-0]
	sw   $0,0x814 # write to PORT_HEX3[7-0]
	
###########################################################################
### Values Initialization
###########################################################################

	la	$s0,ID
	la	$s1,sortedID
	lw 	$t1,IDsize			# $t1 = Value of IDsize
	addi $s3, $zero, 4			# $s3 = 4
	mul	$t2,$t1,$s3			# size of the ID in memory 	
	add $t0,$s0,$t2    			# $t0 holds the address of the end of the ID
    	
###########################################################################
### Sort ID
###########################################################################
copy:
	lw	$t2, 0($s0)
	nop 
	sw	$t2, 32($s0)		# copy an int to the sortedID
	addi	$s0, $s0, 4
	bne	$s0, $t0, copy		# if $s0 != $t0, we must keep iterating
	
	addi	$t0,$t0,28
	
loop1:	
	add 	$t1, $zero, $zero	# $t1 is a flag to know if list sorted (init 0)
	la 	$s0, sortedID		# $s0 is the base address of the sortedID to sort
	
loop2:
	lw	$t2, 0($s0)
	lw	$t3, 4($s0)
	slt	$t4, $t3, $t2		# $t4 = 1 if $t3<$t2
	beq	$t4, $zero, continue	# if $t4 = 1, then swap
	addi	$t1, $zero, 1		# flag set to 1 means we changed the array
	sw	$t2, 4($s0)
	sw	$t3, 0($s0)

continue:
	addi	$s0, $s0, 4
	bne	$s0, $t0, loop2		# if $s0 != $t0, we must keep iterating
	bne	$t1, $zero, loop1	# if $t4 = 1, we swapped and must go back at the beginning
	
###########################################################################	
### Infinite loop for printing contents of array to HEX0.
### $s0: address of sorted array, $t0: i
###########################################################################
END:	la	$s0, sortedID
	add 	$t0, $zero, $zero	# $t0 = 0, i = 0

infinite_loop:	
	lw	$t1, 0x818		# If SW0 = 0 -> RESTART
	and	$t1, $t1, 1
	beq	$t1, $zero, END
	
	and	$t1, $t0, 7		# $t1 = i and 0x7
	mul	$t1, $t1, $s3		# $t1 = $t1 * 4	(offset)
	add	$t2, $s0, $t1		# Address of the element in the sorted array
	lw	$t3, 0($t2)		# Load value of element in the sorted array
	nop 
	sw   	$t3, 0x808 		# write to PORT_HEX0[7-0]
	addi	$t0, $t0, 1
	
delay: 
	move 	$t1,$zero  	# $t1=0
	lw	$t3, D		# $t3=0
	
L:	addi $t1,$t1,1  	# $t1=$t1+1
	slt  $t2,$t1,$t3    # if $t1<N than $t2=1
	beq  $t2,$zero,infinite_loop   #if $t1>=N then go to Loop label
	j    L

