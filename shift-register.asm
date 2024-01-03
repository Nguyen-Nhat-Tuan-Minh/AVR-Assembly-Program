;
; PE12_EX3.asm
;
; Created: 9/17/2023 9:14:39 PM
; Author : tuan minh
;


; Replace with your application code
.def shiftData = r20			; Define the shift data register
.equ clearSignalPort = PORTB	; Set clear signal port to PORTB
.equ clearSignalPin = 3			; Set clear signal pin to pin 2 of PORTB
.equ shiftClockPort = PORTB		; Set shift clock port to PORTB
.equ shiftClockPin = 2			; Set shift clock pin to pin 1 of PORTB
.equ latchPort = PORTB			; Set latch port to PORTB
.equ latchPin = 1				; Set latch pin to pin 0 of PORTB
.equ shiftDataPort = PORTB		; Set shift data port to PORTB
.equ shiftDataPin = 0			; Set shift data pin to pin 3 of PORTB

.ORG 0

main:
		call initport
		
here:
		ldi zh, high(led_data << 1)
		ldi zl, low(led_data << 1)
		ldi r16, 16
		call cleardata
		call shiftoutdata
done:
		jmp done
; Initialize ports as outputs
initport:
		ldi r24, 0x0F
		out DDRB, r24 ; Set DDRB to output	
		ret

cleardata:
		;cbi clearSignalPort, clearSignalPin ; Set clear signal pin to low
; Wait for a short time
		sbi clearSignalPort, clearSignalPin ; Set clear signal pin to high
		ret

; Shift out data
shiftoutdata:
		cbi shiftClockPort, shiftClockPin ;
		ldi r18, 8 ; Shift 8 bits
		lpm shiftData, Z+

shiftloop:
		sbrc shiftData, 7 ; Check if the MSB of shiftData is 1
		sbi shiftDataPort, shiftDataPin ; Set shift data pin to high
		sbi shiftClockPort, shiftClockPin ; Set shift clock pin to high
		lsl shiftData ; Shift left
		cbi shiftClockPort, shiftClockPin ; Set shift clock pin to low
		cbi shiftDataPort, shiftDataPin ; Set shift data pin to low
		dec r18
		brne shiftloop

; Latch data
		sbi latchPort, latchPin ; Set latch pin to high
		call DELAY1s
		cbi latchPort, latchPin ; Set latch pin to low
		dec r16
		brne shiftoutdata
		ret

DELAY1s:
		LDI R16,100
LOOP_1:	LDI R17,100
LOOP_2:	LDI R18,100
LOOP_3:	NOP		; 1C
		DEC R18		; 2C
		BRNE LOOP_3		; 2C
		DEC R17
		BRNE LOOP_2
		DEC R16
		BRNE LOOP_1
		RET

; The value for the shift register output to led
led_data:.DB 0,1,3,7,15,31,63,127,255,254,252,248,240,224,192,128,0
