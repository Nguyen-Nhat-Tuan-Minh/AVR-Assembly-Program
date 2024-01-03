;
; pe22_ex2.asm
;
; Created: 10/7/2023 3:40:12 PM
; Author : tuan minh
;


; Replace with your application code
.ORG 0
.EQU SEG7LATCHPORT = PORTB
.EQU SEG7LATCHDDR = DDRB
.EQU SEG7DATAPORT = PORTD
.EQU SEG7DATADDR = DDRD
.EQU SWITCHPORT = PORTA
.EQU SWITCHDDR = DDRA
.DEF TEMP = R16
.DEF BCD0 = R23 ; BCD DIGIT 1, 0
.DEF BCD1 = R24 ; BCD DIGIT 3, 2
.DEF COUNTER = R19
.DEF HIGHBYTE = R22
.DEF LOWBYTE = R21
.DEF OPERAND = R17
.DEF TIMEREG = R25
.EQU NLE0 = 0 ; LATCH SIGNAL DATA
.EQU NLE1 = 1 ; LATCH SIGNAL LED

MAIN:
		CALL LED_INIT

BEGIN:
		CALL READ_SWITCH
		CALL DATA_CONVERSION
		CALL DATA_INIT

LOOP:
		CALL LED_SCAN
		CALL LED_DISPLAY
		CALL DELAYT1_5ms
		INC TEMP
		CPI TEMP, 4
		BREQ BEGIN
		RJMP LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LED_INIT:
		LDI TEMP, 0
		OUT SWITCHDDR, TEMP ; CONFIGURE SWITCH INPUT PORTA
		LDI TEMP, 0xFF
		OUT SWITCHPORT, TEMP ; PULL-UP PORTA
		OUT SEG7DATADDR, TEMP ; CONFIGURE DATA OUTPUT PORTD
		LDI TEMP, 0x03
		OUT SEG7LATCHDDR, TEMP ; CONFIGURE LATCH OUTPUT PORTB 
		LDI TEMP, 0xFF
		OUT SEG7DATAPORT, TEMP
		LDI ZH, HIGH(SEG7BCD << 1) ; GET LED DATA 
		LDI ZL, LOW(SEG7BCD << 1) ; GET LED DATA
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
READ_SWITCH:
		IN COUNTER, PINA ; R19 OBSOLETE AFTER MUL
		COM R19
		LDI R22, 9
		MUL R19, R22
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA_CONVERSION:
		LDI COUNTER, 16 ; MAX 2295 (12-BIT BIN)
		CLR BCD0
		CLR BCD1
		MOV LOWBYTE, R0
		MOV HIGHBYTE, R1

BINTOBCD16:
		LSL LOWBYTE 
		BRCS SETFLAG
		LSL HIGHBYTE
		RJMP BCD_LOW

SETFLAG:
		LSL HIGHBYTE
		ORI HIGHBYTE, 1 ; BIT 7 LOWBYTE SHIFTED IN IS HIGH

BCD_LOW:
		BRCS SETBCD0
		LSL BCD0
		RJMP BCD_HIGH

SETBCD0:
		LSL BCD0
		ORI BCD0, 1 ; BIT 7 HIGHBYTE SHIFTED IN IS HIGH

BCD_HIGH:
		BRCS SETBCD1 
		LSL BCD1
		RJMP UPDATE

SETBCD1:
		LSL BCD1
		ORI BCD1, 1 ; BIT 7 BCD0 SHIFTED IN IS HIGH
		 
UPDATE: 
		DEC COUNTER
		BRNE ADD3
		RET

ADD3: 
		LDI OPERAND, 0x30
		ADD BCD1, OPERAND ; ADD 3 TO BCD1 HIGH NIBBLE
		SBRS BCD1, 7
		SUB BCD1, OPERAND
		LDI OPERAND, 0x03
		ADD BCD1, OPERAND ; ADD 3 TO BCD1 LOW NIBBLE
		SBRS BCD1, 3
		SUB BCD1, OPERAND
		LDI OPERAND, 0x30
		ADD BCD0, OPERAND ; ADD 3 TO BCD0 HIGH NIBBLE
		SBRS BCD0, 7
		SUB BCD0, OPERAND
		LDI OPERAND, 0x03
		ADD BCD0, OPERAND ; ADD 3 TO BCD0 LOW NIBBLE
		SBRS BCD0, 3
		SUB BCD0, OPERAND 
		RJMP BINTOBCD16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA_INIT:
		LDI XH, 0x04
		LDI XL, 0x00
		LDI TEMP, 0
		LDI R22, 0xF0
		AND R22, BCD1
		SWAP R22
		ST X+, R22 ; DIGIT-3 0x0100
		LDI R22, 0x0F
		AND R22, BCD1
		ST X+, R22 ; DIGIT-2 0x0101
		LDI R22, 0xF0
		AND R22, BCD0
		SWAP R22
		ST X+, R22 ; DIGIT-1 0x0102
		LDI R22, 0x0F
		AND R22, BCD0
		ST X+, R22 ; DIGIT-0 0x0103
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

SEG7BCD: 
.DB 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90
; VALUE TABLE FOR BCD 0-9

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LED_DISPLAY:
		LD R22, -X
		ADD ZL, R22
		LPM OPERAND, Z
		SUB ZL, R22
		OUT SEG7DATAPORT, OPERAND
		SBI SEG7LATCHPORT, NLE0 ; SET LATCH TO START RETAIN DATA
		CALL SDELAY
		CBI SEG7LATCHPORT, NLE0 ; CLEAR LATCH TO FINISH RETAIN DATA
		OUT SEG7DATAPORT, R20 ; CHOOSE LED TO DISPLAY
		SBI SEG7LATCHPORT, NLE1
		CALL SDELAY
		CBI SEG7LATCHPORT, NLE1
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SDELAY:
		NOP
		NOP
		RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAYT1_5ms:
		LDI TIMEREG, 0b00001011 ; CTC MODE, PRESCALER CLK/64
		STS TCCR1B, TIMEREG
		LDI TIMEREG, 0x02
		STS OCR1AH, TIMEREG
		LDI TIMEREG, 0x71
		STS OCR1AL, TIMEREG
		CLR TIMEREG
		STS TCNT1H, TIMEREG
		STS TCNT1L, TIMEREG

DELAYT1_5ms_LOOP:
		SBIS TIFR1, OCF1A
		RJMP DELAYT1_5ms_LOOP
		SBI TIFR1, OCF1A ; RESET TIMER1
		RET
