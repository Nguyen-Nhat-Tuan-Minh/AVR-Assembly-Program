;
; PEX2.asm
;
; Created: 9/16/2023 10:52:35 AM
; Author : tuan minh
;


; Replace with your application code
		LDI R16, 0xFF 	; Initialize R16 for addition
		OUT DDRB, R16
		LDI R16, 0x00
		OUT DDRA, R16	; Done configuration of in/out port
		LDI R17, 0x05
SAMPLE: IN R16, PINA
		ADD R16, R17
		OUT PORTB, R16
		RJMP SAMPLE

