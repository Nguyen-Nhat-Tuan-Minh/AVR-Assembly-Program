;
; pe21_ex3.asm
;
; Created: 10/1/2023 9:25:58 AM
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
		LDI R16, (1 << COM0B1)|(1 << COM0A1) | (1 << WGM00)|(1 << WGM01)
		OUT TCCR0A, R16 ; setup TCCR0A
		LDI R16, (1 << CS01)
		OUT TCCR0B, R16 ; setup TCCR0B
		LDI R16, 100
		OUT OCR0A, r16 ; OCRA = 100
		LDI R16, 75
		OUT OCR0B, R16 ; OCRB = 75
		RET
