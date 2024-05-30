.model tiny

MAX_SIZE EQU 10001
FILENAME_SIZE EQU 256d

OPEN_FILE_FN    EQU 3Dh
CLOSE_FILE_FN   EQU 3Eh
READ_FILE_FN    EQU 3Fh
WRITE_FILE_FN   EQU 40h

TAIL_BYTES EQU 80h
TAIL_START EQU 81h
TAIL_LENGTH EQU 127

.data?
filename db FILENAME_SIZE dup(?)
code       db MAX_SIZE DUP(?)
cells      dw MAX_SIZE DUP(?)

.code
org 100h

init:
clearUnintializedVariables:
    mov di, offset filename
    mov si, di                              ; Prepare si for decodeLoop
    mov cx, MAX_SIZE*3+FILENAME_SIZE        ; length of uninitialized data
    xor ax, ax                              ; Also prepare ah for Read-only mode
    rep stosb                               ; all bits set to 0
;endp

copyFilename:
    mov si, 82h
    mov cl, [ds:TAIL_BYTES]
    dec cl
    mov di, offset filename
    ; read the argument byte by byte and write it into memory using movsb
    rep movsb
readCode:
    mov ah, OPEN_FILE_FN    ; al = Read-only mode, preset by `xor ax, ax`
    mov dx, offset filename
    ; dx is preset to ASCIIZ filename
    int 21h
    ; No error checking, since is guaranteed by requirements
    mov bx, ax              ; File handle
    mov ah, READ_FILE_FN
    dec cx                  ; Number of bytes to read (0FFFFh)
    mov dx, offset code     ; Where to store the code      
    int 21h
; end of proc


decodeCommand:

increment:

decrement:

incrementPointer:

decrementPointer:

startLoop:

endLoop:

writeChar:

readChar:

exit:
    ret
end init