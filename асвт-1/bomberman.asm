.model tiny
.code
org 100h
locals

main:
    jmp begin

    int9off = 09h * 04h
    int1coff = 1ch * 04h
    int8off = 08h * 04h

    sprite_len = 20 * 18
    block_width = 20
    block_height = 18

    buflen = 64
    buffer db buflen dup(0)
    endbuf:
    head dw buffer
    tail dw buffer
    next9 dw ?, ?

    map db 160 dup(0)
    map_end:
    lvls db "################"
         db "#  *  m   *    #"
         db "# # # # #*#*# ##"
         db "#&         %  *#"
         db "#*# # # # # #*##"
         db "#  *       m   #"
         db "# # # #*#*# # ##"
         db "#&*        *   #"
         db "# # #*# # # # ##"
         db "################"
         db "################"
         db "#              #"
         db "# # # # # # # ##"
         db "#              #"
         db "# # # # # # # ##"
         db "#              #"
         db "# # # # # # # ##"
         db "#&             #"
         db "# # # # # # # ##"
         db "################"
    current_level db 1

    monster_move_speed = 2

    bomb_type = 2
    monster_type = 10

    hero_move_speed = 2
    hero_position dw block_width, block_height
    hero_dx db 0
    hero_dy db 0
    hero_moves db 0
    rays_len db 1
    base_rays_len db 1
    max_bombs db 1

    hero_state_sprite dw 0
    hero_animate dw 0

    goal_found db 0
    booster_found db 0
    victory db 0
    game_over db 0
    players_have_control db 0
    objects db 120 dup(0)
    objects_head dw objects

    lose_melody db 25, 25, 0, 0, 22, 22, 0, 0, 20, 20, 18, 18, 0, 0
                db 22, 22, 0, 0, 23, 23, 22, 22, 0, 0, 20, 20, 18, 18, 15, 15, 13, 13
    lose_melody_len = $ - lose_melody
    main_melody db 24, 0, 24, 0, 19, 23, 24, 0, 24, 0, 24, 23, 21, 0
                db 21, 0, 19, 0, 21, 0, 21, 0, 21, 19, 17, 0, 17, 0, 17, 21, 19, 0
                db 19, 0, 19, 23
    melody_len = $ - main_melody
    victory_melody db 19, 18, 16, 21, 20, 24, 24
    victory_melody_len = $ - victory_melody
    booster_melody db 19, 0, 21, 17, 0, 19, 19, 19, 0, 0
    booster_melody_len = $ - booster_melody
    bomb_sound db 50
    bomb_sound_len = $ - bomb_sound
    set_bomb_sound db 30
    set_bomb_sound_len = $ - set_bomb_sound
    melody_pos dw 0
    current_sound dw 0, 0
    cur_sound_pos dw 0
    ticks_wait dw 0
    ticks_in_sound = 1092/130/4
           ; C     C#    D     D#    E     F     F#    G     G#    A     A#    B
    notes dw 9121, 8609, 8126, 7670, 7239, 6833, 6449, 6087, 5746, 5423, 5119, 4831
          dw 4560, 4304, 4063, 3834, 3619, 3416, 3224, 3043, 2873, 2711, 2559, 2415
          dw 2280, 2152, 2031, 1917, 1809, 1715, 1612, 1521, 1436, 1355, 1292, 1207
          dw 1140, 1076, 1016, 959,  905,  854,  806,  760,  718,  678,  640,  604
          dw 18242, 17218, 16251, 15340, 14479, 13666, 12899, 12175, 11492, 10847, 10238, 9664

    timer_counter = 21846 ; 54.6 раз в секунду
    clock_ticks dw 0
    old_mode db 0

; выдает случайное число от 0 до ax в ax
randgen proc
    or ax, ax
    jz RND_end
    push bx
    push cx
    push dx

    push ax
    mov ax, RND_seed1
    mov bx, RND_seed2
    mov cx, ax
    mul RND_const
    shl cx, 1
    shl cx, 1
    shl cx, 1
    add ch, cl
    add dx, cx
    add dx, bx
    shl bx, 1
    shl bx, 1
    add dx, bx
    add dh, bl
    mov cl, 5
    shl bx, cl
    add ax, 1
    adc dx, 0
    mov RND_seed1, ax
    mov RND_seed2, dx
    pop bx
    xor ax, ax
    xchg ax, dx
    div bx
    xchg ax, dx

    pop dx
    pop cx
    pop bx
RND_end:
    ret

    RND_const dw  8405h
    RND_seed1 dw  ?
    RND_seed2 dw  ?
randgen endp

; в al входной код
write_buf proc
    mov bx, cs:head
    mov [bx], al
    mov ax, bx
    inc word ptr cs:head
    cmp word ptr cs:head, offset endbuf
    jne @@1
    mov cs:head, offset buffer
@@1:
    mov bx, cs:head
    cmp bx, cs:tail
    jnz @@2
    mov cs:head, ax
@@2:
    ret
write_buf endp

read_buf proc
    push bx
    mov bx, cs:tail
    cmp bx, cs:head
    jnz @@1
    pop bx
    stc ; буфер пуст
    ret
@@1:
    mov al, [bx]
    inc word ptr cs:tail
    cmp word ptr cs:tail, offset endbuf
    jnz @@2
    mov word ptr cs:tail, offset buffer
@@2:
    pop bx
    clc
    ret
read_buf endp

begin proc
    mov ah, 00h
    xor dh, dh
    int 1Ah
    mov RND_seed1, dx
    xor dh, dh
    int 1Ah
    mov RND_seed2, dx

    mov ah, 0fh
    int 10h
    mov old_mode, al

    mov ax, 13h
    int 10h
    mov al, 0b6h
    out 43h, al

    xor ax, ax
    mov es, ax
    cli
    mov al, 34h
    out 43h, al
    mov al, timer_counter - (timer_counter / 256) * 256
    out 40h, al
    mov al, timer_counter / 256
    out 40h, al
    mov bx, word ptr es:int9off+2
    mov next9+2, bx
    mov bx, word ptr es:int9off
    mov next9, bx
    mov word ptr es:int9off+2, ds
    mov word ptr es:int9off, offset int9
    mov bx, word ptr es:int1coff+2
    mov next1c+2, bx
    mov bx, word ptr es:int1coff
    mov next1c, bx
    mov word ptr es:int1coff+2, ds
    mov word ptr es:int1coff, offset int1c
    mov bx, word ptr es:int8off+2
    mov next8+2, bx
    mov bx, word ptr es:int8off
    mov next8, bx
    mov word ptr es:int8off+2, ds
    mov word ptr es:int8off, offset int8
    sti
    mov ax, cs
    mov es, ax

    call start_level

handler:
    call read_buf
    jc handler
    lea si, command_to_proc
    xor ah, ah
    mov bx, ax
@@search:
    lodsw
    cmp ax, 0ffffh
    je handler
    cmp ax, bx
    je @@found
    add si, 2
    jmp @@search
@@found:
    lodsw
    call ax
    jmp handler
    ret
begin endp

exit proc
    in al, 61h
    and al, 0fch
    out 61h, al
    xor ax, ax
    mov es, ax
    cli
    mov bx, next9
    mov word ptr es:int9off, bx
    mov bx, next9+2
    mov word ptr es:int9off+2, bx
    mov bx, next1c
    mov word ptr es:int1coff, bx
    mov bx, next1c+2
    mov word ptr es:int1coff+2, bx
    mov bx, next8
    mov word ptr es:int8off, bx
    mov bx, next8+2
    mov word ptr es:int8off+2, bx
    mov al, 34h
    out 43h, al
    mov al, 0
    out 40h, al
    mov al, 0
    out 40h, al
    sti

    mov al, old_mode
    mov ah, 00h
    int 10h

    int 20h
exit endp

draw_map proc
    mov cx, 160
    xor ax, ax
    xor bx, bx
read_map:
    call draw_map_cell
    add ax, block_width
    cmp ax, block_width * 16
    jne @@1
    xor ax, ax
    add bx, block_height
@@1:
    dec cx
    cmp cx, 0
    jg read_map
    ret
draw_map endp

; в ax адрес, в bx длина
add_sound proc
    cli
    mov current_sound, ax
    mov current_sound+2, bx
    mov cur_sound_pos, 00h
    sti
    ret
add_sound endp

sound proc
    push si
    in al, 61h
    or al, 03h
    out 61h, al
    mov bx, current_sound
    cmp bx, 00h
    je @@main_melody
    mov ax, cur_sound_pos
    mov cx, current_sound+2
    cmp ax, cx
    je @@3
    add bx, ax
    mov al, byte ptr ds:[bx]
    inc cur_sound_pos
    jmp @@2
@@3:
    mov current_sound, 00h
@@main_melody:
    mov al, game_over
    cmp al, 01h
    je @@shutup
    mov al, victory
    cmp al, 01h
    je @@shutup
    mov bx, melody_pos
    mov al, main_melody+bx
@@2:
    cmp al, 00h
    je @@shutup
    mov bl, 2
    mul bl
    lea si, notes
    add si, ax
    lodsw
    out 42h, al
    mov al, ah
    out 42h, al
    jmp @@bye
@@shutup:
    in al, 61h
    and al, 0fch
    out 61h, al
@@bye:
    mov ax, melody_pos
    inc ax
    cmp ax, melody_len
    jne @@1
    mov ax, 0
@@1:
    mov melody_pos, ax
@@4:
    pop si
    ret
sound endp

