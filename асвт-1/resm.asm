.model tiny

.code
    org 100h
program:
    call read_args
    sub al, 09h
    mov bl, 02h
    mul bl
    mov bx, ax
    mov bx, t3+bx
    jmp bx

    int_num = 10h
    int_offset = int_num * 04h
    res_len = handler_end - handler
    sign_req = "PK"
    sign_ans = "KP"

;-----------Читаем аргументы. Результирующее состояние в al------------;

read_args proc
    mov si, 81h ; позиция в строке
    xor dx, dx  ; текущее состояние
    xor cx, cx ; количество корректных аргументов
read_args_loop:
    lodsb
    lea bx, t1
    xlat
    lea bx, t2
    add al, dh
    xlat
    cmp al, 09h
    jl not_term
    cmp cl, 00h
    jne too_many
    cmp al, 14
    jl not_end
    sub al, 05h
    push ax
    jmp end_of_args
not_end:
    inc cx
    push ax
    xor dx, dx
    mov al, 01h
not_term:
    mov ah, 09h
    mul ah
    mov dh, al
    jmp read_args_loop
too_many:
    cmp al, 20
    je end_of_args
    pop ax
    mov ax, 14
    push ax
end_of_args:
    pop ax
    ret
read_args endp

;----------------------------------------------------------------------;

;----------------------------Код резидента-----------------------------;

handler:
    cmp ax, sign_req
    jne jmp_next
    mov ax, sign_ans
    mov bx, cs
jmp_next:
    db 0eah
    next dw ?, ?
handler_end:

;----------------------------------------------------------------------;

;----------------Вызывает прерывание с нужным запросом-----------------;

check_res proc
    mov ax, sign_req
    int int_num
    ret
check_res endp

;----------------------------------------------------------------------;

;-------------Записать значение bx в указанное в dx место--------------;

write_addr proc
    mov ax, ds
    mov es, ax
    mov di, dx
    mov cl, 12
mov_loop:
    mov ax, bx
    shr ax, cl
    and al, 0fh
    cmp al, 0ah
    jl digit
    add al, 07h
digit:
    add al, 30h
    stosb

    sub cl, 04h
    jns mov_loop

    ret
write_addr endp

;----------------------------------------------------------------------;

;-------Установить резидента. Адрес сегмента с резидентом в bx---------;

install proc
    mov ax, 4800h
    mov bx, res_len
    shr bx, 04h
    inc bx
    clc
    int 21h

    cli ; будет неприятно получить вызов обработчика, которого еще нет

    xor bx, bx
    mov ds, bx
    mov si, int_offset
    lea di, next
    movsw
    movsw
    mov bx, cs
    mov ds, bx

    mov cx, res_len
    mov es, ax
    xor di, di
    lea si, handler
    rep movsb

    dec ax
    mov es, ax
    inc ax
    mov word ptr es:01h, ax ; подменяем адрес PSP в MCB на сегмент с обработчиком

    mov es, cx ; в cx гарантированно ноль
    mov word ptr es:int_offset+2, ax
    mov word ptr es:int_offset, cx

    sti

    mov bx, ax
    ret
install endp

;----------------------------------------------------------------------;

;-----------------Убить резидента, в bx его адрес----------------------;

uninstall proc
    xor cx, cx
    mov es, cx
    mov di, int_offset
    mov ds, bx
    mov si, next - handler
    movsw
    movsw
    mov cx, cs
    mov ds, cx

    dec bx
    mov es, bx
    mov di, 01h
    xor ax, ax
    stosw       ; делаем MCB свободным

    inc bx
    ret
uninstall endp

;----------------------------------------------------------------------;

usage:
    lea dx, usage_msg
    jmp output

help:
    lea dx, help_msg
    jmp output

kill:
    call check_res
    cmp ax, sign_ans
    je kill_good
    lea dx, not_inst_msg
    jmp output
kill_good:
    call uninstall
    lea dx, kill_addr
    call write_addr
    lea dx, kill_msg
    jmp output

state:
    call check_res
    cmp ax, sign_ans
    je state_good
    lea dx, not_inst_msg
    jmp output
state_good:
    lea dx, state_handler_addr
    call write_addr
    lea dx, state_msg
    jmp output

