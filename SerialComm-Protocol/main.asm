;
; PE41_EX4.asm
;
; Created: 11/12/2023 10:37:47 AM
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
.DEF COUNTER = R18
.DEF DUMMY = R19
;;;;;;;;;;;;;;;;;;;;;;;;;;;; EEPROM INSTRUCTION ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.EQU READ  = 0b00000011 ; Read data from memory array beginning at selected address
.EQU WRITE = 0b00000010 ; Write data to memory array beginning at selected address
.EQU WREN  = 0b00000110 ; Set the write enable latch (enable write operations)
.EQU WRDI  = 0b00000100 ; Reset the write enable latch (disable write operations)
.EQU CE    = 0b11000111 ; Chip Erase – erase all sectors in memory array

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAIN:
		RCALL INIT_PORT
		RCALL INIT_UART0 ; INITIALIZE USART0
		RCALL INIT_MSPI ; INITIALIZE MASTER SPI
		CLR COUNTER
		RCALL READ_EEPROM

LOOP:
		CALL UART_PROTOCOL ; DATA EXCHANGE USING UART
		INC COUNTER
		CALL SPI_PROTOCOL ; DATA EXCHANGE USING SPI
		OUT PORTA, COUNTER
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
UART_PROTOCOL:
		RCALL DATA_RECEIVE
		RCALL DATA_TRANSMIT
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SPI_PROTOCOL:
		RCALL WRITE_ENABLE
		RCALL WRITE_EEPROM
		RCALL WRITE_DISABLE
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA_TRANSMIT:
		LDS TEMP, UCSR0A 
		SBRS TEMP, UDRE0
		RJMP DATA_TRANSMIT
		STS UDR0, DATA_TEMP ; UNNECESSARY
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA_RECEIVE:
		LDS TEMP, UCSR0A
		SBRS TEMP, RXC0
		RJMP DATA_RECEIVE
		LDS DATA_TEMP, UDR0
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;; SPI DOMAIN ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_MSPI:
		; ENABLE SPI MASTER, RATE FCK/16
		LDI TEMP, (1 << PIN_MOSI) | (1 << PIN_SCK) | (1 << PIN_SS)
		OUT SPI_DDR, TEMP
		LDI TEMP, (1 << SPE0) | (1 << MSTR0) | (1 << SPR00) ;| (1 << DORD0) | (1 << CPOL0) | (1 << CPHA0) ; CLK = Fosc/16
		OUT SPCR0, TEMP
		SBI SPI_PORT, PIN_SS ; DISABLE EEPROM
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
READ_EEPROM:
		LDI DATA_TEMP, READ ; READ INSTRUCTION
		CBI SPI_PORT, PIN_SS
		RCALL MSPI_TRANSMIT ; SEND READ INSTRUCTION
		CLR DATA_TEMP ; READ ADDRESS IN x0
		RCALL MSPI_TRANSMIT ; 1 BYTE ADDRESS
		RCALL MSPI_TRANSMIT ; 1 BYTE ADDRESS
		RCALL MSPI_TRANSMIT ; 1 BYTE ADDRESS
		RCALL MSPI_TRANSMIT ; 1 EXTRA CLOCKING FOR DATA SHIFT OUT
		IN DATA_TEMP, SPDR0
		SBI SPI_PORT, PIN_SS
		MOV COUNTER, DATA_TEMP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WRITE_ENABLE:
		LDI DATA_TEMP, WREN
		CBI SPI_PORT, PIN_SS
		RCALL MSPI_TRANSMIT
		SBI SPI_PORT, PIN_SS
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WRITE_EEPROM:
		LDI DATA_TEMP, WRITE
		CBI SPI_PORT, PIN_SS
		RCALL MSPI_TRANSMIT
		CLR DATA_TEMP
		RCALL MSPI_TRANSMIT ; 24-BIT ADDRESS
		RCALL MSPI_TRANSMIT
		RCALL MSPI_TRANSMIT
		MOV DATA_TEMP, COUNTER 
		RCALL MSPI_TRANSMIT
		SBI SPI_PORT, PIN_SS
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WRITE_DISABLE:
		LDI DATA_TEMP, WRDI
		CBI SPI_PORT, PIN_SS
		CALL MSPI_TRANSMIT
		SBI SPI_PORT, PIN_SS
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MSPI_TRANSMIT:
		; MASTER SPI DATA TRANSMISSION
		OUT SPDR0, DATA_TEMP

WAIT_TRANSMIT:
		; WAIT TRANSMISSION COMPLETE
		IN TEMP, SPSR0
		SBRS TEMP, SPIF0
		RJMP WAIT_TRANSMIT
		RET
