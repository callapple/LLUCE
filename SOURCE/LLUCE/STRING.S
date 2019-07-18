            LST    RTN
            TTL    'LLUCE - String Commands'
            PAG
*===============================
* Contents:
*
* ASC      - Get Ascii Value Of A String
* CHRSTR   - Handle The Chr$() Function
* INSTR    - Get The Instr()
* LEFTSTR  - Get The Left$
* LEFTTRIM - Trim Leading Spaces
* LEN      - Get The Length Of A String
* LOWERSTR - Convert String To Lower Case
* MIDSTR   - Get the mid$ or insert string into string
* MIXEDSTR - Convert String To Mixed Case
* RGTTRIM  - Trim Trailing Spaces
* RIGHTSTR - Get The Right$
* STRSTR   - Get A Number In String Form
* UPPERSTR - Convert String To Upper Case
* VAL      - Get The Value From A String
*===============================

*===============================
* Name: INSTR - Get The Instr()
*===============================

INSTR       JSR    INPSARG
            PUSHA  STRLEN                       ; Save String Info
            PUSHA  STRLOC
            PUSHA  STRLOC+1
            JSR    INPSARG                      ; Get Other String
            STZ    TEMP3+1
            IFNE   (PRGPTR);#','+Hibit;DO_NSR0  ; start specified?

            JSR    INPNARG8                     ; get the number
            DEX
            STX    TEMP3+1

DO_NSR0     PLX
            PLY
            PLA
            STZ    SETRAM1
            JSR    DO_NSR00
            BRA    DTRM

*===============================
* Name: UPPERSTR - Convert String To Upper Case
*       LOWERSTR - Convert String To Lower Case
*       MIXEDSTR - Convert String To Mixed Case
*===============================

UPPERSTR    LDA    #%00000000                   ; Hi Bit Clear
            SKIP2
LOWERSTR    LDA    #%10000000                   ; Hi Bit Set
            SKIP2
MIXEDSTR    PUSHA  #%01000000                   ; V Flag Set
            JSR    INPSARG                      ; Get String Info
            PLA
            STZ    SETRAM1
            JSR    STRCASE
            BRA    DTRM

*===============================
* Name: RGTTRIM - Trim Trailing Spaces
*===============================

RGTTRIM     JSR    CKMSARG                      ; Get The String Info
            BCS    XTRM
            STZ    SETRAM1
            JSR    RGTTRIM0
            BRA    DTRM

*===============================
* Name: LEFTTRIM - Trim Leading Spaces
*===============================

LEFTTRIM    JSR    CKMSARG                      ; Get The String Info
            BCS    XTRM
            STZ    SETRAM1
            JSR    LFTTRIM0
DTRM        STZ    SETRAM2
XTRM        RTS

*===============================
* Name: LEN - Get The Length Of A String
*===============================

LEN         BCS    LEN_ERR
            JSR    INPSARG                      ; Point To String
            LDA    STRLEN                       ; Get Length
            JMP    SVDATA

LEN_ERR     JMP    SYNTAX

*===============================
* Name: LEFTSTR - Get The Left$
*===============================

LEFTSTR     BCS    LEN_ERR
            PHP
            JSR    DO_ISTR                      ; Get String And Length
            BRA    DO_XSTR                      ; Were Done

*===============================
* Name: RIGHTSTR - Get The Right$
*===============================

RIGHTSTR    BCS    LEN_ERR
            PHP
            JSR    DO_ISTR
            LDA    TEMP2+1
            SEC
            SBC    TEMP2                        ; Find Out How Much Used
            BEQ    DO_XSTR

            CLC
            ADA    TEMP;TEMP                    ; Get Start Of String
            BCC    DO_XSTR
            IBRA   TEMP+1;DO_XSTR               ; Finish Up

*===============================
* Name: MIDSTR - Get The Mid$
*===============================

MIDSTR      PHP
            JSR    DO_ISTR                      ; Point To String
            DEC    TEMP2
            CLC
            AD     TEMP2;TEMP;TEMP              ; Get Start Of String
            BCC    DO_MID2
            INC    TEMP+1
DO_MID2     LDA    (PRGPTR)
            LDX    #-1
            CPNE   #','+Hibit;DO_MID3           ; Is There A Length Arg

            JSR    COMNUM8                      ; Get It
            JSR    GETBYT                       ; Gobble )
