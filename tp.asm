;***************************************************************************
; Programa main.asm (PIC16F628A)	Fecha de inicio de proyecto: 24-10-2023	
; Autor: Angel Valentin Altieri												
; Programa que controla el agua de un termotanque con una bomba de agua y su temperatura con una
; resistencia. Se utilizan LEDS para visualizar el control del microcontrolador, con un retardo de 5s
; entre cada LED.
; - Velocidad del Reloj: 4MHz		- Tipo de Reloj: Interno				
; - Perro guardián: OFF			- Protección de código: OFF											
;***************************************************************************
	
	 __CONFIG 3F10
	 LIST		P=16F628A
	 INCLUDE	<P16F628A.INC>

;***************************************************************************
; Declaracion de variables													
;***************************************************************************
	CBLOCK 0x20
		
	TEMP_ACT        ;0X20 Temperatura actual, se irá incrementando y decrementando
	TEMP_MAX        ;0X21 Temperatura máxima a la que llegará el termotanque
	SENSOR_TERMO    ;0X22 Sensor para verificar si el termotanque esta encendido, comienza apagado
	NIVEL_AGUA      ;0X23 Nivel de agua actual, se irá incrementando y decrementando
	NIVEL_AGUA_MIN  ;0X24 Nivel de agua mínimO, lo necesitamos para cuando se abra la canilla
	NIVEL_AGUA_MAX  ;0X25 Nivel de agua máximo
	CANILLA         ;0X26 Este registro se irá abriendo y cerrando
		
    CONT1       	;0X27 Registros para los distintos retardos
	CONT2   		;0X28
	CONT3   		;0X29
	CONT4			;0X30

	ENDC
	
	#DEFINE BANCO_0 BCF STATUS,RP0	; Definimos macros para cambiar de bancos 
	#DEFINE BANCO_1	BSF STATUS,RP0

	ORG 0x00

	CALL INICIALIZAR_VARIABLES	; Subrutina que da valor a las variables y configura los puertos para los LEDS

	GOTO INICIO

INICIO

	CLRF	CANILLA 		 ; Cerramos canilla
	BANCO_0					 ; Vamos al banco 0
	CLRF	PORTB			 ; Apagamos todos los LEDS
	
    BTFSS	SENSOR_TERMO,1   ; Verifica si esta enchufado con el bit 1, si está enchufado salta
    COMF 	SENSOR_TERMO     ; Si esta desenchufado, se enchufa poniendolo en 1
	
	CALL	PRENDER_LED_RB0  ; Encendemos el RB0 indicando que se enchufo el termo
	CALL	DELAY_1S

	CALL	CARGAR_AGUA      ; Subrutina que verifica si el agua es menor a 110 litros y acciona la bomba
	CALL	DELAY_1S	

	CALL	PRENDER_LED_RB2 ; Prendemos el RB2 indicando que se verificará la temperatura
	CALL	CALENTAR_AGUA	; Subrutina que verifica la temperatura del agua, si es menor a 45 se enciende la resistencia

	CALL	DELAY_1S		; Esperamos 1 segundo y abrimos la canilla	
		
	CALL	CANILLA_ABIERTA ; Subrutina que abre canilla

	CALL	DELAY_1S		; Esperamos 1 segundo y generamos loop
	
	GOTO	INICIO
	
;***************************************************************************
; Subrutina que carga el agua hasta el tope (acciona la bomba)												
;***************************************************************************
CARGAR_AGUA ; Bomba en acción
	MOVF	NIVEL_AGUA,W        ; Muevo NIVEL_AGUA a W
	SUBWF	NIVEL_AGUA_MAX,W    ; NIVEL_AGUA_MAX - NIVEL_AGUA
	BTFSS	STATUS,Z		    ; Si Z se pone en 1, la operacion dio 0 y ya llego a 110 litros y salta, sino sigue llenandose
	GOTO 	INC_LOOP_AGUA		; Va a INC_LOOP_AGUA para incrementar
	RETURN

INC_LOOP_AGUA
	INCF	NIVEL_AGUA,F 	   ; Sumo 1 litro
	CALL	PRENDER_LED_RB1	   ; Encendemos el RB1 indicando que se prendió la bomba
	GOTO 	CARGAR_AGUA        ; Regresa a CARGAR_AGUA


;***************************************************************************
; Subrutina que calienta el agua hasta el máximo (se prende la resistencia)												
;***************************************************************************
CALENTAR_AGUA
	MOVF 	TEMP_ACT,W			; Movemos a W la temperatura actual
	SUBWF	TEMP_MAX,W			; TEMP_MAX - TEMP_ACT
	BTFSS	STATUS,Z			; Si Z se pone en un 1 ya llego a 45 grados y salta, sino se sigue calentando
	GOTO	INC_LOOP_TEMP		; Va al loop que incrementa la temperatura actual
	CALL	PRENDER_LED_RB3		; LED que indica que se llegó a la temperatura máxima
	RETURN						; Cuando ya este lleno retorna

INC_LOOP_TEMP
	INCF	TEMP_ACT,F			; Suma 1 grado
	CALL	PRENDER_LED_INTERMITENTE ;subrutina del led intermitente, se prenderá y apagará cada 1s hasta que se caliente el agua al tope
	GOTO	CALENTAR_AGUA		; Regresa a CALENTAR_AGUA	

;***************************************************************************
; Subrutina que abre la canilla y deja el termotanque a 50 litros												
;***************************************************************************
CANILLA_ABIERTA
	COMF	CANILLA

