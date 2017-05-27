.model tiny
.code
org 100h
locals

main:
    jmp begin

    int_num = 09h
    int_off = int_num * 04h
    buflen = 2
    buffer db buflen dup(0)
    endbuf:
    head dw buffer
    tail dw buffer
    pressed db 127 dup(0)
    place dw 127 dup(0)
    was_prefix db 0
    next dw ?, ?

; в al входной код
write_buf proc
    push bx
    mov bx, cs:head
    mov cs:[bx], al
    mov ax, bx
    inc word ptr cs:head
    cmp word ptr cs:head, offset endbuf
    jne @@no_overflow
    mov cs:head, offset buffer
@@no_overflow:
    mov bx, cs:head
    cmp bx, cs:tail
    jne @@bye
    mov cs:head, ax
@@bye:
    pop bx
    ret
write_buf endp

; в al считанное значение
read_buf proc
    mov bx, cs:tail
    cmp bx, cs:head
    jne read
    stc ; буфер пуст
    ret
read:
    mov al, cs:[bx]
    inc word ptr cs:tail
    cmp word ptr cs:tail, offset endbuf
    jne @@no_overflow
    mov word ptr cs:tail, offset buffer
@@no_overflow:
    clc
    ret
read_buf endp

begin proc
    xor ax, ax
    mov es, ax
    cli
    mov bx, word ptr es:int_off
    mov next, bx
    mov bx, word ptr es:int_off+2
    mov next+2, bx
    mov word ptr es:int_off, offset int9
    mov word ptr es:int_off+2, ds
    sti
    mov ax, cs
    mov es, ax

handler:
    hlt
    call read_buf
    jc handler

    cmp al, 01h
    je exit

    mov ah, 00h
    lea di, pressed
    add di, ax
    test al, 80h
    jnz up
    scasb
    je handler
    dec di
    stosb
    jmp output
up:
    cmp al, 0e0h
    je prefix
    cmp al, 0e1h
    je prefix
    sub di, 80h
    mov byte ptr es:[di], 00h
    jmp output
prefix:
    lea di, was_prefix
    stosb
    jmp handler
output:
    mov bl, was_prefix
    cmp bl, 00h
    je scan
    mov cl, al
    mov al, bl
    call print
    mov al, cl
    mov was_prefix, 00h
scan:
    test al, 80h
    jz @@2
    call print_same_line
    mov cl, al
    jmp check_space
@@2:
    call store_place
    mov cl, al
    call print
check_space:
    cmp cl, 0b9h
    jne handler
    call line
    jmp handler

exit:
    xor ax, ax
    mov es, ax
    mov di, int_off
    lea si, next
    cli
    movsw
    movsw
    sti
    ret
begin endp

store_place proc
    push ax
    mov ah, 03h
    mov bh, 00h
    int 10h
    pop ax
    push ax
    mov bl, 02h
    mul bl
    mov bx, ax
    add dl, 03h
    mov place+bx, dx
    cmp dh, 18h
    jne @@bye
    mov bx, 1
@@lp:
    add bx, 2
    cmp bx, 251
    je @@bye
    mov al, byte ptr place+bx
    cmp al, 00h
    je @@lp
    dec byte ptr place+bx
    jmp @@lp

@@bye:
    pop ax
    ret
store_place endp

print_same_line proc
    push ax
    mov ah, 03h
    mov bh, 00h
    int 10h
    pop ax
    push dx
    push ax
    sub al, 80h
    mov bl, 02h
    mul bl
    mov bx, ax
    mov dx, place+bx
    cmp dx, 00h
    je @@1
    mov ah, 02h
    mov bh, 00h
    int 10h
@@1:
    pop ax
    mov cl, al
    call print
    mov ah, 02h
    mov bh, 00h
    pop dx
    push cx
    int 10h
    pop ax
    ret
print_same_line endp

line proc
    mov cx, 20
@@1:
    mov dl, 3dh
    mov ah, 02h
    int 21h
    loop @@1
    mov dl, 0dh
    int 21h
    mov dl, 0ah
    int 21h
    mov bx, 1
@@lp:
    add bx, 2
    cmp bx, 251
    je @@bye
    mov al, byte ptr place+bx
    cmp al, 00h
    je @@lp
    dec byte ptr place+bx
    jmp @@lp

@@bye:
    ret
line endp

print proc
    mov bl, al
    mov ah, 02h
    mov dl, bl
    shr dl, 4
    cmp dl, 10
    jl num1
    add dl, 7h
num1:
    add dl, 30h
    int 21h
    mov dl, bl
    and dl, 0fh
    cmp dl, 10
    jl num2
    add dl, 7h
num2:
    add dl, 30h
    int 21h
    mov dl, 0dh
    int 21h
    mov dl, 0ah
    int 21h
    ret
print endp

int9 proc
    cli
    push ax
    in al, 60h
    call write_buf
    in al, 61h
    or al, 80h
    out 61h, al
    and al, 7fh
    out 61h, al
    mov al, 20h
    out 20h, al
    pop ax
    sti
    iret
int9 endp

end main
