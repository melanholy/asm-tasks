.model tiny

.code
	org 100h
program:
	jmp start

	input dw 1dh
	result dw 01h, 00h, 00h, 00h, 00h, 00h, 00h, 00h
	sz dw sz - result

printm proc
	mov cl, 0ch
	mov ah, 02h
printwordloop:
	mov dx, [bx]    ; помещаем чиселку на вывод
	shr dx, cl    ; сдвигаем в младший байт интересующую нас циферку
	and dl, 0fh   ; убираем байты старше младшего
	cmp dl, 0ah
	jl digit
	add dl, 07h
digit:
	add dl, 30h
	int 21h

	sub cl, 04h
	jns printwordloop

	ret
printm endp

fact proc
	mov bx, [sz]
	sub bx, 02h
	mulloop:
		mov ax, [result + bx] ; получаем умножаемое слово
		mul cx
		mov [result + bx], ax
		jnc nocarry
		push bx
	carry: ; если результат больше слова, делаем перенос
		add bx, 02h
		add [result + bx], dx
		mov dx, 01h
		jc carry
		pop bx
	nocarry:
		sub bx, 02h
		jns mulloop
	dec cx
	jz endfac
	call fact
endfac:
	ret
fact endp

start:
	mov cx, [input]
	call fact

	mov bx, [sz]
	sub bx, 02h
printresloop:
	add bx, offset result
	call printm
	sub bx, offset result + 02h
	jns printresloop

	ret
end program
