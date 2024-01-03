;
; PEX12_EX2.asm
;
; Created: 9/17/2023 6:33:37 PM
; Author : tuan minh
;


; Replace with your application code	
MAIN:	SBI DDRA, 0
		SBI PORTA, 0
		CALL DELAY1s
		CBI PORTA, 0
		CALL DELAY1s
		RJMP MAIN

DELAY1s:
		LDI R16,100
LOOP_1:	LDI R17,100
LOOP_2:	LDI R18,100
LOOP_3:	NOP				; 1C
		DEC R18			; 2C
		BRNE LOOP_3		; 2C
		DEC R17
		BRNE LOOP_2
		DEC R16
		BRNE LOOP_1
		RET

		
