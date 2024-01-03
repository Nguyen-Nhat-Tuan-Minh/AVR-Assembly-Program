;
; PEX5.asm
;
; Created: 9/16/2023 8:07:56 PM
; Author : tuan minh
;


; Replace with your application code
		CBI DDRA, 0
		SBI PORTA, 0
		SBI DDRA, 1
MAIN:		SBIC PINA, 0
		RJMP ON
		SBI PORTA, 1
		RJMP MAIN
ON:		CBI PORTA, 1
		RJMP MAIN

