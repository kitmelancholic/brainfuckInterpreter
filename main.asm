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
filename   db FILENAME_SIZE dup(?)
code       db MAX_SIZE DUP(?)
cells      dw MAX_SIZE DUP(?)

.code
org 100h

init:
clearUnintializedVariables:
    mov di, offset filename
    mov si, di                          ; Set up si for later use
    mov cx, MAX_SIZE*3+FILENAME_SIZE    ; Total length of uninitialized data
    xor ax, ax                          ; Zero out ax
    rep stosb                           ; Initialize memory to zero

copyFilename:                           ; Transfer filename from command line
    mov si, 82h
    mov cl, [ds:TAIL_BYTES]
    dec cl
    mov di, offset filename
    rep movsb

readCode:
    mov ah, OPEN_FILE_FN                ; Prepare to open file
    mov dx, offset filename             ; Point to filename
    int 21h
    ; Error handling omitted
    mov bx, ax                          ; Store file handle

    mov ah, READ_FILE_FN
    dec cx                              ; Set to max possible size
    mov dx, offset code                 ; Destination for code
    int 21h

decodeCommand:
; Parameters:
;   al - current instruction
;   si - instruction pointer
;   di - data pointer
; Used registers:
;   bx - file descriptor
;   cx - I/O byte count
; No return value
increment:
    cmp al, '+'
    jne SHORT decrement
    inc word ptr [di]
decrement:
    cmp al, '-'
    jne SHORT incrementPointer
    dec word ptr [di]
incrementPointer:
    cmp al, '>'
    jne SHORT decrementPointer
    inc di
    inc di
decrementPointer:
    cmp al, '<'
    jne SHORT startLoop
    dec di
    dec di
startLoop:

endLoop:

checkReadChar:
    cmp al, ','
    jne checkWriteChar
    inc cx                              ; Reset loop counter, set byte count
readChar:
    mov ah, READ_FILE_FN
    mov dx, di
    mov word ptr [di], bx               ; Clear memory location
    int 21h
    dec ax
    or word ptr [di], ax                ; Handle EOF condition
checkLF:
    cmp byte ptr [di], CR               ; Skip CR in CRLF sequence
    je readChar
    dec cx                              ; Restore loop counter

checkWriteChar:
    cmp al, '.'                         ; Check for output instruction
    jne loadNextChar
writeChar:
    mov ah, 02h
    cmp byte ptr [di], LF               ; Add CR before LF if needed
    jne writeSimpleChar
    mov dl, CR
    int 21h
writeSimpleChar:
    mov dx, [di]
    int 21h

loadNextChar:
    lodsb
    or al, al
    jne decodeCommand
exit:
    ret
end init