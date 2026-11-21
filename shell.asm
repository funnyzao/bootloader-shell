;------------Pré processamento------------
BITS 16
ORG 7E00h
BUFF equ 9000h

	cli
	xor bx, bx
	mov ss, bx
	mov sp, 5000h
	sti
	
;-----------------------------------------

;------------------Código-----------------
inicio:
	xor ax, ax			;Prepara todos os registradores para a execução
	xor bx, bx			;do programa
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
	
	call printChar		;Função para printar o caracter pressionado
	call buffer			;Função para armazenar no buffer
	ret
	
enter:
	call newLine
	call endBuffer
	jmp inicio
	
newLine:
	mov ah, 0Eh
	mov al, 0Dh
	int 10h
	mov al, 0Ah
	int 10h
	ret

backspace:
	call getCursor
	call decBuffer
	
	mov ah, 0Eh
	mov al, 08h			;Volta o cursor
	int 0x10
	mov al, ' '			;Coloca o caracter 'espaço'
	int 10h
	mov al, 08h			;Volta o cursor novamente
	int 10h
	jmp loop
	
printString:
	mov al, [si]		;Coloca o caracter de [si] em al
	cmp al, 00h			;Compara com 00h para saber se chegou ao fim
	jne seguir			;Se nao chegou, pular ao loop para imprimir
	ret
	seguir:
		inc si			;Aumenta o endereço de si para o proximo caracter
		mov ah, 0Eh
		int 10h
		jmp printString
	
printChar:
	mov ah, 0Eh
	int 10h
	ret
	
getCursor:
	mov ah, 03h			;Pega a posição do cursor
	mov bh, 00h
	int 10h
	cmp dl, 06h			;Compara com 06h, para nao sobreescrever o texto do shell
	jbe loop
	ret

buffer:
	mov [di], al		;Pega o conteudo de al e joga no conteudo apontado por di
	inc di				;Aumenta di o endereço de di para o próximo caracter
	
	ret
	
decBuffer:
	cmp di, BUFF		;Compara o endereço de di com o endereço de BUFF
	jg true				;para saber se está na primeira posição de di
	ret
	
	true:
		dec di			;Decrementa o endereço de di a fim de retornar um
		ret				;caracter
		
endBuffer:
	mov [di], 0			;Termina o texto escrito com 0
	mov di, BUFF		;Volta ao inicio do endereço
	call compare		;Chama função para comparar com os comandos
	ret
	
compare:
	mov si, comandos	;Inicializa a função de comparação
	mov dx, si
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
			;jmp loop1
			cmp bl, 20h
			je decider
			jmp loop1

next:
	mov di, BUFF
	mov ax, 4
	inc cx
	mul cx
	mov si, comandos
	add si, ax
	mov dx, si
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
	add dx, 2
	mov si, dx
	jmp [si]
	
rebootComand:
	xor ax, ax
	int 19h
	jmp inicio
	
waitComand:
	mov ah, 86h
	mov cx, 004Ch
	mov dx, 4B40h
	int 15h	
	jmp inicio
	
clearComand:
	mov ah, 06h       	; scroll up
	mov al, 00h       	; 0 = limpa toda a janela
	mov bh, 07h       	; atributo: fundo preto, texto cinza
	mov ch, 00h       	; linha inicial
	mov cl, 00h       	; coluna inicial
	mov dh, 24        	; última linha
	mov dl, 79        	; última coluna
	int 10h
	
	mov ah, 02h
	mov bh, 00h
	mov dh, 00h
	mov dl, 00h
	int 10h
	jmp inicio
	
versionComand:
	mov si, versionText
	call printString
	jmp inicio
	
helpComand:
	mov si, helpText
	call printString
	call newLine
	jmp inicio
	
echoComand:
	mov si, BUFF
	add si, 5
	call printString
	call newLine
	jmp inicio
	
dateComand:
	mov ah, 04h
	int 1Ah				;ch=seculo, cl=ano, dh=mes, dl=dia
	
	mov al, dl
	call bcdPrinter		;Printar dia
	mov ax, '/'
	call printChar
	mov al, dh
	call bcdPrinter		;Printar mes
	mov ax, '/'
	call printChar
	mov al, ch
	call bcdPrinter		;Printar seculo
	mov al, cl
	call bcdPrinter		;Printar ano
	call newLine
	jmp inicio
	
bcdPrinter:
	push ax
	shr al, 4
	add al, '0'
	call printChar
	
	pop ax
	and al, 0Fh
	add al, '0'
	call printChar
	
	ret
	
	
;-----------------------------------------

;-----------------Variáveis---------------
mensagem db "shell>", 0
reboot db "reboot", 0
waitt db "wait", 0
clear db "clear", 0
version db "version", 0
help db "help", 0
echo db "echo", 20h, 0
date db "date", 0

helpText db 0Ah, "reboot - reinicia o sistema", 0Dh, 0Ah
		 db "wait - espera de 5 segundos", 0Dh, 0Ah
		 db "clear - limpa todo o texto", 0Dh, 0Ah
		 db "echo - digita o texto passado por parametro", 0Dh, 0Ah
		 db "date - exibe a data atual", 0Dh, 0Ah
		 db "version - mostra a versao do shell", 0Dh, 0Ah, 0
		 
comandoInvalido db "Comando invalido, digite help para ajuda", 0
versionText db "versao 1.0 100% atualizado", 0Dh, 0Ah, 0

comandos:
	dw reboot, rebootComand
	dw waitt, waitComand
	dw clear, clearComand
	dw help, helpComand
	dw version, versionComand
	dw echo, echoComand
	dw date, dateComand
	dw 0, 0

times 1024-($-$$) db 0