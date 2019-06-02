TITLE System Input/Output with Win32 API

; Author:					Robert Jones
; Description:				This program receives 10 character strings from the user
;							and validates the input to be compatable as a 32-bit signed integer
;							The program converts the strings to 32-bit signed integers and saves
;							them to an array. The program then displays the numbers (back as strings),
;							their sum, and their average (rounded down) as strings using the Win32 API calls.


;Constant definitions
INCLUDE Irvine32.inc
NUMELEM = 10
ENDL	EQU <0dh, 0ah>

;******************************************************************************************
; displayString Macro
; Description:			This macro takes an address of a string and uses the Win32 API to write
;						the string to the console, ending at the null terminator.
; Receives:				Address of array of characters (string)
; Returns:				None.
; Preconditions:		String ends in the null terminator. The StringLength helper procedure
;						calculates the number of characters up to the null terminator
; Registers affected:	None
;*********************************************************************************************
displayString MACRO string
	pushad

	mov		eax, 0
	push	eax
	lea		eax, DWORD PTR [esp]
	push	eax
	push	string
	call	StringLength
	pop		ebx									;;string length now in [ebx]

	INVOKE	GetStdHandle, STD_OUTPUT_HANDLE		;;handle is saved to eax
	mov		edx, 0
	push	edx
	lea		edx, DWORD PTR [esp]
	cld
	INVOKE	WriteConsole,						;; Win32 API Call
			eax,     							;; console output handle
			string,								;; address to beginning of string array
			ebx,								;; length of the string (calculated from StringLength procedure)
			edx,								;; return value of number of bytes written
			0									;; not used
	pop		edx
	popad
ENDM

;******************************************************************************************
; getString Macro
; Description:			This macro displays a prompt to ask the user for input. It then reads
;						this console using the Win32 API up to the defined buffer size.
; Receives:				Address to start of input buffer array, maximum size of buffer, and
;						the address to start of a prompt message string.
; Returns:				Returns the input character string as a reference parameter of buffer.
; Preconditions:		buffer and maximum size of buffer is a sufficient amount to receive expected string
; Registers affected:	None.
;*********************************************************************************************
getString MACRO buffer, bufferSize, prompt
	pushad

	displayString prompt
	mov		edx, 0
	push	edx
	lea		edx, DWORD PTR [esp]				;; return value for number of bytes written

	INVOKE	GetStdHandle, STD_INPUT_HANDLE		;; handle is saved to eax
	INVOKE	ReadConsole,						;; Win32 API Call
			eax,								;; console input handle
			buffer,								;; address to beginning of array to store string
			bufferSize,							;; buffer maximum
			edx,								;; return value of number of bytes read
			0									;; not used
	pop		esi									;; Remove cariage return (last 2 bytes) and replace with null character
	mov		edi, buffer
	add		edi, esi
	dec		edi
	mov		eax, 0
	mov		[edi], eax
	dec		edi
	mov		[edi], eax
	popad
ENDM

.data
; Variable Definitions
numArray	SDWORD	10 DUP(?)
sum			SDWORD	?
newLine		BYTE	ENDL, 0
intro1		BYTE	"PROGRAMMING ASSIGNMENT 6a: Designing low-level I/O procedures", ENDL, "Written by: Robert Jones", ENDL, ENDL,  0
intro2		BYTE	"Please provide 10 signed decimal integers.  Each number needs to be small enough to fit inside a 32 ", ENDL
			BYTE	"bit register. After you have finished inputting the raw numbers I will display a list of the integers, ", ENDL
			BYTE	"their sum, and their average value. ", ENDL, ENDL, 0
ecMsg		BYTE	"**EC #1: Number each line of user input and display a running subtotal of the user’s numbers", ENDL
			BYTE	"**EC #2: ReadVal and WriteVal can handle signed 32-bit integers (first character being '-')", ENDL
			BYTE	"**EC #3: ReadVal procedure is recursive.", ENDL
			BYTE	"**EC #5: getString and displayString macros are implemented using the Win32 API console functions (Canvas Announcement)", ENDL, ENDL, 0