; в bx, cx позиция(x, y), в al тип, в ah данные
add_object proc
    mov di, objects_head
    stosb
    xchg ax, bx
    stosw
    mov ax, cx
    stosw
    mov al, bh
    stosb
    add objects_head, 6
    ret
add_object endp

; в si адрес
del_object proc
    push si
lp:
    mov ax, ds:[si+6]
    mov ds:[si], ax
    mov ax, ds:[si+8]
    mov ds:[si+2], ax
    mov ax, ds:[si+10]
    mov ds:[si+4], ax
    add si, 6
    mov ax, objects_head
    cmp si, ax
    jne lp
    sub objects_head, 6

    pop si
    ret
del_object endp

update proc
    lea si, objects
objects_loop:
    mov ax, objects_head
    cmp si, ax
    jge @@bye
    lodsb
    cmp al, -1
    jne @@1
    dec si
    call del_object
    jmp objects_loop
@@1:
    push si
    lea si, type_to_handler
    xor ah, ah
    mov bx, ax
@@search:
    lodsw
    cmp ax, bx
    je @@found
    add si, 2
    jmp @@search
@@found:
    lodsw
    pop si
    push si
    dec si
    call ax
    pop si
    push si
    dec si
    mov al, ds:[si]
    cmp al, monster_type
    jne @@not_monster
    mov ax, ds:[si+1]
    mov cx, hero_position
    cmp ax, cx
    jg @@3
    xchg ax, cx
@@3:
    sub ax, cx
    cmp ax, 14
    jg @@not_monster
    mov bx, ds:[si+3]
    mov dx, hero_position+2
    cmp bx, dx
    jg @@2
    xchg bx, dx
@@2:
    sub bx, dx
    cmp bx, 14
    jg @@not_monster
    pop si
    call lose
    ret
@@not_monster:
    pop si
    add si, 5
    jmp objects_loop
@@bye:
    ret
update endp

; в ax, bx позиция(x, y), в si адрес рисунка
draw_object proc
    push ax
    push bx
    push cx
    mov cx, sprite_len
    mov dx, block_width
    call draw_image
    pop cx
    pop bx
    pop ax
    ret
draw_object endp

; в ax, bx координаты, в cx длина массива байтов, в dx ширина рисунка, в si адрес
draw_image proc
    push dx
    mov di, ax
    mov ax, bx
    mov bx, 320
    mul bx
    add di, ax
    mov ax, 0a000h
    mov es, ax
    pop dx
    mov bx, dx
@@1:
    lodsb
    cmp al, 255
    je @@3
    stosb
    jmp @@4
@@3:
    inc di
@@4:
    dec bx
    jnz @@2
    mov bx, dx
    add di, 320
    sub di, dx
@@2:
    dec cx
    jnz @@1
    mov ax, cs
    mov es, ax
    ret
draw_image endp

hero_set_bomb proc
    mov al, players_have_control
    cmp al, 0
    je @@bye
    mov bl, 0
    lea si, objects
search_bombs:
    mov ax, objects_head
    cmp ax, si
    je @@2
    lodsb
    cmp al, bomb_type
    jne @@1
    inc bl
@@1:
    add si, 5
    jmp search_bombs
@@2:
    mov al, max_bombs
    cmp al, bl
    je @@bye
    mov ax, hero_position
    mov bx, hero_position+2
    mov cl, "B"
    call set_map_obj
    mov cx, bx
    mov bx, ax
    mov ah, 100
    mov al, 2
    call add_object

    lea ax, set_bomb_sound
    mov bx, set_bomb_sound_len
    call add_sound

    mov ax, hero_position
    mov bx, hero_position+2
    call draw_hero
@@bye:
    ret
hero_set_bomb endp

put_out_fire proc
    push ax
    push bx
    push dx
    push cx
    mov cl, rays_len
    mov @@count, cl
    pop cx
    push cx
@@1:
    push cx
    push dx
    add ax, cx
    add bx, dx
    call get_map_obj
    cmp cl, "@"
    jne @@3
    mov cl, " "
    call set_map_obj
    dec @@count
    mov cl, @@count
    cmp cl, 0
    pop dx
    pop cx
    jne @@1
    jmp @@bye
@@3:
    pop dx
    pop cx
@@bye:
    pop cx
    pop dx
    pop bx
    pop ax
    ret

    @@count db 0
put_out_fire endp

; в ax, bx начальная позиция, в cx, dx направления
spread_fire proc
    push ax
    push bx
    push dx
    push cx
    mov cl, rays_len
    mov @@count, cl
    pop cx
    push cx
@@1:
    push cx
    push dx
    add ax, cx
    add bx, dx
    call get_map_obj
    cmp cl, "#"
    je @@bye
    cmp cl, "B"
    je @@bye
    cmp cl, "&"
    je @@reveal_goal
    cmp cl, "%"
    jne @@4
    mov booster_found, 1
    call set_map_obj
    jmp @@bye
@@reveal_goal:
    mov goal_found, 1
    call set_map_obj
    jmp @@bye
@@4:
    mov ch, cl
    mov cl, "@"
    call set_map_obj
    cmp ch, "*"
    je @@bye
    dec @@count
    mov cl, @@count
    cmp cl, 0
    pop dx
    pop cx
    jne @@1
    jmp @@3
@@bye:
    pop dx
    pop cx
@@3:
    pop cx
    pop dx
    pop bx
    pop ax
    ret

    @@count db 0
spread_fire endp

; si - адрес данных
bomb_tick proc
    dec byte ptr ds:[si+5]
    mov cl, ds:[si+5]
    cmp cl, 20
    je explode
    cmp cl, 00h
    jne @@bye
    mov byte ptr ds:[si], -1
    mov ax, word ptr ds:[si+1]
    mov bx, word ptr ds:[si+3]
    mov cl, " "
    call set_map_obj
    mov dx, 0
    mov cx, block_width
    call put_out_fire
    mov cx, -block_width
    call put_out_fire
    mov dx, block_height
    mov cx, 0
    call put_out_fire
    mov dx, -block_height
    call put_out_fire
    ret
explode:
    lea ax, bomb_sound
    mov bx, bomb_sound_len
    call add_sound
    mov ax, word ptr ds:[si+1]
    mov bx, word ptr ds:[si+3]
    mov cl, "@"
    call set_map_obj
    mov cx, block_width
    mov dx, 0
    call spread_fire
    mov cx, -block_width
    call spread_fire
    mov cx, 0
    mov dx, block_height
    call spread_fire
    mov dx, -block_height
    call spread_fire
@@bye:
    ret
bomb_tick endp

start_level proc
    mov objects_head, offset objects
    mov hero_position, block_width
    mov hero_position+2, block_height
    mov hero_dx, 0
    mov hero_dy, 0
    mov hero_moves, 0
    mov goal_found, 0
    mov booster_found, 0
    mov victory, 0
    mov game_over, 0
    mov hero_state_sprite, offset bomber_idle
    mov players_have_control, 0
    mov current_sound, 0
    mov melody_pos, 0
    mov al, current_level
    dec al
    mov bl, 160
    mul bl
    xor bx, bx
    lea si, lvls
    add si, ax
@@1:
    lodsb
    mov ds:[map+bx], al
    inc bx
    cmp bl, 160
    jne @@1

    mov ax, 0a000h
    mov es, ax
    xor di, di
    mov cx, 320 * 200
    mov ax, 00h
    rep stosw
    mov ax, cs
    mov es, ax

    mov ah, 02h
    mov bh, 00h
    mov dx, 0b10h
    int 10h
    inc dl

    mov bx, 0007h
    mov cx, 01h
    lea si, string
@@2:
    lodsb
    mov ah, 09h
    push si
    int 10h
    mov ah, 02h
    int 10h
    inc dl
    pop si
    cmp si, offset string_end
    jne @@2

    mov ah, 09h
    mov al, current_level
    add al, 30h
    int 10h

    mov ax, 4003h
    call add_object
    ret

    string db "LEVEL "
    string_end:
start_level endp

next_level proc
    mov al, rays_len
    mov base_rays_len, al
    mov players_have_control, 0
    inc current_level
    mov objects_head, offset objects
    mov victory, 01h
    mov ax, 0a004h
    call add_object
    lea ax, victory_melody
    mov bx, victory_melody_len
    call add_sound
    ret
next_level endp

win_sound proc
    dec byte ptr ds:[si+5]
    mov al, ds:[si+5]
    cmp al, 00h
    jne @@bye
    call start_level
@@bye:
    ret
win_sound endp

restart proc
    mov al, game_over
    cmp al, 1
    jne @@bye
    call start_level
@@bye:
    ret
restart endp

; в si адрес данных монстра
monster_change_dir proc
    mov dl, byte ptr ds:[si+5]
    test dl, 6
    jnz @@8
    or dl, 2
    mov byte ptr ds:[si+5], dl
    jmp @@bye
@@8:
    mov cl, dl
    and cl, 6
    cmp cl, 6
    jne @@9
    and dl, 249
    mov byte ptr ds:[si+5], dl
    jmp @@bye
@@9:
    test dl, 4
    jz @@10
    or dl, 2
    mov byte ptr ds:[si+5], dl
    jmp @@bye
@@10:
    and dl, 249
    or dl, 4
    mov byte ptr ds:[si+5], dl
@@bye:
    ret
monster_change_dir endp

; si - адрес данных
monster_move proc
    mov al, players_have_control
    cmp al, 0
    je @@near_bye
    mov al, ds:[si+5]
    test al, 1
    jnz @@3
    or al, 1
    mov ds:[si+5], al
@@near_bye:
    ret
