TITLE Composite Numbers  

; Author:					Robert Jones
; Description:				This program calculates composite numbers. The user is asked how many 
;							composite numbers [1...400]. The program then calculates and displays 
;							all of the composite numbers up to and including the nth number. 
;							The results are displayed 10 per line with at least 3 spaces between the numbers.
;							**EC #1: the output is aligned in columns.
;							**EC #3: the algorithm is optimized to check for composites only against prime numbers.
;Source Cite:				Algorithm for determining composite and prime numbers modified & adapted from:
;							GeeksforGeeks "Composite Numbers", https://www.geeksforgeeks.org/composite-number/

INCLUDE Irvine32.inc

; Constant Definitions
MAX_INPUT		= 400
TRUE			= 1
FALSE			= 0
.data
; Variable definitions
count			DWORD	?
primeArray		DWORD	MAX_INPUT DUP(2)
nbrOfElements	DWORD	1
columnCounter	DWORD	0
intro1			BYTE	"Welcome to the Composite Numbers Program by Robert Jones", 10, 13, 10, 13, 0
intro2			BYTE	"Enter the number of composite numbers you would like to see", 10, 13, "I'll accept orders for up to 400 composites.", 10, 13, 0
introec1		BYTE	"**EC 1: Align the output columns.", 10, 13, 0
introec3		BYTE	"**EC 3: Check composites only against prime numbers.", 10, 13, 10, 13, 0
prompt1			BYTE	"Enter the number of composites to display [1 .. 400]: ", 0
error1			BYTE	"Out of range. Try again.", 10, 13, 0
goodbye1		BYTE	"Results certified by Robert Jones. Goodbye.", 10, 13, 0
minSpacer		BYTE	"   ",0				;minimum of 3 spaces between the numbers
extraSpace		BYTE	" ",0				;extra space for 1 or 2 digit numbers

.code
main PROC
	call	introduction
	push	OFFSET count
	call	getUserData						;receives & returns integer of user's number of composites by reference to the count variable
	push	count
	call	showComposites					;receives parameter of number of composites from system stack.
	call	farewell
	exit									; exit to operating system
main ENDP

;Additional procedures
;*******************************************************************
;Introduction		 This provides an introduction and instruction to the user.
;Receives:			 none
;Returns:			 none
;Preconditions:		 none.
;Registers affected: none.
;*******************************************************************
introduction	PROC
	push	ebp
	mov		ebp, esp
	push	edx
	mov		edx, OFFSET intro1				;"Welcome to the Composite Numbers Program by Robert Jones"
	call	WriteString
	mov		edx, OFFSET intro2				;"Enter the number of composite numbers you would like to see" \n "I'll accept orders for up to 400 composites."
	call	WriteString
	mov		edx, OFFSET introec1			;"**EC 1: Align the output columns."
	call	WriteString
	mov		edx, OFFSET	introec3			;"**EC 3: Check composites only against prime numbers."
	call	WriteString
	pop		edx
	pop		ebp
	ret
introduction	ENDP
;*******************************************************************
;getUserData 		 Receives the number of number of composites to display from the user
;					 and validates the number to be in range through the validate procedure
;Receives:			 Reference to variable count on system stack (no default value necessary).
;Returns:			 Total number of composites to display by reference to variable count on system stack
;Preconditions:		 none.
;Registers affected: none.
;*******************************************************************
getUserData	PROC
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	edx
	mov		ebx, [ebp + 8]					;reference to count variable
NumberPrompt:
	mov		edx, OFFSET prompt1				;"Enter the number of composites to display [1 .. 400]: "
	call	WriteString
	call	ReadInt
	mov		[ebx], eax
	push	eax
	call	validate						;Results returned in EAX as true/false
	cmp		eax, FALSE
	jz		NumberPrompt
	pop		edx
	pop		ebx
	pop		ebp
	pop		eax
	ret		4
getUserData	ENDP

;*******************************************************************
;validate			 this validates a parameter integer to be in range.
;Receives:			 The number to evaluate and validate as in-range.
;Returns:			 True(1) if valid, False(0) if invalid through EAX.
;Preconditions:		 None.
;Registers affected: EAX
;*******************************************************************
validate	PROC
	push	ebp
	mov		ebp, esp
	push	edx
	mov		eax, [ebp + 8]
	cmp		eax, 1							;Minimum input value
	jl		InvalidInput
	cmp		eax, MAX_INPUT					;Maximum input value
	jg		InvalidInput
	mov		eax, TRUE
	jmp		ValidInput
InvalidInput:
	mov		edx, OFFSET error1				;"Out of range. Try again."
	call	WriteString
	mov		eax, FALSE
ValidInput:
	pop		edx
	pop		ebp
	ret		4
validate	ENDP

