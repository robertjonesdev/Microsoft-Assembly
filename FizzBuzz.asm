TITLE FizzBuzz
;Robert Jones
;June 10, 2019
;Classic FizzBuzz Example

INCLUDE Irvine32.inc

.data
space		BYTE " ", 0
fizz		BYTE "Fizz",0
buzz		BYTE "Buzz",0

.code
 main PROC


	mov		ebx, 0
LoopStart:
	inc		ebx
	mov		eax, ebx
	call	WriteDec
	mov		edx, OFFSET space
	call	WriteString
	mov		ecx, 3
	cdq		
	div		ecx
	cmp		edx, 0
	jnz		NoThree
	mov		edx, OFFSET fizz
	call	WriteString
NoThree:
	mov		eax, ebx
	mov		ecx, 5
	cdq		
	div		ecx
	cmp		edx, 0
	jnz		NoFive
	mov		edx, OFFSET buzz
	call	WriteString
NoFive:
	call	Crlf
	cmp		ebx, 100
	jge		EndLoop
	jmp		LoopStart
EndLoop:

	exit
main ENDP


exit
END main