@@3:
    and al, 254
    mov ds:[si+5], al

    mov ax, ds:[si+1]
    mov bx, ds:[si+3]
    call get_map_obj
    cmp cl, "@"
    jne @@not_dead
    mov byte ptr ds:[si], -1
    ret
@@not_dead:
    mov ax, ds:[si+3]
    mov cl, block_height
    div cl
    cmp ah, 0
    je @@1
    jmp @@move
@@1:
    mov bl, al
    mov ax, ds:[si+1]
    mov cl, block_width
    div cl
    cmp ah, 0
    je @@2
    jmp @@move
@@2:
    push ax
    mov ax, 4
    call randgen
    cmp ax, 2
    jne @@no_change
    call monster_change_dir
@@no_change:
    pop ax
    mov dl, byte ptr ds:[si+5]
    test dl, 2
    jz @@horiz
    test dl, 4
    jnz @@up
    inc bl
    jmp @@7
@@up:
    dec bl
    jmp @@7
@@horiz:
    test dl, 4
    jnz @@left
    inc al
    jmp @@7
@@left:
    dec al
@@7:
    shl bl, 4
    or bl, al
    mov bh, 0
    mov al, map+bx
    cmp al, " "
    je @@move
    cmp al, "@"
    je @@move
    cmp al, "&"
    je @@6
    cmp al, "%"
    jne @@find_new_direction
    mov al, booster_found
    cmp al, 0
    je @@find_new_direction
    jmp @@move
@@6:
    mov al, goal_found
    cmp al, 0
    jne @@move
@@find_new_direction:  ; 0 -> 2, 6 -> 0, 4 -> 6, 2 -> 4
    call monster_change_dir
    jmp @@draw_monster
@@move:
    mov dl, byte ptr ds:[si+5]
    mov ax, word ptr ds:[si+1]
    mov bx, word ptr ds:[si+3]
    call draw_cells_near
    test dl, 2
    jnz @@move_y
    test dl, 4
    jz @@right
    sub word ptr ds:[si+1], monster_move_speed
    jmp @@draw_monster
@@right:
    add word ptr ds:[si+1], monster_move_speed
    jmp @@draw_monster
@@move_y:
    test dl, 4
    jz @@down
    sub word ptr ds:[si+3], monster_move_speed
    jmp @@draw_monster
@@down:
    add word ptr ds:[si+3], monster_move_speed
@@draw_monster:
    mov ax, word ptr ds:[si+1]
    mov bx, word ptr ds:[si+3]
    call draw_cells_near
    mov ax, word ptr ds:[si+1]
    mov bx, word ptr ds:[si+3]
    lea si, monster
    call draw_object
@@bye:
    ret
monster_move endp

lose proc
    mov objects_head, offset objects
    mov game_over, 1
    mov players_have_control, 0

    mov al, base_rays_len
    mov rays_len, al

    lea ax, lose_melody
    mov bx, lose_melody_len
    call add_sound

    lea si, go_image
    mov ax, 22
    mov bx, 60
    mov cx, go_len
    mov dx, go_image_width
    call draw_image
    ret
lose endp

; в si адрес данных
new_level_screen proc
    dec byte ptr ds:[si+5]
    mov al, ds:[si+5]
    cmp al, 0h
    jne @@bye

    mov objects_head, offset objects

    lea si, map
add_monsters:
    cmp si, offset map_end
    je @@3
    lodsb
    cmp al, "m"
    jne add_monsters
    push si
    mov byte ptr ds:[si-1], " "
    mov ax, si
    sub ax, (offset map)+1
    mov cl, 16
    div cl
    mov bl, ah
    mov ah, 0
    mov cl, block_height
    mul cl
    xchg ax, bx
    mov ah, 0
    mov cl, block_width
    mul cl
    mov cx, bx
    mov bx, ax
    mov al, monster_type
    mov ah, 6
    call add_object
    pop si
    jmp add_monsters

@@3:
    call draw_map
    call draw_hero

    mov players_have_control, 1

    mov bx, hero_position
    mov cx, hero_position
    mov al, 1
    call add_object
@@bye:
    ret
new_level_screen endp

; в ax, bx экранные координаты
get_map_obj proc
    push ax
    push bx
    push dx
    mov dl, block_width
    div dl
    mov cl, al
    mov ax, bx
    mov dl, block_height
    div dl
    shl al, 4
    mov bl, al
    or bl, cl
    mov bh, 0
    mov cl, map+bx

    pop dx
    pop bx
    pop ax
    ret
get_map_obj endp

; ax, bx экранные координаты, в cl символ
set_map_obj proc
    push dx
    push cx
    mov dl, block_width
    div dl
    mov ch, al
    mul dl
    push ax
    mov ax, bx
    mov dl, block_height
    div dl
    mov dh, al
    mul dl
    push ax
    shl dh, 4
    or ch, dh
    mov bh, 0
    mov bl, ch
    mov map+bx, cl
    pop bx
    pop ax
    call draw_map_cell
    pop cx
    pop dx
    ret
set_map_obj endp

; ax, bx экранные координаты
draw_map_cell proc
    push ax
    push bx
    push cx
    push si
    mov cl, block_width
    div cl
    mul cl
    xchg ax, bx
    mov cl, block_height
    div cl
    mul cl
    xchg ax, bx
    call get_map_obj
    cmp cl, " "
    je @@ground
    cmp cl, "B"
    je @@bomb
    cmp cl, "#"
    je @@gwall
    cmp cl, "@"
    je @@expcenter
    cmp cl, "&"
    je @@goal
    cmp cl, "%"
    je @@booster
    cmp cl, "m"
    je @@monster
    lea si, wall
    jmp @@next
@@monster:
    lea si, ground
    call draw_object
    lea si, monster
    jmp @@next
@@ground:
    lea si, ground
    jmp @@next
@@bomb:
    lea si, ground
    call draw_object
    lea si, bomb
    jmp @@next
@@goal:
    mov dl, goal_found
    cmp dl, 1
    jne @@1
    lea si, goal
    jmp @@next
@@1:
    lea si, wall
    jmp @@next
@@booster:
    mov dl, booster_found
    cmp dl, 1
    jne @@2
    lea si, ground
    call draw_object
    lea si, booster
    jmp @@next
@@2:
    lea si, wall
    jmp @@next
@@expcenter:
    lea si, expcenter
    jmp @@next
@@gwall:
    lea si, gwall
@@next:
    call draw_object

    pop si
    pop cx
    pop bx
    pop ax
    ret
draw_map_cell endp

draw_hero proc
    mov ax, hero_position
    mov bx, hero_position+2
    call draw_cells_near
    mov si, hero_state_sprite
    mov ax, hero_animate
    mov cx, sprite_len
    mul cx
    add si, ax
    mov ax, hero_position
    mov bx, hero_position+2
    call draw_object
    ret
draw_hero endp

; в dx сдвиг по x
hero_move_x proc
    mov ax, hero_position
    mov bx, hero_position+2
    call draw_cells_near
    cmp dl, 1
    je @@right
    sub hero_position, hero_move_speed
    jmp @@1
@@right:
    add hero_position, hero_move_speed
@@1:
    ret
hero_move_x endp

; ax, bx - координаты
draw_cells_near proc
    push dx
    call draw_map_cell
    add bx, block_height
    call draw_map_cell
    sub bx, block_height
    add ax, block_width
    call draw_map_cell
    pop dx
    ret
draw_cells_near endp

; в dx сдвиг по y
hero_move_y proc
    mov ax, hero_position
    mov bx, hero_position+2
    call draw_cells_near
    cmp dl, 1
    je @@down
    sub hero_position+2, hero_move_speed
    jmp @@1
@@down:
    add hero_position+2, hero_move_speed
@@1:
    ret
hero_move_y endp

hero_move proc
    mov al, should_move
    cmp al, 0
    jne @@3
    mov should_move, 1
    ret
@@3:
    mov should_move, 0
    mov ax, hero_position
    mov bx, hero_position+2
    call get_map_obj
    cmp cl, "@"
    jne not_dead
    call lose
    ret
not_dead:
    cmp cl, "&"
    je @@goal
    cmp cl, "%"
    jne not_goal
@@goal:
    mov ch, cl
    mov dx, ax
    mov cl, block_width
    div cl
    mul cl
    cmp ax, dx
    jne not_goal
    mov ax, bx
    mov cl, block_height
    div cl
    mul cl
    cmp bx, ax
    jne not_goal
    cmp ch, "&"
    jne @@get_booster
    call next_level
    ret
@@get_booster:
    mov cl, " "
    mov ax, hero_position
    mov bx, hero_position+2
    call set_map_obj
    inc rays_len
    lea ax, booster_melody
    mov bx, booster_melody_len
    call add_sound
not_goal:
    mov al, hero_moves
    cmp al, 00h
    je @@near_bye
    mov ax, hero_position+2
    mov cl, block_height
    div cl
    cmp ah, 0
    je @@1
    mov ah, hero_dx
    cmp ah, 0
    jne @@4
    jmp move
@@near_bye:
    ret
@@1:
    mov bl, al
    mov ax, hero_position
    mov cl, block_width
    div cl
    cmp ah, 0
    je @@2
    mov ah, hero_dy
    cmp ah, 0
    jne @@5
    jmp move
@@4:
    call adjust_y
    ret
@@5:
    call adjust_x
    ret
@@2:
    add al, hero_dx
    add bl, hero_dy
    shl bl, 4
    or bl, al
    mov bh, 0
    mov al, map+bx
    cmp al, " "
    je move
    cmp al, "@"
    je move
    cmp al, "&"
    je @@6
    cmp al, "%"
    jne @@draw_hero
    mov al, booster_found
    cmp al, 0
    je @@draw_hero
    jmp move
