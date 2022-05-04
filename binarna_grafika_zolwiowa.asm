#only 24-bits 600x50 pixels BMP files are supported
.eqv BMP_FILE_SIZE 90122
.eqv BYTES_PER_ROW 1800
#space for 30 16-bits instructions
.eqv BIN_FILE_SIZE 60

	.data
#space for the 600x50px 24-bits bmp image
.align 4
res:	.space 2
image:	.space BMP_FILE_SIZE
instructions:	.space BIN_FILE_SIZE

bmpfilename:	.asciiz "source1.bmp"
outfilename:	.asciiz "output.bmp"
binfilename:	.asciiz "input.bin"
fileproblemsmsg:	.asciiz " can't be open"
invalidinstructionmsg:	.asciiz "Invalid instruction"

	.text
main:
#read BMP file - set arguments
	la $a0, bmpfilename
	la $a1, image
	la $a2, BMP_FILE_SIZE
	jal read_file
	
#read BIN file - set arguments
	la $a0, binfilename
	la $a1, instructions
	la $a2, BIN_FILE_SIZE
	jal read_file
	
	li $s0, 0	#x coordinate
	li $s1, 0	#y coordinate
	li $s2, 0	#direction -up/down/right/left
	li $s3, 0	#pen - up/down
	li $s4, 0 	#color
	
	jal execute_instructions
	
#save output file - set arguments
	la $a0, outfilename
	la $a1, image
	la $a2, BMP_FILE_SIZE
	jal save_bmp_file

exit:
	li $v0, 10
	syscall
	
#=============READ FILE==================================================================
read_file:
#description: 
#	reads the contents of a file into memory
#arguments:
#	$a0 - file name
#	$a1 - memory address
#	$a2 - file size
#return value: none
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, 4($sp)
	sub $sp, $sp, 4		#push $t2
	sw $t2, 4($sp)
	sub $sp, $sp, 4		#push $t3
	sw $t3, 4($sp)
	
	move $t2, $a1	#move memory address from $a1 to $t2
	move $t3, $a2	#move file size from $a2 to $t3
	
#open file
	li $v0, 13
        li $a1, 0		#flags: 0-read file
        li $a2, 0		#mode: ignored
        syscall
        bltz $v0,  open_file_problems 		#problems with file
	move $s1, $v0      #save the file descriptor

#read file
	li $v0, 14
	move $a0, $s1
	move $a1, $t2
	move $a2, $t3
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
        lw $t3, 4($sp)		#restore (pop) $t3
	add $sp, $sp, 4
	lw $t2, 4($sp)		#restore (pop) $t2
	add $sp, $sp, 4
	lw $s1, 4($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
        
#file problems
open_file_problems:
	li $v0, 4
	syscall	#print file name
	li $v0, 4
	la $a0, fileproblemsmsg
	syscall	#print " can't be open"
	j exit
	
#=============SAVE FILE==================================================================
save_bmp_file:
#description: 
#	saves bmp file stored in memory to a file
#arguments:
#	$a0 - file name
#	$a1 - memory address
#	$a2 - file size
#return value: none
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, 4($sp)
	sub $sp, $sp, 4		#push $t2
	sw $t2, 4($sp)
	sub $sp, $sp, 4		#push $t3
	sw $t3, 4($sp)
	
	move $t2, $a1	#move memory address from $a1 to $t2
	move $t3, $a2	#move file size from $a2 to $t3
	
#open file
	li $v0, 13
        li $a1, 1		#flags: 1-write file
        li $a2, 0		#mode: ignored
        syscall
        bltz $v0, save_file_problems 		#problems with file
	move $s1, $v0      # save the file descriptor
	
#save file
	li $v0, 15
	move $a0, $s1
	move $a1, $t2
	move $a2, $t3
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
	
	lw $t3, 4($sp)		#restore (pop) $t3
	add $sp, $sp, 4
	lw $t2, 4($sp)		#restore (pop) $t2
	add $sp, $sp, 4
	lw $s1, 4($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
	
#file problems
save_file_problems:
	li $v0, 4
	syscall	#print file name
	li $v0, 4
	la $a0, fileproblemsmsg
	syscall	#print " can't be open"
	j exit
	
#=============PUT PIXEL==================================================================
put_pixel:
#description: 
#	sets the color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#	$a2 - 0RGB - pixel color
#return value: none

	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)
	sub $sp, $sp, 4		#push $t1 to the stack
	sw $t1,4($sp)
	sub $sp, $sp, 4		#push $t2 to the stack
	sw $t2,4($sp)
	sub $sp, $sp, 4		#push $t3 to the stack
	sw $t3,4($sp)

	la $t1, image + 10	#adress of file offset to pixel array
	lw $t2, ($t1)		#file offset to pixel array in $t2
	la $t1, image		#adress of bitmap
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move $t3, $a0		
	sll $a0, $a0, 1
	add $t3, $t3, $a0	#$t3= 3*x
	add $t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	#pixel address 
	
	#set new color
	sb $a2,($t2)		#store B
	srl $a2,$a2,8
	sb $a2,1($t2)		#store G
	srl $a2,$a2,8
	sb $a2,2($t2)		#store R

	lw $t3, 4($sp)		#restore (pop) $t3
	add $sp, $sp, 4
	lw $t2, 4($sp)		#restore (pop) $t2
	add $sp, $sp, 4
	lw $t1, 4($sp)		#restore (pop) $t1
	add $sp, $sp, 4
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
#=============EXECUTE INSTRUCTIONS========================================================
execute_instructions:
#description: 
#	reads instructions from BIN file and executes them

	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)
	
	la $t0, instructions
	addiu $t3, $t0, BIN_FILE_SIZE	#$t3 contains end of BIN file

