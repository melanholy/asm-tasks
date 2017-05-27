.model tiny
.code
org 100h
locals

main:
    jmp begin

    melody0 dw melody0_len
            dw 120
            db 2, 5, 18, 56, 22, 8, 25
            db 2, 1, 0
            db 2, 3, 18, 22, 27
            db 2, 1, 0
            db 2, 4, 20, 54, 25, 6
            db 2, 2, 20, 25
            db 2, 2, 20, 27
            db 2, 4, 20, 53, 29, 5
            db 2, 1, 0
            db 2, 2, 20, 29
            db 2, 2, 20, 27
            db 2, 1, 0
            db 2, 2, 20, 25
            db 2, 1, 5
            db 2, 3, 20, 1, 27
            db 2, 1, 53
            db 2, 5, 18, 51, 22, 3, 25
            db 2, 1, 0
            db 2, 5, 18, 53, 22, 5, 27
            db 2, 2, 53, 6
            db 2, 4, 20, 56, 25, 8
            db 2, 2, 20, 25
            db 2, 4, 20, 57, 27, 9
            db 2, 4, 20, 58, 29, 10
            db 2, 1, 0
            db 2, 2, 20, 29
            db 2, 2, 20, 27
            db 2, 1, 0
            db 2, 4, 21, 57, 25, 9
            db 2, 4, 21, 57, 25, 9
            db 2, 4, 21, 57, 27, 9
            db 2, 2, 57, 9
            melody0_len = $ - melody0

    melody1 dw melody1_len
            dw 220
           db 4, 1, 9
           db 4, 1, 0
           db 4, 1, 12
           db 4, 1, 0
           db 2, 1, 14
           db 2, 1, 0
           db 2, 1, 14
           db 2, 1, 0
           db 4, 1, 14
           db 4, 1, 0
           db 4, 1, 16
           db 4, 1, 0
           db 2, 1, 17
           db 2, 1, 0
           db 2, 1, 17
           db 2, 1, 0
           db 4, 1, 17
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 2, 1, 16
           db 2, 1, 0
           db 2, 1, 16
           db 2, 1, 0
           db 4, 1, 14
           db 4, 1, 0
           db 4, 1, 12
           db 4, 1, 0
           db 4, 1, 12
           db 4, 1, 0
           db 2, 1, 14
           db 1, 1, 0

           db 4, 1, 9
           db 4, 1, 0
           db 4, 1, 12
           db 4, 1, 0
           db 2, 1, 14
           db 2, 1, 0
           db 2, 1, 14
           db 2, 1, 0
           db 4, 1, 14
           db 4, 1, 0
           db 4, 1, 16
           db 4, 1, 0
           db 2, 1, 17
           db 2, 1, 0
           db 2, 1, 17
           db 2, 1, 0
           db 4, 1, 17
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 2, 1, 16
           db 2, 1, 0
           db 2, 1, 16
           db 2, 1, 0
           db 4, 1, 14
           db 4, 1, 0
           db 4, 1, 12
           db 4, 1, 0
           db 2, 1, 14
           db 2, 1, 0
           db 1, 1, 0

           db 4, 1, 9
           db 4, 1, 0
           db 4, 1, 12
           db 4, 1, 0
           db 2, 1, 14
           db 2, 1, 0
           db 2, 1, 14
           db 2, 1, 0
           db 4, 1, 14
           db 4, 1, 0
           db 4, 1, 17
           db 4, 1, 0
           db 2, 1, 19
           db 2, 1, 0
           db 2, 1, 19
           db 2, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 4, 1, 21
           db 4, 1, 0
           db 2, 1, 22
           db 2, 1, 0
           db 2, 1, 22
           db 2, 1, 0
           db 4, 1, 21
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 4, 1, 21
           db 4, 1, 0
           db 2, 1, 14
           db 1, 1, 0

           db 4, 1, 14
           db 4, 1, 0
           db 4, 1, 16
           db 4, 1, 0
           db 2, 1, 17
           db 2, 1, 0
           db 2, 1, 17
           db 2, 1, 0
           db 2, 1, 19
           db 2, 1, 0
           db 4, 1, 21
           db 4, 1, 0
           db 2, 1, 14
           db 1, 1, 0
           db 4, 1, 14
           db 4, 1, 0
           db 4, 1, 17
           db 4, 1, 0
           db 2, 1, 16
           db 2, 1, 0
           db 2, 1, 16
           db 2, 1, 0
           db 4, 1, 17
           db 4, 1, 0
           db 4, 1, 14
           db 4, 1, 0
           db 2, 1, 16
           db 4, 1, 16
           melody1_len = $ - melody1

    melody2 dw melody2_len
            dw 220
           db 2, 1, 23
           db 2, 1, 19
           db 1, 1, 23
           db 2, 1, 23
           db 2, 1, 0
           db 2, 1, 23
           db 2, 1, 19
           db 2, 1, 23
           db 2, 1, 18
           db 1, 1, 23
           db 2, 1, 23
           db 2, 1, 0
           db 2, 1, 23
           db 2, 1, 18
           db 2, 1, 28
           db 2, 1, 19
           db 1, 1, 28
           db 2, 1, 28
           db 2, 1, 0
           db 2, 1, 28
           db 2, 1, 19
           db 2, 1, 28
           db 2, 1, 0
           db 2, 1, 28
           db 2, 1, 0
           db 2, 1, 28
           db 2, 1, 23
           db 2, 1, 21
           db 2, 1, 23
           db 2, 1, 23
           db 2, 1, 0

           db 1, 1, 19
           db 1, 1, 31
           db 1, 1, 31
           db 1, 1, 31
           db 1, 1, 0
           db 2, 1, 30
           db 2, 1, 31
           db 2, 1, 30
           db 2, 1, 26
           db 1, 1, 28
           db 1, 1, 28
           db 1, 1, 28
           db 2, 1, 0
           db 2, 1, 19
           db 2, 1, 24
           db 2, 1, 0
           db 2, 1, 24
           db 2, 1, 0
           db 2, 1, 24
           db 2, 1, 23
           db 2, 1, 21
           db 2, 1, 23
           db 1, 1, 19
           db 1, 1, 19
           db 1, 1, 31
           db 1, 1, 31
           db 1, 1, 31
           db 1, 1, 31
           db 2, 1, 30
           db 2, 1, 31
           db 2, 1, 33
           db 2, 1, 30
           db 1, 1, 28
           db 1, 1, 28
           db 1, 1, 28
           db 2, 1, 0
           db 2, 1, 19
           db 2, 1, 24
           db 2, 1, 0
           db 2, 1, 24
           db 2, 1, 0
           db 2, 1, 24
           db 2, 1, 23
           db 2, 1, 21
           db 2, 1, 23
           db 1, 1, 19
           db 1, 1, 19
           melody2_len = $ - melody2

    melody3 dw melody3_len
            dw 100
            db 1, 1, 6
            db 2, 1, 13
            db 4, 1, 10
            db 4, 1, 0
            db 2, 1, 10
            db 2, 1, 0
            db 2, 1, 8
            db 4, 1, 6
            db 4, 1, 0
            db 2, 1, 6
            db 1, 1, 11
            db 4, 1, 10
            db 4, 1, 0
            db 2, 1, 10
            db 4, 1, 8
            db 4, 1, 0
            db 2, 1, 8
            db 2, 1, 6
            db 2, 1, 0
            db 2, 1, 6
            db 2, 1, 13
            db 4, 1, 10
            db 4, 1, 0
            db 4, 1, 10
            db 4, 1, 0
            db 2, 1, 10
            db 2, 1, 8
            db 4, 1, 6
            db 4, 1, 0
            db 2, 1, 6
            db 1, 1, 3
            db 1, 1, 1
            db 2, 1, 0
            db 1, 1, 0
            db 4, 1, 6
            db 4, 1, 0
            db 2, 1, 6
            db 2, 1, 13
            db 4, 1, 10
            db 4, 1, 0
            db 2, 1, 10
            db 4, 1, 8
            db 4, 1, 0
            db 2, 1, 8
            db 4, 1, 6
            db 4, 1, 0
            db 2, 1, 6
            db 1, 1, 11
            db 4, 1, 10
            db 4, 1, 0
            db 2, 1, 10
            db 4, 1, 8
            db 4, 1, 0
            db 2, 1, 8
            db 4, 1, 6
            db 4, 1, 0
            db 2, 1, 6
            db 2, 1, 13
            db 2, 1, 0
            db 4, 1, 10
            db 4, 1, 0
            db 2, 1, 10
            db 2, 1, 8
            db 2, 1, 0
            db 4, 1, 6
            db 4, 1, 0
            db 2, 1, 6
            db 1, 1, 8
            db 1, 1, 3
            melody3_len = $ - melody3

    melody4 dw melody4_len
            dw 300
           db 4, 1, 32
           db 4, 1, 0
           db 4, 1, 34
           db 4, 1, 0
           db 4, 1, 32
           db 4, 1, 0
           db 4, 1, 31
           db 4, 1, 0
           db 4, 1, 32
           db 4, 1, 0
           db 4, 1, 34
           db 4, 1, 0
           db 4, 1, 36
           db 4, 1, 0
           db 4, 1, 37
           db 4, 1, 0
           db 4, 1, 39
           db 4, 1, 0
           db 2, 1, 0
           db 4, 1, 36
           db 4, 1, 0
           db 2, 1, 0
           db 2, 1, 36
           db 4, 1, 36
           db 1, 1, 0
           db 4, 1, 0
           db 4, 1, 16
           db 2, 1, 0
           db 4, 1, 0
           db 4, 1, 37
           db 2, 1, 0
           db 4, 1, 0
           db 2, 1, 37
           db 4, 1, 37
           db 1, 1, 0
           db 4, 1, 0
           db 4, 1, 39
           db 2, 1, 0
           db 4, 1, 0
           db 4, 1, 36
           db 2, 1, 0
           db 4, 1, 0
           db 2, 1, 36
           db 4, 1, 36
           db 1, 1, 0
           db 4, 1, 0
           db 4, 1, 32
           db 4, 1, 0
           db 4, 1, 34
           db 4, 1, 0
           db 4, 1, 32
           db 4, 1, 0
           db 4, 1, 31
           db 4, 1, 0
           db 4, 1, 32
           db 4, 1, 0
           db 4, 1, 34
           db 4, 1, 0
           db 4, 1, 36
           db 4, 1, 0
           db 4, 1, 37
           db 4, 1, 0
           db 4, 1, 39
           db 4, 1, 0
           db 2, 1, 0
           db 4, 1, 36
           db 4, 1, 0
           db 2, 1, 0
           db 2, 1, 36
           db 4, 1, 36
           db 1, 1, 0
           db 4, 1, 0
           db 4, 1, 38
           db 4, 1, 0
           db 4, 1, 36
           db 4, 1, 0
           db 4, 1, 34
           db 4, 1, 0
           db 2, 1, 0
           db 4, 1, 38
           db 4, 1, 0
           db 4, 1, 36
           db 4, 1, 0
           db 4, 1, 34
           db 4, 1, 0
           db 2, 1, 0
           db 4, 1, 39
           db 2, 1, 39
           db 4, 1, 0
           db 1, 1, 0
           db 4, 1, 17
           db 4, 1, 0
           db 4, 1, 13
           db 4, 1, 0
           db 4, 1, 17
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 4, 1, 20
           db 4, 1, 0
           db 2, 1, 0
           db 4, 1, 17
           db 4, 1, 0
           db 4, 1, 13
           db 4, 1, 0
           db 4, 1, 17
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 4, 1, 20
           db 4, 1, 0
           db 1, 1, 0
           db 1, 1, 0
           db 4, 1, 32
           db 4, 1, 0
           db 2, 1, 0
           db 4, 1, 32
           db 4, 1, 0
           db 4, 1, 31
           db 4, 1, 0
           db 2, 1, 0
           db 4, 1, 29
           db 4, 1, 0
           db 2, 1, 0
           db 4, 1, 27
           db 2, 1, 0
           db 4, 1, 0
           db 4, 1, 26
           db 4, 1, 0
           db 1, 1, 27
           db 1, 1, 27
           db 2, 1, 0

           db 4, 1, 17
           db 4, 1, 0
           db 4, 1, 14
           db 4, 1, 0
           db 4, 1, 17
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 4, 1, 20
           db 2, 1, 0
           db 4, 1, 0
           db 4, 1, 17
           db 4, 1, 0
           db 4, 1, 14
           db 4, 1, 0
           db 4, 1, 17
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 4, 1, 20
           db 2, 1, 0
           db 4, 1, 0
           db 1, 1, 0

           db 2, 1, 22
           db 4, 1, 32
           db 4, 1, 0
           db 4, 1, 22
           db 4, 1, 0
           db 4, 1, 31
           db 2, 1, 0
           db 4, 1, 0
           db 2, 1, 29
           db 1, 1, 27
           db 4, 1, 27
           melody4_len = $ - melody4

    melody5 dw melody5_len
            dw 100
           db 4, 1, 16
           db 2, 1, 0
           db 4, 1, 0
           db 4, 1, 23
           db 4, 1, 0
           db 2, 1, 0
           db 4, 1, 23
           db 4, 1, 0
           db 4, 1, 21
           db 4, 1, 0
           db 4, 1, 23
           db 2, 1, 0
           db 4, 1, 0
           db 4, 1, 21
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 4, 1, 21
           db 4, 1, 0
           db 2, 1, 0
           db 4, 1, 21
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 4, 1, 16
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 4, 1, 16
           db 2, 1, 0
           db 4, 1, 0
           db 4, 1, 23
           db 4, 1, 0
           db 2, 1, 0
           db 4, 1, 23
           db 4, 1, 0
           db 4, 1, 21
           db 4, 1, 0
           db 4, 1, 23
           db 2, 1, 0
           db 4, 1, 0
           db 4, 1, 21
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 4, 1, 21
           db 4, 1, 0
           db 2, 1, 0
           db 4, 1, 21
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 4, 1, 16
           db 4, 1, 0
           db 4, 1, 19
           db 4, 1, 0
           db 4, 1, 16
           melody5_len = $ - melody5

    melody6 dw melody6_len
            dw 190
            db 4, 1, 30
            db 4, 1, 0
            db 4, 1, 30
            db 4, 1, 0
            db 4, 1, 26
            db 4, 1, 0
            db 4, 1, 23
            db 4, 1, 0
            db 2, 1, 0
            db 4, 1, 23
            db 2, 1, 0
            db 4, 1, 0
            db 4, 1, 28
            db 4, 1, 0
            db 2, 1, 0
            db 4, 1, 28
            db 2, 1, 0
            db 4, 1, 0
            db 4, 1, 28
            db 4, 1, 0
            db 4, 1, 32
            db 4, 1, 0
            db 4, 1, 32
            db 4, 1, 0
            db 4, 1, 33
            db 4, 1, 0
            db 4, 1, 35
            db 4, 1, 0
            db 4, 1, 33
            db 4, 1, 0
            db 4, 1, 33
            db 4, 1, 0
            db 4, 1, 33
            db 4, 1, 0
            db 4, 1, 28
            db 2, 1, 0
            db 4, 1, 0
            db 4, 1, 26
            db 2, 1, 0
            db 4, 1, 0
            db 4, 1, 30
            db 2, 1, 0
            db 4, 1, 0
            db 4, 1, 30
            db 2, 1, 0
            db 4, 1, 0
            db 4, 1, 30
            db 4, 1, 0
            db 4, 1, 28
            db 4, 1, 0
            db 4, 1, 28
            db 4, 1, 0
            db 4, 1, 30
            db 4, 1, 0
            db 4, 1, 28
            db 4, 1, 0
            db 4, 1, 30
            db 4, 1, 0
            db 4, 1, 30
            db 4, 1, 0
            db 4, 1, 26
            db 4, 1, 0
            db 4, 1, 23
            db 4, 1, 0
            db 2, 1, 0
            db 4, 1, 23
            db 2, 1, 0
            db 4, 1, 0
            db 4, 1, 28
            db 4, 1, 0
            db 2, 1, 0
            db 4, 1, 28
            db 2, 1, 0
            db 4, 1, 0
            db 4, 1, 28
            db 4, 1, 0
            db 4, 1, 32
            db 4, 1, 0
            db 4, 1, 32
            db 4, 1, 0
            db 4, 1, 33
            db 4, 1, 0
            db 4, 1, 35
            db 4, 1, 0
            db 4, 1, 33
            db 4, 1, 0
            db 4, 1, 33
            db 4, 1, 0
            db 4, 1, 33
            db 4, 1, 0
            db 4, 1, 28
            db 2, 1, 0
            db 4, 1, 0
            db 4, 1, 26
            db 2, 1, 0
            db 4, 1, 0
            db 4, 1, 30
            db 2, 1, 0
            db 4, 1, 0
            db 4, 1, 30
            db 2, 1, 0
            db 4, 1, 0
            db 4, 1, 30
            db 4, 1, 0
            db 4, 1, 28
            db 4, 1, 0
            db 4, 1, 28
            db 4, 1, 0
            db 4, 1, 30
            db 4, 1, 0
            db 4, 1, 28
            melody6_len = $ - melody6

    melody8 dw melody8_len
             dw 300
             db 1, 1, 21
             db 1, 1, 26
             db 1, 1, 21
             db 1, 1, 26
             db 2, 1, 21
             db 1, 1, 26
             db 2, 1, 21
             db 2, 1, 0
             db 2, 1, 20
             db 2, 1, 21
             db 2, 1, 0
             db 2, 1, 21
             db 2, 1, 20
             db 2, 1, 21
             db 2, 1, 19
             db 2, 1, 0
             db 2, 1, 18
             db 2, 1, 19
             db 2, 1, 18
             db 1, 1, 17
             db 2, 1, 17
             db 2, 1, 14
             db 1, 1, 14
             db 1, 1, 0
             db 1, 1, 21
             db 1, 1, 26
             db 1, 1, 21
             db 1, 1, 26
             db 2, 1, 21
             db 1, 1, 26
             db 2, 1, 21
             db 2, 1, 0
             db 2, 1, 20
             db 1, 1, 21
             db 2, 1, 19
             db 2, 1, 0
             db 1, 1, 19
             db 2, 1, 19
             db 2, 1, 18
             db 1, 1, 19
             db 2, 1, 24
             db 1, 1, 22
             db 1, 1, 21
             db 1, 1, 19
             db 2, 1, 19
             db 1, 1, 21
             db 1, 1, 26
             db 1, 1, 21
             db 1, 1, 26
             db 2, 1, 21
             db 1, 1, 26
             db 2, 1, 21
             db 2, 1, 0
             db 2, 1, 20
             db 2, 1, 21
             db 2, 1, 0
             db 2, 1, 24
             db 2, 1, 0
             db 1, 1, 24
             db 2, 1, 21
             db 1, 1, 19
             db 2, 1, 16
             db 2, 1, 17
             db 2, 1, 14
             db 1, 1, 14
             db 1, 1, 0
             db 1, 1, 14
             db 1, 1, 14
             db 1, 1, 17
             db 1, 1, 17
             db 1, 1, 21
             db 1, 1, 21
             db 1, 1, 24
             db 1, 1, 24
             db 1, 1, 27
             db 1, 1, 26
             db 2, 1, 20
             db 1, 1, 21
             db 2, 1, 17
             melody8_len = $ - melody8


    int1coff = 08h * 04h
    int9off = 09h * 04h
           ; C     C#    D     D#    E     F     F#    G     G#    A     A#    B
    notes dw 9121, 8609, 8126, 7670, 7239, 6833, 6449, 6087, 5746, 5423, 5119, 4831
          dw 4560, 4304, 4063, 3834, 3619, 3416, 3224, 3043, 2873, 2711, 2559, 2415
          dw 2280, 2152, 2031, 1917, 1809, 1715, 1612, 1521, 1436, 1355, 1292, 1207
          dw 1140, 1076, 1016, 959,  905,  854,  806,  760,  718,  678,  640,  604
          dw 18242, 17218, 16251, 15340, 14479, 13666, 12899, 12175, 11492, 10847, 10238, 9664

    ticks_in_q dw 0
    ticks_wait dw 0
    timer_counter = 23864
    frequency = 50
    read dw 0
    melody dw 0
    melody_len dw 0
    buflen = 20h
    buffer db buflen dup(0)
    endbuf:
    head dw buffer
    tail dw buffer

    next9 dw ?, ?
    next1c dw ?, ?