@@6:
    mov al, goal_found
    cmp al, 0
    je @@draw_hero
move:
    mov dl, hero_dx
    cmp dl, 00h
    je move_y
    call hero_move_x
    jmp @@draw_hero
move_y:
    mov dl, hero_dy
    call hero_move_y
@@draw_hero:
    call draw_hero
    inc @@count
    mov al, @@count
    cmp al, 5
    jne @@bye
    mov @@count, 0
    mov ax, @@animation_dir
    add hero_animate, ax
    mov ax, hero_animate
    cmp ax, 3
    je @@change_dir_neg
    cmp ax, -1
    jne @@bye
    mov hero_animate, 1
    mov @@animation_dir, 1
    jmp @@bye
@@change_dir_neg:
    mov hero_animate, 1
    mov @@animation_dir, -1
@@bye:
    ret

    @@animation_dir dw 1
    @@count db 0
    should_move db 0
hero_move endp

adjust_y proc
    mov ax, hero_position
    mov bx, hero_position+2
    mov cl, hero_dx
    cmp cl, 01h
    je @@7
    sub ax, block_width
    jmp @@8
@@7:
    add ax, block_width
@@8:
    call get_map_obj
    cmp cl, " "
    jne @@6
    mov ax, hero_position+2
    mov bl, block_height
    div bl
    mul bl
    mov bx, hero_position+2
    sub bx, ax
    cmp bx, 4
    jg @@bye
    mov hero_dy, -1
    jmp @@9
@@6:
    add bx, block_height
    call get_map_obj
    cmp cl, " "
    jne @@bye
    mov ax, hero_position+2
    mov bl, block_height
    div bl
    mul bl
    mov bx, hero_position+2
    sub bx, ax
    cmp bx, block_height - 4
    jl @@bye
    mov hero_dy, 1
@@9:
    mov al, hero_dx
    push ax
    mov hero_dx, 0
    mov should_move, 1
    call hero_move
    pop ax
    mov hero_dy, 0
    mov hero_dx, al
@@bye:
    ret
adjust_y endp

adjust_x proc
    mov ax, hero_position
    mov bx, hero_position+2
    mov cl, hero_dy
    cmp cl, 01h
    je @@7
    sub bx, block_height
    jmp @@8
@@7:
    add bx, block_height
@@8:
    call get_map_obj
    cmp cl, " "
    jne @@6
    mov ax, hero_position
    mov bl, block_width
    div bl
    mul bl
    mov bx, hero_position
    sub bx, ax
    cmp bx, 6
    jg @@bye
    mov hero_dx, -1
    jmp @@9
@@6:
    add ax, block_height
    call get_map_obj
    cmp cl, " "
    jne @@bye
    mov ax, hero_position
    mov bl, block_width
    div bl
    mul bl
    mov bx, hero_position
    sub bx, ax
    cmp bx, block_width - 6
    jl @@bye
    mov hero_dx, 1
@@9:
    mov al, hero_dy
    push ax
    mov hero_dy, 0
    mov should_move, 1
    call hero_move
    pop ax
    mov hero_dy, al
    mov hero_dx, 0
@@bye:
    ret
adjust_x endp

hero_up proc
    mov al, players_have_control
    cmp al, 0
    je @@bye
    mov al, hero_moves
    cmp al, 1
    je @@bye
    mov hero_state_sprite, offset bomber_up
    mov hero_moves, 1
    mov hero_dy, -1
@@bye:
    ret
hero_up endp

hero_left proc
    mov al, players_have_control
    cmp al, 0
    je @@bye
    mov al, hero_moves
    cmp al, 1
    je @@bye
    mov hero_state_sprite, offset bomber_left
    mov hero_moves, 1
    mov hero_dx, -1
@@bye:
    ret
hero_left endp

hero_right proc
    mov al, players_have_control
    cmp al, 0
    je @@bye
    mov al, hero_moves
    cmp al, 1
    je @@bye
    mov hero_state_sprite, offset bomber_right
    mov hero_moves, 1
    mov hero_dx, 1
@@bye:
    ret
hero_right endp

hero_down proc
    mov al, players_have_control
    cmp al, 0
    je @@bye
    mov al, hero_moves
    cmp al, 1
    je @@bye
    mov hero_state_sprite, offset bomber_down
    mov hero_moves, 1
    mov hero_dy, 1
@@bye:
    ret
hero_down endp

hero_stop_up proc
    mov al, hero_moves
    cmp al, 1
    jne @@bye
    mov al, hero_dy
    cmp al, -1
    jne @@bye
    mov al, players_have_control
    cmp al, 0
    je @@bye
    mov hero_animate, 0
    mov hero_state_sprite, offset bomber_idle
    call draw_hero
    mov hero_moves, 0
    mov hero_dy, 0
@@bye:
    ret
hero_stop_up endp

hero_stop_down proc
    mov al, hero_moves
    cmp al, 1
    jne @@bye
    mov al, hero_dy
    cmp al, 1
    jne @@bye
    mov al, players_have_control
    cmp al, 0
    je @@bye
    mov hero_animate, 0
    mov hero_state_sprite, offset bomber_idle
    call draw_hero
    mov hero_moves, 0
    mov hero_dy, 0
@@bye:
    ret
hero_stop_down endp

hero_stop_left proc
    mov al, hero_moves
    cmp al, 1
    jne @@bye
    mov al, hero_dx
    cmp al, -1
    jne @@bye
    mov al, players_have_control
    cmp al, 0
    je @@bye
    mov hero_animate, 0
    mov hero_state_sprite, offset bomber_idle
    call draw_hero
    mov hero_moves, 0
    mov hero_dx, 0
@@bye:
    ret
hero_stop_left endp

hero_stop_right proc
    mov al, hero_moves
    cmp al, 1
    jne @@bye
    mov al, hero_dx
    cmp al, 1
    jne @@bye
    mov al, players_have_control
    cmp al, 0
    je @@bye
    mov hero_animate, 0
    mov hero_state_sprite, offset bomber_idle
    call draw_hero
    mov hero_moves, 0
    mov hero_dx, 0
@@bye:
    ret
hero_stop_right endp

int1c proc
    push ax
    push bx
    push cx
@@1:
    mov ax, ticks_wait
    cmp ax, 00h
    jne @@next
    mov ticks_wait, ticks_in_sound+1
    call sound
@@next:
    dec ticks_wait
    pop cx
    pop bx
    pop ax
    db 0eah
    next1c dw ?, ?
int1c endp

int8 proc
    cli
    push ax
    push bx
    mov al, 6
    call write_buf
    inc clock_ticks
    mov ax, clock_ticks
    cmp ax, 03h
    jne @@1
    sub ax, 03h
    mov clock_ticks, ax
    pop bx
    pop ax
    sti
    db 0eah
    next8 dw ?, ?
@@1:
    mov al, 20h
    out 20h, al
    pop bx
    pop ax
    sti
    iret
int8 endp

int9 proc
    cli
    push ax
    push si
    push bx
    in al, 60h
    mov ah, al
    in al, 61h
    or al, 80h
    out 61h, al
    and al, 7fh
    out 61h, al

    lea si, scan_to_command
@@search:
    lodsb
    cmp al, 0ffh
    je @@bye
    cmp ah, al
    je @@found
    inc si
    jmp @@search
@@found:
    lodsb
    call write_buf
@@bye:
    mov al, 20h
    out 20h, al
    pop bx
    pop si
    pop ax
    sti
    iret
int9 endp

scan_to_command:
    db 1, 1
    db 11h, 2
    db 91h, 7
    db 1fh, 3
    db 9fh, 8
    db 1eh, 4
    db 9eh, 9
    db 20h, 5
    db 0a0h, 10
    db 39h, 11
    db 1ch, 13
    dw 0ffffh

command_to_proc:
    dw 1, exit
    dw 2, hero_up
    dw 3, hero_down
    dw 4, hero_left
    dw 5, hero_right
    dw 6, update
    dw 7, hero_stop_up
    dw 8, hero_stop_down
    dw 9, hero_stop_left
    dw 10, hero_stop_right
    dw 11, hero_set_bomb
    dw 12, start_level
    dw 13, restart
    dw 14, sound
    dw 0ffffh

type_to_handler:
    dw 1, hero_move
    dw bomb_type, bomb_tick
    dw 3, new_level_screen
    dw 4, win_sound
    dw monster_type, monster_move
    dw 0ffffh

ground db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
    db 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2

booster db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,27,54,54,54,54,54,54,54,54,54,54,54,54,54,27,0,255,255
    db 255,255,54,27,0,0,0,0,0,0,0,0,0,0,0,0,54,0,255,255
    db 255,255,54,0,27,27,27,27,27,27,27,27,27,54,54,0,54,0,255,255
    db 255,255,54,0,27,27,27,27,27,27,27,54,54,54,0,0,54,0,255,255
    db 255,255,54,0,27,27,27,27,54,54,54,54,54,0,0,54,54,0,255,255
    db 255,255,54,0,27,27,27,54,54,54,54,0,0,0,54,54,54,0,255,255
    db 255,255,54,0,27,27,54,54,54,54,54,54,54,54,54,0,54,0,255,255
    db 255,255,54,0,27,54,54,0,54,0,54,54,54,54,0,0,54,0,255,255
    db 255,255,54,0,27,54,54,0,54,0,54,54,54,0,0,27,54,0,255,255
    db 255,255,54,0,27,54,54,54,54,54,54,0,54,54,54,54,54,0,255,255
    db 255,255,54,0,27,54,54,0,0,0,0,54,54,54,0,0,54,0,255,255
    db 255,255,54,0,27,0,54,54,54,54,54,54,54,0,0,27,54,0,255,255
    db 255,255,54,0,27,27,0,54,54,54,54,54,0,0,27,27,54,0,255,255
    db 255,255,54,0,27,27,27,0,0,0,0,0,0,27,27,27,54,0,255,255
    db 255,255,27,54,54,54,54,54,54,54,54,54,54,54,54,54,27,0,255,255
    db 255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255