prompt		BYTE	" Please enter a signed integer: ", 0
promptError	BYTE	"  ERROR: You did not enter a valid signed integer, or your number was too big.", ENDL, "  Please try again: ", 0
listMsg		BYTE	"You entered the following numbers:", ENDL, 0
runningMsg	BYTE	ENDL, "Running subtotal: ", 0
sumMsg		BYTE	"The sum of these numbers is: ", 0
avgMsg		BYTE	"The average is: ", 0
endMsg		BYTE	"Thanks for playing!", ENDL, ENDL, 0
strSpacer	BYTE	", ", 0
inputString	BYTE	80 DUP(0), 0, 0

;Procedures
.code
main PROC
	displayString OFFSET intro1
	displayString OFFSET intro2
	displayString OFFSET ecMsg

	push	OFFSET runningMsg
	push	OFFSET promptError
	push	OFFSET prompt
	push	DWORD PTR SIZEOF inputString
	push	OFFSET inputString
	push	OFFSET numArray
	call	GetNums												;Procedure to get 10 strings from console and save as signed 32-bit integers in array

	displayString OFFSET newLine
	displayString OFFSET listMsg

	push	OFFSET strSpacer
	push	OFFSET numArray
	call	DisplayArray										;Display all the numbers received in previous procedure

	displayString OFFSET sumMsg

	push	OFFSET sum
	push	OFFSET numArray
	call	GetSum												;Calculate the sum of the array elements, return by reference to sum variable.

	displayString OFFSET newLine

	push	OFFSET avgMsg
	push	sum
	Call	GetAvg												;Calculate the average based on the sum / elements

	displayString OFFSET newLine
	displayString OFFSET newLine
	displayString OFFSET endMsg									;End of program message

	exit
main ENDP

;******************************************************************************************
; GetNums
; Description:				This procedure calls ReadVal procedure 10 times to receive validated
;							32-bit signed integers to store in the number array.
; Receives:					Base pointer to the number array, base pointer to the string buffer,
;							maximum size of the string buffer, prompt string message, error 
;							prompt string message, and running total string message.
; Returns:					Returns the number array populated by received and validated 32-bit signed integers.
; Preconditions:			None.
; Registers affected:		None.
;*********************************************************************************************
GetNums PROC
	push	ebp
	mov		ebp, esp
	pushad
	mov		eax, [ebp+16]
	sub		eax, 2
	mov		[ebp+16], eax

	mov		eax, 0									;Accumulator for running subtotal
	mov		ebx, 1									;Line counter
	mov		edi, [ebp+8]							;base pointer of number array

	displayString OFFSET newLine
GetNumLoop:											;Get 10 strings and store as 32-bit signed integers
	push	DWORD PTR ebx
	call	WriteVal

	push	edi
	push	DWORD PTR [ebp+24]						;promptError string message
	push	DWORD PTR [ebp+20]						;prompt string message
	push	DWORD PTR [ebp+16]						;size of inputString for buffer maximum
	push	DWORD PTR [ebp+12]						;inputString buffer array of characters
	call	ReadVal

	add		eax, [edi]
	displayString [ebp+28]							;runningMsg string message
	push	DWORD PTR eax
	call	WriteVal
	displayString OFFSET newLine
	add		edi, TYPE DWORD
	inc		ebx
	cmp		ebx, NUMELEM
	jle		GetNumLoop

	popad
	mov		esp, ebp
	pop		ebp
	ret		24
GetNums ENDP

;******************************************************************************************
; DisplayArray
; Description:				This procedure prints out each element of an integer array to the console.
; Receives:					Base pointer to the beginning of an integer array, and string spacer message ", "
; Returns:					None.
; Preconditions:			Array is populated with valid 32-bit signed integers.
; Registers affected:		None.
;*********************************************************************************************
DisplayArray PROC
	push	ebp
	mov		ebp, esp
	pushad

	mov		ecx, NUMELEM
	mov		edi, [ebp+8]						;Reference to SDWORD numArray
DisplayLoop:
	mov		eax, [edi]
	push	DWORD PTR eax
	call	WriteVal							;Display each of all numbers
	cmp		ecx, 1
	jz		NoStringSpacer
	displayString [ebp+12]						;strSpacer string message ", "
