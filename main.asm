;
; PE13_EX1.asm
;
; Created: 9/18/2023 11:26:04 PM
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

LCD_ON:
; INITIALIZE STACK POINTER 
		LDI R21, LOW(RAMEND)
		OUT SPL, R21
		LDI R21, HIGH(RAMEND)
		OUT SPH, R21

		LDI R16, 0b11110111
		OUT LCD_DDR, R16 ; SET OUTPUT PORT TO LCD (DATA PA4 - PA7, RS = PA0, RW = PA1, EN = PA2)
		CALL DELAY_20ms ; WAIT FOR POWER UP

		LDI R16, 0x02 ; RETURN HOME
		CALL CMDWRITE
		LDI R16, 0x28 ; FUCNTION SET: 4-BIT, 2 LINES, 5x7 DOTS
		CALL CMDWRITE
		LDI R16, 0x0E ; DISPLAY ON, CURSOR ON
		CALL CMDWRITE
		LDI R16, 0x01 ; CLEAR DISPLAY SCREEN
		CALL CMDWRITE
		LDI R16, 0x80 ; FORCE CURSOR TO BEGIN OF 1ST ROW
		CALL CMDWRITE
		LDI R31, HIGH(LAB_MSG0<<1)
		LDI R30, LOW(LAB_MSG0<<1)

STRING0: 
		LPM R16, Z+
		CPI R16, 0
		BREQ NEXT_LINE
		CALL DATAWRITE
		RJMP STRING0

NEXT_LINE: 
		LDI R16, 0xC0 ; FORCE CURSOR TO BEGIN OF 2ND ROW
		CALL CMDWRITE
		LDI R31, HIGH(LAB_MSG1<<1)
		LDI R30, LOW(LAB_MSG1<<1)

STRING1:	
		LPM R16, Z+
		CPI R16, 0
		BREQ DONE
		CALL DATAWRITE
		RJMP STRING1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DONE:
		JMP DONE

LAB_MSG0: .DB "EX VXL-AVR", 0
LAB_MSG1: .DB "GROUP: 05", 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CMDWRITE:
		CALL DELAY_20ms
		MOV R18,R16
		ANDI R18,0xF0 ; MASK LOW NIBBLE
		OUT LCD_PORT, R18    ; SEND HIGH NIBBLE
		SBI LCD_PORT, LCD_EN ; EN = 1 HIGH PULSE
		CALL SDELAY          ; EXTEND EN PULSE
		CBI LCD_PORT, LCD_EN ; EN=0 FOR H-to-L PULSE
		CALL DELAY_100us     

		SWAP R16
		ANDI R16, 0xF0 ; MASK HIGH NIBBLE
		OUT LCD_PORT, R16    ; SEND LOW NIBBLE
		SBI LCD_PORT, LCD_EN ; EN = 1 FOR HIGH PULSE
		CALL SDELAY          ; EXTEND EN PULSE
		CBI LCD_PORT, LCD_EN ; EN=0 FOR H-to-L PULSE
		CALL DELAY_100us
		RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATAWRITE:
		CALL DELAY_20ms
		MOV R18,R16
		ANDI R18,0xF0 ; MASK LOW NIBBLE
		OUT LCD_PORT, R18    ; SEND HIGH NIBBLE
		SBI LCD_PORT, LCD_RS ; RS = 1 TO DATA
		;CBI LCD_PORT, LCD_RW ; RW = 0 TO WRITE
		SBI LCD_PORT, LCD_EN ; EN = 1 HIGH PULSE
		CALL SDELAY          ; EXTEND EN PULSE
		CBI LCD_PORT, LCD_EN ; EN=0 FOR H-to-L PULSE
		CALL DELAY_100us 

		SWAP R16
		ANDI R16, 0xF0 ; MASK HIGH NIBBLE
		OUT LCD_PORT, R16    ; SEND LOW NIBBLE
		SBI LCD_PORT, LCD_RS ; RS = 1 TO DATA
		;CBI LCD_PORT, LCD_RW ; RW = 0 TO write
		SBI LCD_PORT, LCD_EN ; EN = 1 HIGH PULSE
		CALL SDELAY          ; EXTEND EN PULSE
		CBI LCD_PORT, LCD_EN ; EN=0 FOR H-to-L PULSE
		CALL DELAY_100us   
		RET 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SDELAY:
		NOP
		NOP
		RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAY_100us:
		PUSH R17
		LDI R17,100
DR0: 
		CALL SDELAY
		DEC R17
		BRNE DR0
		POP R17
		RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAY_2ms:
		PUSH R17
		LDI R17,20
LDR0: 
		CALL DELAY_100us
		DEC R17
		BRNE LDR0
		POP R17
		RET
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAY_20ms:
		PUSH R17
		LDI R17, 10
POWERUP:
		CALL DELAY_2ms
		DEC R17
		BRNE POWERUP
		POP R17
		RET
