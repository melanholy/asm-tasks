.model tiny
.386

.code
    org 100h
start:
    jmp rstart
pixel proc
    mov ah, 0ch
    mov bh, 00h
    int 10h

    ret
pixel endp

char proc
    mov ah, 02h
    mov bh, 00h
    int 10h
    mov ah, 0ah
    mov bh, 00h
    mov bl, 07h
    mov cx, 1
    int 10h

    ret
char endp

num proc
    cmp al, 0
    jge above
    push ax
    mov al, 45
    call char
    pop ax
    neg ax
    inc dl
above:
    add ax, 48
    call char
    ret
num endp

axis proc
    mov cx, 319
    mov dx, 350
    mov bx, -3
yaxis:
    mov al, 07h
    call pixel
    push dx
    sub dx, 175
    jns posy
    neg dx
posy:
    mov ax, dx
    mov dx, 87
    div dl
    cmp ah, 0
    pop dx
    jne nexty
; число
    push dx
    push cx
    push bx
    mov ax, dx
    mov bx, 14
    div bl
    mov dh, al
    mov dl, 41
    pop bx
    mov al, bl
    push bx
    call num
    pop bx
    pop cx
    pop dx
    inc bx
; черточка
    mov cx, 314
marky:
    mov al, 07h
    call pixel
    inc cx
    cmp cx, 324
    jne marky
    mov cx, 319
nexty:
    dec dx
    jnz yaxis

    mov dx, 88
    mov cx, 640
    mov bx, 3
xaxis:
    mov al, 07h
    call pixel
    push cx
    sub cx, 319
    jns posx
    neg cx
posx:
    mov ax, cx
    mov cx, 106
    div cl
    cmp ah, 0
    pop cx
    jne nextx
; число
    push dx
    push cx
    push bx
    mov ax, cx
    mov bx, 8
    div bl
    mov dh, 5
    mov dl, al
    pop bx
    mov al, bl
    push bx
    call num
    pop bx
    pop cx
    pop dx
    dec bx
;черточка
    mov dx, 82
markx:
    mov al, 07h
    call pixel
    inc dx
    cmp dx, 92
    jne markx
    mov dx, 88
nextx:
    dec cx
    jnz xaxis

    ret
axis endp

xstart dd -2.0
y dd 0
step dd 0.009375
ycoef dd 87.0

rstart:
    mov ah, 00h
    mov al, 10h
    int 10h

    call axis

    finit
    fld xstart
    mov cx, 106
lp:
    fld ST(0)
    fabs
    fld1
    fsubp
    fmul ST(0), ST(0)
    fld1
    fsubrp
    fsqrt
    fld1
    fsubrp
    fmul ycoef
    fistp y
    mov dx, word ptr y
    mov al, 19h
    call pixel

    fld ST(0)
    fabs
    fld1
    fsubrp
    fld ST(0)
    fmul ST(0), ST(0)
    fld1
    fsubrp
    fsqrt
    fxch
    fpatan
    fldpi
    fsubp
    fst y
    fld1
    fsubp
    fabs
    fmul ycoef
    fistp y
    mov dx, word ptr y
    mov al, 3dh
    call pixel

    inc cx
    fadd step
    cmp cx, 534
    jle lp

    mov ah, 01h
    int 21h
    mov ah, 00h
    mov al, 03h
    int 10h
    ret
end start
