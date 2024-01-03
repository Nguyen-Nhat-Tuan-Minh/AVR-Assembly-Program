;
; PE41_EX5.asm
;
; Created: 11/13/2023 7:48:08 PM
; Author : tuan minh
;


; Replace with your application code
.ORG 0
.EQU DATA_DDR = DDRA
.EQU DATA_PORT = PORTA
.DEF TEMP = R16
.DEF DATA_TEMP = R17 ; INTERNAL EEPROM ADDRESS POINTER
.DEF DUMMY = R18
.DEF COUNTER = R20

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAIN:
		RCALL INIT_PORT
		RCALL INIT_UART0 ; INITIALIZE USART0
		LDI DATA_TEMP, 1 ; INIT STORING ADDRESS TO [x101]
		RCALL READIN_EEPROM ; READ AVR INTERNAL EEPROM

LOOP:
		RCALL DATA_RECEIVE
		RCALL DATA_TRANSMIT ; DATA EXCHANGE USING UART
		INC COUNTER
		OUT DATA_PORT, COUNTER
		RCALL WRITEIN_EEPROM ; WRITE AVR INTERNAL EEPROM
		RCALL DELAYT1_5ms ; ERASE AND WRITE IN ONE OP = 3.4ms 
		RJMP LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_PORT:
		LDI TEMP, 0xFF
		OUT DATA_DDR, TEMP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_UART0:
		CLR TEMP
		STS UBRR0H, TEMP
		LDI TEMP, 51
		STS UBRR0L, TEMP
		LDI TEMP, (1 << RXEN0) | (1 << TXEN0) ; ENABLE RECEPTION/TRANSMISSION
		STS UCSR0B, TEMP
		LDI TEMP, (1 << UCSZ01) | (1 << UCSZ00) ; ASYNC, 1 STOP-BIT, 1-BYTE DATA
		STS UCSR0C, TEMP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA_TRANSMIT:
		LDS TEMP, UCSR0A 
		SBRS TEMP, UDRE0
		RJMP DATA_TRANSMIT
		STS UDR0, DUMMY
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA_RECEIVE:
		LDS TEMP, UCSR0A
		SBRS TEMP, RXC0
		RJMP DATA_RECEIVE
		LDS DUMMY, UDR0
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WRITEIN_EEPROM:
		SBIC EECR, EEPE ; SAMPLE PREVIOUS WRITE
		RJMP WRITEIN_EEPROM
		OUT EEARH, DATA_TEMP ; EEAR = EEPROM ADDRESS REGISTER
		OUT EEARL, DATA_TEMP ; ALWAYS WRITE TO [0x101]
		OUT EEDR, COUNTER ; EEDR = EEPROM DATA REGISTER
		SBI EECR, EEMPE ; EEPROM WRITE "ENABLE"
		SBI EECR, EEPE ; START EEPROM WRITE WITHIN 1 CYCLE
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
READIN_EEPROM:
		SBIC EECR, EEPE ; SAMPLE PREVIOUS WRITE
		RJMP READIN_EEPROM
		OUT EEARH, DATA_TEMP ; ALWAYS READ FROM [0x101]
		OUT EEARL, DATA_TEMP
		SBI EECR, EERE ; START EEPROM READ
		IN COUNTER, EEDR
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAYT1_5ms:
		LDI TEMP, 0b00001001 ; CTC MODE, NO PRESCALER
		STS TCCR1B, TEMP
		LDI TEMP, 0x9C
		STS OCR1AH, TEMP
		LDI TEMP, 0x40
		STS OCR1AL, TEMP
		CLR TEMP
		STS TCNT1H, TEMP
		STS TCNT1L, TEMP

DELAYT1_5ms_LOOP:
		SBIS TIFR1, OCF1A
		RJMP DELAYT1_5ms_LOOP 
		SBI TIFR1, OCF1A ; RESET TIMER1
		CLR TEMP
		STS TCCR1A, TEMP
		STS TCCR1B, TEMP
		RET
