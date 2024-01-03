;
; PE42_EX1.asm
;
; Created: 11/15/2023 5:20:40 AM
; Author : tuan minh
;


; Replace with your application code
.ORG 0
.EQU LCD_PORT = PORTA ; LCD DATA PORT
.EQU LCD_DDR = DDRA  ; LCD DATA DDR
.EQU LCD_PIN = PINA  ; LCD DATA PIN
.EQU LCD_RS = 0		  ; LCD RS
.EQU LCD_RW = 1       ; LCD RW
.EQU LCD_EN = 2       ; LCD EN
.EQU SEG7LATCHPORT = PORTC
.EQU SEG7LATCHDDR = DDRC
.EQU SEG7DATAPORT = PORTB
.EQU SEG7DATADDR = DDRB
.EQU NLE0 = 0 ; LATCH SIGNAL DATA
.EQU NLE1 = 1 ; LATCH SIGNAL LED
.DEF TEMP = R16
.DEF DATA_TEMP = R17
.DEF COUNTER = R19
.DEF BCD0 = R21 ; BCD DIGIT 1, 0
.DEF BCD1 = R22 ; BCD DIGIT 3, 2
.DEF HIGHBYTE = R25
.DEF LOWBYTE = R24

		RJMP MAIN

.ORG $0028
		RJMP USART0_RX

.ORG $0050
MAIN:
		CLR HIGHBYTE
		CLR LOWBYTE
		RCALL INIT_PORT
		RCALL INIT_LCD
		RCALL INIT_UART0

RESET:
		RCALL STORAGE
		CLR R23

LOOP:
		RCALL LED_SCAN
		RCALL LED_DISPLAY
		RCALL DELAY_100us
		INC R23
		CPI R23, 4
		BREQ RESET
		RJMP LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_PORT:
		LDI TEMP, 0b11110111
		OUT LCD_DDR, TEMP
		LDI TEMP, 0xFF
		OUT SEG7DATADDR, TEMP ; CONFIGURE DATA OUTPUT PORTB
		LDI TEMP, (1 << NLE1) | (1 << NLE0)
		OUT SEG7LATCHDDR, TEMP ; CONFIGURE LATCH OUTPUT PORTC 
		LDI TEMP, 0xFF
		OUT SEG7DATAPORT, TEMP
		LDI ZH, HIGH(SEG7BCD << 1) ; GET LED DATA 
		LDI ZL, LOW(SEG7BCD << 1) ; GET LED DATA
		RET

SEG7BCD: 
.DB 0xC0, 0xF9, 0xA4, 0xB0, 0x99, 0x92, 0x82, 0xF8, 0x80, 0x90

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_LCD:
		LDI TEMP, 0x02 ; RETURN HOME
		CALL CMDWRITE
		LDI TEMP, 0x28 ; FUCNTION SET: 4-BIT, 2 LINES, 5x7 DOTS
		CALL CMDWRITE
		LDI TEMP, 0x0E ; DISPLAY ON, CURSOR ON
		CALL CMDWRITE
		LDI TEMP, 0x01 ; CLEAR DISPLAY SCREEN
		CALL CMDWRITE
		LDI TEMP, 0x80 ; FORCE CURSOR TO BEGIN OF 1ST ROW
		CALL CMDWRITE
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_UART0:
		CLR TEMP
		STS UBRR0H, TEMP
		LDI TEMP, 51
		STS UBRR0L, TEMP
		LDI TEMP, (1 << RXEN0) | (1 << RXCIE0) ; ENABLE RECEIVE INTERRUPT
		STS UCSR0B, TEMP
		LDI TEMP, (1 << UCSZ01) | (1 << UCSZ00) ; ASYNC, 1 STOP-BIT, 1-BYTE DATA
		STS UCSR0C, TEMP
		SEI
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CMDWRITE:
		RCALL DELAY_10ms
		MOV R18, TEMP
		ANDI R18, 0xF0 ; MASK LOW NIBBLE
		OUT LCD_PORT, R18    ; SEND HIGH NIBBLE
		SBI LCD_PORT, LCD_EN ; EN = 1 HIGH PULSE
		RCALL SDELAY          ; EXTEND EN PULSE
		CBI LCD_PORT, LCD_EN ; EN=0 FOR H-to-L PULSE
		RCALL DELAY_100us     

		SWAP TEMP
		ANDI TEMP, 0xF0 ; MASK HIGH NIBBLE
		OUT LCD_PORT, TEMP    ; SEND LOW NIBBLE
		SBI LCD_PORT, LCD_EN ; EN = 1 FOR HIGH PULSE
		RCALL SDELAY          ; EXTEND EN PULSE
		CBI LCD_PORT, LCD_EN ; EN=0 FOR H-to-L PULSE
		RCALL DELAY_100us
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATAWRITE:
		RCALL DELAY_10ms
		MOV R18, TEMP
		ANDI R18, 0xF0 ; MASK LOW NIBBLE
		OUT LCD_PORT, R18    ; SEND HIGH NIBBLE
		SBI LCD_PORT, LCD_RS ; RS = 1 TO DATA
		SBI LCD_PORT, LCD_EN ; EN = 1 HIGH PULSE
		RCALL SDELAY          ; EXTEND EN PULSE
		CBI LCD_PORT, LCD_EN ; EN=0 FOR H-to-L PULSE
		RCALL DELAY_100us 

		SWAP TEMP
		ANDI TEMP, 0xF0 ; MASK HIGH NIBBLE
		OUT LCD_PORT, TEMP    ; SEND LOW NIBBLE
		SBI LCD_PORT, LCD_RS ; RS = 1 TO DATA
		SBI LCD_PORT, LCD_EN ; EN = 1 HIGH PULSE
		RCALL SDELAY          ; EXTEND EN PULSE
		CBI LCD_PORT, LCD_EN ; EN=0 FOR H-to-L PULSE
		RCALL DELAY_100us   
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LED_SCAN:
		MOV R18, R23
		INC R18
		LDI R20, 0xFF
		CLC ; CLEAR C FLAG
		 
