.globl main
.text

#define O_DSYNC     10000
#define O_RDWR      2
#define RTC         0x1f00000
#define STDIN       0
#define ICANON      2
#define ECHO        8
#define TCSANOW     0
#define FIONREAD    21531

main:
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

    ldr r0, =devmem
    ldr r1, =O_RDWR | O_DSYNC
    bl open

    cmp r0, #0
    blt err

    ldr r1, =RTC
    push {r1}
    push {r0}
    mov r0, #0
    mov r1, #4096
    mov r2, #3
    mov r3, #1
    bl mmap
    add sp, #8
    push {r0}
    ldr r0, =style
    bl printf
    mov r6, #1
    mov r7, #1
lp:
    cmp r7, #1
    bne no_print

    ldr r0, [sp]

    ldr r5, [r0, #16]
    and r1, r5, #0xff00
    lsr r1, #8
    and r2, r5, #0xff
    and r3, r5, #0xff0000
    lsr r3, #16
    mov r5, #1970
    add r3, r5

    ldr r5, [r0, #20]
    and r4, r5, #0xff
    push {r4}
    and r4, r5, #0xff00
    lsr r4, #8
    push {r4}
    and r4, r5, #0xff0000
    lsr r4, #16
    push {r4}

    cmp r6, #1
    ldreq r0, =date1
    ldrne r0, =date2
    neg r6, r6

    bl printf
    add sp, #12

no_print:
    bl kbhit
    cmp r0, #0
    beq sleep

read_inp:
    mov r4, r0
    bl getchar
    cmp r0, #'x'
    beq exit_loop
    cmp r0, #' '
    bne no_stop
    neg r7, r7
no_stop:
    subs r4, #1
    bne read_inp

sleep:
    ldr r0, =100000
    bl usleep

    b lp

err:
    ldr r0, =errmsg
    bl printf
    b exit
exit_loop:
    add sp, #4
exit:
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

data:
    devmem: .asciz "/dev/mem"
    style: .asciz "\033c"
    date1: .asciz "\033[12;35f%02lu/%02lu/%04lu %02lu:%02lu:%02lu\n\033[12;0f"
    date2: .asciz "\033[12;35f%02lu/%02lu/%04lu %02lu %02lu %02lu\n\033[12;0f"
    errmsg: .asciz "bla-bla\n"
    test: .asciz "%d\n"

.bss
    term1: .fill 60, 1, 0
    termlen = . - term1
    term2: .fill 60, 1, 0
    n: .fill 4, 1, 0
