TITLE Program6     (program6.asm)

; Author: Chris Hauser
; Last Modified:6/8/2020
; OSU email address: hauserch@oregonstate.edu	
; Course number/section: CS271 C400 
; Project Number:  6              Due Date: 6/7/2020
; Description:	Takes in 10 signed integers from users, validates them, then converts them to their numeric representation 
; and stores them in an array. Calculates the sum and average of these numbers and then displays them to user.
; All string writing and getting is done through macros. All conversions are done using string primitive manipulations.

INCLUDE Irvine32.inc


;------------------------------------------------
getString MACRO store:REQ, max_chars:REQ, msg:REQ, entered
; Displays a prompt, then gets a string from the user of the specified number of characters and stores it in the 
; location passed to the macro.
;
; preconditions: none
;
; postconditions: none
;
; receives:		store:	OFFSET of a string buffer terminated with 0
;				chars:	SIZEOF store	
;				msg:	OFFSET of a prompt for input
;				entered:OFFSET of memory location to store number of characters entered by user
;				
; returns: stores the first max_chars - 1 characters entered by the user in the memory location "store". Stores the number of 
; characters entered in the memory location "entered"
;
; Registers changed: None
;------------------------------------------------

	pushad
	displayString	msg
	mov				edx, store
	mov				ecx, max_chars
	call			ReadString
	mov				ebx, entered
	mov				[ebx], eax
	popad

ENDM


;------------------------------------------------
displayString MACRO text:REQ
; Displays the null terminated string which is in the passed memory location
;
; preconditions: none
;
; postconditions: none
;
; receives:		
;				text: a null terminated string
;
; returns: writes the string to output
;
; Registers changed: None
;------------------------------------------------
	
	pushad
	mov		edx, text
	call	WriteString
	popad

ENDM

NUMS_LENGTH		EQU		10					;number of integers to take in
DELTA			EQU		48					; Difference between ASCII of '1' = 49 and value 1

.data

;strings
intro			BYTE	"Program 6: Low Level I/O, by Chris Hauser", 0
instruct		BYTE	"Please enter in 10 signed decimal integers. Each needs to fit inside a 32 bit register." 
				BYTE	"I will then display a list of the integers as well as their sum and average.", 0
goodbye			BYTE	"That's all folks!", 0
prompt			BYTE	"Please input a signed decimal number: ", 0
error_msg		BYTE	"ERROR: That number was too large or was not a signed integer.", 0
nums_msg		BYTE	"These were  the numbers you entered: ", 0
sum_msg			BYTE	"The sum is: ", 0
avg_msg			BYTE	"The average is: ", 0
comma			BYTE	", ", 0
user_str		BYTE	13 DUP(0)				;Range of SDWORD is -2,147,483,648 to +2,147,483,647, so 11 digits plus trailing 0
												; made length 13 to catch numbers which have too many digits in getString
str_val_rev		BYTE	12 DUP(0)
str_val			BYTE	12 DUP(0)
str_len			DWORD	0
digit			SDWORD	1
is_neg			SDWORD	0
is_min			SDWORD	0
sum				SDWORD	0

;arrays
nums_array		SDWORD	NUMS_LENGTH DUP(?)


.code
main PROC

	push	OFFSET intro
	push	OFFSET instruct
	call	introduction
	
	push	OFFSET is_neg			;44
	push	OFFSET digit			;40
	push	OFFSET user_str			;36	
	push	SIZEOF user_str			;32
	push	OFFSET prompt			;28
	push	OFFSET str_len			;24
	push	OFFSET error_msg		;20
	push	DELTA					;16
	push	OFFSET nums_array		;12
	push	NUMS_LENGTH				;8
	call	fillArray					

	call	crlf
	push	NUMS_LENGTH				;32
	push	OFFSET	is_min			;28
	push	OFFSET	nums_msg		;24
	push	OFFSET	comma			;20
	push	OFFSET	str_val			;16
	push	OFFSET	nums_array		;12
	push	DELTA					;8
	call	displayList

	call	crlf
	
	push	OFFSET	sum_msg			;32
	push	OFFSET	sum				;28
	push	NUMS_LENGTH				;24
	push	OFFSET	is_min			;20
	push	OFFSET	str_val			;16
	push	OFFSET	nums_array		;12
	push	DELTA					;8
	call	displaySum

	call	crlf
	push	sum						;28
	push	OFFSET	avg_msg			;24
	push	NUMS_LENGTH				;20
	push	OFFSET	is_min			;16
	push	OFFSET	str_val			;12
	push	DELTA					;8
	call	displayAverage

	push	OFFSET goodbye
	call	outro

	exit	
