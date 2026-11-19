BITS 16
ORG 7C00h
	
	xor bx, bx
	mov es, bx

boot:
	mov ah, 02h
	mov al, 02h		;Parametro para ler 2 setores
	mov ch, 00h
	mov cl, 02h
	mov dh, 00h
	mov bx, 7E00h
	int 13h
	jmp 7E00h
	
times 510-($-$$) db 0
dw 0xAA55