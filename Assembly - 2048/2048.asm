.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date

matrix DD 0,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

i DD 0
j DD 0

window_title DB "2048",0
area_width EQU 800
area_height EQU 600
area DD 0
x DD 0
aux DD 0
aux2 DD 0

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20
arg5 EQU 24
arg6 EQU 28
arg7 EQU 32
arg8 EQU 36
ok DD 0

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

.code
make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ;
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0FFFFFFh
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm


draw_number proc ; void draw_number( number, x, y)
	push ebp
	mov ebp, esp
	
	mov eax, [ebp + 8]
	mov ecx, 10
	mov ebx, [ebp + 12]
	
	cmp eax, 0
	je zero
div10:
	xor edx, edx
	div ecx
	add edx, '0'
	make_text_macro edx, area, ebx, [ebp + 16]
	sub ebx, 10
	cmp eax, 0
	jg div10
	jmp fn
	zero:
	make_text_macro '.', area, ebx, [ebp + 16]
	fn:
	mov esp, ebp
	pop ebp
	ret 12
draw_number endp

draw_number_macro macro number, x, y
	push y
	push x
	push number
	call draw_number
endm

find proc
	push ebp
	mov ebp, esp
	mov aux2, ecx
	mov ecx, [ebp + arg5]
	mov ebx, [ebp + arg1]
	add ebx, [ebp + arg2]
	mov edx, matrix[eax]
	cmp edx, 0
	jne cauta
	
	cauta_2:
	add ebx, [ebp + arg3]
	add ebx, [ebp + arg4]
	mov edx, matrix[ebx]
	cmp edx, 0
	jg found2
	dec ecx
	cmp ecx, 0
	jg cauta_2
	jmp done

	found2:
	mov edx, matrix[eax]
	add edx, matrix[ebx]
	mov matrix[eax], edx
	mov edx, 0
	mov matrix[ebx], edx
	inc ok
	
	dec ecx
	cmp ecx, 0
	je done
	
	cauta:
	add ebx, [ebp + arg3]
	add ebx, [ebp + arg4]
	mov edx, matrix[ebx]
	cmp edx, matrix[eax]
	je found
	dec ecx
	cmp ecx, 0
	jg cauta
	
	jmp done

	found:
	mov ecx, matrix[eax]
	add ecx, matrix[ebx]
	mov matrix[eax], ecx
	mov ecx, 0
	mov matrix[ebx], ecx
	inc ok

	done:
	mov ecx, aux2
	mov esp, ebp
	pop ebp
	ret 20
find endp

find_m macro z, q, a, b, pasi
	push pasi
	push b
	push a
	push q
	push z
	call find
endm

parcurgere proc ;macro x, y, first_i, first_j, second_i, second_j , start_i, start_j
	push ebp
	mov ebp, esp
	mov eax, [ebp + arg1]
	mov i, eax
	mov eax, [ebp + arg2]
	mov j, eax
	mov ecx, 4
first:
	mov aux, ecx
	mov ecx, 3
	second:
		mov eax, j
		add eax, i
		mov ebx, ok
		;cmp ebx, 1
		;je stoop
		;mov matrix[4], eax
		;add edx, 4
		;mov matrix[edx], eax
		find_m i, j, [ebp + arg5], [ebp + arg6], ecx
		mov ebx, i
		add ebx, [ebp + arg5]
		mov i, ebx
		mov ebx, j
		add ebx, [ebp + arg6]
		mov j, ebx
		dec ecx
		cmp ecx, 0
		jg second
	mov ebx, i
	add ebx, [ebp + arg3]
	mov i, ebx
	mov ebx, j
	add ebx, [ebp + arg4]
	mov j, ebx
	mov ecx, aux

	mov eax, [ebp + arg7]
	cmp eax, -1
	je nu1
	mov ebx, [ebp + arg7]
	mov i, ebx
	nu1:

	mov eax, [ebp + arg8]
	cmp eax, -1
	je nu2
	mov ebx, [ebp + arg8]
	mov j, ebx
	nu2:
	dec ecx
	cmp ecx, 0
	jg  first
	stoop:
	mov esp, ebp
    pop ebp
	ret 32
parcurgere endp

parcurgere_m macro x, y, first_i, first_j, second_i, second_j , start_i, start_j
	push start_j;
	push start_i;
	push second_j;
	push second_i;
	push first_j;
	push first_i;
	push y;
	push x;
	call parcurgere;
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	mov ok, 0
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	xor edx, edx
	jmp final_draw
evt_click:
	xor edx, edx
	mov eax, [ebp + arg2]
	cmp eax, 110
	jl stanga
	cmp eax, 660
	jg dreapta
	mov eax, [ebp + arg3]
	cmp eax, 140
	jl sus
	cmp eax, 450
	jg jos
	jmp final_draw


stanga:
	parcurgere_m 0, 4, 16, 0, 0 , 4, -1, 4
jmp final_draw

dreapta:
	parcurgere_m 0, 16, 16, 0, 0 , (-4), -1, 16
jmp final_draw
	

sus:
	parcurgere_m 0, 4, 0, 4, 16 , 0, 0, -1
jmp final_draw


jos:
	parcurgere_m 48, 4, 0, 4, -16 , 0, 48, -1

final_draw:

	mov eax, ok
	cmp eax, 0
	je noup
	mov ecx, 4
	mov ebx, 16
	;generam numar random 0-15 in eax
	mul eax
	xor eax, ebx
	xor eax, ecx
	and eax, 15
	mul ecx
	full:
	add eax, 4
	cmp eax,68
	jne	dute
	mov eax, 4
	dute:
	cmp matrix[eax], 0
	jne full
	mov matrix[eax], 2
noup:
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 255
	push area
	call memset
	add esp, 12
	draw_number_macro matrix[4], 140, 140
	draw_number_macro matrix[8], 310, 140
	draw_number_macro matrix[12], 480, 140
	draw_number_macro matrix[16], 650, 140
	
	draw_number_macro matrix[20], 140, 240
	draw_number_macro matrix[24], 310, 240
	draw_number_macro matrix[28], 480, 240
	draw_number_macro matrix[32], 650, 240

	draw_number_macro matrix[36], 140, 340
	draw_number_macro matrix[40], 310, 340
	draw_number_macro matrix[44], 480, 340
	draw_number_macro matrix[48], 650, 340
	
	draw_number_macro matrix[52], 140, 440
	draw_number_macro matrix[56], 310, 440
	draw_number_macro matrix[60], 480, 440
	draw_number_macro matrix[64], 650, 440

	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	push 0
	call exit
end start
