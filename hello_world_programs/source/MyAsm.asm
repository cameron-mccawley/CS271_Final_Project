INCLUDE irvine32.inc
INCLUDE MyIO.inc


.data
	hello	BYTE	"Hello, static library.", 0

.code
main PROC
	push	OFFSET hello
	call	printString

	INVOKE ExitProcess, 0
main ENDP


END main
