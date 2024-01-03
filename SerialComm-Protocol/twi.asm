;
; PE41_EX2.asm
;
; Created: 12/10/2023 10:25:31 PM
; Author : tuan minh
;


; Replace with your application code
.ORG 0
.EQU SDA = 1
.EQU SCL = 0
.EQU SLA_W = 0b11011110 ; MCP79401 ADDRESS + WRITE: 1 = READ / 0 = WRITE
.DEF TEMP = R16
.DEF DATA_TEMP =R17

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;; TWI STATUS CODE ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.EQU START = 0x08 ; A START COND. HAS BEEN TRANSMITTED
.EQU MT_SLA_ACK = 0x18 ; SLA+W HAS BEEN TRANSMITTED;
.EQU MT_DATA_ACK = 0x28 ;DATA HAS BEEN TRANSMITTED + ACK RECEIVED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAIN:
		LDI TEMP, (1 << SDA) | (1 << SCL) ; INTERNAL PULL-UP
		OUT PORTA, TEMP
		RCALL TWI_PROTOCOL ; CONSISTS OF ALL TWI STEPS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
TWI_PROTOCOL:
		RCALL START_CONDITION ; SEND START CONDITION
		RCALL WAIT_START ; WAIT START CONDITION TRANSMISSION
		RCALL START_ADDRESS ; SEND SLAVE ADDRESS + WRITE
		RCALL ACK_RECEIVE ; POLL FOR SLAVE ACKNOWLEDGE
		RCALL START_DATA ; SEND DATA 
		RCALL STOP_CONDITION ; SEND STOP CONDITION
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START_CONDITION:
		LDI TEMP, (1 << TWINT) | (1 << TWSTA) | (1 << TWEN) ; CLEAR TWINT FLAG
		STS TWCR, TEMP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
WAIT_START:
		LDS TEMP, TWCR
		SBRS TEMP, TWINT
		RJMP WAIT_START ; WAIT FOR START COMPLETE
		LDS TEMP, TWSR
		ANDI TEMP, 0xF8
		CPI TEMP, START
		BRNE TWI_PROTOCOL ; ERROR RETURN TO BEGINNING
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START_ADDRESS:
		LDI TEMP, SLA_W
		STS TWDR, TEMP
		LDI TEMP, (1 << TWINT) | (1 << TWEN)
		STS TWCR, TEMP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ACK_RECEIVE:
		LDS TEMP, TWCR
		SBRS TEMP, TWINT
		RJMP ACK_RECEIVE
		LDS TEMP, TWSR
		ANDI TEMP, 0xF8
		CPI TEMP, MT_SLA_ACK
		BRNE TWI_PROTOCOL
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
START_DATA:
		//LDI DATA_TEMP, DATA
		STS TWDR, DATA_TEMP
		LDI TEMP, (1<<TWINT) | (1 << TWEN)
		STS TWCR, TEMP

START_DATA_POLL:
		LDS TEMP, TWCR
		SBRS TEMP, TWINT
		RJMP START_DATA_POLL

		LDS TEMP, TWSR
		ANDI TEMP, 0xF8
		CPI TEMP, MT_DATA_ACK
		BRNE TWI_PROTOCOL
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
STOP_CONDITION:
		LDI TEMP, (1 << TWINT) | (1 << TWEN) | (1 << TWSTO)
		STS TWCR, TEMP
		RET
