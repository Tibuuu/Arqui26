
        ORG     $0
        DC.L    $8000           
        DC.L    INICIO          

        ORG     $400

*DEFINICIONES DE EQUIVALENCIAS

MR1A    EQU     $effc01       * registro de modo 1 linea A (escritura)
MR2A    EQU     $effc01       * registro de modo 2 linea A (escritura)
SRA     EQU     $effc03       * registro de estado linea A (lectura)
CSRA    EQU     $effc03       * registro de seleccion de reloj A (escritura)
CRA     EQU     $effc05       * registro de control linea A (escritura)
TBA     EQU     $effc07       * buffer de transmision linea A (escritura)
RBA     EQU     $effc07       * buffer de recepcion linea A (lectura)
ACR     EQU     $effc09       * registro de control auxiliar
IMR     EQU     $effc0B       * registro de mascara de interrupcion (escritura)
ISR     EQU     $effc0B       * registro de estado de interrupcion (lectura)
MR1B    EQU     $effc11       * registro de modo 1 linea B (escritura)
MR2B    EQU     $effc11       * registro de modo 2 linea B (escritura)
CRB     EQU     $effc15       * registro de control linea B (escritura)
TBB     EQU     $effc17       * buffer de transmision linea B (escritura)
RBB     EQU     $effc17       * buffer de recepcion linea B (lectura)
SRB     EQU     $effc13       * registro de estado linea B (lectura)
CSRB    EQU     $effc13       * registro de seleccion de reloj B (escritura)
IVR     EQU     $EFFC19       * registro del vector de interrupcion

*Variables globales:

IMR_COPIA DS.B 1  *Enunciado pide guardarle por si acaso
HUECO DS.B 1      *Para dejar las direcciones pares







*Código principal:
*Init tener en cuenta $40 número vector int y $100 dir tabla dfe vectores
INIT:
 
        
        MOVE.B #%00010000,CRA
        MOVE.B #%00000011,MR1A *Inicializo línea A
        MOVE.B #%00000000,MR2A *La pongo en modo normal
        MOVE.B #%11001100,CSRA *Pongo la velocidad pedida 38400 
        
        *Ahora hago lo mismo para la linea B 
        MOVE.B #%00010000,CRB
        MOVE.B #%00000011,MR1B 
        MOVE.B #%00000000,MR2B 
        MOVE.B #%11001100,CSRB 


        MOVE.B #%00000000,ACR *Por ende ACR tiene el bit 7=0 para la velocidad
        MOVE.B #%00000101,CRA *Habilito transmisiones a la vez.
        MOVE.B #%00000101,CRB
        
        MOVE.B #$40,IVR 

        *COnfiguro el IMR
        MOVE.B #%00100010,IMR_COPIA
        MOVE.B IMR_COPIA,IMR

        MOVE.L #RTI,$100 *Actualizo la dir de la RTI en la Tabla de Vectores de ints.

        *LLAMO A INI_BUFS Y LUEGO ACABO EL PROGRAMA
        BSR INI_BUFS 

        RTS

        
SCAN:
        MOVEM.L D2-D4/A1,-(A7)
        LINK A6,#0  *Creo el marco de pilanga
        CLR.L 			D2
	CLR.L 			D3
	CLR.L 			D4	

        MOVE.W 12(A6),D2 *Cargo descriptor
        MOVE.W 14(A6),D3 *Tam max
        MOVE.L 8(A6),A1  *Dir buffer
        CLR.L D4          *Contador

        CMP.W #0,D2      *Compruebo si el descriptor es un ceropio
        BEQ SCANA         * Me voy al scaner de la linea A
        CMP.W #1,D2      *Lo mismo para B
        BEQ SCANB
        MOVE.L #$FFFFFFFF,D0 *Devolvemos error
        BRA ERRSCAN       *Me salgo del scan a error

SCANA:
        CLR.L D0                *Vacio D0 para usarlo como buffer
        BSR LEECAR              *Copio al buffer D0
        CMP.L #$FFFFFFFF,D0   *COMpruebao que el no este vacío
        BEQ FINSCAN             *Si lo está, paro 
        MOVE.B D0,(A1)+        *Lo copio a A1
        ADDQ.L #1,D4           *Aumento contadores.
        SUBQ.W #1,D3           
        BNE SCANA             *COMPARO SI YA HEMOS TERMINADO EL TAMAÑO DEL BUFFER
        BRA FINSCAN

SCANB:
        MOVE.L #1,D0           *Vacio D0 para usarlo como buffer
        BSR LEECAR              *Copio al buffer D0
        CMP.L #$FFFFFFFF,D0   *COMpruebao que el no este vacío
        BEQ FINSCAN             *Si lo está, paro 
        MOVE.B D0,(A1)+        *Lo copio a A1
        ADDQ.L #1,D4           *Aumento contadores.
        SUBQ.W #1,D3           
        BNE SCANB  
 
FINSCAN:
        MOVE.L D4,D0    *nº CHARS LEÍDOS

ERRSCAN:
        MOVEM.L (A7)+,D2-D4/A1 *desapilamos y rehacemos el marco de pila al de antes
        UNLK A6
        RTS


PRINT:
        LINK A6,#0
        MOVEM.L D2-D4/A1,-(A7)

        MOVE.L 8(A6),A1        *BUFFER
        MOVE.W 12(A6),D2       *DESCRIPOR
        MOVE.W 14(A6),D3       *TAM
        CLR.L D4                *CONTADOR

        CMP.W #0,D2
        BEQ PRINTA
        CMP.W #1,D2
        BEQ PRINTB
        MOVE.L #$FFFFFFFF,D0
        BRA ERRPRINT