begin proc
    mov al, 0b6h
    out 43h, al

    cli
    xor ax, ax
    mov es, ax
    mov al, 34h
    out 43h, al
    mov al, timer_counter - (timer_counter / 256) * 256
    out 40h, al
    mov al, timer_counter / 256
    out 40h, al
    mov bx, word ptr es:int1coff+2
    mov next1c+2, bx
    mov bx, word ptr es:int1coff
    mov next1c, bx
    mov word ptr es:int1coff+2, ds
    mov word ptr es:int1coff, offset int1c
    mov bx, word ptr es:int9off+2
    mov next9+2, bx
    mov bx, word ptr es:int9off
    mov next9, bx
    mov word ptr es:int9off+2, ds
    mov word ptr es:int9off, offset int9
    mov ax, cs
    mov es, ax
    sti

handler:
    hlt
    call read_buf
    jc handler
    cmp al, 0ffh
    je @@shutup
    cmp al, 0feh
    je @@bye
    cmp al, 00h
    jne @@play
    in al, 61h
    and al, 0fch
    out 61h, al
    jmp handler
@@play:
    mov bl, al
    in al, 61h
    or al, 03h
    out 61h, al
    mov al, bl
    mov ah, 00h
    mov bl, 02h
    mul bl
    lea si, notes
    add si, ax
    lodsw
    out 42h, al
    mov al, ah
    out 42h, al

    jmp handler
