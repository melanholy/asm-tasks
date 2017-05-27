.model tiny
.386
.8087

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
    jg above
    je endr
    push ax
    mov al, 45
    call char
    pop ax
    neg ax
    inc dl
above:
    add ax, 48
    call char
endr:
    ret
num endp

axis proc
    mov cx, 320
    mov dx, 350
    mov bx, -3
yaxis:
    mov al, 07h
    call pixel
    push dx
    mov ax, dx
    mov dx, 50
    div dl
    cmp ah, 0
    pop dx
    jne nexty
    cmp bx, 0
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
    mov cx, 315
marky:
    mov al, 07h
    call pixel
    inc cx
    cmp cx, 325
    jne marky
    mov cx, 320
nexty:
    dec dx
    jnz yaxis

    mov dx, 200
    mov cx, 640
    mov bx, 6
xaxis:
    mov al, 07h
    call pixel
    push cx
    mov ax, cx
    mov cx, 46
    div cl
    cmp ah, 0
    pop cx
    jne nextx
; число
    push dx
    push cx
    push bx
hhh:
    mov ax, cx
    mov bx, 8
    div bl
    mov dh, 13
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
    mov dx, 195
markx:
    mov al, 07h
    call pixel
    inc dx
    cmp dx, 205
    jne markx
    mov dx, 200
nextx:
    dec cx
    jnz xaxis

    ret
axis endp

normalize proc
    fsub four
    fabs
    fmul ycoef
    fistp y
    mov dx, word ptr y
    ret
normalize endp

xstart dd -7.0
y dd 0
step dd 0.021875
ycoef dd 50.0
one dd 1.0
two dd 2.0
three dd 3.0
four dd 4.0
five dd 5.0
seven dd 7.0
coef1 dd 0.0913722
coef2 dd 2.71052
coef3 dd 1.5
coef4 dd 0.5
coef5 dd 1.35526
coef6 dd 0.9
coef7 dd 0.97
coef8 dd 0.75
store dd 0
store1 dd 0
store2 dd 0

rstart:
    mov ax, 10h
    int 10h

    call axis

    finit
    fld xstart
    mov cx, 0
lp:
    fld ST(0)
    fdiv two
    fabs
    fstp store
    fld ST(0)
    fmul ST(0), ST(0)
    fmul coef1
    fsubr store
    fsub three
    fstp store
    fld ST(0)
    fabs
    fsub two
    fabs
    fsub one
    fmul ST(0), ST(0)
    fsubr one
    fsqrt
    fadd store
    call normalize
    mov al, 2eh
    call pixel

    fld ST(0)
    fdiv seven
    fmul ST(0), ST(0)
    fsubr one
    fsqrt
    fmul three
    fchs
    fstp store
    fld ST(0)
    fabs
    fsub four
    fstp store1
    fld ST(0)
    fabs
    fsub four
    fabs
    fdiv store1
    fsqrt
    fmul store
    call normalize
    mov al, 04h
    call pixel

    fld ST(0)
    fabs
    fmul coef4
    fsubr coef3
    fadd coef2
    fstp store
    fld ST(0)
    fabs
    fsub one
    fmul ST(0), ST(0)
    fsubr four
    fsqrt
    fmul coef5
    fsubr store
    fstp store
    fld ST(0)
    fabs
    fsub one
    fstp store1
    fld ST(0)
    fabs
    fsub one
    fabs
    fdiv store1
    fsqrt
    fmul store
    fadd coef6
    call normalize
    mov al, 22h
    call pixel

    fld ST(0)
    fabs
    fsub one
    fabs
    fchs
    fstp store
    fld ST(0)
    fabs
    fsubr three
    fabs
    fmul store
    fstp store
    fld ST(0)
    fabs
    fsub one
    fstp store1
    fld ST(0)
    fabs
    fsubr three
    fmul store1
    fdivr store
    fsqrt
    fmul two
    fstp store
    fld ST(0)
    fabs
    fsub three
    fabs
    fstp store1
    fld ST(0)
    fabs
    fsub three
    fdivr store1
    fadd one
    fmul store
    fstp store
    fld ST(0)
    fdiv seven
    fmul ST(0), ST(0)
    fsubr one
    fsqrt
    fmul store
    fstp store
    fld ST(0)
    fsub coef4
    fabs
    fmul coef7
    fstp store1
    fld ST(0)
    fadd coef4
    fabs
    fadd store1
    fadd five
    fstp store1
    fld ST(0)
    fsub coef8
    fabs
    fstp store2
    fld ST(0)
    fadd coef8
    fabs
    fadd store2
    fmul three
    fsubr store1
    fstp store1
    fld ST(0)
    fabs
    fsubr one
    fabs
    fstp store2
    fld ST(0)
    fabs
    fsubr one
    fdivr store2
    fadd one
    fmul store1
    fadd store
    call normalize
    mov al, 19h
    call pixel

    inc cx
    fadd step
    cmp cx, 640
    jle lp

    mov ah, 01h
    int 21h
    mov ah, 00h
    mov al, 03h
    int 10h
    ret
end start