NoStringSpacer:
	add		edi, TYPE DWORD
	loop	DisplayLoop
	displayString OFFSET newLine

	popad
	mov		esp, ebp
	pop		ebp
	ret		8
DisplayArray ENDP

;******************************************************************************************
; GetSum
; Description:				This procedure calculates the sum of all elements in an integer array.
; Receives:					Base pointer to the beginning of an integer array, and reference variable
;							to return the sum.  It also prints out the sum to the terminal console.
; Returns:					Returns the sum of the array through the reference variable.
; Preconditions:			Array is populated with valid 32-bit signed integers.
; Registers affected:		None.
;*********************************************************************************************
GetSum PROC
	push	ebp
	mov		ebp, esp
	pushad
	mov		ecx, NUMELEM
	mov		edi, [ebp+8]						;base of numArray
	mov		eax, 0
AdderLoop:
	add		eax, [edi]
	add		edi, TYPE DWORD
	loop	AdderLoop
	push	DWORD PTR eax
	call	WriteVal							;Sum of all numbers

	mov		ebx, [ebp+12]
	mov		[ebx], eax							;return sum to reference paramater
	popad
	mov		esp, ebp
	pop		ebp
	ret		8
GetSum ENDP

;******************************************************************************************
; GetAverage
; Description:				This procedure calculates the average of the elements in the array.
;							It then prints the integer value to the console.
; Receives:					The sum of the array by value and a string message.
; Returns:					None.
; Preconditions:			Sum is a valid 32-bit signed integer
; Registers affected:		None.
;*********************************************************************************************
GetAvg PROC
	push	ebp
	mov		ebp, esp
	pushad
	displayString	[ebp+12]

	mov		eax, [ebp+8]						;sum
	cdq
	mov		ebx, NUMELEM
	idiv	ebx
	push	DWORD PTR eax
	call	WriteVal							;Average of all numbers

	popad
	mov		esp, ebp
	pop		ebp
	ret		4
GetAvg ENDP

;******************************************************************************************
; RealVal
; Description:				This procedure takes user console input using the getString macro
;							and Win32 API calls. It validates and converts the character string
;							in to a 32-bit signed integer and then returns integer value.
;							If input is invalid, the procedure will recursively call itself
;							until valid, in range, input is given.
; Receives:					Reference to a character array, maximum size of the array,
;							standard message prompt (string), and message prompt for error (string)
;							Reference to a 32-bit signed integer for return value
; Returns:					32-bit signed integer through reference variable
; Preconditions:			None.
; Registers affected:		None.
;*********************************************************************************************
ReadVal PROC
	push	ebp
	mov		ebp, esp
	sub		esp, 8
	pushad

	getString DWORD PTR [ebp+8], DWORD PTR [ebp+12], DWORD PTR [ebp+16]
GetStringLoop:
	lea		eax, [ebp-4]
	push	eax
	push	SDWORD PTR [ebp+8]
	call	StringLength					;get the length of the input string, stored in [ebp-4]

	mov		ecx, [ebp-4]
	cmp		ecx, 0
	jz		StringHasError					;check for empty string
	mov		esi, [ebp+8]					;string base pointer
	cld
	lodsb
	cmp		al, 45							;check first character for negative
	jne		SignIsPositive
	mov		eax, -1
	mov		[ebp-8], eax					;sign is negative, save to multiply to value at the end
	mov		eax, [ebp-4]					;reduce string length by 1 to exclude the sign.
	dec		eax
	mov		[ebp-4], eax
	jmp		SignIsNegative
SignIsPositive:
	mov		eax, 1
	mov		[ebp-8], eax
	mov		esi, [ebp+8]
SignIsNegative:
	mov		ecx, [ebp-4]					;loop counter = length of string
	mov		eax, 0
FindInvalidChars:							;iterate through character string for any invalid characters
	cld
	lodsb
	cmp		al, 0							;null character, end of string
	je		EndOfStringFound
	cmp		al, 48							;below decimal 0
	jl		StringHasError
	cmp		al, 57							;greater than decimal 9
	jg		StringHasError
	loop	FindInvalidChars
