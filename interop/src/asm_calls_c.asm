.686p
.model flat,stdcall
.stack 4096

printf PROTO C,:VARARG

.data
        called      BYTE    "Hello, I have been called!", 13, 10, 0
        invoked     BYTE    "Hello, I have been invoked!", 13, 10, 0

.code

main PROC C
        push    OFFSET called
        call    printf
        add     esp, 4  

        INVOKE printf, OFFSET invoked

        mov     eax, 0
        ret
main ENDP

END

