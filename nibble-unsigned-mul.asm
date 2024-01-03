;
; PEX3.asm
;
; Created: 9/16/2023 11:51:14 AM
; Author : tuan minh
;


; Replace with your application code
			LDI R16, 0x00	
			OUT DDRA, R16	; Input A
			LDI R16, 0xFF	; Output B
			OUT DDRB, R16
			OUT PORTA, R16	; Pull-up config.
			
			LDI R17, 0x00	; Initialize low nibble holder
REWIND:		LDI R18, 0x04 	; Initialize shift counter
			IN R16, PINA
			COM R16			; Pull-up config.
			MOV R17, R16	; R17 holds the same content as R16
			ANDI R17, 0x0F	; R17 now holds low nibble of R16
HIGH_NIB:	LSR R16 
			DEC R18
			BRNE HIGH_NIB	; Done high nibble extraction

			MUL R17, R16
			OUT PORTB, R0

			RJMP REWIND

