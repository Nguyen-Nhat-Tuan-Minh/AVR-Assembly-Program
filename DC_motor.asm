;
; pe3_ex4.asm
;
; Created: 10/23/2023 10:21:28 PM
; Author : tuan minh
;


; Replace with your application code
.ORG 0
.DEF TEMP = R16
.DEF COUNTER = R17
.DEF DELAY = R18
.DEF DUTY = R19
.EQU CTRL_PORT = PORTB
.EQU CTRL_DDR = DDRB
.EQU SW_PORT = PORTA
.EQU SW_DDR = DDRA
.EQU SW_PIN = PINA
.EQU SPEED_INC = 0
.EQU SPEED_DEC = 1
.EQU RUN = 2
.EQU DIRECTION = 3
.EQU MOTOR_ENABLE = 1
.EQU MOTOR_CTRL1 = 4  ; OC0B
.EQU MOTOR_CTRL2 = 2
.EQU ENCODER_A = 3

		RJMP MAIN

.ORG $0008 ; PCINT0
		JMP PCINT_0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
MAIN:
		CALL INIT_PORT
		CALL INIT_PCINT0 ; ENABLE PIN CHANGE INTERRUPT FOR PA2

LOOP:	
		CALL READ_POWER ; SAMPLE RUN/STOP SWITCH
		CALL READ_SPEED ; SAMPLE SPEED BUTTONS
		CALL READ_DIRECTION ; SAMPLE DIRECTION BUTTON
		RJMP LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_PORT:
		LDI TEMP, (1 << MOTOR_ENABLE) | (1 << MOTOR_CTRL1) | (1 << MOTOR_CTRL2)
		OUT CTRL_DDR, TEMP
		CLR TEMP
		OUT SW_DDR, TEMP
		LDI TEMP, (1 << SPEED_INC) | (1 << SPEED_DEC) | (1 << RUN) | (1 << DIRECTION)
		OUT SW_PORT, TEMP ; PULL-UP
		SBI CTRL_PORT, MOTOR_ENABLE
		SBI CTRL_PORT, MOTOR_CTRL1
		SBI CTRL_PORT, MOTOR_CTRL2
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PWM_TIMER0:
		LDI TEMP, (1 << COM0B1) | (1 << COM0B0) | (1 << WGM01) | (1 << WGM00) ; FAST PWM, INVERTING MODE
		OUT TCCR0A, TEMP
		LDI DUTY, 120 ; ~120 CYCLES
		OUT OCR0A, DUTY
		CLR DUTY
		LDI TEMP, (1 << WGM02) | (1 << CS02) | (1 << CS00) ; PRESCALER CLK/64, TOP OCR0B
		OUT TCCR0B, TEMP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_PCINT0:
		SEI
		LDI TEMP, (1 << PCINT2)
		STS PCMSK0, TEMP ; CONFIG PINA2 AS INTERRUPT SOURCE
		LDI TEMP, (1 << PCIE0)
		STS PCICR, TEMP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
READ_POWER: 
		SBIC SW_PIN, RUN
		RJMP READ_POWER
		RCALL DELAY_10ms ; NEW
		SBIC SW_PIN, RUN ; NEW
		RJMP READ_POWER ; NEW
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
READ_SPEED:
		SBIC SW_PIN, RUN
		RJMP DONE_SPEED
		SBIC SW_PIN, SPEED_INC
		RJMP SLOW_DOWN
		RCALL DELAY_10ms
		SBIC SW_PIN, SPEED_INC
		RJMP DONE_SPEED
		CPI DUTY, 0
		BREQ DONE_SPEED
		SUBI DUTY, 6
		OUT OCR0B, DUTY
		RJMP DONE_SPEED 
		
SLOW_DOWN:
		SBIC SW_PIN, RUN
		RJMP DONE_SPEED
		SBIC SW_PIN, SPEED_DEC
		RJMP DONE_SPEED
		CALL DELAY_10ms
		SBIC SW_PIN, SPEED_DEC
		RJMP DONE_SPEED
		CPI DUTY, 120
		BREQ DONE_SPEED
		SUBI DUTY, -6
		OUT OCR0B, DUTY

DONE_SPEED:
		RET 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
READ_DIRECTION:
		SBIC SW_PIN, RUN
		RJMP DONE_DIRECTION
		SBIC SW_PIN, DIRECTION
		RJMP COUNTER_CLOCK

CLOCK:
		LDI TEMP, (1 << COM0B1) | (1 << COM0B0) | (1 << WGM01) | (1 << WGM00) ; FAST PWM, INVERTING MODE
		OUT TCCR0A, TEMP
		CBI CTRL_PORT, MOTOR_CTRL2
		RJMP DONE_DIRECTION

COUNTER_CLOCK:
		LDI TEMP, (1 << COM0B1) | (0 << COM0B0) | (1 << WGM01) | (1 << WGM00) ; FAST PWM, NON-INVERTING MODE
		OUT TCCR0A, TEMP
		SBI CTRL_PORT, MOTOR_CTRL2

DONE_DIRECTION:
		RET 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAY_10ms:
		LDI DELAY, 0b00001011 ; CTC MODE, CLK/64
		STS TCCR1B, DELAY
		LDI DELAY, 0x27
		STS OCR1AH, DELAY
		LDI DELAY, 0x10
		STS OCR1AL, DELAY
		CLR DELAY
		STS TCNT1H, DELAY
		STS TCNT1L, DELAY

DELAY10ms_LOOP:
		SBIS TIFR1, OCF1A
		RJMP DELAY10ms_LOOP 
		SBI TIFR1, OCF1A ; RESET TIMER1
		CLR DELAY
		STS TCCR1A, DELAY
		STS TCCR1B, DELAY
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PCINT_0:
		SBIC SW_PIN, RUN  
		RJMP NEXT ; DIPSW_RUN OFF, BREAK MOTOR  
		RJMP END_INT ; DIPSW_RUN ON, ENABLE MOTOR

NEXT:
		CLR TEMP
		OUT TCCR0A, TEMP ; DISABLE PWM WAVE
		SBI CTRL_PORT, MOTOR_CTRL1 ; BOTH CTRL 1 & 2 HIGH 
		SBI CTRL_PORT, MOTOR_CTRL2 ; FOR BREAKING MOTOR
		RETI

END_INT:
		CALL PWM_TIMER0 ; ENABLE PWM WAVE
		RETI




		
