INCLUDE C:\Irvine\irvine32.inc

luaL_openlibs PROTO C :DWORD
luaL_newstate PROTO C 
lua_pushcclosure PROTO C :DWORD, :DWORD, :DWORD 
lua_setglobal PROTO C :DWORD, :DWORD
luaL_loadfilex PROTO C :DWORD, :DWORD, :DWORD
lua_pcallk PROTO C :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD
lua_close PROTO C :DWORD
lua_tolstring PROTO C :DWORD, :DWORD, :DWORD

printString PROTO

.data
    L       DWORD   ?
    file    BYTE    30 DUP(?)
    func    BYTE    "printString", 0
    prompt  BYTE    "Please enter name of lua script: ", 0
    done    BYTE    "Would you like to exit? [1] yes, [0] no.", 0

.code

lua_printString PROC C
    push    ebp
    mov     ebp, esp

    INVOKE lua_tolstring, L, 1, 0
    push    eax
    call    printString
    add     esp, 4

    pop     ebp
    ret

lua_printString ENDP



main PROC C
    
    INVOKE luaL_newstate
    mov     L, eax
    INVOKE luaL_openlibs, L
    
    INVOKE lua_pushcclosure, L, OFFSET lua_printString, 0
    INVOKE lua_setglobal, L, OFFSET func

    top:
    
        mov     edx, OFFSET prompt
        call    writeString

        mov     edx, OFFSET file
        mov     ecx, 29
        call    readString
        call    Crlf
        

        INVOKE luaL_loadfilex, L, OFFSET file, 0
        INVOKE lua_pcallk, L, 0, 0, 0, 0 ,0

        call    Crlf
        call    Crlf
        
        mov     edx, OFFSET done
        call    writeString
        call    Crlf
        call    readDec
        cmp     eax, 0

        je top

    INVOKE lua_close, L
    
    INVOKE exitprocess, 0

main ENDP


END

