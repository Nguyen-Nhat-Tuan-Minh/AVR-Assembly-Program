;
; pe21_ex4.asm
;
; Created: 10/2/2023 12:15:44 PM
; Author : tuan minh
;


; Replace with your application code
.ORG 0
		CALL INITTIMER0

START:
		RJMP START

INITTIMER0:
		; Set OC0A (PB3) and OC0B (PB4) pins as outputs
		LDI R16, (1 << PB3) | (1 << PB4);
		OUT DDRB, R16
		; UNCOMMENT THE DESIRED CASE
		;LDI R16, (1 << COM0B1) | (1 << COM0A1) | (1 << WGM00) | (1 << WGM01) ; case 0
		;LDI R16, (1 << COM0B1) | (1 << COM0A1) | (1 << WGM00) | (1 << WGM01) ; case 1
		LDI R16, (1 << COM0B1) | (1 << COM0A1) | (1 << WGM00) ; case 2
		OUT TCCR0A, R16 ; setup TCCR0A
		;LDI R16, (1 << CS01) ; case 0
		;LDI R16, (1 << WGM02) | (1 << CS01) ; case 1
		LDI R16, (1 << CS01) ; case 2
		OUT TCCR0B, R16 ; setup TCCR0B
		LDI R16, 100
		OUT OCR0A, r16 ; OCRA = 100
		LDI R16, 75
		OUT OCR0B, R16 ; OCRB = 75
		RET