DO_MID3     SEC
            SB     TEMP2+1;TEMP2;TEMP2          ; Compute Maximum Length
            STX    TEMP2+1
            CPLT   TEMP2+1;DO_MID4              ; Find Out Which To Use

            TXA
DO_MID4     STA    TEMP2
DO_XSTR     LD16   TEMP                         ; return string loc & length
            LDY    TEMP2
            PLP
            BCS    INS_STR
            JMP    SVSTR

INS_STR     SVXAY                               ; save size and location
            JSR    EQUSTR                       ; get the insertion string
            PULL   TEMP2+1                      ; restore size and location
            PULL   TEMP+1
            PULL   TEMP
            LDX    STRLEN                       ; make the length legal
            JSR    DO_IST1

            LDY    #0                           ; move the string data
INS_LUP     MOV    (STRLOC),Y;(TEMP),Y
            INY
            DBNE   TEMP2;INS_LUP
            RTS

DO_ISTR     JSR    INPARG                       ; Get The String
            MOVD   STRLOC;TEMP                  ; Save String Info
            MOV    STRLEN;TEMP2+1
            JSR    INPNARG8
DO_IST1     STX    TEMP2                        ; Get The Number
            CPLTX  TEMP2+1;DO_IST2              ; Make Length Legal

            LDX    TEMP2+1
DO_IST2     STX    TEMP2
            RTS

*===============================
* Name: CHRSTR - Handle The Chr$() Function
*===============================

CHRSTR      JSR    INPNARG8                     ; Get Char Number
            PHX
            LDA    (PRGPTR)
            LDX    #1                           ; Check For More Data
            CPNE   #','+Hibit;DO_CHR2

            JSR    INPNARG8
DO_CHR2     STX    DATA+3                       ; Get Number Of Chars
            MOVD   VARSTR;DATA+1
            PLA
CHR_ADD     STA    (VARSTR)                     ; Create String
            JSR    INCVARST
            DBNE   X;CHR_ADD

            LDY    #0
            MOV    #2;DATA                      ; Data Type 2
            RTS

*===============================
* Name: VAL - Get The Value From A String
*===============================

VAL         JSR    GETBYT                       ; Gobble (
            JSR    INSTR2                       ; Do Use Any Space
            LDY    STRLEN
            LDA    #0
            STA    LNBUF,Y                      ; Terminate String
DO_VAL2     DBMI   Y;DO_VAL3

            MOV    (STRLOC),Y;LNBUF,Y           ; copy string
            BRA    DO_VAL2

DO_VAL3     MOVD   #LNBUF;TEMP3                 ; Point To String
            JSR    ZNUMIN                       ; Get Number
            ST24   DATA+1
            JSR    GETBYT                       ; Gobble )
            MOV    #1;DATA                      ; Data Type 1
            RTS

*===============================
* Name: STRSTR - Get A Number In String Form
*===============================

STRSTR      JSR    INPNARG                      ; Get Arg
            PUSHW  VECTOR                       ; Save Current Vector Value
            MOVD   #NIL;VECTOR                  ; Suppress Output
            JSR    GETNUMB                      ; Print Number To Memory
            JSR    DECOUT
            PULLW  VECTOR                       ; Restore Vector
            MOVD   VARSTR;DATA+1                ; Point To String
            MOV    TXTNUM;DATA+3                ; Save Length
            LDX    #1
SS_COPY     MOV    TXTNUM,X;(VARSTR)            ; Copy Byte
            INX
            JSR    INCVARST                     ; Inc String Space
            DBNE   TXTNUM;SS_COPY               ; Count The Digits

            MOV    #2;DATA                      ; Were Done
            RTS

*===============================
* Name: ASC - Get Ascii Value Of A String
*===============================

ASC         JSR    INPSARG                      ; Read String
            LDEQX  STRLEN;ASC2                  ; Any String There?

            LDA    (STRLOC)
            JMP    SVDATA                       ; Return Byte

ASC2        LDA    #-1                          ; return -1
            TAX
            TAY
            JSR    SAVEDATA
            LDX    #1                           ; SHOULD BE LDA #1
            STA    DATA
            RTS

CKMSARG     JSR    INPSARG
CHKMEM      LDA    STRLOC+1
CHKMEM2     CPLT   #>NODENUM;CHKMEM3            ; In scratch memory?
            CPLT   #>OVERBUF;CHKMEM4            ; In ramcard area?
CHKMEM3     SEC
            RTS

CHKMEM4     CLC
            RTS
            LST    OFF

