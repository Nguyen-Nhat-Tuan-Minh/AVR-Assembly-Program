;
; pe22_ex1.asm
;
; Created: 10/2/2023 11:02:23 PM
; Author : tuan minh
;


; Replace with your application code
.EQU SEG7LATCHPORT = PORTB
.EQU SEG7LATCHDDR = DDRB
.EQU SEG7DATAPORT = PORTD
.EQU SEG7DATADDR = DDRD
.DEF TEMP = R16
.DEF TIMEREG0 = R22
.DEF TIMEREG1 = R21
.EQU NLE0 = 0 ; LATCH SIGNAL DATA
.EQU NLE1 = 1 ; LATCH SIGNAL LED

MAIN:
		CALL LEDINIT

LOOP:
		CALL LED_SCAN
		CALL LED_DISPLAY
		CALL DELAYT1_5ms
		INC TEMP
		CPI TEMP, 4
		BREQ MAIN
		RJMP LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LEDINIT:
		LDI TEMP, 0xFF
		OUT SEG7DATADDR, TEMP ; CONFIGURE DATA OUTPUT PORTD 
		LDI TEMP, 0x03
		OUT SEG7LATCHDDR, TEMP ; CONFIGURE LATCH OUTPUT PORTB 
		LDI TEMP, 0xFF
		OUT SEG7DATAPORT, TEMP
		LDI ZH, HIGH(SEG7DATA << 1) ; GET LED DATA 
		LDI ZL, LOW(SEG7DATA << 1) ; GET LED DATA
		LDI TEMP, 0
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LED_DISPLAY:
		ADD ZL, TEMP
		LPM R17, Z
		SUB ZL, TEMP
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
		MOV R18, TEMP
		INC R18
		LDI R20, 0xFF
		CLC ; CLEAR C FLAG 
SCAN_LOOP:
		ROL R20 ; D7 <- D0 <- (C = 0)
		DEC R18
		BRNE SCAN_LOOP
		RET 

SEG7DATA: 
.DB 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90, 0x88, 0x83, 0xC6, 0xA1, 0x86, 0x8E
; VALUE TABLE FOR 7 SEGMENT 0 - F

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SDELAY:
		NOP
		NOP
		RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAYT1_5ms:
		LDI TIMEREG0, 0b00001011 ; CTC MODE, PRESCALER CLK/64
		STS TCCR1B, TIMEREG0
		LDI TIMEREG1, 0x02
		LDI TIMEREG0, 0x71
		STS OCR1AH, TIMEREG1
		STS OCR1AL, TIMEREG0
		CLR TIMEREG1
		STS TCNT1H, TIMEREG1
		STS TCNT1L, TIMEREG1

DELAYT1_5ms_LOOP:
		SBIS TIFR1, OCF1A
		RJMP DELAYT1_5ms_LOOP
		SBI TIFR1, OCF1A ; RESET TIMER1
		RET