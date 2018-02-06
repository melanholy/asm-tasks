.globl main
.text

#ifndef CL
    #ifndef SR
        #error No mode specified.
    #endif
#endif

#ifdef CL
    #define uart_offset 0x400
    #define uart_bit    17
#else
    #define uart_offset 0x800
    #define uart_bit    18
#endif
#define ccu_base_addr   0x1c20000
#define uart_base_addr  0x1c28000

#define O_DSYNC         10000
#define O_RDWR          2
#define STDIN           0
#define ICANON          2
#define ECHO            8
#define TCSANOW         0
#define FIONREAD        21531

main:
    push {lr}

#ifdef CL
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
#endif

    ldr r0, =devmem
    ldr r1, =O_RDWR | O_DSYNC
    bl open

    cmp r0, #0
    blt err

    push {r0}
    ldr r1, =ccu_base_addr
    bl do_mmap

    pop {r1}
    push {r0}

    mov r0, r1
    ldr r1, =uart_base_addr
    bl do_mmap
    push {r0}

    ldr r1, [sp, #4]
    ldr r0, [r1, #0x6C]
    orr r0, #1<<uart_bit
    str r0, [r1, #0x6C]

    ldr r0, [r1, #0x2D8]
    orr r0, #1<<uart_bit
    str r0, [r1, #0x2D8]

    ldr r1, [sp]
    ldr r0, [r1, #uart_offset+0x0C]
    orr r0, #0b10000011
    str r0, [r1, #uart_offset+0x0C]

    mov r0, #13
    str r0, [r1, #uart_offset]

    mov r0, #0
    str r0, [r1, #uart_offset+0x04]

    ldr r0, [r1, #uart_offset+0x0C]
    and r0, #~0b10000000
    str r0, [r1, #uart_offset+0x0C]

#ifdef CL
wait_input:
    ldr r0, =100000
    bl usleep
    bl kbhit
    cmp r0, #0
    beq wait_input
    ldr r1, [sp]
    mov r4, r0
wait_busy:
    ldr r0, [r1, #uart_offset+0x14]
    and r0, #1<<5
    cmp r0, #0
    beq wait_busy

    bl getchar
    ldr r1, [sp]
    str r0, [r1, #uart_offset]
    cmp r0, #'x'
    beq exit
    subs r4, #1
    bne wait_busy
    b wait_input
#else
wait_symbol:
    ldr r0, [r1, #uart_offset+0x14]
    and r0, #1
    cmp r0, #0
    beq wait_symbol

    ldr r0, [r1, #uart_offset]
    mov r4, r0
    ldr r1, =chr
    strb r0, [r1]
    mov r0, #1
    mov r2, #1
    bl write
    cmp r4, #'x'
    beq wrap_up
    ldr r1, [sp]
    b wait_symbol

wrap_up:
    mov r0, #'\n'
    ldr r1, =chr
    strb r0, [r1]
    mov r0, #1
    mov r2, #1
    bl write
    b exit
#endif

exit:
    add sp, #8
#ifdef CL
    mov r0, #STDIN
    mov r1, #TCSANOW
    ldr r2, =term2
    bl tcsetattr
#endif
err:
    pop {pc}

do_mmap:
    push {lr}

    push {r1}
    push {r0}
    mov r0, #0
    mov r1, #4096
    mov r2, #3
    mov r3, #1
    bl mmap
    add sp, #8

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

.data
    devmem: .asciz "/dev/mem"

.bss
    term1: .fill 60, 1, 0
    termlen = . - term1
    term2: .fill termlen, 1, 0
    n: .fill 4, 1, 0
    chr: .fill 1, 1, 0
