.globl main
.text

#define STDIN 0
#define ICANON 0x1000
#define ECHO 0x100
#define TCSANOW 3
#define FIONREAD 21531

main:
    push {lr}

    mov r0, #STDIN
    ldr r1, =term1
    bl tcgetattr

    ldr r0, =term2
    ldr r1, =term1
    mov r2, #60
    bl memcpy

    ldr r2, =term1
    ldr r0, [r2, #12]
    ldr r1, =~(ICANON | ECHO)
    and r0, r1
    str r0, [r2, #12]

    mov r0, #STDIN
    mov r1, #TCSANOW
    bl tcsetattr

    mov r1, r0
    ldr r0, =test
    bl printf

lp:
    ldr r0, =dot
    bl printf
    mov r0, #1
    bl fflush
    ldr r0, =100000
    bl usleep
    bl kbhit
    cmp r0, #0
    beq lp
    bl getchar
    mov r1, r0
    ldr r0, =sym
    bl printf
    b lp

    mov r0, #STDIN
    mov r1, #TCSANOW
    ldr r2, =term2
    bl tcsetattr

kbhit:
    push {lr}
    mov r0, #STDIN
    ldr r1, =FIONREAD
    ldr r2, =n
    bl ioctl
    ldr r1, =n
    ldr r0, [r1]
    pop {pc}


.data
    dot: .asciz "."
    sym: .asciz " %c "
    test: .asciz "%lu\n"

.bss
    term1: .fill 60, 1, 0
    term2: .fill 60, 1, 0
    n: .fill 4, 1, 0
