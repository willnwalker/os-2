;====================================================================================================

;Copyright ©2015 T-DOS Developers

;====================================================================================================
	
	BITS 16

start:
	mov ax, 07C0h		; Set up 4K stack space after this bootloader
	add ax, 288			; (4096 + 512) / 16 bytes per paragraph
	mov ss, ax
	mov sp, 4096

	mov ax, 07C0h		; Set data segment to where we're loaded
	mov ds, ax			; Moving data segment to DS, using ax register

	mov ah, 0Bh			; Set background: white text on blue background
	mov bh, 00h
	mov bl, 00000001b
	int 10h

	call clear_screen	; Giving us a blank canvas!
	
	call draw_box		; Draw box at top of screen
	
	mov dh, 1
	mov dl, 1
	call move_cursor
	
	mov si, text_string	; Put string position into SI
	call print_string	; Call our string-printing routine
	
	mov dh, 3
	mov dl, 0
	
	jmp $				; Jump here - infinite loop!


	text_string db 'T-DOS 0.1', 10, 13, 0
	text_border_horizontal db 205, 0
	text_border_vertical db 186, 0 			; Vertical border
	text_border1 db 201, 0					; Top left border corner
	text_border2 db 187, 0					; Top right border corner
	text_border3 db	200, 0					; Bottom left border corner
	text_border4 db 188, 0					; Bottom right border corner
	prompt db '>', 0
	;DH-ROW 0-24
	;DL-COLUMN 0-79

	
	
	
	
;====================================================================================================
; SYSTEM CALLS	
;====================================================================================================

cli:
	mov si, prompt
	call print_string
	inc dl
	inc dl
	call input_string
	mov si, ax
	call print_string
	ret
	

;====================================================================================================

clear_screen:
	pusha
	
	mov dx, 0
	call move_cursor
	
	mov ah, 6	; Int10h scroll function- used to clear screen
	mov al, 0 
	mov bh, 7
	mov cx, 0
	mov dh, 24
	mov dl, 79
	int 10h
	
	popa
	ret
	
;====================================================================================================	
	
print_string:		; Routine: output string in SI to screen
	pusha
	mov ah, 0Eh		; int 10h 'print char' function

.repeat:
	lodsb			; Get character from string
	cmp al, 0
	je .done		; If char is zero, end of string
	int 10h			; Otherwise, print it
	jmp .repeat

.done:
	popa
	ret
;====================================================================================================

wait_key:
	pusha
	
	mov ax, 0
	mov ah, 10h
	int 16h
	
	mov [.buf], ax
	
	popa
	mov ax, [.buf]
	ret
	
	.buf dw 0

;====================================================================================================

get_pos:
	pusha

	mov bh, 0
	mov ah, 3
	int 10h				; BIOS interrupt to get cursor position

	mov [.tmp], dx
	popa
	mov dx, [.tmp]
	ret

	.tmp dw 0

;====================================================================================================

input_string:
	pusha

	mov di, ax			; DI is where we'll store input (buffer)
	mov cx, 0			; Character received counter for backspace


.more:					; Now onto string getting
	call wait_key

	cmp al, 13			; If Enter key pressed, finish
	je .done

	cmp al, 8			; Backspace pressed?
	je .backspace			; If not, skip following checks

	cmp al, ' '			; In ASCII range (32 - 126)?
	jb .more			; Ignore most non-printing characters

	cmp al, '~'
	ja .more

	jmp .nobackspace


.backspace:
	cmp cx, 0			; Backspace at start of string?
	je .more			; Ignore it if so

	call get_pos		; Backspace at start of screen line?
	cmp dl, 0
	je .backspace_linestart

	pusha
	mov ah, 0Eh			; If not, write space and move cursor back
	mov al, 8
	int 10h				; Backspace twice, to clear space
	mov al, 32
	int 10h
	mov al, 8
	int 10h
	popa

	dec di				; Character position will be overwritten by new
					; character or terminator at end

	dec cx				; Step back counter

	jmp .more


.backspace_linestart:
	dec dh				; Jump back to end of previous line
	mov dl, 79
	call move_cursor

	mov al, ' '			; Print space there
	mov ah, 0Eh
	int 10h

	mov dl, 79			; And jump back before the space
	call move_cursor

	dec di				; Step back position in string
	dec cx				; Step back counter

	jmp .more


.nobackspace:
	pusha
	mov ah, 0Eh			; Output entered, printable character
	int 10h
	popa

	stosb				; Store character in designated buffer
	inc cx				; Characters processed += 1
	cmp cx, 254			; Make sure we don't exhaust buffer
	jae near .done

	jmp near .more			; Still room for more


.done:
	mov ax, 0
	stosb

	popa
	ret

;====================================================================================================
; DH = row, 0-24
; DL = column, 0-79

move_cursor:
	pusha
	
	mov bh, 0
	mov ah, 2
	int 10h
	
	popa
	ret
;====================================================================================================

draw_box:
	pusha

	mov dx, 0	; Print top left corner
	call move_cursor
	mov si, text_border1
	call print_string
	
	mov dh, 0	; Print top right corner 
	mov dl, 79
	call move_cursor
	mov si, text_border2
	call print_string
	
	mov dh, 2	; Print bottom left corner
	mov dl, 0
	call move_cursor
	mov si, text_border3
	call print_string
	
	mov dh, 2	; Print bottom right corner
	mov dl, 79
	call move_cursor
	mov si, text_border4
	call print_string
	
	mov dh, 1	; Print left border
	mov dl, 0
	call move_cursor
	mov si, text_border_vertical
	call print_string
	
	mov dh, 1	; Print right border
	mov dl, 79
	call move_cursor
	mov si, text_border_vertical
	call print_string

.jumpup:
	xor cx, cx
	mov dh, 0
	mov dl, 1
	call move_cursor
	jmp .loop

.loop:
	cmp cx, 78
	je .jumpdown
	inc dl
	mov si, text_border_horizontal
	call print_string
	inc cx
	jmp .loop
	
.jumpdown:
	xor cx, cx
	mov dh, 2
	mov dl, 1
	call move_cursor
	jmp .loop2
	
.loop2:
	cmp cx, 78
	je .end
	inc dl
	mov si, text_border_horizontal
	call print_string
	inc cx
	jmp .loop2

.end:
	popa
	ret

;====================================================================================================
	
	times 510-($-$$) db 0	; Pad remainder of boot sector with 0s
	dw 0xAA55		; The standard PC boot signature
