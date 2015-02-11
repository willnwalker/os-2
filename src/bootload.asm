	BITS 16

start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288		; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax

	mov ah, 0Bh			; White text on blue background
	mov bh, 00h
	mov bl, 00000001b
	int 10h

	call clear_screen
	
	mov si, text_border	; Put border position into SI
	call print_string	; Call our string-printing routine
	mov si, text_string	; Put string position into SI
	call print_string	; Call our string-printing routine
	mov si, text_border	; Put border position into SI
	call print_string	; Call our string-printing routine
	
	jmp $			; Jump here - infinite loop!


	text_string db 'This is my cool new OS!', 10, 13, 0
	text_border db '--------------------------------------------------------------------------------', 0

clear_screen:
	pusha
	
	mov dx, 0	; Move cursor to top left of screen (TTY mode of course)
	mov bh, 0
	mov ah, 2
	int 10h
	
	mov ah, 6	; Int10h scroll function- used to clear screen
	mov al, 0 
	mov bh, 7
	mov cx, 0
	mov dh, 24
	mov dl, 79
	int 10h
	
	popa
	ret
	
.done:
	ret
	
print_string:			; Routine: output string in SI to screen
	mov ah, 0Eh		; int 10h 'print char' function

.repeat:
	lodsb			; Get character from string
	cmp al, 0
	je .done		; If char is zero, end of string
	int 10h			; Otherwise, print it
	jmp .repeat

.done:
	ret


	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature
