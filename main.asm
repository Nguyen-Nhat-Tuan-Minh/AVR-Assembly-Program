;
; pe3_ex1.asm
;
; Created: 10/23/2023 4:29:21 PM
; Author : tuan minh
;


; Replace with your application code
.ORG $0
.DEF TEMP = R16

		JMP MAIN

.ORG $001E
		JMP TIM1_OVF

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAIN:
		LDI TEMP, 0x01
		OUT DDRC, TEMP
		LDI TEMP, (1 << TOIE1)
		STS TIMSK1, TEMP
		SEI
		LDI TEMP, 0xF0
		STS TCNT1H, TEMP
		LDI TEMP, 0x61
		STS TCNT1L, TEMP
		CLR TEMP
		STS TCCR1A, TEMP
		LDI TEMP, 0x01
		STS TCCR1B, TEMP

HERE:
		RJMP HERE

TIM1_OVF:
		IN TEMP, PORTC
		COM TEMP
		OUT PORTC, TEMP
		LDI TEMP, 0xF0
		STS TCNT1H, TEMP
		LDI TEMP, 0x61
		STS TCNT1L, TEMP
		RETI


		

		