wall db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,0
    db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0
    db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0
    db 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 15,15,15,15,15,0,0,15,15,15,15,15,15,15,15,15,15,15,15,15
    db 7,7,7,7,7,0,15,7,7,7,7,7,7,7,7,7,7,7,7,7
    db 7,7,7,7,7,0,15,7,7,7,7,7,7,7,7,7,7,7,7,7
    db 7,7,7,7,7,0,15,7,7,7,7,7,7,7,7,7,7,7,7,7
    db 7,7,7,7,7,0,15,7,7,7,7,7,7,7,7,7,7,7,7,7
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 15,15,15,15,15,15,15,15,15,15,15,15,0,0,15,15,15,15,15,15
    db 7,7,7,7,7,7,7,7,7,7,7,7,0,15,7,7,7,7,7,7
    db 7,7,7,7,7,7,7,7,7,7,7,7,0,15,7,7,7,7,7,7
    db 7,7,7,7,7,7,7,7,7,7,7,7,0,15,7,7,7,7,7,7
    db 7,7,7,7,7,7,7,7,7,7,7,7,0,15,7,7,7,7,7,7
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

gwall db 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,7
    db 15,15,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,7,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 15,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,28,0
    db 7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,28,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

monster db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,0,0,0,0,0,0,255,255,255,255,255,255,255
    db 255,255,255,255,255,0,0,5,5,5,5,5,5,0,0,255,255,255,255,255
    db 255,255,255,255,0,5,5,5,5,5,5,5,5,5,5,0,255,255,255,255
    db 255,255,255,255,0,5,5,5,5,5,5,5,5,5,5,0,255,255,255,255
    db 255,255,255,0,5,5,5,5,5,5,5,5,5,5,5,5,0,255,255,255
    db 255,255,255,0,5,5,5,15,15,5,5,15,15,5,5,5,0,255,255,255
    db 255,255,255,0,5,5,5,15,0,5,5,15,0,5,5,5,0,255,255,255
    db 255,255,255,0,5,5,5,15,0,5,5,15,0,5,5,5,0,255,255,255
    db 255,255,255,0,5,5,5,5,5,5,5,5,5,5,5,5,0,255,255,255
    db 255,255,255,255,0,5,5,5,5,5,5,5,5,5,5,0,255,255,255,255
    db 255,255,255,255,0,5,5,5,5,0,0,5,5,5,5,0,255,255,255,255
    db 255,255,255,255,255,0,5,5,5,5,5,5,5,5,0,255,255,255,255,255
    db 255,255,255,255,255,255,0,5,5,5,5,5,5,0,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,0,0,5,5,0,0,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,0,15,15,0,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,0,0,0,0,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255

bomber_idle db 255,255,0,0,255,255,255,255,0,0,0,0,0,255,255,255,255,255,255,255
    db 255,0,3,3,0,255,0,0,15,15,15,15,15,0,0,255,255,255,255,255
    db 255,0,3,3,0,0,15,15,15,15,15,15,15,15,15,0,255,255,255,255
    db 255,255,0,0,0,15,15,15,15,12,12,12,12,12,12,12,0,255,255,255
    db 255,255,255,255,0,15,15,15,12,12,0,12,12,12,0,12,0,255,255,255
    db 255,255,255,255,0,15,15,15,12,12,0,12,12,12,0,12,0,255,255,255
    db 255,255,255,255,0,15,15,15,12,12,0,12,12,12,0,12,0,255,255,255
    db 255,255,255,255,0,15,15,15,15,12,12,12,12,12,12,12,0,255,255,255
    db 255,255,255,255,0,0,15,15,15,15,15,15,15,15,15,0,0,255,255,255
    db 255,255,255,0,15,15,0,0,0,0,0,0,0,0,0,15,15,0,255,255
    db 255,255,0,15,15,15,15,0,3,3,3,3,3,3,0,15,15,15,0,255
    db 255,0,0,15,15,15,0,3,3,3,3,3,3,3,3,0,15,0,3,0
    db 255,0,3,0,15,0,0,0,0,0,15,15,15,0,0,0,0,3,3,0
    db 255,0,3,3,0,255,0,3,3,3,3,3,3,3,3,0,0,0,0,255
    db 255,255,0,0,255,255,0,0,0,3,3,3,3,0,0,0,255,255,255,255
    db 255,255,255,255,255,0,15,15,15,0,0,0,0,15,15,15,0,255,255,255
    db 255,255,255,255,255,0,0,0,0,0,255,255,0,0,0,0,0,255,255,255
    db 255,255,255,255,0,3,3,3,3,0,255,255,0,3,3,3,3,0,255,255

bomber_down db 255,255,255,255,0,3,3,0,0,15,15,15,15,15,0,0,255,255,255,255
    db 255,255,255,255,0,3,0,15,15,15,15,15,15,15,15,15,0,255,255,255
    db 255,255,255,255,255,0,15,15,15,12,12,12,12,12,12,12,15,0,255,255
    db 255,255,255,255,255,0,15,15,12,12,0,12,12,12,0,12,12,0,255,255
    db 255,255,255,255,255,0,15,15,12,12,0,12,12,12,0,12,12,0,255,255
    db 255,255,255,255,255,0,15,15,12,12,0,12,12,12,0,12,12,0,255,255
    db 255,255,255,255,255,0,15,15,15,12,12,12,12,12,12,12,15,0,255,255
    db 255,255,255,255,0,0,0,15,15,15,15,15,15,15,0,0,0,255,255,255
    db 255,255,255,0,15,15,15,0,0,0,0,0,0,0,3,3,0,0,255,255
    db 255,255,0,3,0,15,0,3,3,3,3,3,3,0,3,0,15,15,0,255
    db 255,255,0,3,3,0,3,3,3,3,3,3,3,3,0,15,15,15,0,255
    db 255,255,255,0,0,0,0,0,0,0,15,15,15,0,0,0,0,0,255,255
    db 255,255,255,255,255,255,0,3,3,3,3,3,3,3,3,3,0,255,255,255
    db 255,255,255,255,255,255,0,15,15,3,3,3,3,3,15,15,0,255,255,255
    db 255,255,255,255,255,255,0,15,15,15,0,0,15,15,15,0,255,255,255,255
    db 255,255,255,255,255,255,0,15,15,15,0,255,0,0,0,255,255,255,255,255
    db 255,255,255,255,255,255,0,0,0,0,0,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,0,3,3,3,0,255,255,255,255,255,255,255,255,255

    db 255,255,255,255,255,255,255,0,0,0,0,0,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,0,0,15,15,15,15,15,0,0,255,255,255,255,255,255
    db 255,255,255,255,0,15,15,15,15,15,15,15,15,15,0,255,255,255,255,255
    db 255,255,255,0,15,15,12,12,12,12,12,12,12,15,15,0,255,255,255,255
    db 255,255,255,0,15,12,12,0,12,12,12,0,12,12,15,0,255,255,255,255
    db 255,255,255,0,15,12,12,0,12,12,12,0,12,12,15,0,255,255,255,255
    db 255,255,255,0,15,12,12,0,12,12,12,0,12,12,15,0,255,255,255,255
    db 255,255,255,0,15,15,12,12,12,12,12,12,12,15,15,0,255,255,255,255
    db 255,255,255,255,0,15,15,15,15,15,15,15,15,15,0,255,255,255,255,255
    db 255,255,255,0,15,0,0,0,0,0,0,0,0,0,15,0,255,255,255,255
    db 255,255,0,15,15,0,3,3,3,3,3,3,3,0,15,15,0,255,255,255
    db 255,0,3,0,0,3,3,3,3,3,3,3,3,3,0,0,3,0,255,255
    db 255,0,3,3,0,0,0,0,15,15,15,0,0,0,0,3,3,0,255,255
    db 255,255,0,0,0,3,3,3,3,3,3,3,3,3,0,0,0,255,255,255
    db 255,255,255,255,0,15,3,3,3,3,3,3,3,15,0,255,255,255,255,255
    db 255,255,255,255,0,15,15,15,0,0,0,15,15,15,0,255,255,255,255,255
    db 255,255,255,255,0,0,0,0,0,255,0,0,0,0,0,255,255,255,255,255
    db 255,255,255,255,0,3,3,3,0,255,0,3,3,3,0,255,255,255,255,255

    db 255,255,255,255,0,0,15,15,15,15,15,0,0,3,3,0,255,255,255,255
    db 255,255,255,0,15,15,15,15,15,15,15,15,15,0,3,0,255,255,255,255
    db 255,255,0,15,12,12,12,12,12,12,12,15,15,15,0,255,255,255,255,255
    db 255,255,0,12,12,0,12,12,12,0,12,12,15,15,0,255,255,255,255,255
    db 255,255,0,12,12,0,12,12,12,0,12,12,15,15,0,255,255,255,255,255
    db 255,255,0,12,12,0,12,12,12,0,12,12,15,15,0,255,255,255,255,255
    db 255,255,0,15,12,12,12,12,12,12,12,15,15,15,0,255,255,255,255,255
    db 255,255,255,0,0,0,15,15,15,15,15,15,15,0,0,0,255,255,255,255
    db 255,255,0,0,3,3,0,0,0,0,0,0,0,15,15,15,0,255,255,255
    db 255,0,15,15,0,3,0,3,3,3,3,3,3,0,15,0,3,0,255,255
    db 255,0,15,15,15,0,3,3,3,3,3,3,3,3,0,3,3,0,255,255
    db 255,255,0,0,0,0,0,15,15,15,0,0,0,0,0,0,0,255,255,255
    db 255,255,255,0,3,3,3,3,3,3,3,3,3,0,255,255,255,255,255,255
    db 255,255,255,0,15,15,3,3,3,3,3,15,15,0,255,255,255,255,255,255
    db 255,255,255,255,0,15,15,15,0,0,15,15,15,0,255,255,255,255,255,255
    db 255,255,255,255,255,0,0,0,255,0,15,15,15,0,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,0,0,0,0,0,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,0,3,3,3,0,255,255,255,255,255,255

