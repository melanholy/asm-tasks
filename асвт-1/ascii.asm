.model tiny
.code
org 100h

int_num = 09h
int_off = 09h * 04h

main:
    mov ax, 0600h
    mov bh, 07h
    xor cx, cx
    mov dx, 1950h
    int 10h

    xor ax, ax
    mov es, ax
    cli
    mov bx, word ptr es:int_off+2
    mov next+2, bx
    mov bx, word ptr es:int_off
    mov next, bx
    mov word ptr es:int_off+2, ds
    mov word ptr es:int_off, offset handler
    sti

lp:
    mov ah, 00h
    int 16h
    cmp al, 1bh
    je stop
    jmp lp

stop:
    cli
    mov bx, next
    mov word ptr es:int_off, bx
    mov bx, next+2
    mov word ptr es:int_off+2, bx
    sti

    mov ax, 0600h
    mov bh, 07h
    xor cx, cx
    mov dx, 1950h
    int 10h
    ret

print:
    push ax
    mov si, pos
    lodsw
    mov dx, si
    sub dx, offset shape
    cmp dx, shape_len
    jne ggg
    lea si, shape
ggg:
    mov pos, si
    mov dx, ax
    mov bh, 0
    mov ah, 02h
    int 10h

    mov al, bl
    shr al, 4
    cmp al, 10
    jl num1
    add al, 7h
num1:
    add al, 30h
    mov ah, 0ah
    mov cx, 1
    int 10h
    mov al, bl
    and al, 0fh
    cmp al, 10
    jl num2
    add al, 7h
num2:
    add al, 30h
    inc dl
    mov bh, 0
    mov ah, 02h
    int 10h
    mov ah, 0ah
    int 10h
    pop ax
    ret

handler:
    pushf
    push cs
    lea ax, callback
    push ax
    db 0eah
    next dw ?, ?
callback:
    in al, 60h
    mov ah, 00h
    lea di, pressed
    add di, ax
    test al, 80h
    jnz up
    scasb
    je noprint
    push ds
    xor cx, cx
    mov ds, cx
    mov bx, ds:41ch
    cmp bl, 1eh
    jne norm
    mov bl, 3eh
norm:
    add bx, 3feh
iii:
    mov bl, [bx]
    pop ds
    call print
noprint:
    dec di
    stosb
    jmp bye
up:
    sub di, 80h
    mov al, 00h
    stosb
bye:
    iret

    pos dw shape
    pressed db 127 dup(0)
    shape     dw 00413h,00415h,00417h,00419h,0041Bh,0041Dh,0041Fh,00421h,00423h,00425h,00427h,00429h
    dw 0042Bh,0042Dh,0042Fh,00431h,00433h,00512h,00535h,00611h,00636h,00711h,00727h,00729h
    dw 00736h,0073Ch,0073Eh,00811h,00825h,0082Bh,00836h,00838h,0083Ah,00840h,00911h,00925h
    dw 0092Dh,00936h,00938h,00940h,00A11h,00A25h,00A2Fh,00A31h,00A33h,00A35h,00A37h,00A40h
    dw 00B11h,00B25h,00B40h,00C11h,00C23h,00C42h,00D0Fh,00D11h,00D23h,00D42h,00E09h,00E0Bh
    dw 00E0Dh,00E0Fh,00E11h,00E23h,00E42h,00F05h,00F07h,00F11h,00F23h,00F42h,01005h,0100Dh
    dw 0100Fh,01011h,01023h,01042h,01107h,01109h,0110Bh,0110Dh,01111h,01125h,01140h,01211h
    dw 01213h,01227h,0123Eh,01311h,01315h,01317h,01319h,0131Bh,0131Dh,0131Fh,01321h,01323h
    dw 01325h,01327h,01329h,0132Bh,0132Dh,0132Fh,01331h,01333h,01335h,01337h,01339h,0133Bh
    dw 0133Dh,01411h,01417h,0141Bh,01421h,0142Ch,01432h,01436h,0143Ch,01511h,01513h,01515h
    dw 0151Dh,0151Fh,01521h,0152Eh,01530h,01532h,01538h,0153Ah,0153Ch
    shape_len = $ - shape
end main