main ENDP




;------------------------------------------------
introduction PROC
; Displays a program title and introduction
;
; preconditions: none
;
; postconditions: none
;
; receives:		introductory strings:
;				[ebp+12]		@intro			
;				[ebp+8]		@instruct

;
; returns: writes to output
;
; Registers changed: None
;------------------------------------------------
		
		;Display title
		push			ebp
		mov				ebp, esp
		pushad
		displayString	[ebp+12]
		call			crlf
		displayString	[ebp+8]
		call			crlf
		call			crlf
		popad
		pop				ebp
		ret				8

introduction ENDP

;------------------------------------------------
fillArray PROC
; Uses readVal to fill an array with NUMS_LENGTH numeric SDWORD values from the user.
;
; preconditions: nums_array is an array of size NUMS_LENGTH with type SDWORD
;
; postconditions: nums_array contains 
;
; receives:		
;			[ebp+44]:		@is_neg				a flag variable to pass to readVal
;			[ebp+40]:		@digit				a counter to pass to readVal
;			[ebp+36]:		@user_str			the user's string input, filled by getString
;			[ebp+32]:		SIZEOF user_str		
;			[ebp+28]:		@prompt				a prompt used by readVal
;			[ebp+24]:		@str_len			characters entered by user from getString
;			[ebp+20]:		@error_msg			error msg used by readVal
;			[ebp+16]:		DELTA				conversion difference for ascii to numeric
;			[ebp+12]:		@nums_array			address of location of SDWORD array
;			[ebp+8]:		NUMS_LENGTH			size of nums_array
;
; returns: nums_array is filled with type SDWORD numeric values corresponding to the string values
; input by users in readVal
;
; Registers changed: None
;------------------------------------------------
		
		;Display title
		push			ebp
		mov				ebp, esp
		pushad

		mov				esi, [ebp+12]		;OFFSET nums_array
		mov				ecx, [ebp+8]		;NUMS_LENGTH

fill_index:
		push			[ebp+16]			;DELTA						40
		push			[ebp+44]			;OFFSET is_neg				36	
		push			[ebp+40]			;OFFSET digit				32
		push			[ebp+36]			;OFFSET user_str			28
		push			[ebp+32]			;SIZEOF	user_str			24	
		push			[ebp+28]			;OFFSET prompt				20	
		push			[ebp+24]			;OFFSET str_len				16	
		push			[ebp+20]			;OFFSET error_msg			12
		push			esi					;OFFSET nums_array element  8
		call			readVal

		add				esi, 4				;move to next element
		loop			fill_index

		popad
		pop				ebp
		ret				40

fillArray ENDP

;------------------------------------------------
readVal PROC
; Description: Calls getString to display a prompt to the user then get a string representation of an integer
; Validates the number is within the allowed range and only has + or - as first digits.
; Transforms the string into it's corresponding numberic value and stores in the array location passed by fillArray
;
; preconditions: nums_array element address for type SDWORD passed as [ebp+8]
;
; receives: 	
;			[ebp+40]:		DELTA				conversion difference for ascii to numeric
;			[ebp+36]:		@is_neg				flag variable used to mark negative values
;			[ebp+32]:		@digit				counter variable to tell where in string we are for purposes of handling + and -		
;			[ebp+28]:		@user_str			location to store string entered by user in getString
;			[ebp+24]:		SIZEOF user_str		passed to getString 
;			[ebp+20]:		@prompt				passed to getString to prompt user for num
;			[ebp+16]:		@str_len			passed to getString, returns number of chars entered by user afterwards
;			[ebp+12]:		@error_msg			error message 
;			[ebp+8]:		@nums_array element	location where the next converted value from user should be placed in nums_array
;
; returns: Prompts the user to enter a value and tries to validate it. Displays an error message if invalid.
; Places a single valid numeric SDWORD value, converted from the user's getString input, into an array location provided by fillArray.
;
;
; Registers changed: None
;------------------------------------------------
		;
		push			ebp
		mov				ebp, esp
		pushad

