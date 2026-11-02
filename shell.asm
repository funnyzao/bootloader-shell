;------------Pré processamento------------
BITS 16
ORG 0x7c00
BUFF equ 8000h
;-----------------------------------------

;------------------Código-----------------
inicio:
	xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	mov ds, ax
	mov di, BUFF
	mov si, mensagem
	call printString
	
loop:
	mov ah, 00h			;Função da bios para leitura de caracter
	int 16h				;Interrupção da bios para leitura de caracter
	
	;Espera caracter ser pressionado
	
	call read
	jmp loop
	
read:
	cmp al, 0Dh			;Verifica se a tecla pressionada foi enter
	je enter
	cmp al, 08h			;Verifica se a tecla pressionada foi backspace
	je backspace
	
	call printChar
	ret
	
enter:
	mov ah, 0Eh
	int 10h
	mov al, 0Ah
	int 10h
	
	call endBuffer
	jmp inicio

backspace:
	call getCursor
	call decBuffer
	
	mov ah, 0Eh
	mov al, 08h			;Volta o cursor novamente
	int 0x10
	mov al, ' '			;Coloca o caracter 'espaço'
	int 10h
	mov al, 08h			;Volta o cursor novamente
	int 10h
	
	jmp loop
	
printString:
	mov al, [si]
	cmp al, 00h
	jne seguir
	ret
	seguir:
		inc si
		mov ah, 0Eh
		int 10h
		jmp printString
	
printChar:
	call buffer
	mov ah, 0Eh
	int 10h
	ret
	
getCursor:
	mov ah, 03h
	mov bh, 00h
	int 10h
	cmp dl, 06h
	jbe loop
	ret

buffer:
	mov [di], al
	inc di
	ret
	
decBuffer:
	cmp di, BUFF
	jg true
	ret
	true:
		dec di
		ret
		
endBuffer:
	mov [di], 0
	mov di, BUFF
	call compare
	ret
	
compare:
	mov si, comandos
	mov si, [si]
	xor cx, cx
		loop1:
			mov al, [si]
			mov bl, [di]
			cmp al, bl
			jne next
			inc si
			inc di
			cmp bl, 0
			je decider
			jmp loop1

next:
	mov di, BUFF
	mov ax, 2
	inc cx
	mul cx
	mov si, comandos
	add si, ax
	mov si, [si]
	cmp [si], 0
	je notEqual
	jmp loop1
	
notEqual:
	mov si, comandoInvalido
	call printString
	
	mov al, 0Dh
	mov ah, 0Eh
	int 10h
	mov al, 0Ah
	int 10h
	
	ret
	
decider:
	cmp cx, 0
	je rebootComand
	cmp cx, 1
	je waitComand
	
rebootComand:
	xor ax, ax
	int 19h
	
waitComand:
	mov ah, 86h
	mov cx, 004Ch
	mov dx, 4B40h
	int 15h
	jmp inicio
	
;-----------------------------------------

;-----------------Variáveis---------------
mensagem db "shell>", 0
reboot db "reboot", 0
waitt db "wait", 0
comandoInvalido db "Comando invalido", 0
comandos:
	dw reboot
	dw waitt

times 510-($-$$) db 0
dw 0xAA55