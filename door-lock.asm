; Wireless Door Lock System using ATmega328p (Assembly)
; -------------------------------------------------------
; Components:
; - ATmega328p
; - nRF24L01 (SPI Wireless Module)
; - TFT LCD (SPI)
; - Servo Motor (PWM on OC1A)
;
; This code assumes a basic unlock command is received wirelessly and sets PB1 to rotate servo.

.include "m328pdef.inc"

; Define Constants
.equ F_CPU = 16000000
.equ BAUD = 9600
.equ UBRR_VALUE = F_CPU / 16 / BAUD - 1

; ---------------------------------------------------
; Section 1: Initialization
; ---------------------------------------------------

.org 0x00
rjmp RESET

RESET:
	; Disable interrupts during setup
	cli

	; Initialize stack pointer
	ldi r16, HIGH(RAMEND)
	out SPH, r16
	ldi r16, LOW(RAMEND)
	out SPL, r16

	; Setup PB1 as output for Servo (OC1A)
	sbi DDRB, PB1

	; Setup Timer1 for Fast PWM, Non-Inverted on OC1A
	ldi r16, (1<<WGM11)
	sts TCCR1A, r16
	ldi r16, (1<<WGM13)|(1<<WGM12)|(1<<CS11)  ; Prescaler 8
	sts TCCR1B, r16
	ldi r16, (1<<COM1A1) ; Clear OC1A on Compare Match
	sts TCCR1A, r16

	ldi r16, HIGH(20000) ; TOP = 20ms (50Hz PWM)
	sts ICR1H, r16
	ldi r16, LOW(20000)
	sts ICR1L, r16

	; Initialize SPI as Master (for nRF24L01)
	sbi DDRB, PB3 ; MOSI
	sbi DDRB, PB5 ; SCK
	sbi DDRB, PB2 ; SS

	ldi r16, (1<<SPE)|(1<<MSTR)|(1<<SPR0) ; Enable SPI, Master, fosc/16
	out SPCR, r16

	sei

MainLoop:
	; Send dummy byte to nRF and receive
	ldi r16, 0xFF
	rcall SPI_Transfer
	cpi r16, 0x01     ; Check if received unlock command (0x01)
	breq Unlock
	rjmp MainLoop

; ---------------------------------------------------
; Section 2: Servo Unlock Control
; ---------------------------------------------------
Unlock:
	; Set OCR1A to 1000 (1ms pulse = LOCK position)
	ldi r16, HIGH(1000)
	sts OCR1AH, r16
	ldi r16, LOW(1000)
	sts OCR1AL, r16
	
	rcall Delay
	
	; Set OCR1A to 2000 (2ms pulse = UNLOCK position)
	ldi r16, HIGH(2000)
	sts OCR1AH, r16
	ldi r16, LOW(2000)
	sts OCR1AL, r16

	rcall Delay
	
	rjmp MainLoop

; ---------------------------------------------------
; Section 3: Subroutines
; ---------------------------------------------------

; SPI Transfer Subroutine
; Sends R16 and returns received byte in R16
SPI_Transfer:
	out SPDR, r16
WaitSPIF:
	in r17, SPSR
	sbrs r17, SPIF
	rjmp WaitSPIF
	in r16, SPDR
	ret

; Simple delay subroutine
Delay:
	ldi r18, 100
Outer:
	ldi r19, 255
Inner:
	nop
	nop
	nop
	subi r19, 1
	brne Inner
	subi r18, 1
	brne Outer
	ret

; ---------------------------------------------------
; End of Program
; ---------------------------------------------------

.end
