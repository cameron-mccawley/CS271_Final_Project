.686p
.model flat, stdcall
.stack 4096

PUBLIC main

MessageBoxA PROTO stdcall, :DWORD, :DWORD, :DWORD, :DWORD

MB_OK   equ  0

.data
        message     BYTE    "This is line one,", 13, 10, "and this is line two.", 0
        title_box   BYTE    "Called From Asm!", 0

.code

main PROC C
        
        INVOKE  MessageBoxA, 0, OFFSET message, OFFSET title_box, MB_OK

        mov     eax, 0
        ret
main ENDP

END