read_instruction: 	#read instruction from BIN file
	beq $t0, $t3, end_execution	#if all instructions were read -> save BMP file
	lh $t1, ($t0)	#load one instruction
	and $t1, $t1, 0xffff
	srl $t2, $t1, 8
	and $t1, $t1, 0xff
	sll $t1, $t1, 8
	or $t1, $t1, $t2	#$t1 contains current instruction
	addiu $t0, $t0, 2	#set $t0 to next instruction
#interpret instruction
	and $t2, $t1, 0x03	#$t2 contains command
	beq $t2, 0, set_pen_state
	beq $t2, 1, move_turtle
	beq $t2, 2, set_direction
	
#=============SET POSITION==========================
	and $s1, $t1, 0xfc
	srl $s1, $s1, 2	#set y coordinate
#read next instruction to get x coordinate
	beq $t0, $t3, invalid_instruction
	lh $t1, ($t0)
	srl $t2, $t1, 8
	and $t1, $t1, 0xff
	sll $t1, $t1, 8
	or $t1, $t1, $t2	#$t1 contains instruction with x coordinate
	addiu $t0, $t0, 2
	and $s0, $t1, 0x3ff	#set x coordinate
	j read_instruction	#read next instruction

#=============SET PEN STATE=========================
set_pen_state:
	and $s3, $t1, 0x8
	srl $s3, $s3, 3	#set pen state - up/down
#red color
	and $t2, $t1, 0xf000	#get red
	sll $s4, $t2, 8
	sll $t2, $t2, 4
	or $s4, $s4, $t2	#set red
#green color
	and $t2, $t1, 0xf00	#get green
	sll $t4, $t2, 4
	or $t2, $t2, $t4
	or $s4, $s4, $t2	#set green
#blue color
	and $t2, $t1, 0xf0	#get blue
	srl $t4, $t2, 4
	or $t2, $t2, $t4
	or $s4, $s4, $t2	#set blue
	
	j read_instruction	#read next instruction

#=============MOVE==================================
move_turtle:
	and $t1, $t1, 0xffc0
	srl $t1, $t1, 6	#$t1 contains distance
	beq $s2, 0, move_right	#$s2 contains direction - up/down/right/left 
	beq $s2, 1, move_up
	beq $s2, 2, move_left

#set move down attributes
	sub $t2, $s1, $t1
	bge $t2, 0, if_move_down_with_color	#if y coordinate more than 0
	li $t2, 0

if_move_down_with_color:
	beqz $s3, end_move_vertical	#s3 contains pen state - up/down
	li $t4, -1
	j go_vertical

#set move up attributes
move_up:
	add $t2, $s1, $t1
	ble $t2, 49, if_move_up_with_color	#if y coordinate less than image size (50)
	li $t2, 49

if_move_up_with_color:
	beqz $s3, end_move_vertical	#s3 contains pen state - up/down
	li $t4, 1

#vertical(y) movement
go_vertical:
	move $a0, $s0	#load x coordinate
	move $a1, $s1	#load y coordinate
	move $a2, $s4	#load color
	jal put_pixel
	add $s1, $s1, $t4	#next pixel while moving down
	bne $t2, $s1, go_vertical
	
end_move_vertical:
	move $s1, $t2	#if move without the color -> move $t5 to $s1
	j read_instruction	#read next instruction

#set move right attributes
move_right:
	add $t2, $s0, $t1
	ble $t2, 599, if_move_right_with_color	#if x coordinate less than image size (600)
	li $t4, 599

if_move_right_with_color:
	beqz $s3, end_move_horizontal	#s3 contains pen state - up/down
	li $t4, 1
	j go_horizontal

#set move left attributes
move_left:
	sub $t2, $s0, $t1
	bge $t2, 0, if_move_left_with_pen	#if x coordinate more than 0
	li $t4, 1

if_move_left_with_pen:
	beqz $s3, end_move_horizontal	#s3 contains pen state - up/down
	li $t4, -1

#horizontal(y) movement
go_horizontal:
	move $a0, $s0	#load x coordinate
	move $a1, $s1	#load y coordinate
	move $a2, $s4	#load color
	jal put_pixel
	add $s0, $s0, $t4	#next pixel while moving right
	bne $t2, $s0, go_horizontal
	
end_move_horizontal:
	move $s0, $t2	#if move without the color -> move $t4 to $s0
	j read_instruction	#read next instruction

#=============SET DIRECTION=========================
set_direction:
	and $s2, $t1, 0xc000
	srl $s2, $s2, 14	#set direction
	j read_instruction	#read next instruction
	
#invalid instruction
invalid_instruction:
	li $v0, 4
	la $a0, invalidinstructionmsg	#print "Invalid instruction"
	syscall
	
end_execution:
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
#========================================================================================