@@shutup:
    in al, 61h
    and al, 0fch
    out 61h, al
    jmp handler

@@bye:
    cli
    xor ax, ax
    mov es, ax
    mov bx, next1c
    mov word ptr es:int1coff, bx
    mov bx, next1c+2
    mov word ptr es:int1coff+2, bx
    mov bx, next9
    mov word ptr es:int9off, bx
    mov bx, next9+2
    mov word ptr es:int9off+2, bx
    mov ax, cs
    mov es, ax
    sti
    ret
begin endp

; в al входной код
write_buf proc
    push bx
    mov bx, cs:head
    mov cs:[bx], al
    mov ax, bx
    inc word ptr cs:head
    cmp word ptr cs:head, offset endbuf
    jne @@no_overflow
    mov cs:head, offset buffer
@@no_overflow:
    mov bx, cs:head
    cmp bx, cs:tail
    jne @@bye
    mov cs:head, ax
@@bye:
    pop bx
    ret
write_buf endp

; в al считанное значение
read_buf proc
    mov bx, cs:tail
    cmp bx, cs:head
    jne @@read
    stc ; буфер пуст
    ret
@@read:
    mov al, cs:[bx]
    inc word ptr cs:tail
    cmp word ptr cs:tail, offset endbuf
    jne @@no_overflow
    mov word ptr cs:tail, offset buffer