bomber_up db 255,255,255,255,0,0,15,15,15,15,0,3,3,0,255,255,255,255,255,255
    db 255,255,255,0,15,15,15,15,15,15,0,3,3,0,255,255,255,255,255,255
    db 255,255,0,15,15,15,15,15,15,15,15,0,0,15,0,255,255,255,255,255
    db 255,255,0,15,15,15,15,15,15,15,15,15,15,15,0,255,255,255,255,255
    db 255,255,0,15,15,15,15,15,15,15,15,15,15,15,0,255,255,255,255,255
    db 255,255,0,15,15,15,15,15,15,15,15,15,15,15,0,255,255,255,255,255
    db 255,255,0,15,15,15,15,15,15,15,15,15,15,0,0,255,255,255,255,255
    db 255,255,255,0,15,15,15,15,15,15,15,15,0,15,15,0,255,255,255,255
    db 255,255,0,15,0,0,0,0,0,0,0,0,0,15,15,15,0,255,255,255
    db 255,255,0,15,0,3,3,3,3,3,3,3,0,0,15,15,0,255,255,255
    db 255,0,15,0,3,3,3,3,3,3,3,3,3,0,15,0,3,0,255,255
    db 255,0,3,0,0,0,0,0,0,0,0,0,0,0,0,3,3,0,255,255
    db 255,0,0,0,3,3,3,3,3,3,3,3,3,0,255,0,0,255,255,255
    db 255,255,0,0,15,15,3,3,3,3,3,3,15,0,255,255,255,255,255,255
    db 255,255,255,0,15,15,15,0,0,15,15,15,0,255,255,255,255,255,255,255
    db 255,255,255,0,15,15,15,0,255,0,0,0,255,255,255,255,255,255,255,255
    db 255,255,255,0,0,0,0,0,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,3,3,3,3,3,255,255,255,255,255,255,255,255,255,255,255,255

    db 255,255,255,255,255,255,255,0,0,0,0,0,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,0,0,15,0,3,0,15,0,0,255,255,255,255,255,255
    db 255,255,255,255,0,15,15,15,0,3,0,15,15,15,0,255,255,255,255,255
    db 255,255,255,0,15,15,15,15,15,0,15,15,15,15,15,0,255,255,255,255
    db 255,255,255,0,15,15,15,15,15,15,15,15,15,15,15,0,255,255,255,255
    db 255,255,255,0,15,15,15,15,15,15,15,15,15,15,15,0,255,255,255,255
    db 255,255,255,0,15,15,15,15,15,15,15,15,15,15,15,0,255,255,255,255
    db 255,255,255,0,15,15,15,15,15,15,15,15,15,15,15,0,255,255,255,255
    db 255,255,255,255,0,15,15,15,15,15,15,15,15,15,0,255,255,255,255,255
    db 255,255,255,0,15,0,0,0,0,0,0,0,0,0,15,0,255,255,255,255
    db 255,255,0,15,15,0,3,3,3,3,3,3,3,0,15,15,0,255,255,255
    db 255,255,0,15,0,3,3,3,3,3,3,3,3,3,0,15,0,255,255,255
    db 255,0,3,0,0,0,0,0,0,0,0,0,0,0,0,0,3,0,255,255
    db 255,0,3,3,0,3,3,3,3,3,3,3,3,3,0,3,3,0,255,255
    db 255,255,0,0,0,15,15,3,3,3,3,3,15,15,0,0,0,255,255,255
    db 255,255,255,255,0,15,15,15,0,0,0,15,15,15,0,255,255,255,255,255
    db 255,255,255,255,0,0,0,0,0,255,0,0,0,0,0,255,255,255,255,255
    db 255,255,255,255,0,3,3,3,0,255,0,3,3,3,0,255,255,255,255,255

    db 255,255,255,255,255,255,0,3,3,0,15,15,15,15,0,0,255,255,255,255
    db 255,255,255,255,255,255,0,3,3,0,15,15,15,15,15,15,0,255,255,255
    db 255,255,255,255,255,0,15,0,0,15,15,15,15,15,15,15,15,0,255,255
    db 255,255,255,255,255,0,15,15,15,15,15,15,15,15,15,15,15,0,255,255
    db 255,255,255,255,255,0,15,15,15,15,15,15,15,15,15,15,15,0,255,255
    db 255,255,255,255,255,0,15,15,15,15,15,15,15,15,15,15,15,0,255,255
    db 255,255,255,255,255,0,0,15,15,15,15,15,15,15,15,15,15,0,255,255
    db 255,255,255,255,0,15,15,0,15,15,15,15,15,15,15,15,0,255,255,255
    db 255,255,255,0,15,15,15,0,0,0,0,0,0,0,0,0,15,0,255,255
    db 255,255,255,0,15,15,0,0,3,3,3,3,3,3,3,0,15,0,255,255
    db 255,255,0,3,0,15,0,3,3,3,3,3,3,3,3,3,0,15,0,255
    db 255,255,0,3,3,0,0,0,0,0,0,0,0,0,0,0,0,3,0,255
    db 255,255,255,0,0,255,0,3,3,3,3,3,3,3,3,3,0,0,0,255
    db 255,255,255,255,255,255,0,15,3,3,3,3,3,3,15,15,0,0,255,255
    db 255,255,255,255,255,255,255,0,15,15,15,0,0,15,15,15,0,255,255,255
    db 255,255,255,255,255,255,255,255,0,0,0,255,0,15,15,15,0,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,0,0,0,0,0,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,3,3,3,3,3,255,255,255

bomber_left db 255,255,255,255,255,0,0,15,15,15,15,15,0,0,0,3,3,0,255,255
    db 255,255,255,255,0,15,15,15,15,15,15,15,15,15,0,3,3,0,255,255
    db 255,255,255,0,12,12,12,12,12,12,12,15,15,15,15,0,0,255,255,255
    db 255,255,255,0,0,12,12,0,12,12,12,12,15,15,15,0,255,255,255,255
    db 255,255,255,0,0,12,12,0,12,12,12,12,15,15,15,0,255,255,255,255
    db 255,255,255,0,0,12,12,0,12,12,12,12,15,15,15,0,255,255,255,255
    db 255,255,255,0,12,12,12,12,12,12,12,15,15,15,15,0,255,255,255,255
    db 255,255,255,255,0,0,15,15,0,0,15,15,15,15,0,255,255,255,255,255
    db 255,255,255,0,3,3,0,0,15,15,0,0,0,0,0,255,255,255,255,255
    db 255,255,255,0,3,0,15,15,15,15,0,3,3,0,15,0,255,255,255,255
    db 255,255,255,0,0,15,15,15,15,15,0,3,3,0,15,15,0,255,255,255
    db 255,255,255,255,0,0,15,15,15,0,0,0,0,0,0,0,0,255,255,255
    db 255,255,255,255,0,3,0,0,0,3,3,3,3,0,0,3,0,255,255,255
    db 255,255,0,0,15,15,3,3,3,3,3,15,15,0,0,0,255,255,255,255
    db 255,0,3,3,0,15,15,15,0,0,15,15,15,15,0,255,255,255,255,255
    db 255,255,0,3,3,0,0,0,255,255,0,15,15,0,3,0,255,255,255,255
    db 255,255,255,0,0,255,255,255,255,255,255,0,0,3,3,0,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,0,3,3,0,255,255,255,255,255

    db 255,255,255,255,255,0,0,0,0,0,255,255,255,255,255,0,0,255,255,255
    db 255,255,255,0,0,15,15,15,15,15,0,0,255,255,0,3,3,0,255,255
    db 255,255,0,15,15,15,15,15,15,15,15,15,0,0,0,3,3,0,255,255
    db 255,0,12,12,12,12,12,15,15,15,15,15,15,0,255,0,0,255,255,255
    db 255,0,12,12,0,12,12,12,15,15,15,15,15,0,255,255,255,255,255,255
    db 255,0,12,12,0,12,12,12,15,15,15,15,15,0,255,255,255,255,255,255
    db 255,0,12,12,0,12,12,12,15,15,15,15,15,0,255,255,255,255,255,255
    db 255,0,12,12,12,12,12,15,15,15,15,15,15,0,255,255,255,255,255,255
    db 255,255,0,0,15,15,15,0,15,15,15,15,0,255,255,255,255,255,255,255
    db 255,255,255,0,0,0,0,15,0,0,0,0,255,255,255,255,255,255,255,255
    db 255,255,0,3,3,0,15,15,15,0,3,0,255,255,255,255,255,255,255,255
    db 255,255,0,3,3,0,15,15,15,0,3,0,255,255,255,255,255,255,255,255
    db 255,255,0,15,15,0,3,3,3,0,0,0,255,255,255,255,255,255,255,255
    db 255,255,0,3,3,0,3,3,3,0,3,0,255,255,255,255,255,255,255,255
    db 255,255,255,0,0,0,0,0,0,0,0,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,0,15,15,15,15,15,0,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,0,0,0,0,0,0,0,255,255,255,255,255,255,255,255,255
    db 255,255,255,0,3,3,3,3,3,3,0,255,255,255,255,255,255,255,255,255

    db 255,255,255,255,255,0,0,15,15,15,15,15,0,0,255,0,3,3,0,255
    db 255,255,255,255,0,15,15,15,15,15,15,15,15,15,0,0,3,3,0,255
    db 255,255,255,0,12,12,12,15,15,15,15,15,15,0,0,0,0,0,255,255
    db 255,255,255,0,12,0,12,12,15,15,15,15,15,15,15,0,255,255,255,255
    db 255,255,255,0,12,0,12,12,15,15,15,15,15,15,15,0,255,255,255,255
    db 255,255,255,0,12,0,12,12,15,15,15,15,15,15,15,0,255,255,255,255
    db 255,255,255,0,12,12,12,15,15,15,15,15,15,15,15,0,255,255,255,255
    db 255,255,0,0,0,0,15,15,15,0,0,0,15,15,0,255,255,255,255,255
    db 255,0,3,3,0,0,0,0,0,15,15,15,0,0,255,255,255,255,255,255
    db 255,0,3,0,0,3,3,3,0,15,15,15,15,0,255,255,255,255,255,255
    db 255,255,0,15,0,3,3,3,3,0,15,15,15,0,0,255,255,255,255,255
    db 255,255,0,15,0,15,15,0,0,0,0,15,0,3,0,255,255,255,255,255
    db 255,255,255,0,0,3,3,3,3,3,3,0,3,3,0,255,255,255,255,255
    db 255,255,255,255,0,0,15,15,15,3,3,3,0,0,255,255,255,255,255,255
    db 255,255,0,0,0,15,15,15,15,0,0,0,15,0,0,255,255,255,255,255
    db 255,0,3,3,0,15,0,255,255,255,0,15,15,0,3,0,255,255,255,255
    db 255,255,0,3,3,0,255,255,255,255,255,0,0,3,3,0,255,255,255,255
    db 255,255,255,0,0,255,255,255,255,255,255,0,3,3,0,255,255,255,255,255

