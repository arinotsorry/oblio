.data
	role_prompt:	.asciiz "Do you accept the role of challenger [enter 1] or guesser [enter 2]?\n"
	role: 				.word 	0 	# 1 for game master, 2 for guesser
	targets:			.space	20160 # 5040 numbers * 4 bytes/number = 20160
		
	wrong_digits_err: .asciiz 	"Your input needs to be four digits long. Please enter another number.\n"
	duplicates_err: 	.asciiz 	"Your number needs to consist of four unique digits. Please enter another number.\n"
	invalid_clue_err: .asciiz 	"Bruh. Your clue isn't possible, amigo.\n"
	role_err:					.asciiz		"Babe sweetheart that wasn't one of the options boo\n"
	
	# print debugging:
	challenger_method: .asciiz	"You've arrived to challenger!\n"
	challenger_post_generate: .asciiz "In challenger, finished generating\n"
	challenger_post_loop: .asciiz "In challenger, finished looping\n"
	guesser_method: .asciiz "You've arrived to guesser!\n"
	main_method: .asciiz "You've arrived to main!\n"
	end_method: .asciiz "You've arrived to end!\n"
	number_combos: .asciiz "Total number of combos: "
	colon:	.asciiz	": "
	newline: .asciiz "\n"
	
.text
	j main
	
# ------------------
# CHALLENGER METHODS
# ------------------	
	
	challenger:
		# Print that we're in the challenger function
		li $v0, 4
		la $a0, challenger_method
		syscall
		
		# call generate_targets
		jal generate_targets
		
		# Print that we're in the challenger function
		li $v0, 4
		la $a0, challenger_post_generate
		syscall
		
		# loop through list
		jal loop_through_list
		
		# Print that we're in the challenger function
		li $v0, 4
		la $a0, challenger_post_loop
		syscall
		
		# end
		j end
		
# ---------------
# GUESSER METHODS
# ---------------

	guesser:
		# Print that we're in the guesser function
		li $v0, 4
		la $a0, guesser_method
		syscall
		
		# end
		j end
		
# --------------
# TARGET GENERATION
# --------------

	generate_targets:
		# $t0 is a, $t1 is b, $t2 is c, $t3 is d
		# $t4 is counter
		# $t5 is approved number
		move $t0, $zero
		move $t1, $zero
		move $t2, $zero
		move $t3, $zero
		move $t4, $zero
		
		# stack shenanigans
		addi $sp, $sp, -8 	# space for 1 register
		sw $ra, 0($sp)
		
		jal loop_a
		
		# Print total number
		#li $v0, 4
		#la $a0, number_combos
		#syscall
		
		#li $v0, 1
		#move $a0, $t4
		#syscall
		
		#li $v0, 11
		#li $a0, 10
		#syscall
		
		# stack shenanigans 2: Electric Boogaloo
		lw $ra, 0($sp)
		addi $sp, $sp, 8
		jr $ra
	
		
	loop_a:
		# stack shenanigans
		addi $sp, $sp, -8 	# space for 1 register
		sw $ra, 0($sp)
		
		# call loop_b
		move $t1, $zero
		jal loop_b
		
		# stack shenanigans 2: Electric Boogaloo
		lw $ra, 0($sp)
		addi $sp, $sp, 8
		
		# check conditional
		addi $t0, $t0, 1		# i++
		slti $t6, $t0, 10		# $t6 = 1 if i < 10
		bne $t6, $zero, loop_a
		
		jr $ra
		
	loop_b:
		# stack shenanigans
		addi $sp, $sp, -8 	# space for 1 register
		sw $ra, 0($sp)
		
		# call loop_c
		move $t2, $zero
		jal loop_c
		
		# stack shenanigans 2: Electric Boogaloo
		lw $ra, 0($sp)
		addi $sp, $sp, 8
		
		# check conditional
		addi $t1, $t1, 1		# i++
		slti $t6, $t1, 10		# $t6 = 1 if i < 10
		bne $t6, $zero, loop_b
		
		jr $ra

	loop_c:
		# stack shenanigans
		addi $sp, $sp, -8 	# space for 1 register
		sw $ra, 0($sp)
		
		# call loop_d
		move $t3, $zero
		jal loop_d
		
		# stack shenanigans 2: Electric Boogaloo
		lw $ra, 0($sp)
		addi $sp, $sp, 8
		
		# check conditional
		addi $t2, $t2, 1		# i++
		slti $t6, $t2, 10		# $t6 = 1 if i < 10
		bne $t6, $zero, loop_c
		
		jr $ra

	loop_d:
		# stack shenanigans
		addi $sp, $sp, -8 	# space for 1 register
		sw $ra, 0($sp)
		
		jal check_number
		
		# stack shenanigans 2: Electric Boogaloo
		lw $ra, 0($sp)
		addi $sp, $sp, 8
		
		# check conditional
		addi $t3, $t3, 1		# i++
		slti $t6, $t3, 10		# $t6 = 1 if i < 10
		bne $t6, $zero, loop_d
		
		jr $ra
		
	check_number:
		beq $t0, $t1, quit_to_loop
		beq $t0, $t2, quit_to_loop
		beq $t0, $t3, quit_to_loop
		beq $t1, $t2, quit_to_loop
		beq $t1, $t3, quit_to_loop
		beq $t2, $t3, quit_to_loop
		j record_number
		
	record_number:
		# $t4 is counter
		# $t5 is number
		li $t6, 10		# Babe are you a decimal number? Cause you're a base 10 ;)
		
		move $t5, $t0			#       a
		mul $t5, $t5, $t6	#     a 0
		add $t5, $t5, $t1 #     a b
		mul $t5, $t5, $t6	#   a b 0
		add $t5, $t5, $t2 #   a b c
		mul $t5, $t5, $t6	# a b c 0
		add $t5, $t5, $t3	# a b c d
		
		# Add to some kind of list
		la $t7, targets		# $t7 = array address, $t3 = # of elements init'd
		mul $t8, $t4, 4		# $t8 = offset
		add $t7, $t7, $t8	# $t7 = address of element to fill in
		sw $t5, ($t7)
		
		# right now, just print the number
		#li $v0, 1
		#move $a0, $t5
		#syscall
		
		# Print new line
		#li $v0, 11
		#li $a0, 10
		#syscall
		
		# increment counter of valid numbers
		addi $t4, $t4, 1
		
		jr $ra
		
	quit_to_loop:
		jr $ra
		
