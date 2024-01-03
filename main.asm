;
; PEX4.asm
;
; Created: 9/16/2023 2:31:56 PM
; Author : tuan minh
;


; Replace with your application code
		LDI R16, 0xFF
		OUT DDRB, R16	; Config output B
		OUT PORTA, R16
		LDI R16, 0x00
		OUT DDRA, R16

MAIN:	IN R16, PINA
		COM R16
		LDI R19, 0x0F
		AND R19, R16	; R19 holds low nibble of PINA
		LDI R20, 0x04

SHIFT:	LSR R16 
		DEC R20
		BRNE SHIFT		; R16 holds high nibble of PINA

		SBRC R16, 3		; Test sign of high nibble
		RJMP SIGN_H	
		LDI R17, 0x00	; Initialize positive sign
		RJMP NEXT
SIGN_H:	LDI R17, 0xF0	; Initialize negative sign

NEXT:	SBRS R19, 3		; Test sign of low nibble
		RJMP SIGN_L
		LDI R18, 0xF0
		RJMP MULT
SIGN_L:	LDI R18, 0x00
		
	
MULT:	OR R16, R17		; Extend sign
		OR R19, R18		; Extend sign
		MULS R16, R19
		OUT PORTB, R0
		RJMP MAIN



