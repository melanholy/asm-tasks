.model tiny

.code
    org 100h
start:
    jmp rstart
pixel proc
    mov ah, 0ch
    mov al, 07h
    mov bh, 00h
    int 10h

    ret
pixel endp

axis proc
    mov cx, 320
    mov dx, 350
yaxis:
    call pixel
    mov bx, dx
    sub dx, 175
    jns posy
    neg dx
posy:
    mov ax, dx
    mov dx, 35
    div dl
    cmp ah, 0
    mov dx, bx
    jne nexty
    mov cx, 315
marky:
    call pixel
    inc cx
    cmp cx, 325
    jne marky
    mov cx, 320
nexty:
    dec dx
    jnz yaxis

    mov dx, 175
    mov cx, 640
xaxis:
    call pixel
    mov bx, cx
    sub cx, 320
    jns posx
    neg cx
posx:
    mov ax, cx
    mov cx, 32
    div cl
    cmp ah, 0
    mov cx, bx
    jne nextx
    mov dx, 170
markx:
    call pixel
    inc dx
    cmp dx, 180
    jne markx
    mov dx, 175
nextx:
    dec cx
    jnz xaxis

    ret
axis endp

xstart dd -10.0
y dd 0
step dd 0.03125
height dd 175.0
one dd 1.0

rstart:
    mov ah, 00h
    mov al, 10h
    int 10h

    finit
    fld xstart
    mov cx, 0
lp:
    fld ST(0)
    fcos
    fsub one
    fabs
    fdiv ST(0), ST(1)
    fadd one
    fmul height
    fistp y
    mov ax, word ptr y
    mov dx, 350
    sub dx, ax
    call pixel
    inc cx
    fadd step
    cmp cx, 640
    jne lp

    call axis

    mov ah, 01h
    int 21h
    mov ah, 00h
    mov al, 03h
    int 10h
    ret
end start