Get:
		getString		[ebp+28],[ebp+24],[ebp+20],[ebp+16]				;gets user_str, stores in user_str, updates str_len 
		mov				eax,[ebp+32]				;digit
		mov				ebx,1						;reinitialize digit counter
		mov				[eax], ebx
		mov				eax,[ebp+36]				;is_neg
		mov				ebx,0						;reinitialize is_neg
		mov				[eax], ebx
		mov				ebx, [ebp+16]				;str_len
		mov				ebx, [ebx]
		cmp				ebx, 0						;check if user entered no characters
		JE				Error
		cmp				ebx,12
		JE				Error
		mov				ecx, [ebp+16]				;str_len
		mov				ecx, [ecx]					;length of string without null term
		mov				esi, [ebp+28]				;OFFSET user_str

Convert:
		 
		cld
		xor				eax,eax						; eax = 0
		LODSB										; eax contains next string byte, esi incremented

		;check if plus or minus
		cmp				eax, 43
		JE				Plus
		cmp				eax, 45
		JE				Minus

		;check if within numerical range
		cmp				eax, 48
		JB				Error
		cmp				eax, 57
		JA				Error

		;convert str byte to integer and add it to the current val in the array
		sub				eax, [ebp+40]				;convert string byte to int
		push			eax							;converted string byte on stack
		mov				edi, [ebp+8]				;offset current val
		mov				eax, [edi]					;eax contains current val being built
		mov				ebx, 10						;ebx contains 10
		mul				ebx							;eax contains current val x 10
		JO				error
		pop				ebx							;ebx contains converted string byte
		add				eax, ebx					;eax contains updated built num
		JO				Overflow_check
		mov				edi, [ebp+8]				;array element address
		mov				[edi], eax					;move updated element to @array
		mov				eax, [ebp+32]				;digit@ in eax
		mov				ebx, [eax]					;digit in ebx
		inc				ebx							
		mov				[eax], ebx					;increment digit
		loop			Convert

		jmp				Fin

Plus:
		mov				ebx, [ebp+32]					;digit
		mov				ebx, [ebx]						
		cmp				ebx, 1							;check if 1st digit
		JNE				Error
		mov				eax, [ebp+32]
		mov				ebx, [eax]
		inc				ebx								;increment digit counter
		mov				[eax], ebx
		loop			Convert

Minus:	
		mov				ebx, [ebp+32]					;digit
		mov				ebx, [ebx]				
		cmp				ebx, 1							;check if 1st digit
		JNE				Error
		mov				edi, [ebp+36]					;is_neg
		mov				ebx, -1							
		mov				[edi], ebx						;set is neg to -1
		mov				eax, [ebp+32]					;digit
		mov				ebx, [eax]	
		inc				ebx								
		mov				[eax], ebx						;increment digit counter
		loop			Convert


Overflow_check:				
		;because I negate after, we have to check if the value which caused overflow actually should be the minimum negative value
		cmp				ebx,8
		JNE				Error
		mov				edx,[ebp+36]					;is_neg
		mov				ebx,[edx]
		cmp				ebx, -1							;check if is_neg is flagged
		JNE				Error

		sub				eax, 1
		neg				eax								;subtract to cause overflow in opposite direction and reset val, then negate and sub 1
		sub				eax, 1
			
		
		mov				edi, [ebp+8]
		mov				[edi],eax
		jmp				Ending
	
Error:					

		call			crlf
		displayString	[ebp+12]						;error_msg
		call			crlf
		mov				eax,0
		mov				edi, [ebp+8]			
		mov				[edi],eax
		jmp				Get	

Fin:
		;if is_neg is flagged, negate the entire array element.
		mov				edx,[ebp+36]
		mov				eax,[edx]
		cmp				eax, -1
		JE				Negate
		jmp				Ending

Negate:

		mov				edi, [ebp+8]				;@array element
		mov				eax, [edi]					;eax contains array element
		neg				eax
		JO				Error
		mov				[edi], eax
		mov				eax,[edi]

Ending:
		popad	
		pop				ebp
		ret				36

readVal ENDP


