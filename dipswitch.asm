;
; PEX1.asm
;
; Created: 9/16/2023 10:19:59 AM
; Author : tuan minh
;


; Replace with your application code
		LDI R16, 0x00
		OUT DDRB, R16 ; Configure input portB
		OUT PORTC, R16
		LDI R16, 0xFF
		;LDI R18, 5
		OUT PORTB, R16
		OUT DDRC, R16
		;OUT DDRB, R16 ; Configure output portC
		LDI R16, 0x01
		LDI R17, 0x02
SW1:	
		SBIC PINB, 0
		RJMP SW2
		;IN R16, PINA
		;COM R16
		;ADD R16, R18
		OUT PORTC, R16
		RJMP SW1

SW2:
		SBIC PINB, 1
		RJMP SW1
		OUT PORTC, R17
		RJMP SW2 

