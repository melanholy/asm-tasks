.globl main
.text
main:
    push {lr}

    cmp r0, #3
    bne err

    ldr r4, [r1, #8]
    ldr r0, [r1, #4]

    mov r1, #0
    mov r7, #5 @ open
    svc #0
    cmp r0, #-1
    blt err
    push {r0} @ fd

    ldr r1, =fstat
    mov r7, #108 @ fstat
    svc #0

    ldr r0, =fstat+20
    ldr r0, [r0]
    push {r0} @ fd flen
    bl malloc

    mov r1, r0
    pop {r2} @ fd
    pop {r0} @
    push {r1} @ addr
    mov r7, #3 @ read
    svc #0

    mov r5, r4
count_len:
    ldrb r2, [r5, #1]!
    cmp r2, #0
    bne count_len
    sub r5, r4

    pop {r0} @
    mov r6, #0
    mov r3, r0
    mov r1, #0
lp1:
    ldrb r2, [r3], #1
    cmp r2, #0
    beq exit
    cmp r2, #0xa
    bne lp1
    mov r2, #0
    strb r2, [r3, #-1]
    push {r0, r1, r3} @ lend len lstart
    mov r1, r4
    bl strstrstr
    cmp r0, #0
    beq notfound
    ldr r1, [sp, #4]
    push {r0} @ lend len lstart pos
    ldr r0, =str1
    bl printf
    pop {r0} @ lend len lstart
    ldr r1, [sp]
    mov r2, r4
print:
    add r6, #1
    mov r3, #0
    strb r3, [r0], #1
    push {r0} @ lend len lstart pos+r5
    ldr r0, =str2
    bl printf

    ldr r0, [sp]
    mov r1, r4
    bl strstrstr
    pop {r1} @ lend len lstart
    add r1, r5
    sub r1, #1
    cmp r0, #0
    beq last_occ
    cmp r1, r0
    mov r2, r4
    ble print
    sub r3, r1, r0
    add r2, r3
    sub r1, r5
    b print
last_occ:
    ldr r0, =str3
    bl printf

notfound:
    pop {r0, r1, r3}
    add r1, r3
    sub r1, r0
    mov r0, r3
    b lp1

err:
    ldr r0, =errmsg
    bl printf
    pop {pc}
exit:
    ldr r0, =total
    mov r1, r6
    bl printf
    pop {pc}

@strstrstr(*haystack, *needle)
strstrstr:
    push {r4, lr}

    mov r4, #0
    ldrb r3, [r1]
lp2:
    ldrb r2, [r0], #1
    cmp r2, #0
    beq strstrstr_notfound
    cmp r2, r3
    beq next_sym
    sub r0, r4
    mov r4, #0
    ldrb r3, [r1]
    b lp2
next_sym:
    add r4, #1
    ldrb r3, [r1, r4]
    cmp r3, #0
    bne lp2

strstrstr_found:
    sub r0, r4
    pop {r4, pc}
strstrstr_notfound:
    mov r0, #0
    pop {r4, pc}

.data
    errmsg: .asciz "bla-bla\n"
    str1: .asciz "\033[34m%08x\033[0m:"
    str2: .asciz "%s\033[1;32m%s\033[0m"
    str3: .asciz "%s\n"
    total: .asciz "\nFound %lu occurences total.\n"

.bss
    fstat: .fill 64, 1, 0