bomber_right db 255,255,0,3,3,0,0,0,15,15,15,15,15,0,0,255,255,255,255,255
    db 255,255,0,3,3,0,15,15,15,15,15,15,15,15,15,0,255,255,255,255
    db 255,255,255,0,0,15,15,15,15,12,12,12,12,12,12,12,0,255,255,255
    db 255,255,255,255,0,15,15,15,12,12,12,12,0,12,12,0,0,255,255,255
    db 255,255,255,255,0,15,15,15,12,12,12,12,0,12,12,0,0,255,255,255
    db 255,255,255,255,0,15,15,15,12,12,12,12,0,12,12,0,0,255,255,255
    db 255,255,255,255,0,15,15,15,15,12,12,12,12,12,12,12,0,255,255,255
    db 255,255,255,255,255,0,15,15,15,15,0,0,15,15,0,0,255,255,255,255
    db 255,255,255,255,255,0,0,0,0,0,15,15,0,0,3,3,0,255,255,255
    db 255,255,255,255,0,15,0,3,3,0,15,15,15,15,0,3,0,255,255,255
    db 255,255,255,0,15,15,0,3,3,0,15,15,15,15,15,0,0,255,255,255
    db 255,255,255,0,0,0,0,0,0,0,0,15,15,15,0,0,255,255,255,255
    db 255,255,255,0,3,0,0,3,3,3,3,0,0,0,3,0,255,255,255,255
    db 255,255,255,255,0,0,0,15,15,3,3,3,3,3,15,15,0,0,255,255
    db 255,255,255,255,255,0,15,15,15,15,0,0,15,15,15,0,3,3,0,255
    db 255,255,255,255,0,3,0,15,15,0,255,255,0,0,0,3,3,0,255,255
    db 255,255,255,255,0,3,3,0,0,255,255,255,255,255,255,0,0,255,255,255
    db 255,255,255,255,255,0,3,3,0,255,255,255,255,255,255,255,255,255,255,255

    db 255,255,255,0,0,255,255,255,255,255,0,0,0,0,0,255,255,255,255,255
    db 255,255,0,3,3,0,255,255,0,0,15,15,15,15,15,0,0,255,255,255
    db 255,255,0,3,3,0,0,0,15,15,15,15,15,15,15,15,15,0,255,255
    db 255,255,255,0,0,255,0,15,15,15,15,15,15,12,12,12,12,12,0,255
    db 255,255,255,255,255,255,0,15,15,15,15,15,12,12,12,0,12,12,0,255
    db 255,255,255,255,255,255,0,15,15,15,15,15,12,12,12,0,12,12,0,255
    db 255,255,255,255,255,255,0,15,15,15,15,15,12,12,12,0,12,12,0,255
    db 255,255,255,255,255,255,0,15,15,15,15,15,15,12,12,12,12,12,0,255
    db 255,255,255,255,255,255,255,0,15,15,15,15,0,15,15,15,0,0,255,255
    db 255,255,255,255,255,255,255,255,0,0,0,0,15,0,0,0,0,255,255,255
    db 255,255,255,255,255,255,255,255,0,3,0,15,15,15,0,3,3,0,255,255
    db 255,255,255,255,255,255,255,255,0,3,0,15,15,15,0,3,3,0,255,255
    db 255,255,255,255,255,255,255,255,0,0,0,3,3,3,0,15,15,0,255,255
    db 255,255,255,255,255,255,255,255,0,3,0,3,3,3,0,3,3,0,255,255
    db 255,255,255,255,255,255,255,255,255,0,0,0,0,0,0,0,0,255,255,255
    db 255,255,255,255,255,255,255,255,255,0,15,15,15,15,15,0,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,0,0,0,0,0,0,0,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,0,3,3,3,3,3,3,0,255,255,255

    db 255,0,3,3,0,255,0,0,15,15,15,15,15,0,0,255,255,255,255,255
    db 255,0,3,3,0,0,15,15,15,15,15,15,15,15,15,0,255,255,255,255
    db 255,255,0,0,0,0,0,15,15,15,15,15,15,12,12,12,0,255,255,255
    db 255,255,255,255,0,15,15,15,15,15,15,15,12,12,0,12,0,255,255,255
    db 255,255,255,255,0,15,15,15,15,15,15,15,12,12,0,12,0,255,255,255
    db 255,255,255,255,0,15,15,15,15,15,15,15,12,12,0,12,0,255,255,255
    db 255,255,255,255,0,15,15,15,15,15,15,15,15,12,12,12,0,255,255,255
    db 255,255,255,255,255,0,15,15,0,0,0,15,15,15,0,0,0,0,255,255
    db 255,255,255,255,255,255,0,0,15,15,15,0,0,0,0,0,3,3,0,255
    db 255,255,255,255,255,255,0,15,15,15,15,0,3,3,3,0,0,3,0,255
    db 255,255,255,255,255,0,0,15,15,15,0,3,3,3,3,0,15,0,255,255
    db 255,255,255,255,255,0,3,0,15,0,0,0,0,15,15,0,15,0,255,255
    db 255,255,255,255,255,0,3,3,0,3,3,3,3,3,3,0,0,255,255,255
    db 255,255,255,255,255,255,0,0,3,3,3,15,15,15,0,0,255,255,255,255
    db 255,255,255,255,255,0,0,15,0,0,0,15,15,15,15,0,0,0,255,255
    db 255,255,255,255,0,3,0,15,15,0,255,255,255,0,15,0,3,3,0,255
    db 255,255,255,255,0,3,3,0,0,255,255,255,255,255,0,3,3,0,255,255
    db 255,255,255,255,255,0,3,3,0,255,255,255,255,255,255,0,0,255,255,255

bomb db 255,255,255,255,255,255,255,255,255,255,255,0,15,0,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,0,0,0,0,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,0,15,0,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,0,0,0,0,0,0,255,255,255,255,255,255,255
    db 255,255,255,255,255,0,0,0,0,0,0,0,0,0,255,255,255,255,255,255
    db 255,255,255,255,0,0,15,15,0,0,0,0,0,0,0,255,255,255,255,255
    db 255,255,255,0,0,15,15,0,0,0,0,0,0,0,0,0,255,255,255,255
    db 255,255,255,0,0,15,0,0,0,0,0,0,0,0,0,0,255,255,255,255
    db 255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255,255
    db 255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255,255
    db 255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255,255
    db 255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255,255
    db 255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255,255
    db 255,255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255,255,255
    db 255,255,255,0,0,0,0,0,0,0,0,0,0,0,0,0,255,255,255,255
    db 255,255,255,255,0,0,0,0,0,0,0,0,0,0,0,255,255,255,255,255
    db 255,255,255,255,255,0,0,0,0,0,0,0,0,0,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,0,0,0,0,0,255,255,255,255,255,255,255,255

