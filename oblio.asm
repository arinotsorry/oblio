.data
	role_prompt:	.asciiz "Do you accept the role of challenger [enter 1] or guesser [enter 2]?\n"
	guess_prompt: .asciiz	"Guess: "
	score_prompt: .asciiz "Score: "
	
	score_intro: 	.asciiz "Score: "
	guess_intro:	.asciiz "Guess: "
	
	role: 				.word 	0 	# 1 for game master, 2 for guesser
	guess:				.word		0		# This will be the guess
	next_guess:		.word		0		# This will be for storing the next guess so that we only have to go through the loop once
	score:				.word		0		# This will be the score
	target:				.word		0		# Program's secret number
	guessed:			.word		0		# Becomes 1 if game ended
	
	guesses_made: .double	0.0		# number of guesses so far
	guesses_this_round: .double 0.0 # number of guesses this round
	games_played:	.double	0.0		# number of games played
	
	guesses_message_a:	.asciiz		"We've played "
	guesses_message_b:	.asciiz		" games were played taking "
	guesses_message_c:	.asciiz		" guesses / game.\n"
	good_bye:						.asciiz		"Good bye.\n"
	
	ending_message: .asciiz " guesses to reach target "

	.align 2
	targets:			.space	20160 # 5040 numbers * 4 bytes/number = 20160
	
	you_win:	.asciiz "Congratulations you smartie pants, you win!\nWant to play again???? [enter 1]\nIf not that's okay :'( [enter 0]\n"
	play_again:				.asciiz		"Play another game? [y/n]: "
				
	wrong_digits_err: .asciiz 	"\nYour input needs to be four digits long\n"
	duplicates_err: 	.asciiz 	"\nYour number needs to consist of four unique digits\n"
	invalid_clue_err: .asciiz 	"\nBruh. Your clue isn't possible, amigo.\n"
	role_err:					.asciiz		"\nBabe sweetheart that wasn't one of the options boo\n"
	bad_score_err:		.asciiz		"\nAw baby, you must've entered a wrong score. It's okay, accidents happen <3\n"
	
	# print debugging:
	newline: .asciiz "\n"
	
.text
	j main
	
# ---------------
# GUESSER METHODS
# ---------------

	# "main" method for guesser, just calls other guessing functions
	guesser:
		# add 1 to number of games played
		lw $t0, games_played
		addi $t0, $t0, 1
		sw $t0, games_played
		
		# set guesses_this_round to 0
		sw $zero, guesses_this_round
		
		jal choose_target
		
		j guessing_loop # just in case sequence gets messed up when I reorder these
		
		guessing_loop:
		jal take_in_guess
		jal score_user_guess
		
		# end
		j end
		
	choose_target:
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
		
		# update number of valid guesses made
		lw $t0, guesses_made
		addi $t0, $t0, 1
		sw $t0, guesses_made
		
		lw $t0, guesses_this_round
		addi $t0, $t0, 1
		sw $t0, guesses_this_round
		
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
		
		j compare_a
		
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
		# print guesses this turn
		li $v0, 1
		lw $a0, guesses_this_round
		syscall
			
		li $v0, 4
		la $a0, ending_message
		syscall
			
		li $v0, 1
		lw $a0, target
		syscall
			
		li $v0, 4
		la $a0, newline
		syscall
			
		li $v0, 4
		la $a0, play_again
		syscall
			
		li $v0, 12
		syscall # $v0 contains y or n
			
		li $t0, 'n'
		beq $v0, $t0, end
			
		li $v0, 4
		la $a0, newline
		syscall
			
		j guesser
		
		
# ------------------
# CHALLENGER METHODS
# ------------------	
	
	challenger:
		lw $t0, games_played
		addi $t0, $t0, 1
		sw $t0, games_played
		
		sw $zero, guesses_this_round
		
		# have to regenerate targets since we're eliminating from this list every round
		jal generate_targets
		
		jal make_first_guess
		
		challenger_sub_loop:
		
			jal get_score
		
			li $t0, 40
			lw $t1, score
		
			beq $t0, $t1, print_congrats_message
		
			jal loop_through_list
		
			jal make_guess
		
			j challenger_sub_loop
		
		print_congrats_message:
			# print guesses this turn
			li $v0, 1
			lw $a0, guesses_this_round
			syscall
			
			li $v0, 4
			la $a0, ending_message
			syscall
			
			li $v0, 1
			lw $a0, guess # the last guess was correct, so print that
			syscall
			
			li $v0, 4
			la $a0, newline
			syscall
			
			li $v0, 4
			la $a0, play_again
			syscall
			
			li $v0, 12
			syscall # $v0 contains y or n
			
			li $t0, 'n'
			beq $v0, $t0, end
			
			li $v0, 4
			la $a0, newline
			syscall
			
			j challenger
		
		# make guess
		# take in and save score
		# loop through list, comparing every number's score
		# jal loop_through_list (and remove number(s))
		
		# end
		j end
		
	get_score:
		# ask for score
		li $v0, 4
		la $a0, score_prompt
		syscall
		
		# take in score
		li $v0, 5
		syscall # $v0 contains integer read
		
		# assign guess to $v0's contents
		sw $v0, score
		
		jr $ra
		
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
		
		# increment counter of valid numbers
		addi $t4, $t4, 1
		
		jr $ra
		
	quit_to_loop:
		jr $ra
		
