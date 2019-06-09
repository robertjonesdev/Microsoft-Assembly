TITLE Program 6a System Input/Output  

; Author:					Robert Jones
; Description:				This program receives 10 character strings from the user
;					and validates the input to be compatable as a 32-bit signed integer
;					The program converts the strings to 32-bit signed integers and saves
;					them to an array. The program then displays the numbers (back as strings),
;					their sum, and their average (rounded down) as strings using the Win32 API calls.
;Extra credit:				**EC #1: Number each line of user input and display a running subtotal of the user’s numbers
;					**EC #2: ReadVal and WriteVal can handle signed 32-bit integers (first character being '-' for negative, do not use '+')
;					**EC #5: getString and displayString macros are implemented using the Win32 API console functions (Canvas Announcement)
;
;Source cite: Kip Irvine Assembly Language Chapter 10.2 "Macros Containing Code and Data"
;Source cite: Console inpput/output Kip Irvine Assembly Ch 11.1 Win-32 Console Programming

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
; Receives:				Address to start of input buffer array, retrun, and reference for number of characters read.
;						the address to start of a prompt message string.
; Returns:				Returns the input character string as a reference parameter of buffer, and the number of characters read.
; Preconditions:		buffer and maximum size of buffer is a sufficient amount to receive expected string
; Registers affected:	None.
;*********************************************************************************************
getString MACRO buffer, bufferCount, prompt
	pushad

	displayString prompt

	INVOKE	GetStdHandle, STD_INPUT_HANDLE		;; handle is saved to eax
	INVOKE	ReadConsole,						;; Win32 API Call
			eax,								;; console input handle
			buffer,								;; address to beginning of array to store string
			80,									;; buffer maximum
			bufferCount,						;; return value of number of bytes read
			0									;; not used
	
	mov		ebx, bufferCount
	mov		eax, [ebx]
	sub		eax, 2
	mov		[ebx], eax

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
ecMsg		BYTE	"**EC #1: Number each line of user input and display a running subtotal of the users numbers", ENDL
			BYTE	"**EC #2: ReadVal and WriteVal can handle signed 32-bit integers (first character being '-')", ENDL
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
inStringSize DWORD	?
outputString BYTE	80 DUP(0), 0, 0

;Procedures
.code
main PROC
	push	 OFFSET intro1
	push	 OFFSET intro2
	push	 OFFSET ecMsg
	call	Introduction

	push	OFFSET outputString
	push	OFFSET runningMsg
	push	OFFSET promptError
	push	OFFSET prompt
	push	OFFSET inStringSize
	push	OFFSET inputString
	push	OFFSET numArray
	call	GetNums												;Procedure to get 10 strings from console and save as signed 32-bit integers in array

	push	OFFSET outputString
	push	OFFSET numArray
	call	DisplayArray										;Display all the numbers received in previous procedure

	push	OFFSET outputString
	push	OFFSET avgMsg
	push	OFFSET sumMsg
	push	OFFSET numArray
	call	GetSumAndAverage									;Calculate the sum of the array elements and their average.

	push	OFFSET endMsg										;End of program message
	call	Farewell

	exit
main ENDP

;******************************************************************************************
; GetNums
; Description:				This procedure calls ReadVal procedure 10 times to receive validated
;							32-bit signed integers to store in the number array.
; Receives:					Base pointer to the number array, base pointer to the string buffer,
;							maximum size of the string buffer, prompt string message, error 
;							prompt string message, and running total string message, output string used for WriteVal
; Returns:					Returns the number array populated by received and validated 32-bit signed integers.
; Preconditions:			None.
; Registers affected:		None.
;*********************************************************************************************
GetNums PROC
	push	ebp
	mov		ebp, esp
	pushad

	mov		eax, 0							;Accumulator for running subtotal
	mov		ebx, 1							;Line counter
	mov		edi, [ebp+8]						;base pointer of number array

	call	Crlf