CANILLA_ABIERTA_LOOP
	MOVF	NIVEL_AGUA_MIN,W    ; Guardamos en W los 50 litros
	SUBWF	NIVEL_AGUA,W		; NIVEL_AGUA - NIVEL_DE_AGUA_MIN
	BTFSS	STATUS,Z			; Si Z se pone en 0 ya llego al minimo y salta, sino seguimos restando
	GOTO	DEC_AGUA_LOOP
	RETURN

DEC_AGUA_LOOP
	DECF	NIVEL_AGUA,F		; Decrementamos en 1 el nivel de agua
	GOTO	CANILLA_ABIERTA_LOOP; Volvemos a CANILLA_ABIERTA

;***************************************************************************
; Subrutinas de LEDS											
;***************************************************************************
PRENDER_LED_RB0 ; LED que indica que se enchufo el termotanque
	BANCO_0
	BSF		PORTB,0				; Prendemos el led del bit 0 (RB0)
	RETURN	

PRENDER_LED_RB1 ; LED que indica que se accionó la bomba
	BANCO_0
	BSF		PORTB,1				; Prendemos el led del bit 1 (RB1)
	RETURN

PRENDER_LED_RB2 ; LED que indica que se verificará la temperatura
	BANCO_0
	BSF		PORTB,2				; Prendemos el led del bit 2 (RB2)
	RETURN

PRENDER_LED_RB3	; LED que indica que se llegó a la temperatura máxima
	BANCO_0
	BSF		PORTB,3				; Prendemos el led del bit 3 (RB3)
	RETURN

PRENDER_LED_INTERMITENTE ; LED que indica que se encendió la resistencia
	BANCO_0
    BSF PORTB,4     			; Prender el LED en RB4
    CALL DELAY_250MS   			; Esperar 1 segundo
    BCF PORTB,4     			; Apagar el LED en RB4
    CALL DELAY_250MS   			; Esperar 1 segundo nuevamente
    RETURN


;***************************************************************************
; Subrutinas de demoras											
;***************************************************************************
DELAY_1MS
	MOVLW	D'250'		; Cargar 250 en W
	MOVWF	CONT1		; Lo asigno a CONT1
LOOP	
	NOP					; No hace nada, consume 4 ciclos reloj = 1 ciclo de instruccion
	DECFSZ	CONT1,F		; Decrementa CONT1, cuando sea 0 salta
	GOTO	LOOP		; Regresa a LOOP
	RETURN

DELAY_250MS
	MOVLW	D'250'		; Cargamos 250 en W
	MOVWF	CONT2		; Lo aisgno a CONT1
LOOP_2	
	CALL	DELAY_1MS	; Llamamos a DELAY_1MS 
	DECFSZ	CONT2,F		; Se decrementa CONT2, cuando sea 0 salta    Se ejecutará 250 * 1ms = 250ms
	GOTO	LOOP_2		; Regresa a LOOP_2
	RETURN

DELAY_1S
	MOVLW	D'4'		; Cargamos 4 en W
	MOVWF	CONT3		; Lo asigno en CONT3
LOOP_3
	CALL	DELAY_250MS	; Llamamos a DELAY_250MS
	DECFSZ	CONT3,F		; Se decrementa CONT3, cuando sea 0 salta    Se ejecutará 4 * 250ms = 1s
	GOTO	LOOP_3	    ; Regresa a LOOP_3
	RETURN

DELAY_5S		
		MOVLW D'5'		; Cargamos 5 en W		
		MOVWF CONT4		; Lo asignamos en CONT4
LOOP_4					
		CALL DELAY_1S	; Llamamos a DELAY_1S		
		DECFSZ CONT4,F	; Se decrementa CONT4, cuando sea 0 salta    Se ejecutará 5 * 1s = 1s	
		GOTO LOOP_4		; Regresa a LOOP_4
		RETURN

;***************************************************************************
; Subrutina de inicialización de variables												
;***************************************************************************
INICIALIZAR_VARIABLES

		;Damos valor a las variables
		MOVLW D'20'			   ; Cargamos en W la temperatura mínima 
		MOVWF TEMP_ACT	       ; Lo asignamos a TEMP_ACT 

		MOVLW D'45'			   ; Cargamos en W la temperatura máxima
		MOVWF TEMP_MAX		   ; Lo asignamos a TEMP_MAX
		
		MOVLW D'0'             ; Cargamos en W el nivel de agua actual
		MOVWF NIVEL_AGUA	   ; Lo asignamos a NIVEL_AGUA
		
		MOVLW D'50'            ; Cargamos en W el nivel de agua mínimo
		MOVWF NIVEL_AGUA_MIN   ; Lo asignamos en NIVEL_AGUA_MIN

		MOVLW D'110'           ; Cargamos en W el nivel de agua máximo
		MOVWF NIVEL_AGUA_MAX   ; Lo asignamos en NIVEL_AGUA_MAX

		CLRF  SENSOR_TERMO     ; Termotanque desenchufado por defecto

		CLRF	CANILLA 	   ; Canilla empieza cerrada
		
		;Configuramos los puertos que vamos a usar como salida
		BANCO_1				   ; Voy al banco 1 para utilizar TRISB
		MOVLW B'11100000'	   ; Cargamos en W ese numero en binario
		MOVWF TRISB 		   ; Lo asignamos en TRISB

		BANCO_0				   ; Regresamos al banco 0
		CLRF PORTB 			   ; Por defecto estan todos LEDS apagados
	
		RETURN

		END

; ************************************************************
; FIN
; ************************************************************