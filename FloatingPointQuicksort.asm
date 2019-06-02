TITLE  Floating Point Quicksort

; Author:						Robert Jones
; Description:					This program accepts an integer from the user and creates a list of random floating-point numbers
;								in the amount of the user's integer. The program displays the random list. Then the program sorts the
;								list in descending order using the recursive quicksort algorithm. Then the program identifies and displays
;								the median of the list. Then the program displays the sorted list of floating-point numbers in a table
;								with 10 columns, ordered by columns (instead of rows), in descending order.
; Implementation note:			Please size the output console to be large enough to display the 10 floating-point numbers on one row.
; Source cite:					Algorithm for quicksort adapted from https://www.geeksforgeeks.org/quick-sort/
;								See end of file comments for full algorithm.
INCLUDE Irvine32.inc

;Constant definitions
MIN		= 10
MAX		= 200
LO		= 100
HI		= 999
I_local			EQU DWORD PTR [ebp-4]
J_local			EQU DWORD PTR [ebp-8]
pivot_local		EQU DWORD PTR [ebp-12]
numRows			EQU DWORD PTR [ebp-4]
remainder		EQU DWORD PTR [ebp-8]
return_arg		EQU [ebp+20]
high_arg		EQU [ebp+16]
low_arg			EQU [ebp+12]

.data
; Variable definitions
request			DWORD	0
array			REAL10	MAX DUP(0.0)
intro1			BYTE	"Welcome to the Array Sort Program by Robert Jones", 10, 13, 10, 13, \
						"This program generates random numbers in the range [100 .. 999], displays the original list, sorts the list, ", 10, 13, \
						"and calculates the median value.  Finally, it displays the list sorted in descending order.", 10, 13, 10, 13, \
						"**EC 1: Display the numbers ordered by column instead of by row.", 10, 13, 0
intro2			BYTE	"**EC 2: Use a recursive sorting algorithm (Quicksort is implemented). ", 10, 13,\
						"**EC 3: Implement the program using floating-point numbers and the floating-point processor. ", 10, 13, 10, 13, 0 
input1			BYTE	"How many numbers should be generated? [10 .. 200]: ", 0
inputerror		BYTE	"Invalid input.",10, 13, 0
outputUnsorted	BYTE	"Unsorted Array", 10, 13, 0
outputSorted	BYTE	"Sorted Array", 10, 13, 0
outputMedian	BYTE	"The median is ", 0


.code
main PROC
	finit
	call	Randomize
	
	push	OFFSET intro1
	push	OFFSET intro2
	call	introduction

	push	OFFSET input1
	push	OFFSET inputerror
	push	OFFSET request
	call	getData

	push	OFFSET array
	push	request
	call	fillArray

	push	OFFSET outputUnsorted
	push	request
	push	OFFSET array
	call	displayList

	mov		eax, request
	dec		eax								;Due to the recurssive quicksort algorithm, request needs to be decremented by 1
	push	eax
	push	0
	push	OFFSET array
	call	sortList

	push	OFFSET outputMedian
	push	request
	push	OFFSET array
	call	displayMedian

	push	OFFSET outputSorted
	push	request
	push	OFFSET array
	call	displayList

	exit	; exit to operating system
main ENDP

;**********************************************************************************************
; introduction
; Description:			This procedure displays the welcome message to the user's console.
; Receives:				Two character strings by reference. Strings must end in null character.
; Returns:				None.
; Preconditions:		None.
; Registers affected:	None.
;*********************************************************************************************
introduction	PROC
	push	ebp
	mov		ebp, esp
	push	edx

	mov		edx, [ebp + 12]
	call	WriteString
	mov		edx, [ebp + 8]
	call	WriteString

	pop		edx
	pop		ebp
	ret		8
introduction	ENDP

;********************************************************************************************
; getData
; Description:			This procedure asks the user for how many random numbers to generate for the array.
;						Input is validated between HI and LO constants
; Receives:				Reference to request variable, two character strings by references for output.
; Returns:				Total number of elements for the array (reference to request)
; Preconditions:		None.
; Registers affected:	None
;*********************************************************************************************
getData	PROC
	push	ebp
	mov		ebp, esp
	pushad

AskInput:
	mov		edx, [ebp + 16]
	call	WriteString
	call	ReadInt
	cmp		eax, MIN
	jl		InvalidInput
	cmp		eax, MAX
	jg		InvalidInput
	jmp		ValidInput

InvalidInput:
	mov		edx, [ebp + 12]
	call	WriteString
	jmp		AskInput

ValidInput:
	mov		ebx, [ebp + 8]
	mov		[ebx], eax

	popad
	pop		ebp
	ret		12
getData	ENDP

;******************************************************************************************
; fillArray
; Description:			This procedure generates a number of random floating point numbers
;						ranging from 100.000 to 999.000. The numbers are stored in an array
;						up to the request value.
; Receives:				Address of the array base, number of array elements (request)
; Returns:				Returns a filled array of random floating point numbers (through reference to array)
; Preconditions:		Number of array elements is a positive integer.
; Regsiters affected:	None
;*******************************************************************************************
fillArray	PROC
	push	ebp
	mov		ebp, esp
	pushad

	mov		ecx, [ebp+8]					;request in loop requester ecx
	mov		edi, [ebp+12]					;base address of array
