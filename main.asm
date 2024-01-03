;
; TEST1.asm
;
; Created: 9/16/2023 8:46:20 PM
; Author : tuan minh
;


; Replace with your application code
.include "m324PAdef.inc"
.org	0
	ldi r16,0x01
	out	DDRA, r16
start:
       sbi	PORTA,PINA0
       cbi	PORTA, PINA0
       rjmp start
		  

	sbic pina, 0
	
