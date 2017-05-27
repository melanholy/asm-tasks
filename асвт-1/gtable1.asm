.model tiny

.code
    org 100h
start:
    xor ax, ax
    mov es, ax
    mov di, es:044eh ; начало страницы
    mov al, es:0449h ; режим
    mov dx, 0b800h

    cmp al, 07h
    je seven
    cmp al, 03h
    jle good
    ret
seven:
    mov dh, 0b0h
good:
    mov cx, 80*25
    cmp al, 02h
    jl smll
    mov si, (80*25-2*80-20)*2+86 ; потом вычтется bp
    mov bp, 86
    jmp fff
smll:
    shr cx, 1
    mov si, (40*25-2*40-2)*2+6 ; потом вычтется bp
    mov bp, 06h
fff:
    mov es, dx
    push di
    push cx
    mov ax, 01f00h
    rep stosw

    sub di, si
    lea si, special
    call border
    mov bx, 0a30h
    call newline ; в dl 0
    mov bx, 0641h
    call print
    stosw
    call border

    mov dl, 30h
    mov bx, 1000h
loop1:
    call newline
    stosw
    inc dx
    cmp dl, 3ah
    jne row_num
    mov dl, 41h
row_num:
    cmp dl, 47h
    jne loop1

    call border

    mov ah, 01h
    int 21h

    pop cx
    pop di
    mov ax, 0700h
    rep stosw
bye:
    ret

border:
    add di, bp
    mov cl, 04h
kkk:
    lodsb
    stosw
    loop kkk
    mov cl, 20h
    rep stosw
    lodsb
    stosw
    ret

newline:
    add di, bp ; перевод строки
    mov al, 0bah
    stosw
    mov al, dl
    stosw
    mov al, 0b3h
    stosw
    scasw
    ; за newline всегда вызывается print
print:
    mov cl, bh
ploop:
    mov al, bl
    inc bx
    stosw
    scasw ; увеличить di на 2
    loop ploop
    mov al, 0bah ; это нужно после некоторых вызовов print
    ret

    special db 0c9h, 0cdh, 0d1h, 0cdh, 0bbh, 0c7h
            db 0c4h, 0c5h, 0c4h, 0b6h, 0c8h, 0cdh
            db 0cfh, 0cdh, 0bch

end start
