;
; PE41_EX1.asm
;
; Created: 11/2/2023 11:22:12 AM
; Author : tuan minh
;


; Replace with your application code
.ORG 0
.DEF TEMP = R16
.DEF TEMP_DATA = R17

MAIN:
		CALL INIT_PORT
		CALL INIT_UART0

AGAIN:
		CALL DATA_RECEIVE
		CALL DATA_TRANSMIT
		RJMP AGAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_PORT:
		LDI TEMP, 0xFF
		OUT DDRB, TEMP
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
		STS UDR0, TEMP_DATA
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA_RECEIVE:
		LDS TEMP, UCSR0A
		SBRS TEMP, RXC0
		RJMP DATA_RECEIVE
		LDS TEMP_DATA, UDR0
		OUT PORTB, TEMP_DATA
		RET