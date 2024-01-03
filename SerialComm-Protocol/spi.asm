;
; PE41_EX3.asm
;
; Created: 11/11/2023 8:43:49 PM
; Author : tuan minh
;


; Replace with your application code
.ORG 0
.EQU PIN_SS = 4
.EQU PIN_MOSI = 5
.EQU PIN_MISO = 6
.EQU PIN_SCK = 7
.EQU DATA_DDR = DDRA
.EQU DATA_PORT = PORTA
.EQU SPI_DDR = DDRB
.EQU SPI_PORT = PORTB
.DEF TEMP = R16
.DEF DATA_TEMP = R17

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAIN:
		CALL INIT_UART0 ; INITIALIZE USART0
		CALL INIT_MSPI ; INITIALIZE MASTER SPI
		LDI DATA_TEMP, 1

LOOP:
		; DATA EXCHANGE USING UART
		CALL DATA_TRANSMIT
		CALL DATA_RECEIVE
		; DATA OUTPUT USING SPI
		CALL MSPI_TRANSMIT 
		RJMP LOOP

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
INIT_MSPI:
		; ENABLE SPI MASTER, RATE FCK/16
		LDI TEMP, (1 << PIN_MOSI) | (1 << PIN_SCK) | (1 << PIN_SS) | (1 << PB0)
		SBI SPI_PORT, PB0
		OUT SPI_DDR, TEMP
		LDI TEMP, (1 << SPE0) | (1 << MSTR0) | (1 << SPR00)
		OUT SPCR0, TEMP
		SBI SPI_PORT, PIN_SS ; DISABLE EEPROM
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA_TRANSMIT:
		LDS TEMP, UCSR0A 
		SBRS TEMP, UDRE0
		RJMP DATA_TRANSMIT
		STS UDR0, DATA_TEMP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA_RECEIVE:
		LDS TEMP, UCSR0A
		SBRS TEMP, RXC0
		RJMP DATA_RECEIVE
		LDS DATA_TEMP, UDR0
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MSPI_TRANSMIT:
		CBI SPI_PORT, PIN_SS
		OUT SPDR0, DATA_TEMP

WAIT_TRANSMIT:
		; WAIT TRANSMISSION COMPLETE
		IN TEMP, SPSR0
		SBRS TEMP, SPIF0
		RJMP WAIT_TRANSMIT
		SBI SPI_PORT, PIN_SS
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAYT1_32u:
		LDI TEMP, 0b00001001 ; CTC MODE, NO PRESCALER
		STS TCCR1B, TEMP
		LDI TEMP, 0x00
		STS OCR1AH, TEMP
		LDI TEMP, 0xE0
		STS OCR1AL, TEMP
		CLR TEMP
		STS TCNT1H, TEMP
		STS TCNT1L, TEMP

DELAY32u_LOOP:
		SBIS TIFR1, OCF1A
		RJMP DELAY32u_LOOP 
		SBI TIFR1, OCF1A ; RESET TIMER1
		CLR TEMP
		STS TCCR1A, TEMP
		STS TCCR1B, TEMP
		RET