FillLoop:
	mov		eax, HI							;Generate a random floating-point number between HI (999.000) and LO (100.000)
	mov		ebx, 1000
	mul		ebx
	push	eax
	mov		eax, LO
	mov		ebx, 1000
	mul		ebx
	mov		ebx, eax
	pop		eax
	sub		eax, ebx
	call	RandomRange						
	add		eax, ebx
	push	eax
	fild	DWORD PTR [esp]
	pop		eax
	push	1000
	fidiv	DWORD PTR [esp]
	pop		eax
	fstp	REAL4 PTR [edi]
	add		edi, 4
	loop	FillLoop

	popad
	pop		ebp
	ret		8
fillArray	ENDP

;******************************************************************************************
; sortList
; Description:			Recursive function to implement the quicksort algorithm.
;						Sorts an array of floating-point numbers in descending order.
; Receives:				Address of the array base, value of low, value of high
; Returns:				Through array reference, a sorted list of floating point numbers
; Preconditions:		For initial call, to sort the entire array, low=0 and high=number of elements minus 1
; Registers affected:	None.
;******************************************************************************************
sortList PROC
	push	ebp
	mov		ebp, esp
	sub		esp, 4							;I_local, local variable [ebp-4]
	pushad

	mov		I_local, 0				
	mov		eax, low_arg					;[ebp+12]
	cmp		eax, high_arg					;[ebp+16]
	jge		ExitQuickSort

	lea		eax, I_local					;call partition helper function
	push	eax 
	push	high_arg
	push	low_arg
	push	[ebp+8]
	call	partition

	mov		eax, I_local					;recursive call quicksort #1
	dec		eax
	push	eax
	push	low_arg
	push	[ebp+8]
	call	sortList

	push	high_arg						;recursive call quicksort #2
	mov		eax, I_local
	inc		eax
	push	eax
	push	[ebp+8]
	call	sortList

ExitQuickSort:
	popad
	mov		esp, ebp
	pop		ebp
	ret		12
sortList ENDP

;******************************************************************************************
; partition
; Description:		 This is a helper function for sortList (quicksort algorithm)
;					 Takes the last element as pivot, places the pivot element at its correct 
;					 position in sorted array, and places all smaller (than pivot) to left of pivot
;					 and all greater elements to the right of pivot.
; Receives:			 Address of the array base, value of low, value of high, and a reference to a return value
; Returns:			 Pivot through reference by [ebp+20]
; Preconditions:	 None.
; Registers affected: None
;******************************************************************************************
partition PROC
	push	ebp
	mov		ebp, esp
	sub		esp, 12							;local variables I_local, J_local, pivot_local
	pushad
	mov		edi, [ebp+8]

	mov		eax, high_arg
	mov		ebx, 4
	mul		ebx
	add		eax, [ebp+8]
	mov		esi, eax
	mov		eax, [esi]
	mov		pivot_local, eax				;pivot = arr[high]
	mov		eax, low_arg
	dec		eax
	mov		I_local, eax					;i_local = low-1
	mov		eax, low_arg
	mov		J_local, eax
WhileLoopP:									;Iterate from low to high, j_local is the counter
	mov		eax, J_local
	mov		ebx, high_arg
	cmp		eax, ebx
	jge		ExitLoopP
	mov		eax, J_local					;if (arr[j] >= pivot), increment i, swap arr[i] and arr[j]
	mov		ebx, 4
	mul		ebx
	mov		esi, eax
	add		esi, [ebp+8]
	fld		DWORD PTR [esi]
	fld		pivot_local
	fcompp									;Source cite: floating point comparisons from Kip Irvine Assmelby SEction 12.2.6
	fnstsw	ax
	sahf
	jae		InnerIfGreater
	mov		eax, I_local					
	inc		eax
	mov		I_local, eax

	mov		eax, J_local
	mov		ebx, 4
	mul		ebx
	add		eax, edi
	push	eax
	mov		eax, I_local
	mov		ebx, 4
	mul		ebx
	add		eax, edi
	push	eax
	call	exchange						;Call exchange(&array[i], &array[j])
InnerIfGreater:
	mov		eax, J_local					
	inc		eax
	mov		J_local, eax
	jmp		WhileLoopP
ExitLoopP:
	mov		eax, high_arg
	mov		ebx, 4
	mul		ebx
	add		eax, edi
	push	eax
	mov		eax, I_local
	inc		eax
	mov		ebx, 4
	mul		ebx
	add		eax, edi
	push	eax
	call	exchange						;exchange(&array[i+1], &array[high])
	mov		eax, I_local
	inc		eax
	mov		ebx, return_arg
	mov		[ebx], eax						;return (i + 1) through return_arg variable;

	popad
	mov		esp, ebp
	pop		ebp
	ret		16
partition ENDP