GetNumLoop:									;Get 10 strings and store as 32-bit signed integers
	push	[ebp+32]
	push	SDWORD PTR ebx
	call	WriteVal

	push	SDWORD PTR edi							;return value for signed 32-bit integer
	push	DWORD PTR [ebp+24]						;promptError string message
	push	DWORD PTR [ebp+20]						;prompt string message
	push	DWORD PTR [ebp+16]						;return value of inputString for buffer maximum
	push	DWORD PTR [ebp+12]						;inputString buffer array of characters
	call	ReadVal

	add		eax, [edi]

	displayString [ebp+28]
	push	[ebp+32]
	push	SDWORD PTR eax
	call	WriteVal
	call	Crlf

	add		edi, TYPE DWORD
	inc		ebx
	cmp		ebx, NUMELEM
	jle		GetNumLoop

	popad
	mov		esp, ebp
	pop		ebp
	ret		28
GetNums ENDP

;******************************************************************************************
; DisplayArray
; Description:				This procedure prints out each element of an integer array to the console.
; Receives:				Base pointer to the beginning of an integer array, and output string array used for WriteVal
; Returns:				None.
; Preconditions:			Array is populated with valid 32-bit signed integers.
; Registers affected:			None.
;*********************************************************************************************
DisplayArray PROC
	push	ebp
	mov		ebp, esp
	pushad

	displayString OFFSET newLine	
	displayString OFFSET newLine
	displayString OFFSET listMsg

	mov		ecx, NUMELEM
	mov		edi, [ebp+8]					;Reference to SDWORD numArray
DisplayLoop:
	push	[ebp+12]
	mov		eax, [edi]
	push	SDWORD PTR eax
	call	WriteVal						;Display each of all numbers

	cmp		ecx, 1
	jz		NoStringSpacer
	displayString OFFSET strSpacer					;strSpacer string message ", "
NoStringSpacer:
	add		edi, 4
	loop	DisplayLoop
	call	Crlf

	popad
	mov		esp, ebp
	pop		ebp
	ret		8
DisplayArray ENDP

;******************************************************************************************
; GetSumAndAverage
; Description:			This procedure calculates the sum of all elements in an integer array.
;				It then divides it by the total number of numbers for the avarege.
; Receives:			Base pointer to the beginning of an integer array, and 2 string for sum and array messages
; Returns:			None.
; Preconditions:		Array is populated with valid 32-bit signed integers.
; Registers affected:		None.
;*********************************************************************************************
GetSumAndAverage PROC
	push	ebp
	mov		ebp, esp
	pushad
	displayString [ebp+12]
	mov		ecx, NUMELEM
	mov		edi, [ebp+8]						;base of numArray
	mov		eax, 0
AdderLoop:
	add		eax, [edi]
	add		edi, TYPE DWORD
	loop	AdderLoop

	push	[ebp+20]
	push	SDWORD PTR eax
	call	WriteVal							;Sum of all numbers
	call	Crlf
	displayString [ebp+16]
	mov		ebx, NUMELEM
	cdq
	idiv	ebx

	push	[ebp+20]
	push	SDWORD PTR eax
	call	WriteVal							;Average of all numbers

	call	Crlf
	popad
	mov		esp, ebp
	pop		ebp
	ret		12
GetSumAndAverage ENDP


;******************************************************************************************
; RealVal
; Description:				This procedure takes user console input using the getString macro
;					and Win32 API calls. It validates and converts the character string
;					in to a 32-bit signed integer and then returns integer value.
;					if input is invalid, the procedure will loop
;					until valid, in range, input is given.
; Receives:				Reference to a character array, maximum size of the array,
;					standard message prompt (string), and message prompt for error (string)
;					Reference to a 32-bit signed integer for return value
; Returns:				32-bit signed integer through reference variable
; Preconditions:			None.
; Registers affected:		None.
;*********************************************************************************************
ReadVal PROC
	push	ebp
	mov		ebp, esp
	sub		esp, 4
	pushad