@@no_overflow:
    clc
    ret
read_buf endp

int9 proc
    cli
    push ax
    push si
    push dx
    in al, 60h
    mov ah, al
    in al, 61h
    or al, 80h
    out 61h, al
    and al, 7fh
    out 61h, al
    mov al, 20h
    out 20h, al

    cmp ah, 01h
    jne @@1
    mov al, 0ffh
    call write_buf
    mov ax, melody
    cmp ax, 00h
    jne @@2
    mov al, 0feh
    call write_buf
    jmp @@bye
@@2:
    mov melody, 00h
    jmp @@bye
@@1:
    lea si, scan_to_song
@@search:
    lodsb
    cmp al, 0ffh
    je @@bye
    cmp ah, al
    je @@found
    add si, 3
    jmp @@search
@@found:
    lodsb
    lodsw
    mov bx, melody
    cmp ax, bx
    je @@bye
    mov si, ax
    mov melody, ax
    lodsw
    mov melody_len, ax
    lodsw
    mov si, ax
    mov ax, frequency*60
    xor dx, dx
    div si
    mov ticks_in_q, ax
    mov read, 4
    mov ticks_wait, 0
    mov chord_pos, 2
    mov chord_len, 0
@@bye:
    pop dx
    pop si
    pop ax
    sti
    iret