EndOfStringFound:							;calculate real value of whole numbers.
	dec		esi								;start before the null character
	mov		ecx, [ebp - 4]					;loop counter = length of string
	mov		ebx, 1							;place value multiplier
CalculateIntValue:
	mov		eax, 0
	std
	lodsb
	sub		al, 48
	mul		ebx
	jo		StringHasError					;if overflow, number is too large
	mov		edx, [ebp+24]
	add		eax, [edx]
	jo		StringHasError
	mov		[edx], eax
	mov		eax, ebx
	mov		ebx, 10
	mul		ebx
	mov		ebx, eax
	mov		eax, 0
	loop	CalculateIntValue				;calculation complete whole number value
	mov		ebx, [ebp+24]
	mov		eax, [ebx]
	mov		ebx, [ebp-8]
	imul	ebx								;multiply by sign (1:positive, -1:negative)
	jo		StringHasError					;if overflow, number is too large
	mov		ebx, [ebp+24]					;store in return value
	mov		[ebx], eax
	jmp		ReturnValidString
StringHasError:								;Clear out the value and call the ReadVal procedure again. If string is valid,  recursive call will be skipped.
	mov		ebx, [ebp+24]
	mov		eax, 0
	mov		[ebx], eax
	push	ebx								;push parameters recursive call
	push	DWORD PTR [ebp+20]
	push	DWORD PTR [ebp+20]
	push	DWORD PTR [ebp+12]
	push	DWORD PTR [ebp+8]
	call	ReadVal							;Recursive call
ReturnValidString:
	popad
	mov		esp, ebp
	pop		ebp
	ret		20
ReadVal ENDP


;******************************************************************************************
; WriteVal
; Description:				This procedure accepts a 32 bit signed integer as a parameter
;							converts it to a character array and the displays it to the console
;							with the displayString macro that utilizes the Win32 API calls.
; Receives:					Parameter by value of a 32-bit signed integer.
; Returns:					None.
; Preconditions:			Parameter value in the range of -2,147,483,648 to 2,147,483,647
;							for accurate output.
; Registers affected:		None.
;*********************************************************************************************
WriteVal PROC
    push	ebp
    mov		ebp, esp
    sub		esp, 12
    pushad
	mov		eax, [ebp+8]				;integer value to print
	cmp		eax, 0
	jge		AbsoluteValue				;for division, only work with a positive number
	mov		ebx, -1						;the sign character will be added at the end.
	mul		ebx
AbsoluteValue:
	mov		ebx, 10						;divisor
	mov		ecx, 0						;character counter
DivideByTen:
	cdq
	div		ebx
	add		edx, 48
	push	edx
	inc		ecx
	cmp		eax, 0
	jz		DividngComplete
	jmp		DivideByTen
DividngComplete:
	mov		eax, [ebp+8]
	cmp		eax, 0
	jge		NoSign
	mov		eax, 45						;'-' for negative sign
	push	eax
	inc		ecx
NoSign:
   	mov		edi, [ebp-12]				;local string base address
LoadStringArray:
	pop		eax							;pop characters off the stack to eax and load them to character string
	cld
	stosb
	loop	LoadStringArray
	mov		eax, 0						;null character to end string
	cld
	stosb
	displayString DWORD PTR [ebp-12]
	popad
	mov		esp, ebp
	pop		ebp
	ret		4
WriteVal ENDP

;******************************************************************************************
; StringLength
; Description:				This function calculates the length of a character string 
;							from beginning until the null terminator.
; Receives:					Base of array of characters, and a reference variable to return
;							the length as an integer.
; Returns:					Returns the length of the string as a positive integer.
; Preconditions:			The string must end in the null terminator. 
; Registers affected:		None.
;*********************************************************************************************
StringLength PROC
	push	ebp
	mov		ebp, esp
	pushad

	mov		edi, [ebp+8]
	mov		eax, 0
StrLenLoop:
	cmp		BYTE PTR [edi], 0
	je		StrLenExit
	inc		edi
	inc		eax
	jmp		StrLenLoop
StrLenExit:
	mov		edi, [ebp+12]
	mov		[edi], eax

	popad
	mov		esp, ebp
	pop		ebp
	ret		8
StringLength ENDP

END main