;*******************************************************************
;showComposites	 	 Loops from 1 to Count to determine if a number is composite, if so print it.
;					 Loop counter is not incremented if it the number is not composite.
;Receives:			 Number of composites to calculate & show as parameter on system stack.
;Returns:			 none.
;Preconditions:		 Number of composites is validated from > 0 and <= MAX_INPUT
;Registers affected: none.
;*******************************************************************
showComposites	PROC
	push	ebp
	mov		ebp, esp
	push	eax
	push	ecx
	push	edx
	mov		eax, 1					
	mov		ecx, [ebp + 8]	
LoopThroughCount:
	push	eax
	call	isComposite						;Results returned in EBX as true/false
	cmp		ebx, TRUE
	je		NumIsComposite
	inc		ecx
	jmp		NumIsNotComposite
NumIsComposite:
	inc		columnCounter
	mov		ebx, columnCounter
	push	ebx
	push	eax
	call	printNumber
NumIsNotComposite:
	inc		eax
	loop	LoopThroughCount
	pop		edx
	pop		ecx
	pop		eax
	pop		ebp
	ret		4
showComposites	ENDP

;*******************************************************************
;isComposite	     Tests a parameter number if it is composite or not. 
;					 If the number is prime, then add it to an global array of 
;					 prime numbers for future composite number testing.
;Impl. note:		 The procedure is called iteratively from 1 to count by showComposites function.
;Receives:			 The integer to determine if composite or prime as a variable on system stack
;Returns:			 True if composite, False if not, through EBX
;Preconditions:		 The parameter number is a validated integer from 1 to 400 and the prime number is populated 
;					 with all prime numbers < the integer passed in eax.
;Registers affected: EBX
;*******************************************************************
isComposite PROC
	push	ebp
	mov		ebp, esp
	push	ecx							;Save the outer loop counter from showComposites on to the stack.
	push	edi
	mov		ebx, FALSE
	mov		eax, [ebp + 8]
	cmp		eax, 1						;1 is not a composite number, return false
	je		isNotCompositeExit
	cmp		eax, 2						;2 is not a composite number, return false. It is already in the prime array.
	je		isNotCompositeExit
	mov		edi, OFFSET primeArray
	mov		ecx, nbrOfElements		
LoopThroughPrimes:						;For numbers > 2, loop through the prime number array to compare division remainders to 0. If r = 0 then it is composite
	push	eax 
	mov		ebx, [edi]				
	cdq		
	div		ebx
	pop		eax
	cmp		edx, 0
	je		isCompLoopExit
	add		edi, 4					
	Loop	LoopThroughPrimes
	mov		[edi],eax					;if the loop finishes without any r=0 then add the prime number to the array
	inc		nbrOfElements
	mov		ebx, FALSE
	jmp		isNotCompositeExit
isCompLoopExit:
	mov		ebx, TRUE
isNotCompositeExit:
	pop		edi
	pop		ecx
	pop		ebp
	ret		4
isComposite ENDP

;*******************************************************************
;printNumber		 Formats and prints the composite number to the console.
;					 Enters a new line if necessary (every 10th number)
;Receives:			 1st parameter: composite number to print, on system stack
;					 2nd parameter: lineCounter to determine newlines, on system stack
;Returns:			 none.
;Preconditions:		 composite number and lineCounter are initialized, non-negative integers
;Registers affected: none
;*******************************************************************
printNumber PROC
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	edx
	mov		ebx, [ebp + 12]					;parameter #2, lineCounter
	mov		eax, [ebp + 8]					;parameter #1, composite number to print
	call	WriteDec
	mov		edx, OFFSET minSpacer
	call	WriteString
	cmp		eax, 10
	jge		NoExtraSpace1
	mov		edx, OFFSET extraSpace
	call	WriteString
NoExtraSpace1:
	cmp		eax, 100
	jge		NoExtraSpace2
	mov		edx, OFFSET extraSpace
	call	WriteString
NoExtraSpace2:
	mov		eax, ebx
	cdq		
	mov		ebx, 10							;after every 10th number, print a newline
	div		ebx
	cmp		edx, 0
	jne		NoNewLine
	call	Crlf
NoNewLine:
	pop		edx
	pop		ebx
	pop		eax
	pop		ebp
	ret		8
printNumber	ENDP

;*******************************************************************
;farewell 			 Displays a farewell message to the user.
;Receives:			 none.
;Returns:			 none.
;Preconditions:		 none.
;Registers affected: none.
;*******************************************************************
farewell PROC
	push	ebp
	mov		ebp, esp
	push	edx
	call	Crlf
	mov		edx, OFFSET goodbye1			;"Results certified by Robert Jones. Goodbye."
	call	WriteString
	pop		edx
	pop		ebp
	ret
farewell ENDP

END main
