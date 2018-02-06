.globl main
.text
main:
    push {lr}

    cmp r0, #3
    blt err
    ldr r0, [r1, #4]
    push {r1}
    bl atoi
    pop {r1}
    push {r0}
    ldr r0, [r1, #8]
    bl atoi
    pop {r1}
    cmp r0, #2
    blt err
    cmp r0, #16
    bgt err

@ r0 - osnov, r1 - chislo
    mov r4, #0
divloop:
    add r4, #1
    udiv r3, r1, r0
    mul r2, r3, r0
    sub r1, r2
    push {r1}
    mov r1, r3
    tst r1, r1
    bne divloop

    ldr r0, =style
    bl printf

printloop:
    pop {r1}
    ldr r0, =number
    push {r4}
    bl printf
    pop {r4}
    subs r4, #1
    bne printloop

exit:
    ldr r0, =clear
    bl printf
    pop {pc}

err:
    ldr r0, =errmsg
    bl printf
    pop {pc}

.data
    style: .asciz "\033c\033[1;3;35m\033[12;35f"
    number: .asciz "%x"
    clear: .asciz "\n\n\n\n\n\n\033[0m"
    errmsg: .asciz "vvedi chislo i osnovanie(< 17 i > 1)     iiiiiiiiiiiiiiiiiii\n"
