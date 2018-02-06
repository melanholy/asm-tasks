.globl main
.text

#ifndef UART
    #error Specify UART number.
#endif

#define uart_offset     (0x400 * UART)
#define uart_bit        (16 + UART)
#define ccu_base_addr   0x1c20000
#define uart_base_addr  0x1c28000
#define RTC             0x1f00000

#define O_DSYNC         10000
#define O_RDWR          2
#define STDIN           0
#define FIONREAD        21531
#define ICANON          2
#define ECHO            8
#define TCSANOW         0
#define F_GETFL         3
#define F_SETFL         4
#define O_NONBLOCK      2048

main:
    push {lr}

    ldr r0, =devmem
    ldr r1, =O_RDWR | O_DSYNC
    bl open

    cmp r0, #0
    blt err

    mov r4, r0
    bl set_noncanon
    mov r0, r4

    push {r0} @ mem
    ldr r1, =RTC
    bl do_mmap
    ldr r1, =rtc_addr
    str r0, [r1]

    ldr r0, [sp]
    ldr r1, =ccu_base_addr
    bl do_mmap

    pop {r1}
    push {r0}

    mov r0, r1
    ldr r1, =uart_base_addr
    bl do_mmap
    ldr r1, =uart_addr
    str r0, [r1]
    pop {r1}

    bl config_uart

    mov r4, #20
lp1:
    mov r0, #1
    ldr r1, =clear
    mov r2, #80
    bl write
    subs r4, #1
    bne lp1
    mov r0, #1
    ldr r1, =solid
    mov r2, #80
    bl write

    mov r4, #3
lp4:
    mov r0, #1
    ldr r1, =clear
    mov r2, #80
    bl write
    subs r4, #1
    bne lp4
    mov r0, #1
    ldr r1, =msg_start
    mov r2, #msg_start_len
    bl write

main_loop:
    mov r0, #1
    bl usleep
    bl kbhit
    cmp r0, #0
    beq no_inp
    bl handle_input
    cmp r0, #1
    beq exit

