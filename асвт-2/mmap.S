.globl main
.text

#define O_DSYNC     10000
#define O_RDWR      2
#define RTC         0x1f00000

main:
    push {lr}

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
lp:
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
    ldr r0, =100000
    bl usleep
    b lp

    pop {pc}
err:
    ldr r0, =errmsg
    bl printf
    pop {pc}

data:
    devmem: .asciz "/dev/mem"
    style: .asciz "\033c"
    date1: .asciz "\033[12;35f%02lu/%02lu/%04lu %02lu:%02lu:%02lu\n\033[12;0f"
    date2: .asciz "\033[12;35f%02lu/%02lu/%04lu %02lu:%02lu %02lu\n\033[12;0f"
    errmsg: .asciz "bla-bla\n"
    test: .asciz "%lu\n"