inst:
    call check_res
    cmp ax, sign_ans
    jne inst_good
    lea dx, inst_bad_handler_addr
    call write_addr
    lea dx, inst_bad_msg
    jmp output
inst_good:
    call install
    lea dx, inst_succ_handler_addr
    call write_addr
    lea dx, inst_succ_msg
    jmp output

args_too_many:
    lea dx, args_too_many_msg
    jmp output

uninst:
    call check_res
    cmp ax, sign_ans
    je uninst_semi
    lea dx, not_inst_msg
    jmp output
uninst_semi:
    xor ax, ax
    mov es, ax
    mov cx, word ptr es:int_offset
    mov dx, word ptr es:int_offset+2
    cmp cx, 00h
    jne uninst_bad
    cmp dx, bx
    je uninst_good
uninst_bad:
    push cx
    push dx
    lea dx, uninst_handler_addr
    call write_addr
    pop bx
    lea dx, uninst_cur_top_seg
    call write_addr
    pop bx
    lea dx, uninst_cur_top_off
    call write_addr
    lea dx, uninst_not_top_msg
    jmp output
uninst_good:
    call uninstall
    lea dx, uninst_succ_addr
    call write_addr
    lea dx, uninst_succ_msg

output:
    mov ah, 09h
    int 21h
    ret

    help_msg db "Данная программа позволяет получить в рабство обработчик исключения 2F.", 0dh, 0ah
             db "Доступные опции:", 0dh, 0ah
             db "    -h вывести это сообщение", 0dh, 0ah
             db "    -i поместить в память обработчик", 0dh, 0ah
             db "    -u принять тридцатую поправку;", 0dh, 0ah
             db "       невозможно если обработчик не последний в цепочке", 0dh, 0ah
             db "    -s вывести местоположение обработчика в памяти", 0dh, 0ah
             db "    -k отправить обработчик к праотцам", "$"

    usage_msg db "Юзаге: resm.com [-h] [-i] [-s] [-k]", 0dh, 0ah
              db "Еще больше шуток и каламбурчиков: resm.com -h", "$"

    inst_succ_msg          db "Обработчик успешно установлен по адресу "
    inst_succ_handler_addr dd ?
                           db ":0000", "$"

    inst_bad_msg          db "Обработчик уже был установлен по адресу "
    inst_bad_handler_addr dd ?
                          db ":0000", "$"

    state_msg          db "Обработчик установлен по адресу "
    state_handler_addr dd ?
                       db ":0000", "$"

    not_inst_msg db "Обработчик не установлен", "$"

    uninst_not_top_msg  db "Адрес верхнего обработчика в цепочке "
    uninst_cur_top_seg  dd ?
                        db ":"
    uninst_cur_top_off  dd ?
                        db " не совпадает с адресом обработчика "
    uninst_handler_addr dd ?
                        db ":0000, снятие невозможно", "$"

    uninst_succ_msg  db "Обработчик был успешно снят c адреса "
    uninst_succ_addr dd ?
                     db ":0000", "$"

    kill_msg  db "Обработчик был успешно снят c адреса "
    kill_addr dd ?
              db ":0000", 0dh, 0ah
              db "Как ты жесток, дорогой...", "$"

    args_too_many_msg db "Слишком много аргументов", "$"

    t1 db 13 dup(8), 7, 18 dup(8), 6, 12 dup(8), 0, 58 dup(8)
       db 1, 4, 8, 2, 7 dup(8), 3, 8, 5, 10 dup(8)

    t2 db 0, 0, 0, 0, 0, 0, 1,  20, 0
       db 2, 0, 0, 0, 0, 0, 1,  20, 0
       db 0, 3, 4, 5, 6, 7, 1,  20, 0
       db 0, 0, 0, 0, 0, 0, 9,  14, 0
       db 0, 0, 0, 0, 0, 0, 10, 15, 0
       db 0, 0, 0, 0, 0, 0, 11, 16, 0
       db 0, 0, 0, 0, 0, 0, 12, 17, 0
       db 0, 0, 0, 0, 0, 0, 13, 18, 0

    t3 dw help, kill, state, inst
       dw uninst, args_too_many, usage

dno:
end program