no_inp:
    ldr r1, =uart_addr
    ldr r1, [r1]
    ldr r0, [r1, #uart_offset+0x14]
    ands r0, #1
    beq no_read
    bl read_all
no_read:
    bl get_timestamp
    ldr r2, =last_sync_sent
    ldr r1, [r2]
    cmp r0, r1
    beq no_sync
    str r0, [r2]
    ldr r0, =zero
    ldr r1, =sync
    mov r2, #0
    bl send_msg
no_sync:
    bl get_timestamp
    ldr r1, =last_sync_got
    ldr r2, [r1]
    cmp r2, #0
    beq main_loop
    sub r2, r0, r2
    cmp r2, #5
    beq exit
    b main_loop

exit:
    bl restore_canon
    ldr r0, =clearscreen
    bl printf
err:
    pop {pc}

@ handle_input()
handle_input:
    push {r4, lr}
    bl getchar
    mov r4, r0
    cmp r0, #127
    beq bsp
    cmp r0, #27
    bne not_special
    bl detect_special
    cmp r0, #0
    beq handle_input_exit
    cmp r0, #1
    bne arrows
    b handle_input_exit
bsp:
    mov r0, #1
    ldr r1, =backspace
    mov r2, #backspace_len
    bl write
    ldr r0, =inp_len
    ldr r1, [r0]
    cmp r1, #0
    beq inp_empty
    sub r1, #1
    str r1, [r0]
inp_empty:
    mov r0, #0
    b handle_input_exit
arrows:
    cmp r0, #3
    beq arrow_up
    ldr r0, =msg_offset
    ldr r1, [r0]
    sub r1, #1
    str r1, [r0]
    bl show_messages
    mov r0, #0
    b handle_input_exit
arrow_up:
    ldr r0, =msg_offset
    ldr r1, [r0]
    add r1, #1
    str r1, [r0]
    bl show_messages
    mov r0, #0
    b handle_input_exit
not_special:
    ldr r0, =inp
    ldr r1, =inp_len
    ldr r2, [r1]
    strb r4, [r0, r2]
    add r2, #1
    cmp r4, #'\n'
    bne input_more

    mov r3, #0
    strb r3, [r0, r2]
    str r3, [r1]
    mov r4, r2

    ldr r0, =inp
    ldr r1, =name
    mov r2, #name_len
    bl strncmp
    cmp r0, #0
    bne normal
    ldr r0, =inp
    add r0, #name_len
    mov r1, r4
    sub r1, #name_len+1
    ldr r2, =my_name
    bl set_name
    bl clear_box
    ldr r0, =inp
    add r0, #name_len
    ldr r1, =name
    b ooo
normal:
    ldr r0, =inp
    mov r1, r4
    ldr r2, =my_name
    bl add_message
    bl show_messages
    bl clear_box
    ldr r0, =inp
    ldr r1, =msg
ooo:
    mov r2, #1
    bl send_msg
    mov r0, #0
    b handle_input_exit

input_more:
    str r2, [r1]
    sub r2, #1
    mov r1, r0
    add r1, r2
    mov r0, #1
    mov r2, #1
    bl write
    mov r0, #0
handle_input_exit:
    pop {r4, pc}

@ send_msg(char *msg, char *type, int conf)
send_msg:
    push {r0, r2, r4, lr}
    mov r0, r1
    bl send_str
    mov r4, r0
    pop {r0}
    bl send_str
    add r4, r0
    mov r3, #256
    udiv r2, r4, r3
    mul r2, r3
    sub r4, r2
    ldr r0, =crc8
    strb r4, [r0]
    bl send_str
    pop {r0}
    cmp r0, #0
    beq send_msg_exit
send_msg_exit:
    pop {r4, pc}

@ send_str(char *str)
send_str:
    push {lr}
    sub r0, #1
    mov r3, r0
    mov r0, #0
    ldr r2, =uart_addr
    ldr r2, [r2]
wait_busy:
    ldr r1, [r2, #uart_offset+0x14]
    ands r1, #1<<5
    beq wait_busy

    ldrb r1, [r3, #1]!
    add r0, r1
    cmp r1, #0
    beq send_str_stop
    str r1, [r2, #uart_offset]
    push {r0, r2, r3}
    mov r0, #1
    bl usleep
    pop {r0, r2, r3}
    b wait_busy
send_str_stop:
    pop {pc}

read_all:
    push {r4, r5, r6, lr}
new_msg:
    ldr r2, =received
    sub r2, #1
    mov r3, #0 @ is end of msg
    mov r4, #0 @ checksum
    mov r5, #0 @ is start of new msg
    mov r6, #0 @ len
    ldr r1, =uart_addr
    ldr r1, [r1]
wait_symbol:
    ldr r0, [r1, #uart_offset+0x14]
    ands r0, #1
    bne has_inp
    cmp r5, #0
    beq read_all_exit
    b wait_symbol

has_inp:
    mov r5, #1
    ldr r0, [r1, #uart_offset]
    cmp r3, #1
    beq end
    strb r0, [r2, #1]!
    add r4, r0
    add r6, #1
    cmp r0, #'\n'
    bne not_end
    sub r6, #1
    mov r3, #1
not_end:
    b wait_symbol
end:
    mov r2, #256
    udiv r3, r4, r2
    mul r3, r2
    sub r4, r3
    cmp r0, r4
    bne new_msg

    ldr r0, =received
    ldr r1, =name
    mov r2, #name_len
    bl strncmp
    cmp r0, #0
    beq got_name
    ldr r0, =received
    ldr r1, =msg
    mov r2, #msg_len
    bl strncmp
    cmp r0, #0
    beq got_msg
    ldr r0, =received
    ldr r1, =sync
    mov r2, #sync_len
    bl strncmp
    cmp r0, #0
    beq got_sync
got_trash:
    b new_msg
got_name:
    bl send_ok
    ldr r0, =received
    add r0, #name_len
    mov r1, r6
    sub r1, #name_len
    bl handle_name
    b new_msg
got_msg:
    bl send_ok
    ldr r0, =received
    mov r1, #0
    add r6, #1
    strb r1, [r0, r6]
    sub r6, #1
    add r0, #msg_len
    mov r1, r6
    sub r1, #msg_len
    bl handle_msg
    b new_msg
got_sync:
    bl handle_sync
    b new_msg

read_all_exit:
    pop {r4, r5, r6, pc}

send_ok:
    push {lr}
    ldr r0, =zero
    ldr r1, =ok
    mov r2, #0
    bl send_msg
    pop {pc}

@ handle_msg(char *args, int len)
handle_msg:
    push {lr}
    ldr r2, =yo_name
    bl add_message
    bl show_messages
    pop {pc}

@ add_message(char *msg, int msg_len, char *name)
add_message:
    push {r0, r1, r2, r4, lr}
lp8:
    ldr r0, [sp]
    ldr r1, =esc_seq
    bl strstr
    cmp r0, #0
    beq no_esc
    mov r1, #27
    strb r1, [r0, #1]
    ldr r1, [sp]
    sub r2, r0, r1
    ldr r3, [sp, #4]
    sub r2, r3, r2
    sub r3, #1
    str r3, [sp, #4]
    mov r1, r0
    add r1, #1
    bl memmove
    b lp8
no_esc:
    bl get_time
    ldr r0, [sp, #8]
    bl strlen
    ldr r1, [sp, #4]
    add r0, r1
    add r0, #19
    bl calloc
    ldr r1, =msgs_pos
    ldr r2, [r1]
    str r0, [r2]
    add r2, #4
    str r2, [r1]
    ldr r1, =msg_format
    ldr r2, =time
    ldr r3, [sp, #8]
    bl sprintf
    add sp, #12
    pop {r4, pc}

show_messages:
    push {r4, r5, r6, r7, lr}
    mov r0, #1
    ldr r1, =msgs_start
    mov r2, #msgs_start_len
    bl write
    mov r4, #20
lp3:
    mov r0, #1
    ldr r1, =clear
    mov r2, #80
    bl write
    subs r4, #1
    bne lp3
    mov r0, #1
    ldr r1, =msgs_start
    mov r2, #msgs_start_len
    bl write

    mov r5, #0 @ msg count
    mov r6, #0 @ line count
    ldr r7, =msg_addrs_orig
    ldr r4, =msgs_pos
    ldr r4, [r4]
    ldr r0, =msg_addrs_orig
    cmp r0, r4
    beq show_messages_exit
    sub r4, #4
    ldr r0, =msg_offset
    ldr r0, [r0]
    cmp r0, #0
    bge lp5
    mov r1, #4
    mul r0, r1
    sub r7, r0
lp5:
    cmp r4, r7
    blt start_print
    ldr r0, [r4]
    bl strlen
    mov r1, #80
    udiv r0, r1
    add r5, #1
    add r0, #1
    add r6, r0
    sub r4, #4
    cmp r6, #20
    ble lp5
    sub r5, #1
    add r4, #4
start_print:
    ldr r0, =msg_offset
    ldr r0, [r0]
    cmp r0, #0
    blt uuu
    mov r1, #4
    mul r0, r1
    sub r4, r0
    mov r6, #0
uuu:
    cmp r5, #0
    ble show_messages_exit
lp6:
    ldr r0, =msg_addrs_orig
    add r4, #4
    cmp r4, r0
    blt print_blank
    ldr r0, [r4]
    bl strlen
    mov r1, #80
    udiv r1, r0, r1
    add r6, r1
    add r6, #1
    cmp r6, #20
    bgt show_messages_exit
    mov r2, r0
    mov r0, #1
    ldr r1, [r4]
    bl write
    subs r5, #1
    bne lp6
    b show_messages_exit
print_blank:
    mov r0, #1
    ldr r1, =clear
    mov r2, #80
    bl write
    add r6, #1
    cmp r6, #20
    bge show_messages_exit
    b lp6
show_messages_exit:
    ldr r2, =inp_len
    ldr r2, [r2]
    add r2, #1
    ldr r1, =return_pos_templ
    ldr r0, =return_pos
    bl sprintf
    mov r2, r0
    mov r0, #1
    ldr r1, =return_pos
    bl write
    pop {r4, r5, r6, r7, pc}

@ handle_sync()
handle_sync:
    push {lr}
    bl get_timestamp
    ldr r1, =last_sync_got
    str r0, [r1]
    pop {pc}

@ handle_name(char *args, int len)
handle_name:
    push {lr}
    ldr r2, =yo_name
    bl set_name
    pop {pc}

@ set_name(char *new_name, int len, char* name_addr)
set_name:
    push {r1, r2, lr}
    mov r1, r0
    mov r0, r2
    ldr r2, [sp]
    bl memcpy
    pop {r0, r1}
    mov r2, #0
    strb r2, [r1, r0]
    pop {pc}

clear_box:
    push {r4, lr}
    mov r0, #1
    ldr r1, =msg_start
    mov r2, #msg_start_len
    bl write
    mov r4, #3
lp2:
    mov r0, #1
    ldr r1, =clear
    mov r2, #80
    bl write
    subs r4, #1
    bne lp2
    mov r0, #1
    ldr r1, =msg_start
    mov r2, #msg_start_len
    bl write
    pop {r4, pc}

get_timestamp:
    push {r4, lr}
    ldr r1, =rtc_addr
    ldr r1, [r1]

    mov r0, #0
    ldr r2, [r1, #16]
    and r2, #0xff
    ldr r3, =60*60*24
    mul r2, r3
    add r0, r2

    ldr r3, [r1, #20]
    and r2, r3, #0xff
    add r0, r2
    and r2, r3, #0xff00
    lsr r2, #8
    mov r4, #60
    mul r2, r4
    add r0, r2
    and r2, r3, #0xff0000
    lsr r2, #16
    mov r4, #60*60
    mul r2, r4
    add r0, r2
    pop {r4, pc}

get_time:
    push {lr}
    ldr r0, =rtc_addr
    ldr r0, [r0]

    ldr r0, [r0, #20]
    and r3, r0, #0xff
    push {r3}
    and r3, r0, #0xff00
    lsr r3, #8
    and r2, r0, #0xff0000
    lsr r2, #16
    ldr r0, =time
    ldr r1, =time_format
    bl sprintf
    add sp, #4
    pop {pc}

detect_special:
    push {r4, r5, lr}
    mov r0, #0
    mov r1, #F_GETFL
    mov r2, #0
    bl fcntl
    push {r0}
    orr r0, #O_NONBLOCK
    mov r2, r0
    mov r0, #0
    mov r1, #F_SETFL
    bl fcntl
    mov r4, #-1
    ldr r5, =special
lp7:
    bl getchar
    add r4, #1
    strb r0, [r5, r4]
    cmp r0, #-1
    bne lp7
    cmp r4, #0
    beq special_esc
    cmp r4, #2
    beq try_read_arrows
special_no:
    mov r0, #0
    b detect_special_exit
try_read_arrows:
    ldr r0, =special
    ldr r1, =key_up
    mov r2, r4
    bl strncmp
    cmp r0, #0
    beq special_up
    ldr r0, =special
    ldr r1, =key_down
    mov r2, r4
    bl strncmp
    cmp r0, #0
    bne special_no
    mov r0, #2
    b detect_special_exit
special_up:
    mov r0, #3
    b detect_special_exit
special_esc:
    mov r0, #1
detect_special_exit:
    pop {r2}
    push {r0}
    mov r0, #0
    mov r1, #F_SETFL
    bl fcntl
    pop {r0}
    pop {r4, r5, pc}

do_mmap:
    push {r0, r1, lr}
    mov r0, #0
    mov r1, #4096
    mov r2, #3
    mov r3, #1
    bl mmap
    add sp, #8
    pop {pc}

@ config_uart(int uart_addr, int ccu_addr)
config_uart:
    push {lr}
    ldr r2, [r1, #0x6C]
    orr r2, #1<<uart_bit
    str r2, [r1, #0x6C]

    ldr r2, [r1, #0x2D8]
    orr r2, #1<<uart_bit
    str r2, [r1, #0x2D8]

    ldr r2, [r0, #uart_offset+0x08]
    orr r2, #0b00000001 @ включаем фифо
    str r2, [r0, #uart_offset+0x08]

    ldr r2, [r0, #uart_offset+0x0C]
    mov r2, #0b10011011 @ 1 включаем доступ к латчам, 0 хз, 01 even, 1 parity en, 0 один стоп, 11 восемь бит
    str r2, [r0, #uart_offset+0x0C]

    mov r2, #13 @ 24000000/(16*13)=115200 Гц
    str r2, [r0, #uart_offset]

    mov r2, #0
    str r2, [r0, #uart_offset+0x04]

    ldr r2, [r0, #uart_offset+0x0C]
    and r2, #~0b10000000 @ выключаем доступ к латчам
    str r2, [r0, #uart_offset+0x0C]
    pop {pc}

set_noncanon:
    push {lr}
    mov r0, #STDIN
    ldr r1, =term1
    bl tcgetattr

    ldr r0, =term2
    ldr r1, =term1
    mov r2, #termlen
    bl memcpy

    ldr r2, =term1
    ldr r0, [r2, #12]
    ldr r1, =~(ICANON | ECHO)
    and r0, r1
    str r0, [r2, #12]
    mov r0, #STDIN
    mov r1, #TCSANOW
    bl tcsetattr
    pop {pc}

restore_canon:
    push {lr}
    mov r0, #STDIN
    mov r1, #TCSANOW
    ldr r2, =term2
    bl tcsetattr
    pop {pc}

kbhit:
    push {lr}
    mov r0, #STDIN
    ldr r1, =FIONREAD
    ldr r2, =n
    bl ioctl
    ldr r0, =n
    ldr r0, [r0]
    pop {pc}

test:
    push {r0, r1, r2, r3, r4, r5, lr}
    ldr r0, =lala
    bl printf
    pop {r0, r1, r2, r3, r4, r5, pc}

test_int:
    push {r0, r1, r2, r3, r4, r5, lr}
    ldr r0, =lala_int
    mov r1, r8
    bl printf
    pop {r0, r1, r2, r3, r4, r5, pc}

.data
    devmem: .asciz "/dev/mem"
    solid: .asciz "--------------------------------------------------------------------------------"
    clear: .asciz "                                                                                "
    msg_start: .asciz "\033[22;0H"
    msg_start_len = . - msg_start
    msgs_start: .asciz "\033[0;0H"
    msgs_start_len = . - msgs_start
    name: .asciz "/name "
    name_len = . - name - 1
    msg: .asciz "/msg "
    msg_len = . - msg - 1
    sync: .asciz "/sync\n"
    sync_len = . - sync - 1
    ok: .asciz "/ok\n"
    ok_len = . - ok - 1
    zero: .asciz ""
    msg_format: .asciz "[%s] %s: %s\033[0m"
    time_format: .asciz "%02lu:%02lu:%02lu"
    msg_addrs_orig = msg_addrs
    key_up: .ascii "\x5b\x41"
    up_len = . - key_up
    key_down: .ascii "\x5b\x42"
    return_pos_templ: .asciz "\033[22;%dH"
    clearscreen: .asciz "\033c\n"
    esc_seq: .asciz "\\e"
    backspace: .asciz "\033[D \033[D"
    backspace_len = . - backspace
    lala: .asciz "lalala\n"
    lala_int: .asciz "%lu\n"

    msg_offset: .word 0
    msgs_pos: .word msg_addrs
    inp_len: .word 0

.bss
    term1: .fill 60, 1, 0
    termlen = . - term1
    term2: .fill 60, 1, 0
    n: .fill 4, 1, 0
    crc8: .fill 2, 1, 0
    inp: .fill 1024, 1, 0
    received: .fill 1024, 1, 0
    last_sync_sent: .fill 4, 1, 0
    last_sync_got: .fill 4, 1, 0
    my_name: .fill 255, 1, 0
    yo_name: .fill 255, 1, 0
    uart_addr: .fill 4, 1, 0
    rtc_addr: .fill 4, 1, 0
    msg_addrs: .fill 4096, 1, 0
    time: .fill 9, 1, 0
    special: .fill 16, 1, 0
    return_pos: .fill 16, 1, 0