;------------------------------------------------
displayList PROC
;
; Description: prints a title and then displays the values in nums_array as string representations by using writeVal
;
; preconditions: nums_array contains NUMS_LENGTH SDWORD type numeric values 
;
; receives: 
;			
;
;			[ebp+32]:		NUMS_LENGTH			length of nums_array		
;			[ebp+28]:		@is_min				a flag variable to catch the minimum SDWORD value
;			[ebp+24]:		@nums_msg			title for the output 
;			[ebp+20]:		@comma				string of a comma to space outputs
;			[ebp+16]:		@str_val			a str byte array of length 12 to hold the transformed value
;			[ebp+12]:		@nums_array			location of the array of SDWORDS of length NUMS_LENGTH to display 
;			[ebp+8]:		DELTA				conversion difference for ascii to numeric
;
; returns: Moves through nums_array and calls writeVal to display the string representation of each value. 
; Places a title before and commas between values.
;
;
; Registers changed: None

;------------------------------------------------
		
		
		push			ebp
		mov				ebp, esp
		pushad
		displayString	[ebp+24]			;nums_msg
		call			crlf
		mov				esi, [ebp+12]
		mov				ecx, 10
Next:	
		push			[ebp+8]				;20	DELTA
		push			[ebp+28]			;16 is_min
		push			[esi]				;12	current element in nums_array	
		push			[ebp+16]			;8	str_val
		call			writeVal			;print the current value in the num_array

		cmp				ecx, 1
		JE				Done
		displayString	[ebp+20]			;print comma unless last num
		add				esi, 4				;move to next array element
		loop			Next

Done:

		popad
		pop				ebp
		ret				28

displayList ENDP


;------------------------------------------------
writeVal PROC
; Description: Takes in a numeric SDWORD value and transforms it into it's correspodning string equivalent, then writes that string to output using displayString
;
; preconditions: SDWORD value at the location in [ebp+12]
;
; receives: [ebp+20]	DELTA				:add to convert ascii to numeric
;			[ebp+16]	is_min				:flag to catch the minimum value in the range
;			[ebp+12]	numeric value to transform to string and display
;			[ebp+8]		str_val				:a string array to populate with transformed digits of size 12
;
; returns: takes the value at [ebp+12], transforms it into a string representation and prints it to output
;
; Registers changed: None
;------------------------------------------------
		;
		push	ebp
		mov		ebp, esp
		pushad
		mov		ecx, 12
		cld
		mov		edi, [ebp+8]		;offset string array to build

Blank:
		
		mov		eax, 0
		STOSB						;zero out str_val
		loop	Blank

		mov		ebx, [ebp+16]		
		mov		[ebx],eax			;zero out is_min

		mov		eax, [ebp+12]		;value to transform
		mov		edi, [ebp+8]		;Offset of string array to build


		add		eax,0
		JNS		Positive			;check if negative

Negative:
		mov		ebx, 45				;fill first element with '-'
		mov		[edi], ebx
		inc		edi
		neg		eax
		JO		Overflow_case
		jmp		Digit_Check

Overflow_case:
		mov		ebx, [ebp+16]		;is_min
		mov		edx, 1
		mov		[ebx], edx			;save 1 to add in later
		inc		eax
		neg		eax

Positive:
		

Digit_Check:
		
		STD							;move from EDI backwards to the beginning in transformed array
		mov		ecx, 1
		cmp		eax, 10
		JL		Transform

		mov		ecx, 2				;set ecx to number of digits in num/str for this range of values
		inc		edi					;to allow for one more digit in array
		cmp		eax, 100
		JL		Transform

		mov		ecx, 3
		inc		edi
		cmp		eax, 1000
		JL		Transform

		mov		ecx, 4
		inc		edi
		cmp		eax, 10000
		JL		Transform

		mov		ecx, 5
		inc		edi
		cmp		eax, 100000
		JL		Transform

		mov		ecx, 6
		inc		edi
		cmp		eax, 1000000
		JL		Transform

		mov		ecx, 7
		inc		edi
		cmp		eax, 10000000
		JL		Transform

		mov		ecx, 8
		inc		edi
		cmp		eax, 100000000
		JL		Transform

		mov		ecx, 9
		inc		edi
		cmp		eax, 1000000000
		JL		Transform

		mov		ecx, 10
		inc		edi

Transform:
		mov		edx, 0					;clear remainder
		mov		ebx, 10
		div		ebx						
		push	eax						;save quotient
		mov		eax,edx					;remainder in eax
		add		eax, [ebp+20]			;transform numeric to ascii

Overflow_add:
		mov		ebx,[ebp+16]			;is_min flag
		mov		ebx,[ebx]
		cmp		ebx,1
		JNE		Store	
		cmp		ecx,10		
		JNE		Store
		inc		eax						;can only get here if this is the minimum value in range and on the last digit, so add 1 back in
		
