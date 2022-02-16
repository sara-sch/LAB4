PROCESSOR 16F887

; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
  
PSECT udata_shr			 ; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1
  
PSECT resVect, class = CODE, abs, delta = 2
; ----------- VECTOR RESET ----------------
 
ORG 00h
resVect:
	PAGESEL main	    ; cambio de pagina
	GOTO main
	
PSECT intVect, class=CODE, abs, delta=2
;---------------------interrupt vector---------------------
ORG 04h
PUSH:
    MOVWF   W_TEMP	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Guardamos STATUS
    
ISR:
    BTFSC   RBIF
    CALL    INT_IOCB
    
POP:
    SWAPF   STATUS_TEMP, W
    MOVWF   STATUS
    SWAPF   W_TEMP, F
    SWAPF   W_TEMP, W
    RETFIE

;----------------subrutinas int---------------------    
INT_IOCB:
    BANKSEL PORTA
    BTFSS   PORTB, 0
    INCF    PORTA
    BTFSS   PORTB, 1
    DECF    PORTA
    BCF	    RBIF
    RETURN
    
    
    
PSECT code, delta = 2, abs
; ----------- CONFIGURATION ---------------
ORG 100h
main:
    CALL CONFIG_IO
    CALL CONFIG_RELOJ
    CALL CONFIG_IOCB
    CALL CONFIG_INT
    BANKSEL PORTA
        
LOOP:
    GOTO LOOP
    
; ------------subrutinas

CONFIG_IO:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH		; I/O digitales
    
    BANKSEL TRISA
    BSF	    TRISB, 0		; PORTB0 como entrada
    BSF	    TRISB, 1		; PORTB1 como entrada
    BCF	    TRISA, 0		; PORTA como salida
    BCF	    TRISA, 1
    BCF	    TRISA, 2
    BCF	    TRISA, 3
    
    BANKSEL OPTION_REG
    BCF	    OPTION_REG, 7
    
    BANKSEL WPUB
    BSF	    WPUB, 0
    BSF	    WPUB, 1
    
    BANKSEL PORTA
    CLRF    PORTA
    CLRF    PORTB
    
    RETURN
    
CONFIG_RELOJ:
    BANKSEL OSCCON	;cambiamos a banco 1
    BSF OSCCON, 0	; scs -> 1, usamos reloj interno
    BSF OSCCON, 6
    BSF OSCCON, 5
    BCF OSCCON, 4	; IRCF<2:0> -> 110 4MHz
    RETURN
    
CONFIG_INT:
    BANKSEL INTCON
    BSF GIE		; Habilitamos interrupciones
    BSF RBIE		; Habilitamos interrupcion RBIE
    BCF RBIF		; Limpia bandera RBIF
    RETURN
    
CONFIG_IOCB:
    BANKSEL TRISA
    BSF	    IOCB, 0
    BSF	    IOCB, 1
    
    BANKSEL PORTA
    MOVF    PORTB, W	; Al leer, deja de hacer mismatch
    BCF	    RBIF
    RETURN
    
END


