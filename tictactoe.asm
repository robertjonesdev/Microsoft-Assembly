TITLE TicTacToe Game

;Author: Robert Jones
;Website: http://robertjones.dev
;Date: June 11, 2019

INCLUDE Irvine32.inc
X = 88			;ascii code to represent X/O
O = 79

.data
hLine			BYTE	"-+-+-",0
vLine			BYTE	"|",0
gameBoard		DWORD	1, 2, 3, 4, 5, 6, 7, 8, 9
gameWinner		BYTE	0
introMsg		BYTE	"Classic Tic-Tac-Toe", 13, 10, "By Robert Jones", 10, 13, "http://robertjones.dev", 10, 13, 10, 13,0
moveMsg			BYTE	"- Enter your move (1-9): ",0
invalidMsg		BYTE	"   Invalid input. Try again: ",0
winnerMsg		BYTE	" has won the game!", 0
stalemateMsg	BYTE	"The game has ended in a stalemate.",0
.code

 main PROC
	mov		edx, OFFSET introMsg
	call	WriteString
 	call	displayBoard
 GameLoop:
	push	X
	call	GetMove
	call	displayBoard
	call	checkGameState
	mov		al, gameWinner
	cmp		al, 0
	jne		EndOfGame

	push	O
	call	GetMove
	call	displayBoard
	call	checkGameState

	mov		al, gameWinner
	cmp		al, 0
	je		GameLoop
EndOfGame:

	exit
main ENDP

; ******************************************************************************************************
; DisplayBoard
; Description :		 Displays the gameboard from a 9 element DWORD array
;					 Empty space: 1-9
;					 X = 88, O = 79 (ascii codes)
; Receives:			 None.
; Returns:			 None
; Preconditions:	 None.
; Registers Changed: None.
; ******************************************************************************************************
displayBoard PROC
	push	ebp
	mov		ebp, esp
	pushad

	call	Crlf
	mov		eax, 0
	mov		edi, OFFSET gameBoard
	mov		ecx, 3
L1:											;outer loop for rows
	push	ecx
	mov		ecx, 3
L2:											;inner loop for columns
	mov		eax, [edi]
	cmp		eax, 9
	jle		EmptySpace		
	call	WriteChar
	jmp		NotEmptySpace
EmptySpace:
	call	WriteDec
NotEmptySpace:
	add		edi, 4
	cmp		ecx, 1
	je		NoVLine
	mov		edx, OFFSET vLine
	call	WriteString
NoVLine:
	loop	L2
	pop		ecx
	call	Crlf
	cmp		ecx, 1
	je		NoHLine
	mov		edx, OFFSET hLine
	call	WriteString
NoHLine:
	call	Crlf
	loop	L1

	popad
	pop		ebp
	ret							
displayBoard	ENDP

; ******************************************************************************************************
; GetMove
; Description :		   Receives the number corresponding to the gameBoard spot the player wishes to move.
;						The move is validated as valid from 1-9 and that the spot is empty.
; Receives:				X or O as active player [EBP+8]
; Returns:			    Returns the new value of the move to the global array gameBoard
; Preconditions:	    None
; Registers Changed:    None
; ******************************************************************************************************
getMove PROC
	push	ebp
	mov		ebp, esp
	pushad

	mov		al, [ebp+8]
	call	WriteChar
	mov		edx, OFFSET moveMsg
	call	WriteString

	mov		eax, 0
	mov		ebx, 0
	mov		edi, OFFSET gameBoard

GetInput:
	call	ReadDec
	cmp		eax, 1
	jl		InvalidInput
	cmp		eax, 9
	jg		InvalidInput
	cmp		eax, [edi + (4*eax) - 4]
	jne		InvalidInput
	mov		ebx, [ebp+8]
	mov		[edi+ (4*eax) - 4], ebx
	jmp		InputComplete
InvalidInput:
	mov		edx, OFFSET invalidMsg
	call	WriteString
	jmp		GetInput

InputComplete:
	popad
	pop		ebp
	ret		4		
getMove ENDP


; ******************************************************************************************************
; checkGameState
; Description :		  Checks the board for any winning combinations or a stalemate.
; Receives:			  None
; Returns:			  Returns the gameState as != 0 if there is a winner or stalemate.
; Preconditions:	  None
; Registers Changed:  None
; ******************************************************************************************************
checkGameState PROC
	push	ebp
	mov		ebp, esp
	pushad

	mov		edi, OFFSET gameBoard
	mov		ecx, 3
CheckRows:									;Check Rows for winner
	mov		eax, 0
	mov		eax, [edi]
	add		eax, [edi+4]
	add		eax, [edi+8]
	cmp		eax, 264
	je		XWinner
	cmp		eax, 237
	je		OWinner
	add		edi, 12
	Loop	CheckRows

	mov		edi, OFFSET gameBoard
	mov		ecx, 3
CheckCols:									;Check Columns for winner
	mov		eax, 0
	mov		eax, [edi]
	add		eax, [edi+12]
	add		eax, [edi+24]
	cmp		eax, 264
	je		XWinner
	cmp		eax, 237
	je		OWinner
	add		edi, 4
	Loop	CheckCols

	mov		edi, OFFSET gameBoard			;Check Diagonal for winner
	mov		eax, 0
	mov		eax, [edi]
	add		eax, [edi+16]
	add		eax, [edi+32]
	cmp		eax, 264
	je		XWinner
	cmp		eax, 237
	je		OWinner
	mov		eax, 0
	mov		eax, [edi+8]
	add		eax, [edi+16]
	add		eax, [edi+24]
	cmp		eax, 264
	je		XWinner
	cmp		eax, 237
	je		OWinner

	mov		eax, 0
	mov		ecx, 9
	mov		edi, OFFSET gameBoard
CheckStalemate:								;Check for stalemate (no empty spaces)
	add		eax, [edi]
	add		edi, 4
	Loop	CheckStalemate
	cmp		eax, 747
	jge		Stalemate

	jmp		ReturnState						;no winner, no stalemate

XWinner:
	mov		gameWinner, X
	mov		al, X
	call	WriteChar
	mov		edx, OFFSET winnerMsg
	call	WriteString
	call	Crlf
	jmp		ReturnState

OWinner:
	mov		gameWinner, O
	mov		al, O
	call	WriteChar
	mov		edx, OFFSET winnerMsg
	call	WriteString
	call	Crlf
	jmp		ReturnState

Stalemate:
	mov		gameWinner, 1
	mov		edx, OFFSET stalemateMsg
	call	WriteString
	call	Crlf

ReturnState:
	popad
	pop		ebp
	ret							
checkGameState ENDP

exit
END main