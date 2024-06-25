.model tiny

; Constants
MAX_SIZE EQU 10001

CR              EQU 0Dh
LF              EQU 0Ah

OPEN_FILE_FN    EQU 3Dh
CLOSE_FILE_FN   EQU 3Eh
READ_FILE_FN    EQU 3Fh
WRITE_FILE_FN   EQU 40h

TAIL_START      EQU 81h

.data?
code       db MAX_SIZE DUP(?)
cells      dw MAX_SIZE DUP(?)

.code
org 100h

init:
clearUnintializedVariables:
    mov di, offset code
    mov si, di                          ; Set up si for later use
    mov cx, MAX_SIZE*3                  ; Total length of uninitialized data
    xor ax, ax                          ; Zero out ax
    rep stosb                           ; Initialize memory to zero

prepareFilename:
    mov dx, TAIL_START+1
    mov bx, [ds:TAIL_START-1]
    mov byte ptr [bx-2000h+81h], 0

readCode:
    mov ah, OPEN_FILE_FN                ; Prepare to open file
    int 21h
    ; Error handling omitted
    mov bx, ax                          ; Store file handle
    mov ah, READ_FILE_FN
    dec cx                              ; Set to max possible size
    mov dx, si                          ; Destination for code
    int 21h

    mov di, offset cells
    inc cx
decodeCommand:
; Parameters:
;   al - current instruction
;   si - instruction pointer
;   di - data pointer
; Used registers:
;   bx - file descriptor
;   cx - I/O byte count
; No return value
    xor bx, bx
    cmp al, '['
    jne endLoopCheck
startLoop:
    push si
    cmp word ptr [di], bx
    jnz loadNextChar
    inc cx
endLoopCheck:
    cmp al, ']'
    jne checkIsHalted
endLoop:
    pop bx
    dec cx
    jns loadNextChar
    inc cx
    dec bx
    mov si, bx

checkIsHalted:
    or cx, cx
    jnz loadNextChar

decodeModifyingCommand:
    cmp al, '>'
    jne SHORT decrementPointer
    inc di
    inc di

decrementPointer:
    cmp al, '<'
    jne SHORT incrementValue
    dec di
    dec di

incrementValue:
    cmp al, '+'
    jne SHORT decrementValue
    inc word ptr [di]

decrementValue:
    cmp al, '-'
    jne SHORT checkReadChar
    dec word ptr [di]

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