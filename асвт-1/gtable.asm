.model tiny

.code
    org 100h
start:
    jmp rstart

    pge db ?
    x_start db 22
    y_start db 3
    x db 22
    y db 3

print:
    mov dx, word ptr x
    mov ah, 02h
    mov bh, pge
    int 10h
    inc dx
    mov word ptr x, dx
    mov dx, cx
    mov ah, 09h
    mov cx, 01h
    int 10h
    mov cx, dx
    ret

newline:
    mov dx, word ptr x
    inc dh
    mov dl, x_start
    mov word ptr x, dx
    ret

space:
    mov dx, word ptr x
    inc dx
    mov word ptr x, dx
    ret

backspace:
    mov dx, word ptr x
    dec dx
    mov word ptr x, dx
    ret

border:
    mov cx, 21h
borderloop:
    call print
    dec cx
    jnz borderloop
    ret

rstart:
    mov ah, 0fh
    int 10h

    mov pge, bh
    cmp al, 06h
    jle notmda
    mov dh, 0b0h
notmda:
    cmp al, 02h
    jg big
    mov x, 02h
    mov x_start, 02h
big:
    mov ax, 0600h
    mov bh, 0bbh
    xor cx, cx
    mov dx, 1950h
    int 10h

    mov ah, 02h
    mov bh, pge
    mov dh, y_start
    mov dl, x_start
    int 10h

    mov bl, 38h
    mov al, 219
    call print
    mov al, 223
    call border
    mov al, 219
    call print
    call newline
    call print
    call space
    mov al, -1
    mov cl, 16
printloop:
    inc al
    mov bl, 0bdh
    call print
    call space
    dec cl
    jnz printloop

    push ax
    mov cl, 16
    mov al, 219
    mov bl, 08h
    call print
    call newline
    call print
    call space
    pop ax

    cmp al, 255
    jne printloop

    call backspace
    mov al, 220
    mov bl, 38h
    call border
    mov al, 219
    call print

    mov ah, 01h
    int 21h

    mov ax, 0600h
    mov bh, 07h
    xor cx, cx
    mov dx, 1950h
    int 10h

    ret
end start