SCAN_LOOP:
		ROL R20 ; D7 <- D0 <- (C = 0)
		DEC R18
		BRNE SCAN_LOOP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LED_DISPLAY:
		LD TEMP, -X
		ADD ZL, TEMP
		LPM DATA_TEMP, Z
		SUB ZL, TEMP
		OUT SEG7DATAPORT, DATA_TEMP
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAY_100us:
		PUSH R17
		LDI R17, 62

DL100us: 
		CALL SDELAY
		DEC R17
		BRNE DL100us
		POP R17
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAY_2ms:
		PUSH R17
		LDI R17, 20
DL2ms: 
		CALL DELAY_100us
		DEC R17
		BRNE DL2ms
		POP R17
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAY_10ms:
		PUSH R17
		LDI R17, 5
DL10ms: 
		CALL DELAY_2ms
		DEC R17
		BRNE DL10ms
		POP R17
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAY_20ms:
		PUSH R17
		LDI R17, 10
DL20ms:
		CALL DELAY_2ms
		DEC R17
		BRNE DL20ms
		POP R17
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;USART0 RECEIVE INTERRUPT HANDLER;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
USART0_RX:
		LDS DATA_TEMP, UDR0
		RCALL LCD_DISPLAY
		RCALL COUNT_MOD ; PREPARE COUNTER
		RCALL DATA_CONVERSION
		RETI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
COUNT_MOD:
		ADIW HIGHBYTE:LOWBYTE, 1
		CPI HIGHBYTE, 0x03 ; COUNT >= 1001?
		BRLO DONE_COUNT
		CPI LOWBYTE, 0xE9
		BRLO DONE_COUNT
		CLR HIGHBYTE
		CLR LOWBYTE

DONE_COUNT:
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA_CONVERSION:
		PUSH HIGHBYTE
		PUSH LOWBYTE
		LDI COUNTER, 16 ; MAX 2295 (12-BIT BIN)
		CLR BCD0
		CLR BCD1

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
		POP LOWBYTE
		POP HIGHBYTE
		RET

ADD3: 
		LDI TEMP, 0x30
		ADD BCD1, TEMP ; ADD 3 TO BCD1 HIGH NIBBLE
		SBRS BCD1, 7
		SUB BCD1, TEMP
		LDI TEMP, 0x03
		ADD BCD1, TEMP ; ADD 3 TO BCD1 LOW NIBBLE
		SBRS BCD1, 3
		SUB BCD1, TEMP
		LDI TEMP, 0x30
		ADD BCD0, TEMP ; ADD 3 TO BCD0 HIGH NIBBLE
		SBRS BCD0, 7
		SUB BCD0, TEMP
		LDI TEMP, 0x03
		ADD BCD0, TEMP ; ADD 3 TO BCD0 LOW NIBBLE
		SBRS BCD0, 3
		SUB BCD0, TEMP 
		RJMP BINTOBCD16

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STORAGE:
		LDI XH, 0x01 ; LED7SEGVALUE ARRAY START AT 0x0100
		LDI XL, 0x00
		LDI TEMP, 0xF0
		AND TEMP, BCD1
		SWAP TEMP
		ST X+, TEMP
		LDI TEMP, 0x0F
		AND TEMP, BCD1
		ST X+, TEMP
		LDI TEMP, 0xF0
		AND TEMP, BCD0
		SWAP TEMP
		ST X+, TEMP
		LDI TEMP, 0x0F
		AND TEMP, BCD0
		ST X+, TEMP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
LCD_DISPLAY:
		MOV TEMP, DATA_TEMP
		CALL DATAWRITE
		LDI TEMP, 0x80
		CALL CMDWRITE
		RET
		