int9 endp

scan_to_song:
    dw 2, melody0
    dw 3, melody1
    dw 4, melody2
    dw 5, melody3
    dw 6, melody4
    dw 7, melody5
    dw 8, melody6
    dw 9, melody8
    dw 0ffffh

chord_pos dw 2
chord_len dw 0

int1c proc
    cli
    mov bx, melody
    cmp bx, 00h
    je @@no_song
    mov ax, ticks_wait
    cmp ax, 00h
    jne @@1
    mov si, bx
    mov ax, read
    mov bx, melody_len
    cmp ax, bx
    jne play
    mov al, 0ffh
    call write_buf
    mov melody, 00h
    jmp @@no_song
@@1:
    inc chord_pos
    mov ax, chord_pos
    mov bx, chord_len
    cmp ax, bx
    jne @@2
    mov ax, 2
    mov chord_pos, ax
@@2:
    mov si, melody
    add si, read
    sub si, chord_len
    add si, ax
    lodsb
    call write_buf
    jmp bye
play:
    mov chord_pos, 2
    add si, ax
    push ax

    lodsb
    xor bx, bx
    xor dx, dx
    mov bl, al
    mov ax, ticks_in_q
    div bx
    inc ax
    mov ticks_wait, ax
    lodsb
    mov ah, 0
    add al, 2
    mov chord_len, ax
    lodsb
    call write_buf

    pop ax
    add ax, chord_len
    mov read, ax
bye:
    dec ticks_wait
@@no_song:
    mov al, 20h
    out 20h, al
    sti
    iret
int1c endp

end main