# --------------
# TARGET PRUNING
# --------------

loop_through_list:
	# Get address of list
	la $t0, targets
	li $t1, 0 			# $t1 is what index we're at, $t2 will be offset
	
	# stack shenanigans
	addi $sp, $sp, -8 	# space for 1 register
	sw $ra, 0($sp)
		
	jal loop_list_a
	
	# stack shenanigans 2: Electric Boogaloo
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr $ra
	
	
loop_list_a:
		# stack shenanigans
		addi $sp, $sp, -8 	# space for 1 register
		sw $ra, 0($sp)
		
		# get memory address - $t0 + ($t1 * 4)
		mul $t2, $t1, 4
		add $t3, $t2, $t0		# $t3 now has mem addr to check
		
		lw $t4, ($t3) # $t4 should have the value we're looking at
		li $t5, 8367
		beq $t4, $t5, remove_number
		j skip_number
		
		remove_number:
		sw $zero, ($t3)
		
		skip_number:
		# print the number we're looking at:
		li $v0, 1
		move $a0, $t1
		syscall
		
		li $v0, 4
		la $a0, colon
		syscall
		
		li $v0, 1
		move $a0, $t4
		syscall
		
		li $v0, 4
		la $a0, newline
		syscall
		
		# stack shenanigans 2: Electric Boogaloo
		lw $ra, 0($sp)
		addi $sp, $sp, 8
		
		# check conditional
		addi $t1, $t1, 1		# i++
		slti $t2, $t1, 5040		# $t2 = 1 if i < 5040
		bne $t2, $zero, loop_list_a
		
		jr $ra
		
# ----
# MAIN
# ----
	
	end:
		# Tell system this is end of main function
		li $v0, 10
		syscall
		
	main:
		# Print role prompt
		li $v0, 4
		la $a0, role_prompt
		syscall
	
		# Get player's role
		li $v0, 5
		syscall
		sw $v0, role # either 1 or 2 should be in role rn
		
		# Check whether user is guesser or checker
		li $t1 1
		li $t2 2
		lw $t0, role # $t0 = role just to check
		beq $t0, $t1, challenger
		beq $t0, $t2, guesser
		
		# else, print "invalid role" message,
		li $v0, 4
		la $a0, role_err
		syscall
		# and go to main
		jal main
	
		# Tell system this is end of main function
		j end