;******************************************************************************************
; exchange
; Description:		  Utility function for sortList that swaps (exchanges) the 
;					  value of array[i] and array[j] with each other.
; Receives:			  Address location of array[i] and array[j]
; Returns:			  array[i] = array[j] and array[j] = array[i]
; Preconditions:	  None.
; Registers affected: None.
;******************************************************************************************
exchange PROC
	push	ebp
	mov		ebp, esp
	pushad

	mov		esi, [ebp+8]
	mov		eax, [esi]
	mov		edi, [ebp+12]
	mov		edx, [edi]
	mov		[esi], edx
	mov		[edi], eax

	popad
	mov		esp, ebp
	pop		ebp
	ret		8
exchange ENDP

;******************************************************************************************
; displayMedian
; Description:		This procedure calculates and displays the median of a sorted list of numbers
;					If there is an even number of array elements, the middle two elements are averaged.
;					Because the program implements floating point, the averaged elements are not rounded.
; Receives:			Address of beginning of array, value of number of array elements, output string
; Returns:			None.
; Preconditions:	The array of numbers must be sorted in order.
; Registers affected: none.
;*******************************************************************************************
displayMedian	PROC
	push	ebp
	mov		ebp, esp
	pushad

	call	Crlf
	mov		edx, [ebp+16]
	call	WriteString
	mov		eax, [ebp+12]					;number of elements (value)
	mov		edi, [ebp+8]					;address of array start
	cdq
	mov		ebx, 2
	div		ebx
	cmp		edx, 0
	je		EvenNumber
	mov		ebx, 4
	mul		ebx
	mov		esi, eax
	add		esi, edi
	fld		DWORD PTR [esi]					;for an odd number of elements, print the middle element
	call	WriteFloat
	ffree	st[0]
	call	Crlf
	jmp		displayComplete
EvenNumber:									;if an even number of elements, average the middle two.
	dec		eax
	mov		ebx, 4
	mul		ebx
	mov		esi, eax
	add		esi, edi
	fld		DWORD PTR [esi]
	add		esi, 4
	fld		DWORD PTR [esi]	
	faddp
	mov		eax, 2
	push	eax
	fild	DWORD PTR [esp]
	pop		eax
	fdiv	
	call	WriteFloat
	ffree	st[0]
	call	Crlf

displayComplete:
	call	Crlf

	popad
	pop		ebp
	ret		12
displayMedian	ENDP


;******************************************************************************************
; displayList
; Description:  This procedure displays the list of floating-point numbers in a 
;			    table with 10 columns. The display is ordered by columns (extra credit #1) 
;			    instead of rows. 
; Receives:     Address of beginning of array, value of number of array elements, output string
; Returns:      None
; Preconditions:None
; Registers affected: None
;*********************************************************************************************
displayList	PROC
	push	ebp
	mov		ebp, esp
	sub		esp, 8							;I_local, J_local
	pushad

	mov		edx, [ebp + 16]
	call	WriteString
	mov		edi, [ebp+8]					;address of array
	mov		eax, [ebp+12]					;number of elements (value)
	mov		ebx, 10							;number of columns to display
	cdq
	div		ebx
	inc		eax
	mov		numRows, eax					;InumRows = (numElem / numCol + 1
	mov		remainder, edx					;The division remainder will be the number of elements in the last incomplete row.
	mov		eax, 0
	mov		ebx, 0
DisplayLoopOuter:
	mov		ecx, 0
DisplayLoopInner:
	mov		eax, numRows
	dec		eax
	cmp		eax, ebx
	jnz		PrintValue
	mov		eax, remainder
	cmp		eax, ecx
	jg		PrintValue
	jmp		DoNotPrint
PrintValue:
	mov		eax, numRows
	mul		ecx
	add		eax, ebx
	cmp		ecx, remainder
	jl		NoAddOn
	add		eax, remainder
	sub		eax, ecx
NoAddOn:
	mov		edx, 4
	mul		edx
	mov		esi, eax
	add		esi, edi
	fld		DWORD PTR [esi]
	call	WriteFloat
	ffree	st[0]
	mov		al, 32
	call	WriteChar
DoNotPrint:
	inc		ecx
	cmp		ecx, 10
	jl		DisplayLoopInner
	call	Crlf
	inc		ebx
	cmp		ebx, numRows
	jl		DisplayLoopOuter

	popad
	mov		esp, ebp
	pop		ebp
	ret		12
displayList	ENDP

END main

;Algorithm for quicksort
;Source: https://www.geeksforgeeks.org/quick-sort/
;
;quicksort(&array, low, high) {
;	if (low < high) {
;		pivot = partition(array, low, high)
;		quickSort(array, low, pivot - 1)
;		quickSort(array, pivot + 1, high) 
;	}
;}
;int partition(&array, low, high) {
;   pivot = array[high]
;	i = low - 1
;	for (j = low; j < high; j++) {
;		if (array[j] >= pivot) {
;			i++
;			swap(&array[i], &array[j]) 
;		}
;	}
;	return(i+1)
;}