expcenter db 255,255,255,255,255,112,112,42,43,43,43,43,42,112,112,255,255,255,255,255
    db 255,255,255,112,112,40,42,42,43,43,43,43,43,40,40,112,112,255,255,255
    db 255,255,112,112,40,42,42,43,43,43,43,43,43,42,39,40,112,112,255,255
    db 255,112,112,40,42,43,43,43,43,43,43,43,43,43,42,39,40,112,112,255
    db 255,112,40,42,43,43,43,43,43,43,43,43,43,43,43,42,40,112,112,255
    db 112,112,40,42,43,43,43,43,43,44,44,44,43,43,43,43,40,40,112,112
    db 40,40,42,43,43,43,43,43,44,44,44,44,44,43,43,43,42,39,39,40
    db 42,42,43,43,43,43,43,43,44,44,44,44,44,44,43,43,43,42,42,42
    db 43,43,43,43,43,43,43,44,44,44,44,44,44,44,43,43,43,43,43,43
    db 43,43,43,43,43,43,44,44,44,44,44,44,44,44,43,43,43,43,43,43
    db 43,43,43,43,43,44,44,44,44,44,44,44,44,44,44,43,43,43,43,43
    db 43,43,43,43,43,44,44,44,44,44,44,44,44,44,44,43,43,43,43,43
    db 42,42,43,43,43,43,44,44,44,44,44,44,44,44,43,43,43,42,42,42
    db 40,40,42,43,43,43,43,44,44,44,44,44,44,43,43,43,42,39,39,40
    db 112,112,40,42,43,43,43,43,43,44,44,44,43,43,43,43,40,40,112,112
    db 255,112,40,42,43,43,43,43,43,43,43,43,43,43,43,42,40,112,112,255
    db 255,112,112,40,42,43,43,43,43,43,43,43,43,43,42,39,40,112,112,255
    db 255,255,112,112,40,42,42,43,43,43,43,43,43,42,39,40,112,112,255,255

goal db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,164,164,164,164,164,164
    db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,164,7,7,7,7,164
    db 0,0,0,0,0,0,0,0,0,164,164,164,164,164,164,7,7,7,7,164
    db 0,0,0,0,0,0,0,0,0,164,7,7,7,7,164,7,7,7,7,164
    db 0,0,0,0,0,0,0,0,0,164,7,7,7,7,164,7,7,7,7,164
    db 0,0,0,0,0,164,164,164,164,164,7,7,7,7,164,7,7,7,7,164
    db 0,0,0,0,0,164,7,7,7,164,7,7,7,7,164,7,7,7,7,164
    db 164,164,164,164,164,164,7,7,7,164,7,7,7,7,164,7,7,7,7,164
    db 164,7,7,7,7,164,7,7,7,164,7,7,7,7,164,7,7,7,7,164
    db 164,7,7,7,7,164,7,7,7,164,7,7,7,7,164,7,7,7,7,164
    db 164,7,7,7,7,164,7,7,7,164,7,7,7,7,164,7,7,7,7,164
    db 164,7,7,7,7,164,7,7,7,164,7,7,7,7,164,7,7,7,7,164
    db 164,7,7,7,7,164,7,7,7,164,7,7,7,7,164,7,7,7,7,164
    db 164,7,7,7,7,164,7,7,7,164,7,7,7,7,164,7,7,7,7,164
    db 164,7,7,7,7,164,7,7,7,164,7,7,7,7,164,7,7,7,7,164
    db 164,7,7,7,7,164,7,7,7,164,7,7,7,7,164,7,7,7,7,164

    go_image_width = 276
go_image db 255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,4,4,4,4,4
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,4,4,4,4
    db 4,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,4,4,4
    db 4,4,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,4,4
    db 4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,4
    db 4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255
    db 4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255
    db 255,4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255
    db 255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4
    db 4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4
    db 4,4,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255
    db 255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,4,4,255,255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4
    db 4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4
    db 4,4,4,255,255,255,255,255,255,255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,4,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4
    db 4,255,255,255,4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,255,255,255,4,4
    db 4,4,4,255,255,255,255,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,4,255,255,4,4,4,255,255,4,4,4,255,4,4,4,4,4,4,4,255
    db 255,4,4,4,4,4,4,4,255,255,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,4,255,255,255,4,4,4,4,4,255,255,255,255,255,255,255
    db 255,255,255,255,255,4,4,4,4,4,4,4,255,255,4,4,4,4,4,4,255,255,255,4,4
    db 4,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255
    db 255,4,4,4,4,4,255,255,255,255,255,4,4,4,255,255,255,255,255,4,4,4,4,4,255
    db 255,255,4,4,4,255,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,255
    db 4,4,4,255,255,4,4,4,255,4,4,4,255,255,4,4,4,255,255,255,255,255,255,4,4
    db 4,255,4,4,4,255,255,4,4,4,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255
    db 4,4,4,255,255,255,255,255,255,4,4,4,255,255,4,4,4,255,255,255,4,4,4,255,255
    db 255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,4,4,4,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,255,4,4,4,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,255,4,4,4,255,255,4
    db 4,4,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4,4,255,255
    db 255,4,4,4,255,4,4,4,255,255,255,4,4,4,4,4,255,255,255,255,255,4,4,4,255
    db 255,255,255,4,4,4,255,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4
    db 255,4,4,4,255,255,4,4,4,255,4,4,4,255,255,4,4,4,255,255,255,255,255,255,4
    db 4,4,255,255,255,255,255,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,4,4,4,255,255,255,255,255,255,4,4,4,4,255,4,4,4,255,255,255,4,4,4,255
    db 255,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,4,4,4,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,255,4,4,4,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,255,4,4,4,255,255
    db 4,4,4,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,255,4,4,4
    db 255,255,4,4,4,255,4,4,4,255,255,4,4,4,255,4,4,4,255,255,255,255,4,4,4
    db 255,255,255,255,4,4,4,4,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4
    db 4,255,4,4,4,255,255,4,4,4,255,4,4,4,255,255,4,4,4,255,255,255,255,255,255
    db 255,4,4,4,255,255,255,255,255,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,4,4,4,255,255,255,255,255,255,4,4,4,4,4,4,4,4,255,255,255,4,4,4
    db 255,255,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,4,4,4,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,255,4,4,4,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,255,4,4,4,255
    db 255,4,4,4,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,4,4,4,255,4,4
    db 4,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,4,4,4,255,255,255,255,4,4
    db 4,255,255,255,255,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4
    db 4,4,4,4,4,255,255,255,4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,255,255
    db 255,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,4,4,255,255,255,4,4
    db 4,255,255,255,255,4,4,4,4,4,4,255,255,255,4,4,4,4,4,4,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,255,4,4,4,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,4,4,4,255
    db 255,255,255,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,255,4
    db 4,4,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,4,4,4,255,255,255,255,4
    db 4,4,255,255,255,255,4,4,4,4,4,4,4,4,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 4,4,4,255,255,255,255,255,255,4,4,4,4,4,4,255,255,255,4,4,4,255,255,255,255
    db 255,255,255,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,255,255,255,255,255,255,255
    db 255,255,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,4,4,4,4,255,255,255,4
    db 4,4,255,255,255,255,4,4,4,255,255,255,255,255,255,4,4,4,4,4,4,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,255,4,4,4,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,4,4,4
    db 255,255,255,255,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,4
    db 4,4,4,255,255,4,4,4,4,4,4,4,255,255,4,4,4,4,4,4,4,255,255,255,255
    db 4,4,4,255,255,255,255,4,4,4,255,4,4,4,4,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,4,4,4,255,255,255,255,255,255,4,4,4,255,4,4,4,255,255,4,4,4,255,255,255
    db 255,255,255,255,255,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,255,255,255,255,255
    db 255,255,255,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,255,4,4,4,255,255,255
    db 4,4,4,255,255,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,4,4,4,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,255,4,4,4
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,255,4
    db 4,4,255,255,255,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4
    db 255,4,4,4,255,255,4,4,4,255,4,4,4,255,255,4,4,4,255,4,4,4,255,255,255
    db 255,4,4,4,255,255,255,255,4,4,4,255,255,4,4,4,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,4,4,4,255,255,4,4,4,255,255
    db 255,255,255,255,4,4,4,255,4,4,4,255,255,4,4,4,255,4,4,4,255,255,255,255,255
    db 255,255,255,255,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,255,4,4,4,255,255
    db 255,4,4,4,255,255,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,4,4,4,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,255,4,4
    db 4,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4,255
    db 4,4,4,255,255,255,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4
    db 4,255,4,4,4,255,255,4,4,4,255,4,4,4,255,255,4,4,4,255,4,4,4,255,255
    db 255,255,4,4,4,255,255,255,255,4,4,4,255,255,4,4,4,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255,255,255,4,4,4,255,255,255,255,255,255,4,4,4,255,4,4,4,255,255,4,4,4,4
    db 4,4,4,255,255,255,4,4,4,4,4,255,255,255,255,4,4,4,4,4,255,255,255,255,255
    db 255,255,255,255,255,255,255,4,4,4,4,4,4,4,255,255,4,4,4,255,255,4,4,4,255
    db 255,255,4,4,4,255,255,255,255,4,4,4,4,4,4,4,255,255,4,4,4,255,4,4,4
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,255,4,4,4,4
    db 4,255,255,255,255,255,255,255,255,255,255,255,255,255,255,4,4,4,255,255,255,255,4,4,4
    db 255,4,4,4,255,255,255,255,4,4,4,255,255,255,255,255,255,255,255,255,255,255,255,255,4
    db 4,4,255,4,4,4,255,255,255,4,4,4,4,4,4,255,255,4,4,4,255,4,4,4,255
    db 255,255,4,4,4,4,4,255,255,255,4,4,4,255,255,4,4,4,255,255,255,255,255,255,255
    db 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
    db 255
    go_len = $ - go_image

end main