Store:
		STOSB							;store digit and move forwards towards beginning
		pop		eax						;restore quotient to continue
		loop	Transform

		DisplayString	[ebp+8]			;write the transformed value to output
		
		popad
		pop		ebp
		ret		16
writeVal ENDP


;------------------------------------------------
displaySum PROC
; Description: Takes in an array of NUMS_LENGTH SDWORDS and computes then displays their sum
;
; preconditions: nums_array contains NUMS_LENGTH SDWORDS
;
; receives: 
;			[ebp+32]	@sum_msg			:title for sum output
;			[ebp+28]	@sum				:address of holder variable for the sum
;			[ebp+24]	NUMS_LENGTH			length of nums_array
;			[ebp+20]	@is_min				a flag variable to catch the minimum SDWORD value
;			[ebp+16]	@str_val			a str byte array of length 12 to hold the transformed value
;			[ebp+12]	@nums_array			location of the array of SDWORDS of length NUMS_LENGTH to display sum of
;			[ebp+8]		DELTA				conversion difference for ascii to numeric
;
; returns: sum of values in nums_array is now in memory location sum. prints sum and title to output using writeVal
;
; Registers changed: None
;------------------------------------------------
		
		push	ebp
		mov		ebp, esp
		pushad
		;display title
		call			crlf
		displayString	[ebp+32]			;sum_msg
		

		;calculate sum
		mov				eax, 0				;initialize accum to 0
		mov				edi, [ebp+12]		;@nums_arrray
		mov				ecx, [ebp+24]		;NUMS_LENGTH

Summer:
		mov				ebx, [edi]			;grab value
		add				eax,ebx				
		add				edi,4			
		loop			Summer

		;store sum
		mov				ebx,[ebp+28]		;@sum
		mov				[ebx], eax

		;pass sum to writeVal to display
		push			[ebp+8]				;20	DELTA
		push			[ebp+20]			;16 is_min
		push			eax					;12	sum
		push			[ebp+16]			;8	str_val
		call			writeVal			;print the current value in eax
		
		popad
		pop		ebp
		ret		28

displaySum ENDP



;------------------------------------------------
displayAverage PROC
; Description: takes in a sum and number of elements and computes then displays the average, rounding down
;
; preconditions: sum is SDWORD. NUMS_LENGTH not equal to 0
;
; receives: 
;			[ebp+28]	sum					sum of nums_array computed by displaySum
;			[ebp+24]	@avg_msg			title for average output
;			[ebp+20]	NUMS_LENGTH			length of nums_array
;			[ebp+16]	@is_min				a flag variable to catch the minimum SDWORD value
;			[ebp+12]	@str_val			a str byte array of length 12 to hold the transformed value
;			[ebp+8]		DELTA				conversion difference for ascii to numeric
;
; returns: average of values in nums_array is computed by dividing by NUMS_LENGTH and written to output using writeVal
;
; Registers changed: None
;------------------------------------------------
		
		push				ebp
		mov					ebp, esp
		pushad

		;display title
		call				crlf
		displayString		 [ebp+24]

		;calculate avg
		mov					eax,[ebp+28]		;sum
		mov					ebx, [ebp+20]		;NUMS_LENGTH
		CDQ										;sign extend eax
		idiv				ebx					;average is in eax
		add					eax,0
		JS					Negative			;if negative, need to subtract 1 unless remainder is 0 to round the same direction as when positive
		jmp					Display

Negative:
		cmp					edx, 0				;check if remainder is 0
		JE					Display
		sub					eax,1

Display:	
		;pass avg to writeVal to display
		push				[ebp+8]				;20	DELTA
		push				[ebp+16]			;16 is_min
		push				eax					;12	average
		push				[ebp+12]			;8	str_val
		call				writeVal			;print the current value in eax

		popad
		pop					ebp
		ret					24

displayAverage ENDP

;------------------------------------------------
outro PROC
; Description: Writes farewell strings to output
;
; preconditions: none
;
; receives: [ebp+8]		@goodbye string
;
; returns: writes goodbye string to output
;
; Registers changed: None
;------------------------------------------------
		
		push			ebp
		mov				ebp, esp
		pushad

		;display title
		call			crlf
		displayString	[ebp+8]			;avg_msg
		
		popad
		pop				ebp
		ret				4
outro ENDP



END main
