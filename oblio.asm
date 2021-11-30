.data
	role_prompt:	.asciiz "Do you accept the role of challenger [enter 1] or guesser [enter 2]?\n"
	role: 				.word 	0 	# 1 for game master, 2 for guesser
	
	wrong_digits_err: .asciiz 	"Your input needs to be four digits long. Please enter another number.\n"
	duplicates_err: 	.asciiz 	"Your number needs to consist of four unique digits. Please enter another number.\n"
	invalid_clue_err: .asciiz 	"Bruh. Your clue isn't possible, amigo.\n"
	role_err:					.asciiz		"Babe sweetheart that wasn't one of the options boo\n"
	
	# print debugging:
	challenger_method: .asciiz	"You've arrived to challenger!\n"
	guesser_method: .asciiz "You've arrived to guesser!\n"
	main_method: .asciiz "You've arrived to main!\n"
	end_method: .asciiz "You've arrived to end!\n"
	
.text
	j main
	
	challenger:
		# Print that we're in the challenger function
		li $v0, 4
		la $a0, challenger_method
		syscall
		
		# end
		j end
		
	guesser:
		# Print that we're in the guesser function
		li $v0, 4
		la $a0, guesser_method
		syscall
		
		# end
		j end
	
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