# --------------
# TARGET PRUNING
# --------------

loop_through_list:
	# Given: 	guess is computer's guess
	#					score is computer's score
	
	# Get address of list
	la $a0, targets
	li $a1, 0 			# index of offset
	
	# stack shenanigans
	addi $sp, $sp, -8 	# space for 1 register
	sw $ra, 0($sp)
		
	jal loop_list_a
	
	# stack shenanigans 2: Electric Boogaloo
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	jr $ra
	
loop_list_a:
	# Given: 	$a1 is index
	#la $a0, targets
	
	# stack shenanigans
	addi $sp, $sp, -8 	# space for 1 register
	sw $ra, 0($sp)
		
	# get memory address - $t0 + ($t1 * 4)
	la $a0, targets
	mul $t0, $a1, 4
	add $t0, $t0, $a0		# $t0 is memory address of current number
		
	# set $t0 to current number in list
	lw $t0, ($t0) 			# we'll just calculate mem addr again later, it's okay
	
	# if $t0 is 0, skip it
	beq $t0, $zero, skip_number
	
	# Current number: $t0, $t1, $t2, $t3
	# Guess					: $t4, $t5, $t6, $t7
	
	# dissect current number for easy comparison
	li $t8, 10 		# div by 10

	div $t0, $t8 	# Current_Number(ABC) stored in lo, CN(D) stored in hi
	mfhi $t3			# $t4 = CN(D)
	mflo $t0			# $t1 = CN(ABC)
	
	div $t0, $t8	# CN(AB) stored in lo, CN(C) stored in hi
	mfhi $t2			# $t3 = CN(C)
	mflo $t0			#	$t1 = CN(AB)
	
	div $t0, $t8	#CN(A) stored in lo, CN(B) stored in hi
	mfhi $t1			# $t2 = CN(B)
	mflo $t0			# $t1 = CN(A)
	
	# dissect guess
	# $t8 still has 10
	lw $t4, guess
	
	div $t4, $t8	# guess(ABC) stored in lo, guess(D) stored in hi
	mfhi $t7			# $t7 = guess(D)
	mflo $t4			# $t4 = guess(ABC)
	
	div $t4, $t8	# guess(AB) stored in lo, guess(C) stored in hi
	mfhi $t6			# $t6 = guess(C)
	mflo $t4			# $t4 = guess(AB)
	
	div $t4, $t8	# guess(A) stored in lo, guess(B) stored in hi
	mfhi $t5			# $t5 = guess(B)
	mflo $t4			# $t4 = guess(A)
	
	# $t8 will represent the score
	li $t8, 0
	
	j compare_a_computer
	
	# Current number: $t0, $t1, $t2, $t3
	# Guess					: $t4, $t5, $t6, $t7
	compare_a_computer:
		beq $t4, $t0, in_place_a_computer
		beq $t4, $t1, misplaced_a_computer
		beq $t4, $t2, misplaced_a_computer
		beq $t4, $t3, misplaced_a_computer
		j compare_b_computer
		
		in_place_a_computer:
			addi $t8, $t8, 10
			j compare_b_computer
			
		misplaced_a_computer:
			addi $t8, $t8, 1
			j compare_b_computer
			
		compare_b_computer:
		beq $t5, $t0, misplaced_b_computer
		beq $t5, $t1, in_place_b_computer
		beq $t5, $t2, misplaced_b_computer
		beq $t5, $t3, misplaced_b_computer
		j compare_c_computer
		
		in_place_b_computer:
			addi $t8, $t8, 10
			j compare_c_computer
			
		misplaced_b_computer:
			addi $t8, $t8, 1
			j compare_c_computer
			
		compare_c_computer:
		beq $t6, $t0, misplaced_c_computer
		beq $t6, $t1, misplaced_c_computer
		beq $t6, $t2, in_place_c_computer
		beq $t6, $t3, misplaced_c_computer
		j compare_d_computer
		
		in_place_c_computer:
			addi $t8, $t8, 10
			j compare_d_computer
			
		misplaced_c_computer:
			addi $t8, $t8, 1
			j compare_d_computer
		
		compare_d_computer:
		beq $t7, $t0, misplaced_d_computer
		beq $t7, $t1, misplaced_d_computer
		beq $t7, $t2, misplaced_d_computer
		beq $t7, $t3, in_place_d_computer
		j compare_scores
		
		in_place_d_computer:
			addi $t8, $t8, 10
			j compare_scores
			
		misplaced_d_computer:
			addi $t8, $t8, 1
			j compare_scores
	
	compare_scores:
		lw $t9, score
		
		beq $t8, $t9, store_next_guess
		j set_to_zero
		
	store_next_guess:
		# get memory address - $t0 + ($t1 * 4)
		la $a0, targets
		mul $t0, $a1, 4
		add $t0, $t0, $a0		# $t0 is memory address of current number
		
		# set $t0 to current number in list
		lw $t0, ($t0)
		
		# load guess into $t1
		lw $t1, guess
		
		# if $t0 and $t1 are equal, skip to the next number
		beq $t0, $t1, end_of_loop
		
		# otherwise, store the next guess in next_guess
		sw $t0, next_guess
		j end_of_loop
		
	set_to_zero:
		la $a0, targets # just in case
		mul $t0, $a1, 4
		add $t0, $t0, $a0		# $t0 is memory address of current number
		sw $zero, ($t0)
		j end_of_loop
	
	skip_number:
	end_of_loop:
	# stack shenanigans 2: Electric Boogaloo
	lw $ra, 0($sp)
	addi $sp, $sp, 8
		
	# check conditional
	addi $a1, $a1, 1		# i++
	slti $t2, $a1, 5040		# $t2 = 1 if i < 5040
	bne $t2, $zero, loop_list_a
		
	jr $ra
	
	make_first_guess:
		# add 1 to guesses counter
		lw $t0, guesses_made
		addi $t0, $t0, 1
		sw $t0, guesses_made
		
		lw $t0, guesses_this_round
		addi $t0, $t0, 1
		sw $t0, guesses_this_round
		
		# Print guess intro
		li $v0, 4
		la $a0, guess_intro
		syscall
		
		li $t0, 123
		sw $t0, guess # value at 0th index of list, don't want to get the 0th index cause I'm lazy
		
		# Print 0 for aesthetics
		li $v0, 11
		li $a0, 48
		syscall
		
		# Print guess
		li $v0, 1
		lw $a0, guess
		syscall
		
		# Print new line
		li $v0, 4
		la $a0, newline
		syscall
		
		jr $ra
		
	make_guess:
		# add 1 to guesses counter
		lw $t0, guesses_made
		addi $t0, $t0, 1
		sw $t0, guesses_made
		
		lw $t0, guesses_this_round
		addi $t0, $t0, 1
		sw $t0, guesses_this_round
		
		lw $t1, next_guess
		lw $t0, guess
		
		beq $t0, $t1, bad_score
		
		li $v0, 4
		la $a0, guess_intro
		syscall
		
		lw $t1, next_guess
		li $t2, 1000
		slt $t0, $t1, $t2 # $t0 = 1 if next_guess < 1000, else $t0 = 0
		beq $t0, $zero, make_guess_next
		
		# print a 0 first if guess < 1000
		li $v0, 11
		li $a0, 48
		syscall
		
		make_guess_next:
		li $v0, 1
		lw $a0, next_guess
		syscall
		
		li $v0, 4
		la $a0, newline
		syscall
		
		lw $t0, next_guess
		sw $t0, guess
		
		jr $ra
		
	bad_score:
		li $v0, 4
		la $a0, bad_score_err
		syscall
		
		la $a0, play_again
		syscall
		
		li $v0, 5
		syscall # $v0 has taken-in value
		
		beq $v0, $zero, end
		
		j challenger
		
		
# ----
# MAIN
# ----
	
	# print exit message
	end:
		li $v0, 4
		la $a0, newline
		syscall
		
		li $v0, 1
		lw $a0, games_played
		syscall
		
		li $v0, 4
		la $a0, guesses_message_b
		syscall
		
		l.d $f2, guesses_made
		l.d $f4, games_played
		div.s $f12, $f2, $f4
		li $v0, 2
		syscall
		
		li $v0, 4
		la $a0, guesses_message_c
		syscall
		
		li $v0, 4
		la $a0, newline
		syscall
		
		li $v0, 4
		la $a0, good_bye
		syscall
		
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
