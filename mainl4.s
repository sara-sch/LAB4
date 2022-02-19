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
    COUNT:		DS 1
    CONT:		DS 1	; Contador tabla
     
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
    CALL    RESET_TMR0
    CALL    COUNTER
    
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
    CALL CONFIG_TMR0
    CLRF CONT			; Reinicio de contador para tabla
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
    CLRF    TRISC		; PORTC como salida
    
    BANKSEL OPTION_REG
    BCF	    OPTION_REG, 7
    
    BANKSEL WPUB
    BSF	    WPUB, 0
    BSF	    WPUB, 1
    
    BANKSEL PORTA
    CLRF    PORTA
    CLRF    PORTB
    CLRF    PORTC
    
    RETURN
    
CONFIG_RELOJ:
    BANKSEL OSCCON	;cambiamos a banco 1
    BSF OSCCON, 0	; scs -> 1, usamos reloj interno
    BSF OSCCON, 6
    BSF OSCCON, 5
    BCF OSCCON, 4	; IRCF<2:0> -> 110 4MHz
    RETURN
    
CONFIG_TMR0:
    BANKSEL OPTION_REG	; cambiamos de banco
    BCF T0CS		; TMR0 como temporizador
    BCF PSA		; prescaler a TMR0
    BSF PS2
    BSF PS1
    BCF PS0		; PS<2:0> -> 111 PRESCALER 1 : 128
    
    BANKSEL TMR0	; cambiamos de banco
    MOVLW 61
    MOVWF TMR0		; 20ms retardo
    BCF T0IF		; limpiamos bandera de interrupci[on
    RETURN
 
RESET_TMR0:
    BANKSEL TMR0	; cambiamos de banco
    MOVLW 61
    MOVWF TMR0		; 20ms retardo
    BCF T0IF		; limpiamos bandera de interrupcion
    RETURN
    
CONFIG_INT:
    BANKSEL INTCON
    BSF GIE		; Habilitamos interrupciones
    BSF RBIE		; Habilitamos interrupcion RBIE
    BCF RBIF		; Limpia bandera RBIF
    BSF T0IE		; Habilitamos interrupcion TMR0
    BCF T0IF		; Limpiamos bandera de TMR0
    RETURN
    
CONFIG_IOCB:
    BANKSEL TRISA
    BSF	    IOCB, 0
    BSF	    IOCB, 1
    
    BANKSEL PORTB
    MOVF    PORTB, W	; Al leer, deja de hacer mismatch
    BCF	    RBIF
    RETURN
    
COUNTER:
    INCF    COUNT
    MOVLW   50
    XORWF   COUNT, W
    BTFSS   STATUS, 2
    RETURN
    MOVF    CONT, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla ASCII
    INCF    CONT		; Incremento de contador
    BTFSC   CONT, 4
    MOVF    CONT		; Mover CONT a W
    MOVWF   PORTC
    CLRF    STATUS
    CLRF    COUNT
    RETURN
    
ORG 200h    
TABLA:
    CLRF    PCLATH		; Limpiamos registro PCLATH
    BSF	    PCLATH, 1		; Posicionamos el PC en dirección 02xxh
    ANDLW   0x0F		; no saltar más del tamaño de la tabla
    ADDWF   PCL			; Apuntamos el PC a caracter en ASCII de CONT
    RETLW   187			; ASCII char 0
    RETLW   10			; ASCII char 1
    RETLW   115			; ASCII char 2
    RETLW   91			; ASCII char 3
    RETLW   202			; ASCII char 4
    RETLW   217			; ASCII char 5
    RETLW   249			; ASCII char 6
    RETLW   11			; ASCII char 7
    RETLW   251			; 8
    RETLW   203			; 9
    RETLW   235			; A
    RETLW   248			; b
    RETLW   177			; C
    RETLW   122			; d
    RETLW   241			; E
    RETLW   225			; F
    RETURN
    
END


