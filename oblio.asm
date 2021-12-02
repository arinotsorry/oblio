.data
	role_prompt:	.asciiz "Do you accept the role of challenger [enter 1] or guesser [enter 2]?\n"
	guess_prompt: .asciiz	"Enter your guess, boo: \n"
	score_prompt: .asciiz "How'd I do??? "
	
	score_intro: 	.asciiz "Your score is: "
	
	role: 				.word 	0 	# 1 for game master, 2 for guesser
	guess:				.word		0		# This will be the guess
	score:				.word		0		# This will be the score
	target:				.word		0		# Program's secret number
	guessed:			.word		0		# Becomes 1 if game ended

	targets:			.space	20160 # 5040 numbers * 4 bytes/number = 20160
	
	you_win:	.asciiz "Congratulations you smartie pants, you win!\nWant to play again??? [enter 1]\nIf not that's okay :'( [enter 0]\n"
		
	wrong_digits_err: .asciiz 	"\nYour input needs to be four digits long\n"
	duplicates_err: 	.asciiz 	"\nYour number needs to consist of four unique digits\n"
	invalid_clue_err: .asciiz 	"\nBruh. Your clue isn't possible, amigo.\n"
	role_err:					.asciiz		"\nBabe sweetheart that wasn't one of the options boo\n"
	
	# print debugging:
	challenger_method: .asciiz	"You've arrived to challenger!\n"
	challenger_post_generate: .asciiz "In challenger, finished generating\n"
	challenger_post_loop: .asciiz "In challenger, finished looping\n"
	guesser_method: .asciiz "You've arrived to guesser!\n"
	main_method: .asciiz "You've arrived to main!\n"
	end_method: .asciiz "You've arrived to end!\n"
	number_combos: .asciiz "Total number of combos: "
	guess_confirmation: .asciiz "\nYou guessed: "
	target_message: .asciiz "\nI chose target: "
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
		
		# loop through list
		# jal loop_through_list (and remove number(s))
		
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
		
		# jal loop_through_list
		jal choose_target
		
		guessing_loop:
		jal take_in_guess
		jal score_user_guess
		
		# Print that we're in the guesser function
		li $v0, 4
		la $a0, guesser_method
		syscall
		
		# end
		j end
		
	choose_target:
		# read integer
		li $v0, 5
		syscall # $v0 contains integer read
		
		# choose a random number between 0 and 5039
		li $v0, 42
		li $a0, 40 # id of pseudorandom number generator (any int)
		li $a1, 5040 # upper exclusive range of valies
		syscall
		
		move $t1, $a0 		# $t1 contains random number
		li $t2, 5040
		div $t1, $t2			# $t1 % 5040 - $t1 will be 0-5039
		mfhi $t1
		mul $t1, $t1, 4 	# $t1 *= 4
		
		# Get address of list
		la $t0, targets
	
		# get memory address: $t0 + ($t1 * 4)
		add $t1, $t1, $t0		# $t1 now has mem addr to check
		
		lw $t2, ($t1) # $t2 should have the value we're looking at
		sw $t2, target
		
		li $v0, 4
		la $a0, target_message
		syscall
		
		li $v0, 1
		lw $a0, target
		syscall
		
		li $v0, 4
		la $a0, newline
		syscall
		jr $ra
		
	take_in_guess:
		# take in a 4 (or maybe sometimes 3) digit number from the user
		# and store it in guess
		
		# if the user is the guesser (if role = 2)
		# then print the prompt
		#li $t0, 2
		#bne $t0, role, skip # if role != 2, skip printing the prompt
		
		# print prompt
		li $v0, 4
		la $a0, guess_prompt
		syscall
		
		# read integer
		li $v0, 5
		syscall # $v0 contains integer read
		
		# assign guess to $v0's contents
		sw $v0, guess
		move $v0, $t4
		
		# Print intro to guess confirmation
		li $v0, 4
		la $a0, guess_confirmation
		syscall
		
		# Print guess
		li $v0, 1
		lw $a0, guess
		syscall
		
		# Print new line
		li $v0, 4
		la $a0, newline
		syscall
		
		j assess_guess_validity
		
	assess_guess_validity:
		# if guess < 123, display message and jump to take_in_guess
		# if guess > 9876, display message and jump to take_in_guess
		# if guess has duplicates, jump to bad_guess_duplicates
		lw $t4, guess
		
		slti $t0, $t4, 123 # if error, 1
		bne $t0, $zero, bad_guess_digits
		
		sgt $t0, $t4, 9876 # if error, 1
		bne $t0, $zero, bad_guess_digits
		
		# set all the digits to individual registers to make comparison easier
		li $t5, 10
		
		div $t4, $t5	# _ _ _ _/10
		mfhi $t3			# d set to remainder
		mflo $t4			# $t4 set to _ _ _
		
		div $t4, $t5	# _ _ _/10
		mfhi $t2			# c set to remainder
		mflo $t4			# $t4 set to _ _
		
		div $t4, $t5	# _ _/10
		mfhi $t1			# b set to Least Sig Digit (LSD?)
		mflo $t0			# a set to Most Sig Digit
		
		beq $t0, $t1, bad_guess_duplicates
		beq $t0, $t2, bad_guess_duplicates
		beq $t0, $t3, bad_guess_duplicates
		beq $t1, $t2, bad_guess_duplicates
		beq $t1, $t3, bad_guess_duplicates
		beq $t2, $t3, bad_guess_duplicates
		
		jr $ra
		
	bad_guess_digits:
		# display error message and jump to take_in_guess
		li $v0, 4
		la $a0, wrong_digits_err
		syscall
		j take_in_guess
	
	bad_guess_duplicates:
		# display error message and jump to take_in_guess
		li $v0, 4
		la $a0, duplicates_err
		syscall
		j take_in_guess
		
	score_user_guess:
		
		# dissect target for easy comparison
		lw $t0, target
		li $t8, 10
		
		div $t0, $t8	# _ _ _ _/10
		mfhi $t3			# d set to remainder
		mflo $t0			# $t0 set to _ _ _
		
		div $t0, $t8	# _ _ _/10
		mfhi $t2			# c set to remainder
		mflo $t0			# $t4 set to _ _
		
		div $t0, $t8	# _ _/10
		mfhi $t1			# b set to Least Sig Digit (LSD?)
		mflo $t0			# a set to Most Sig Digit
		
		# dissect guess for easy comparison
		lw $t4, guess
		
		div $t4, $t8	# _ _ _ _/10
		mfhi $t7			# d set to remainder
		mflo $t4			# $t0 set to _ _ _
		
		div $t4, $t8	# _ _ _/10
		mfhi $t6			# c set to remainder
		mflo $t4			# $t4 set to _ _
		
		div $t4, $t8	# _ _/10
		mfhi $t5			# b set to Least Sig Digit (LSD?)
		mflo $t4			# a set to Most Sig Digit
		
		move $t8, $zero		# in-place digits
		move $t9, $zero		# out-of-place digits
		
		# compare Ta with Ga, Gb, Gc, Gd
		compare_a:
		beq $t0, $t4, in_place_a
		beq $t0, $t5, misplaced_a
		beq $t0, $t6, misplaced_a
		beq $t0, $t7, misplaced_a
		j compare_b
		
		in_place_a:
			addi $t8, $t8, 1
			j compare_b
			
		misplaced_a:
			addi $t9, $t9, 1
			j compare_b
			
		compare_b:
		beq $t1, $t4, misplaced_b
		beq $t1, $t5, in_place_b
		beq $t1, $t6, misplaced_b
		beq $t1, $t7, misplaced_b
		j compare_c
		
		in_place_b:
			addi $t8, $t8, 1
			j compare_c
			
		misplaced_b:
			addi $t9, $t9, 1
			j compare_c
			
		compare_c:
		beq $t2, $t4, misplaced_c
		beq $t2, $t5, misplaced_c
		beq $t2, $t6, in_place_c
		beq $t2, $t7, misplaced_c
		j compare_d
		
		in_place_c:
			addi $t8, $t8, 1
			j compare_d
			
		misplaced_c:
			addi $t9, $t9, 1
			j compare_d
		
		compare_d:
		beq $t3, $t4, misplaced_d
		beq $t3, $t5, misplaced_d
		beq $t3, $t6, misplaced_d
		beq $t3, $t7, in_place_d
		j display_score
		
		in_place_d:
			addi $t8, $t8, 1
			j display_score
			
		misplaced_d:
			addi $t9, $t9, 1
			j display_score
			
		display_score:
		# calculate the actual score
		mul $t8, $t8, 10
		add $t8, $t8, $t9
		
		# print score
		li $v0, 4
		la $a0, score_intro
		syscall
		
		# if score < 10, print '0'
		slti $t0, $t8, 10
		beq $t0, $zero, skip_extra_zero
		
		li $v0, 11
		li $a0, 48 	# ascii 0
		syscall
		
		skip_extra_zero:
		li $v0, 1
		move $a0, $t8
		syscall
		
		li $v0, 4
		la $a0, newline
		syscall
		
		# if score isn't 40, guessing_loop
		li $t0, 40
		bne $t0, $t8, guessing_loop
		# display 'you win' message
		li $v0, 4
		la $a0, you_win
		syscall
		# take in whether user wants to play again [1 for yes, 0 for no]
		li $v0, 5
		syscall
		beq $v0, $zero, end
		j guesser
		
		
# ----------------------
# TARGET LIST GENERATION
# ----------------------

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
		# Tell system this is end of program
		li $v0, 10
		syscall
		
	main:
		# Generate a list of targets:
		jal generate_targets
		
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