PRINTA:
        MOVE.B (A1)+,D1        *INICIO EL BUFFER
        MOVE.L #2,D0           *LE PONGO AL DESCRIPTOR LAOPCION DE ESTAR EN PRINTA
        BSR ESCCAR              *lAMMO ESCAR
        CMP.L #$FFFFFFFF,D0      *COMPRUEBO QUE HA METIDO UN CHAR EN EL BUFFERS
        BEQ TRPRINTA              
        
        ADDQ.L #1,D4           *ACTUALIZO COPNTADORES
        SUBQ.W #1,D3 
        BNE PRINTA            *REINICIO BUCLE

TRPRINTA: 
        BSET #0,IMR_COPIA      *SE SE HA COPIADO HABILITO LA TRANSMISION DE LA LINEA CORRESPONDIENTE
        MOVE.B IMR_COPIA,IMR
        BRA FINPRINT
        

PRINTB: *LO mismo de A va para B
        MOVE.B (A1)+,D1        *INICIO EL BUFFER
        MOVE.L #3,D0           *LE PONGO AL DESCRIPTOR LAOPCION DE ESTAR EN PRINTA
        BSR ESCCAR              *lAMMO ESCAR
        CMP.L #$FFFFFFFF,D0      *COMPRUEBO QUE HA METIDO UN CHAR EN EL BUFFERS
        BEQ TRPRINTB
                   
        
        ADDQ.L #1,D4           *ACTUALIZO COPNTADORES
        SUBQ.W #1,D3
        BNE PRINTB           *REINICIO BUCLE

TRPRINTB: 
        BSET #4,IMR_COPIA      *SE SE HA COPIADO HABILITO LA TRANSMISION DE LA LINEA CORRESPONDIENTE
        MOVE.B IMR_COPIA,IMR
        BRA FINPRINT
        
        
FINPRINT:
        MOVE.L D4,D0  *misma estructura que en scan

ERRPRINT:
        MOVEM.L (A7)+,D2-D4/A1
        UNLK A6
        RTS

RTI:
        MOVEM.L D0-D1,-(A7) *Apilo los registros que voy a guardarle
BRT1:        
        MOVE.B ISR,D1   *Lem metop el ISR A D0

        BTST #0,D1
        BNE TRSA

        BTST #1,D1
        BNE RECA

        BTST #4,D1
        BNE TRSB

        BTST #5,D1
        BNE RECB
 
        BRA FINRTI

TRSA:
        MOVE.L #2,D0           *COLOCO DESCRIPTOR 2
        BSR LEECAR              *RUTINA LEERCAR
        CMP.L #$FFFFFFFF,D0    *COMPAROT SI EL BUYFFER ESTÁ VACÍO
        BEQ TRSADES             *CASO ESPECIAL INHABILITO 
        MOVE.B D0,TBA          *envio char por línea
        BRA BRT1
TRSADES:
        BCLR #0,IMR_COPIA      *INHABILITO LAS 
        MOVE.B IMR_COPIA,IMR
        BRA BRT1

TRSB:
        MOVE.B #3,D0           *COLOCO DESCRIPTOR 2
        BSR LEECAR              *RUTINA LEERCAR
        CMP.L #$FFFFFFFF,D0    *COMPAROT SI EL BUYFFER ESTÁ VACÍO
        BEQ TRSBDES             *CASO ESPECIAL INHABILITO 
        MOVE.B D0,TBB          *envio char por línea
        BRA BRT1
TRSBDES:
        BCLR #4,IMR_COPIA
        MOVE.B IMR_COPIA,IMR
        BRA BRT1

RECA:
        MOVE.B RBA,D1
        MOVE.B #0,D0
        BSR ESCCAR
        BEQ FINRTI
        BRA FINRTI

RECB:
        MOVE.B RBB,D1
        MOVE.B #1,D0
        BSR ESCCAR
        BEQ FINRTI
        BRA FINRTI




FINRTI:
        MOVEM.L (A7)+,D0-D1
        RTE


TAMANO EQU 1
DESA: EQU 0 * Descriptor línea A
DESB: EQU 1 * Descriptor línea B
BUFFER: DS.B 2100 * Buffer para lectura y escritura de caracteres
PARDIR: DC.L 0 * Direcci´on que se pasa como par´ametro

INICIO: BSR           INIT                * Inicia el controlador
OTRO:   MOVE.W        #TAMANO,-(A7)
		MOVE.W		#DESA,-(A7)
		MOVE.L 		#BUFFER,PARDIR * Parámetro BUFFER = comienzo del buffer
		MOVE.L 		PARDIR,-(A7) * Dirección de lectura
        BSR             SCAN                * Recibe la linea
        ADD.L           #8,A7               * Restaura la pila
        MOVE.W          #TAMANO,-(A7)
		MOVE.W		#DESB,-(A7)
		MOVE.L 		#BUFFER,PARDIR * Parámetro BUFFER = comienzo del buffer
		MOVE.L 		PARDIR,-(A7) * Dirección de lectura
        BSR             PRINT               * Imprime linea
        ADD.L           #8,A7               * Restaura la pila
        BRA             OTRO
        BREAK


    INCLUDE bib_aux.s