GetStringLoop:
	getString DWORD PTR [ebp+8], DWORD PTR [ebp+12], DWORD PTR [ebp+16]

	mov		edi, [ebp+12]
	mov		ecx, [edi]						;length of string
	mov		eax, ecx
	cmp		ecx, 0
	jz		StringHasError					;check for empty string
	mov		esi, [ebp+8]					;string base pointer
	cld
	lodsb

	cmp		al, 45							;check first character for negative
	jne		SignIsPositive
	mov		eax, -1
	mov		[ebp-4], eax					;sign is negative, save to multiply to value at the end
	mov		eax, [edi]						;reduce string length by 1 to exclude the sign.
	dec		eax
	mov		[edi], eax
	jmp		SignIsNegative
SignIsPositive:
	mov		eax, 1
	mov		[ebp-4], eax
	mov		esi, [ebp+8]
SignIsNegative:
	mov		ecx, [edi]						;loop counter = length of string

	add		esi, ecx
	dec		esi
	mov		ebx, 1							;place value multiplier
FindInvalidChars:							;iterate through character string for any invalid characters
	mov		eax, 0
	std
	lodsb
	cmp		al, 48							;below decimal 0
	jl		StringHasError
	cmp		al, 57							;greater than decimal 9
	jg		StringHasError
	sub		eax, 48
	imul	ebx
	jo		StringHasError					;if overflow, number is too large
	mov		edx, [ebp+24]
	add		eax, [edx]
	jo		StringHasError
	mov		[edx], eax
	mov		eax, ebx
	mov		ebx, 10
	imul	ebx
	mov		ebx, eax
	mov		eax, 0
	loop	FindInvalidChars

	mov		ebx, [ebp+24]
	mov		eax, [ebx]
	mov		ebx, [ebp-4]
	imul	ebx								;multiply by sign (1:positive, -1:negative)
	jo		StringHasError					;if overflow, number is too large
	mov		ebx, [ebp+24]					;store in return value
	mov		[ebx], eax

	jmp		ReturnValidString
StringHasError:								;Clear out the value and loop for a new string. If string is valid,  end procedure
	mov		ebx, [ebp+24]
	mov		eax, 0
	mov		[ebx], eax
	mov		eax, [ebp+20]
	mov		[ebp+16], eax
	jmp		GetStringLoop

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
	pushad

	mov		eax, [ebp+8]				;integer value to print
	cmp		eax, 0
	jge		AbsoluteValue				;for division, only work with a positive number
	mov		ebx, -1						;the sign character will be added at the end.
	imul	ebx
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
   	mov		edi, [ebp+12]				;storage string address
	mov		eax, edi

LoadStringArray:
	pop		eax							;pop characters off the stack to eax and load them to character string
	cld
	stosb
	loop	LoadStringArray
	mov		eax, 0						;null character to end string
	cld
	stosb
	displayString [ebp+12]

	popad
	mov		esp, ebp
	pop		ebp
	ret		8
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

;******************************************************************************************
; Introduction
; Description:				This function displays 3 introductory string messages to the console
; Receives:					3 character strings
; Returns:					None
; Preconditions:			The string must end in the null terminator. 
; Registers affected:		None.
;*********************************************************************************************
Introduction PROC
	push	ebp
	mov		ebp, esp
	pushad

	displayString [ebp+16]
	displayString [ebp+12]
	displayString [ebp+8]

	popad
	mov		esp, ebp
	pop		ebp
	ret		12
Introduction ENDP

;******************************************************************************************
; Farewell
; Description:				This function displays 1 farewell string messages to the console
; Receives:					1 character string
; Returns:					None
; Preconditions:			The string must end in the null terminator. 
; Registers affected:		None.
;*********************************************************************************************
Farewell PROC
	push	ebp
	mov		ebp, esp
	pushad

	displayString OFFSET newLine
	displayString [ebp+8]

	popad
	mov		esp, ebp
	pop		ebp
	ret		4
Farewell ENDP

END main
