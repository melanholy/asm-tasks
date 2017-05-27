.model tiny
.code
org 100h
locals

int_num = 09h
int_off = 09h * 04h

main:
    mov al, 0b6h
    out 43h, al

    xor ax, ax
    mov es, ax
    cli
    mov bx, word ptr es:int_off+2
    mov next+2, bx
    mov bx, word ptr es:int_off
    mov next, bx
    mov word ptr es:int_off+2, ds
    mov word ptr es:int_off, offset handler
    mov ax, cs
    mov es, ax
    sti

ddd:
    hlt
    cmp shutdown, 01h
    jne ddd

    ret

m_push proc
    mov bx, cs:head
    mov [bx], ax
    add cs:head, 02h
    ret
m_push endp

m_pop proc
    mov cx, ax
    mov si, cs:head
    std
@@search:
    lodsw
    cmp ax, cx
    jne @@search
@@found:
    mov bx, si
    inc bx
    inc bx
    mov word ptr [bx], 00h
    mov cx, [bx-2]
shift:
    mov al, [bx+2]
    cmp al, 00h
    je @@bye
    mov cx, [bx+2]
    mov [bx], cx
    mov word ptr [bx+2], 00h
    inc bx
    inc bx
    jmp shift
@@bye:
    mov head, bx
    mov ax, cx
    cld
    cmp bx, offset m_stack
    je empty
    clc
    ret
empty:
    stc
    ret
m_pop endp

contains proc
    push ax
    lea si, m_stack
@@search:
    lodsw
    mov cx, head
    cmp si, cx
    jg @@nfound
    cmp ax, bx
    jne @@search
    pop ax
    clc
    ret
@@nfound:
    pop ax
    stc
    ret
contains endp

handler proc
    in al, 60h
    mov bl, al
    in al, 61h
    or al, 80h
    out 61h, al
    and al, 7fh
    out 61h, al
    mov al, 20h
    out 20h, al
    mov al, bl
    cmp al, 01h
    je exit

    mov cl, al
    lea si, tab
    mov ah, 00h
    mov bx, ax
    and bl, 7fh
@@search:
    lodsw
    cmp ax, 0ffffh
    je @@bye
    cmp ax, bx
    je @@found
    inc si
    inc si
    jmp @@search

@@found:
    lodsw
    test cl, 80h
    jnz up
    mov bx, ax
    call contains
    jnc @@bye
    call m_push
    jmp set_freq
up:
    call m_pop
    jc shutup
set_freq:
    out 42h, al
    mov al, ah
    out 42h, al
    in al, 61h
    or al, 03h
    out 61h, al
    iret
shutup:
    in al, 61h
    and al, 0fch
    out 61h, al
@@bye:
    iret
handler endp

exit proc
    xor ax, ax
    mov es, ax
    cli
    mov bx, next
    mov word ptr es:int_off, bx
    mov bx, next+2
    mov word ptr es:int_off+2, bx
    mov ax, cs
    mov es, ax
    sti

    mov shutdown, 01h
    iret
exit endp

tab:
    dw 02, 2415 ; B
    dw 03, 2280 ; C
    dw 04, 2152 ; C#
    dw 05, 2031 ; D
    dw 06, 1917 ; D#
    dw 07, 1809 ; E
    dw 08, 1715 ; F
    dw 09, 1612 ; F#
    dw 10, 1521 ; G
    dw 11, 1436 ; G#
    dw 12, 1355 ; A
    dw 0ffffh

    shutdown db 00h
    next dw ?, ?
    m_stack dw 24 dup(0)
    head dw m_stack
end main
