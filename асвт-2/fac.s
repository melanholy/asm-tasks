.globl main
.text
main:
    push {lr}

    ldr r0, =style
    bl printf

    mov r2, #13
    mov r1, #1
mulloop:
    mul r1, r2
    subs r2, #1
    bne mulloop

    mov r0, #1000
    mov r4, #-1
divloop:
    add r4, #1
    udiv r3, r1, r0
    mul r2, r3, r0
    sub r1, r2
    push {r1}
    mov r1, r3
    tst r1, r1
    bne divloop

    pop {r1}
    ldr r0, =fnumber
    push {r4}
    bl printf
    pop {r4}

printloop:
    pop {r1}
    ldr r0, =number
    push {r4}
    bl printf
    pop {r4}
    subs r4, #1
    bne printloop

    ldr r0, =clear
    bl printf

    pop {pc}

.data
    style: .asciz "\033c\033[1;3;35m\033[12;35f"
    number: .asciz "%03lu "
    fnumber: .asciz "%lu "
    clear: .asciz "\n\n\n\n\n\n\033[0m"
