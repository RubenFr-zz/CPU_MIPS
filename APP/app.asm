#-------------------- MEMORY Mapped I/O -----------------------
#define PORT_LEDG[7-0] 0x800 - LSB byte (Output Mode)
#define PORT_LEDR[7-0] 0x804 - LSB byte (Output Mode)
#define PORT_HEX0[7-0] 0x808 - LSB byte (Output Mode)
#define PORT_HEX1[7-0] 0x80C - LSB byte (Output Mode)
#define PORT_HEX2[7-0] 0x810 - LSB byte (Output Mode)
#define PORT_HEX3[7-0] 0x814 - LSB byte (Output Mode)
#define PORT_SW[7-0]   0x818 - LSB byte (Input Mode)
#define PORT_KEY[3-1]  0x81C - LSB nibble (3 push-buttons - Input Mode)
#--------------------------------------------------------------
#define UCTL           0x820 - Byte 
#define RXBF           0x821 - Byte 
#define TXBF           0x822 - Byte 
#--------------------------------------------------------------
#define BTCTL          0x824 - LSB byte 
#define BTCNT          0x828 - Word 
#--------------------------------------------------------------
#define IE             0x82C - LSB byte 
#define IFG            0x82D - LSB byte
#define TYPE           0x82E - LSB byte
#----------------------- Registers  ---------------------------
# s0 - RXBUF
# s1 - Counter option 1
# s2 - Counter option 2
# s3 - Address next char to send
# s4 - How many char sent
#---------------------- Data Segment --------------------------
.data 
	IV: 	.word main            # Start of Interrupt Vector Table
		.word UartRX_ISR
		.word UartRX_ISR
		.word UartTX_ISR
	        .word BT_ISR
		.word KEY1_ISR
		.word KEY2_ISR
		.word KEY3_ISR

	N:	.word 0xB71B00
	Message:
		.word 'I',' ','l','o','v','e',' ','m','y',' ','N','e','g','e','v'
	
#---------------------- Code Segment --------------------------	
.text
main:	addi $sp,$0,0x800 # $sp=0x800
	addi $t0,$0,0x20  
	sw   $t0,0x824       # BTHOLD (disable BT)
	sw   $0,0x828        # BTCNT=0
	sw   $0,0x82C        # IE=0
	sw   $0,0x82D        # IFG=0
	
	add  $s0,$0,$0	# Init reg
	add  $s1,$0,$0
	add  $s2,$0,$0
	add  $s3,$0,$0
	add  $s4,$0,$0

	addi $t0,$0,0x09
	sw   $t0,0x820       # UTCL=0x09 (SWRST=1, 115200 BR)
	
	addi $t0,$0,0x01     # RXIE
	sw   $t0,0x82C       # IE=0x01
	
	ori  $k0,$k0,0x01    # EINT, $k0[0]=1 uses as GIE
	
L:	j    L		    # infinite loop
	
KEY1_ISR:
	la   $s3,Message	# $s3 points to string to be sent
	add  $s4,$0,$0		# $s4 counts how many chars sent
	
	lw   $t0,0($s3)		# take the current char
	sw   $t0,0x822  	# write to TXBUF
	
	lw   $t1,0x82D 		# read IFG
	andi $t1,$t1,0xFFF7 
	sw   $t1,0x82D 		# clr KEY1IFG
	
	jr   $k1       # reti
	
KEY2_ISR:
	jr   $k1       # reti

KEY3_ISR:
	jr   $k1       # reti
		
BT_ISR:	addi $t0,$0,'1'			# $t2 = 1
	beq  $s0,$t0,Option1_BT		# Branch if RXBF = '1'
	addi $t0,$0,'2'			# $t2 = 2
	beq  $s0,$t0,Option2_BT		# Branch if RXBF = '2'

End_BT: jr   $k1        # reti
        
UartRX_ISR:
init:	addi $t0,$zero,0x20
	sw   $t0,0x824       # BTIP=0, BTSSEL=0, BTHOLD=1
	sw   $0,0x828        # BTCNT=0
	sw   $0,0x82C        # IE=0
	sw   $0,0x82D        # IFG=0
		
	lw   $s0,0x821  	# read RXBUF
	
	addi $t1,$0,'1'		# $t1 = 1
	beq  $s0,$t1,Option1	# Branch if RXBUF = '1'
	
	addi $t1,$0,'2'		# $t1 = 2
	beq  $s0,$t1,Option2	# Branch if RXBUF = '2'
	
	addi $t1,$0,'3'		# $t1 = 3
	beq  $s0,$t1,Option3	# Branch if RXBUF = '3'
	
	addi $t1,$0,'4'		# $t1 = 4
	beq  $s0,$t1,Option4	# Branch if RXBUF = '4'
	
End:    jr   $k1        	# reti

UartTX_ISR:
	addi	$s3, $s3, 4	# increment address
	addi	$s4, $s4, 1	# increment counter
	
	addi	$t0,$0,15	
	beq	$s4,$t0,End_TX	# branch if 15 chars were sent

				# otherwise: 
	lw   	$t0,0($s3)	# take the current char
	sw   	$t0,0x822  	# write to TXBUF
	
End_TX:	jr   	$k1        	# reti

Option1:
	#add  $s1,$0,$0 		# Init counter 
	sw   $s1,0x800  	# write to PORT_LEDG[7-0]
	
	addi $t0,$0,0x26  
	sw   $t0,0x824       	# BTIP=6, BTSSEL=0, BTHOLD=1 - 0.5 sec
	
	addi $t0,$0,0x1460
	lui  $t0, 0x0024
	sw   $t0,0x828        	# BTCNT= 0x241460 - 0.5 sec
	
	addi $t0,$0,0x06  
	sw   $t0,0x824       	# BTIP=6, BTSSEL=0, BTHOLD=0 - 0.5 sec
	
	addi $t0,$0,0x05 	# BTIE | RXIE
	sw   $t0,0x82C        	# IE=0x05
	
	j    End
	
Option1_BT:
	addi $s1,$s1,1
	sw   $s1,0x800  # write to PORT_LEDG[7-0]
	j    End_BT
	
Option2:
	#addi $s2,$0,0xFF 	# Init counter 
	sw   $s2,0x804  	# write to PORT_LEDR[7-0]
	
	addi $t0,$0,0x26  
	sw   $t0,0x824       	# BTIP=6, BTSSEL=0, BTHOLD=1 - 0.5 sec
	
	addi $t0,$0,0x1460
	lui  $t0, 0x0024
	sw   $t0,0x828        # BTCNT= 0x241460 - 0.5 sec
	
	addi $t0,$0,0x06  
	sw   $t0,0x824        # BTIP=6, BTSSEL=0, BTHOLD=0 - 0.5 sec
	
	addi $t0,$0,0x05 
	sw   $t0,0x82C        # IE=0x05
	
	j    End
	
Option2_BT:
	addi $s2,$s2,-1
	sw   $s2,0x804  # write to PORT_LEDR[7-0]
	j    End_BT
	
Option3:
	addi $t0,$0,0x0B 	# KEY1IE | RXIE | TXIE
	sw   $t0,0x82C        	# IE=0x0B
	j    End

Option4:
	addi $t0,$0,0x01 	# RXIE
	sw   $t0,0x82C        	# IE=0x01
	
	add  $s1,$0,$0		# Reset counters Option 1 
	add  $s2,$0,$0		# Reset counters Option 2
	
	sw   $0,0x804  		# write to PORT_LEDR[7-0]
	sw   $0,0x800  		# write to PORT_LEDG[7-0]
	j    End	