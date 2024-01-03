;
; pe3_ex3.asm
;
; Created: 10/23/2023 6:55:52 PM
; Author : tuan minh
;


; Replace with your application code
.ORG 0
.EQU SEG7LATCHPORT = PORTB
.EQU SEG7LATCHDDR = DDRB
.EQU SEG7DATAPORT = PORTD
.EQU SEG7DATADDR = DDRD
.DEF TEMP = R16
.DEF SEGMENT = R22
.EQU NLE0 = 0 ; LATCH SIGNAL DATA
.EQU NLE1 = 1 ; LATCH SIGNAL LED

		RJMP MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.ORG $001A
TIMER1_COMPA:
		IN TEMP, PORTC
		COM TEMP
		OUT PORTC, TEMP
		LDS TEMP, $08FD ; MANIPULATE INTERRUPT RETURN ADDRESS
		INC TEMP
		STS $08FD, TEMP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAIN:
		CALL LEDINIT

LOOP:
		CALL LED_SCAN
		CALL LED_DISPLAY
		CALL INT_5ms
		INC SEGMENT
		CPI SEGMENT, 4
		BREQ MAIN
		RJMP LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LEDINIT:
		SBI DDRC, 0
		LDI SEGMENT, 0xFF
		OUT SEG7DATADDR, SEGMENT ; CONFIGURE DATA OUTPUT PORTD 
		LDI SEGMENT, 0x03
		OUT SEG7LATCHDDR, SEGMENT ; CONFIGURE LATCH OUTPUT PORTB 
		LDI SEGMENT, 0xFF
		OUT SEG7DATAPORT, SEGMENT
		LDI ZH, HIGH(SEG7DATA << 1) ; GET LED DATA 
		LDI ZL, LOW(SEG7DATA << 1) ; GET LED DATA
		LDI SEGMENT, 0
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LED_DISPLAY:
		ADD ZL, SEGMENT
		LPM R17, Z
		SUB ZL, SEGMENT
		OUT SEG7DATAPORT, R17
		SBI SEG7LATCHPORT, NLE0 ; SET LATCH TO START RETAIN DATA
		CALL SDELAY
		CBI SEG7LATCHPORT, NLE0 ; CLEAR LATCH TO FINISH RETAIN DATA
		OUT SEG7DATAPORT, R20 ; CHOOSE LED TO DISPLAY
		SBI SEG7LATCHPORT, NLE1
		CALL SDELAY
		CBI SEG7LATCHPORT, NLE1
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LED_SCAN:
		MOV R18, SEGMENT
		INC R18
		LDI R20, 0xFF
		CLC ; CLEAR C FLAG 

SCAN_LOOP:
		ROL R20 ; D7 <- D0 <- (C = 0)
		DEC R18
		BRNE SCAN_LOOP
		RET 

SEG7DATA:
.DB 0x99, 0xB0, 0xA4, 0xF9 
; VALUE TABLE FOR 7 SEGMENT 1 - 4

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SDELAY:
		NOP
		NOP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INT_5ms:
		LDI TEMP, (1 << OCIE1A)
		STS TIMSK1, TEMP
		SEI
		LDI TEMP, 0
		STS TCCR1A, TEMP
		LDI TEMP, (1 << WGM12) | (1 << CS11) ; CTC, TOP = OCR1A, CLK/8
		STS TCCR1B, TEMP
		LDI TEMP, 0x13
		STS OCR1AH, TEMP
		LDI TEMP, 0x88
		STS OCR1AL, TEMP

 STAY:
		RJMP STAY
		RET

