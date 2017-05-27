.model tiny

.code
    org 100h
program:
    jmp start

    t1 db 97 dup(3), 0, 12 dup(3), 1, 3, 3, 3, 3, 2, 140 dup(3)
    t2 db 1, 0, 0, 0, 1, 2, 0, 0, 3, 0, 0, 0, 1, 4, 0, 0, 5, 0, 0, 0, 1, 4, 6, 0
    ok db "kek$"
    fail db "no luck pal$"

start:
    mov cl, byte ptr ds:80h
    lea bx, t1
    mov bl, 0 ; позиция в строке
    mov dh, 0 ; текущее состояние
readargs:
    cmp bl, cl
    je notfound
    mov al, byte ptr ds:81h+bx
    mov ch, bl
    lea bx, t1
    xlat
    lea bx, t2
    add al, dh
    xlat
    cmp al, 06h
    je found
    mov ah, 4
    mul ah
    mov dh, al
    xor bx, bx
    mov bl, ch
    inc bl
    jmp readargs
notfound:
    lea dx, fail
    jmp result
found:
    lea dx, ok
result:
    mov ah, 09h
    int 21h
    ret
end program
