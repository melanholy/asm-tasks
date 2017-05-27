.model tiny

.code
    org 100h
start:
    jmp rstart

newline:
    mov ah, 06h
    mov dx, 10
    int 21h
    mov dx, 13
    int 21h
    ret

border:
    mov cx, 33
    mov ah, 2
    mov bx, dx
    mov dx, 219
    int 21h
    mov dx, bx
borderloop:
    int 21h
    dec cx
    jnz borderloop

    mov dx, 219
    int 21h
    call newline
    ret

rstart:
    mov dx, 0dfh
    call border
    mov dx, 219
    int 21h
    mov dx, 32
    int 21h
    mov dx, -1
    mov cx, 16
printloop:
    inc dx
    cmp dx, 0ah
    je @@2
    cmp dx, 07h
    je @@2
    cmp dx, 08h
    je @@2
    cmp dx, 1bh
    je @@2
    cmp dx, 0dh
    je @@2
    cmp dx, 09h
    je @@2
    cmp dx, 0ffh
    je @@2
    jmp @@3
@@2:
    mov bx, dx
    mov dx, 20h
    int 21h
    mov dx, bx
    jmp @@1
@@3:
    mov ah, 06h
    int 21h
@@1:
    mov bx, dx
    mov dx, 20h
    int 21h
    mov dx, bx
    dec cx
    jnz printloop

    mov cx, 16
    mov bx, dx
    mov dx, 219
    int 21h
    call newline
    mov dx, 219
    int 21h
    mov dx, 32
    int 21h
    mov dx, bx

    cmp dx, 255
    jne printloop

    mov dx, 13
    int 21h
    mov dx, 0dch
    call border
    ret
end start
