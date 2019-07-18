            LST    RTN
            TTL    'LLUCE - Program Flow'
            PAG
*===============================
* Contents:
*
* ELSE    - Else Statement
* FOR     - Handle For-Next Statement
* DO_DO   - start a DO loop
* GOSUB   - Gosub Statement
* GOTO    - Goto Statement
* IF      - If Statement
* NEXT    - Handle "Next" Part Of For-Next Loop
* NOCAR   - Setup No Carrier Vector
* ON      - Do ON Commands
* ONERROR - Setup On Error Vector
* POP     - Pop A Label Off The Gosub Stack
* PUSH    - Push A Label Onto The Stack
* RESUME  - Resume Command
* RETURN  - Return To The Address On The Stack
* WHILE   - end a DO loop, start a WHILE loop
*===============================

*===============================
* Name: GOTO - Goto Statement
*===============================

GT_RANGE    LDY    #0                           ; check range of goto with
            LD16   TEMP                         ; loop range
            CPLT   TEMP2+1;GT_OUT
            CPLTX  TEMP2;GT_OUT
            CPEQ   TEMP3+1;GT_LOW
            BGE    GT_OUT
GT_LOW      CPEQX  TEMP3;GT_IN
            BLT    GT_IN
GT_OUT      INY
GT_IN       TYA
            RTS

GOTO        JSR    GETRAW                       ; Get Address (No List)
            PHA
            JSR    GETRAW
DO_GT2      STA    TEMP+1                       ; Put Into Program Counter
            PULL   TEMP
DO_GT3      LDEQX  WHATLVL;DO_GT5               ; check loop in progress
            DEX                                 ; get loop type
            LDPL   WHATSTK,X;DO_GT4             ; its a while
            LDX    DOLVL                        ; get while start/end
            DEX
            MOV    WHLOCL,X;TEMP2
            MOV    WHLOCH,X;TEMP2+1
            MOV    END_WHIL,X;TEMP3
            MOV    END_WHIL+16,X;TEMP3+1
            JSR    GT_RANGE                     ; check the range
            BEQ    DO_GT5                       ; in range, do the goto
            DEC    WHILELVL
DO_GT3A     DEC    WHATLVL                      ; bump down the levels
            BRA    DO_GT3                       ; check next one

DO_GT4      LDX    DOLVL                        ; get DO start/end
            DEX
            MOV    DOLOCL,X;TEMP2
            MOV    DOLOCH,X;TEMP2+1
            MOV    END_DO,X;TEMP3
            MOV    END_DO+16,X;TEMP3+1
            JSR    GT_RANGE                     ; check the range
            BEQ    DO_GT5                       ; in range, goto
            DEC    DOLVL                        ; bump down the levels
            BRA    DO_GT3A

DO_GT5      MOVD   TEMP;PRGPTR                  ; reset program pointer
            RTS

*===============================
* Name: GOSUB - Gosub Statement
*===============================

GOSUB       IFEQX  GSBLVL;#16;STKFUL            ; enough room?

            JSR    GETRAW                       ; Get Address (No List)
            PHA
            JSR    GETRAW
            PHA
            MOV    PRGPTR;GSBSTKL,X             ; Current Address -> Stack
            MOV    PRGPTR+1;GSBSTKH,X
            INX                                 ; Increment Stack Pointer
            STX    GSBLVL
            PULL   PRGPTR+1
            PULL   PRGPTR
            RTS

*===============================
* Name: PUSH - Push A Label Onto The Stack
*===============================

PUSH        IFEQX  GSBLVL;#16;STKFUL            ; enough room?

            JSR    GETRAW                       ; Put Data Onto Stack
            STA    GSBSTKL,X
            JSR    GETRAW
            STA    GSBSTKH,X
            INX                                 ; Increment Stack Pointer
            STX    GSBLVL
            RTS

STKFUL      LDA    #Gsbfull                     ; Gosub Stack Full
            SKIP2
NOGSB       LDA    #Nogosub                     ; No Gosub Error
            SKIP2
DOSTKFUL    LDA    #DoFull
            SKIP2
NODOERR     LDA    #NoDo
            JMP    BADERR

*===============================
* Name: RETURN - Return To The Address On The Stack
*===============================

RETURN      LDEQX  GSBLVL;NOGSB                 ; Anything On Stack?
            DEX                                 ; Decrement Stack Pointer
            STX    GSBLVL
            MOV    GSBSTKL,X;PRGPTR
            MOV    GSBSTKH,X;PRGPTR+1
            RTS

*===============================
* Name: POP - Pop A Label Off The Gosub Stack
*===============================

POP         LDEQX  GSBLVL;NOGSB                 ; Anything On Stack?
            DEX                                 ; Decrement Stack Pointer
            STX    GSBLVL
            RTS

*===============================
* Name: DO - DO loop
*===============================

DO_DO       IFEQX  DOLVL;#16;DOSTKFUL           ; enough room?

            MOV    PRGPTR+1;DOLOCH,X
            PHA
            MOV    PRGPTR;DOLOCL,X              ; Current address -> stack
            PHAX
            CLC
            JSR    FINDEND                      ; find DOs end
            PLX
            MOV    PRGPTR;END_DO,X              ; save it
            MOV    PRGPTR+1;END_DO+16,X
            PULLW  PRGPTR                       ; restore pointer
            INC    DOLVL                        ; Increment stack pointer

            LDX    WHATLVL                      ; save type on stack
            STZ    WHATSTK,X
            INC    WHATLVL

DO_TOP      JSR    ZAP_CHNS
            JSR    RUN                          ; run to end of line or block
            CPEQ   #Break;DO_BRK
            CPNE   #Continue;DO_TEST

            LDX    DOLVL                        ; Anything on stack?
            DEX                                 ; Decrement stack pointer
            MOV    END_DO,X;PRGPTR              ; point back to start
            MOV    END_DO+16,X;PRGPTR+1

DO_TEST     JSR    ZAP_CHNS

            LDX    #While                       ; must be a WHILE here
            JSR    GOBBLE

            LDA    (PRGPTR)
            CMP    #'('+Hibit
            BNE    DO_SYN

            JSR    INPNUM                       ; Evaluate expression
            STXY   TEMP                         ; Save high and low byte
            ORA    TEMP                         ; Is it not zero?
            ORA    TEMP+1
            BEQ    POPDO                        ; It is, just return

            LDX    DOLVL                        ; Anything on stack?
            DEX                                 ; Decrement stack pointer
            MOV    DOLOCL,X;PRGPTR              ; point back to start
            MOV    DOLOCH,X;PRGPTR+1
            BRA    DO_TOP                       ; and continue

DO_BRK      LDX    DOLVL
            DEX
            MOV    END_DO,X;PRGPTR
            MOV    END_DO+16,X;PRGPTR+1
            JSR    GETRAW                       ; skip the WHILE statement
            PUSHW  VECTOR
            MOVD   #NIL;VECTOR
            JSR    INPNUM                       ; Evaluate expression
            PULLW  VECTOR
POPDO       DEC    DOLVL
            DEC    WHATLVL
            RTS

DO_SYN      JMP    SYNTAX

*===============================
* Name: WHILE - WHILE loop
*===============================

WHSTKFUL    LDA    #WhileFul
            JMP    BADERR

WHILE       IFEQX  WHILELVL;#16;WHSTKFUL        ; pending DO?

            MOV    PRGPTR+1;WHLOCH,X
            PHA
            MOV    PRGPTR;WHLOCL,X              ; Current address -> stack
            PHAX
            IFNE   (PRGPTR);#'('+Hibit;DO_SYN
            JSR    INPNUM
            SEC
            JSR    FINDEND                      ; find WHILEs end
            PLX
            MOV    PRGPTR;END_WHIL,X            ; save it
            MOV    PRGPTR+1;END_WHIL+16,X
            PULLW  PRGPTR                       ; restore pointer
            INX                                 ; Increment stack pointer
            STX    WHILELVL

            LDX    WHATLVL
            LDA    #-1
            STA    WHATSTK,X
            INC    WHATLVL

WH_TOP      IFNE   (PRGPTR);#'('+Hibit;DO_SYN

            JSR    INPNUM                       ; Evaluate expression
            STXY   TEMP                         ; Save high and low byte
            ORA    TEMP                         ; Is it not zero?
            ORA    TEMP+1
            BEQ    WH_FALSE

            JSR    ZAP_CHNS
            JSR    RUN                          ; run this section
            CPEQ   #Break;WH_FALSE

WH_CONT     LDX    WHILELVL                     ; Anything on stack?
            DEX                                 ; Decrement stack pointer
            MOV    WHLOCL,X;PRGPTR              ; point back to start
            MOV    WHLOCH,X;PRGPTR+1
            BRA    WH_TOP                       ; loop

WH_FALSE    DEC    WHILELVL                     ; kill the last while
            LDX    WHILELVL
            MOV    END_WHIL,X;PRGPTR
            MOV    END_WHIL+16,X;PRGPTR+1
            DEC    WHATLVL
            JMP    ZAP_CHNS

*===============================
* Name: IF - If Statement
*===============================

IF          JSR    INPNUM                       ; Evaluate Expression
            STXY   TEMP                         ; Save High And Low Byte
            ORA    TEMP                         ; Is It Not Zero?
            ORA    TEMP+1
            BNE    IF_TRUE                      ; It Is, Just Return
            SEC
            JSR    FINDEND
            JSR    ZAP_CHNS
            CPNE   #Else;IF_TRUE                ; is there an ELSE?
            JSR    GETBYT                       ; eat the else
            JSR    ZAP_CHNS
IF_TRUE     STZ    LSTTXT                       ; Clear Text Mode
            RTS

*===============================
* Name: ELSE - Else Statement
*===============================

ELSE        SEC
            JSR    FINDEND
            JSR    ZAP_CHNS
            CPEQ   #Else;ELSE                   ; eat ELSEs too
            STZ    LSTTXT                       ; Clear Text Mode
            RTS

FINDEND     PHP                                 ; save eat status
            JSR    ZAP_CHNS                     ; skip chains
            CPNE   #CompStrt;FIND_EOL           ; doing block?

FIND_EOB    JSR    GETRAW                       ; eat the start
            LDY    #0                           ; start level 0
EOB_2       PHY
            JSR    IFGOB                        ; eat byte(s)
            PLY
            STA    LSTTOK
            LDNEX  LSTTXT;EOB_2                 ; Doing Text, no other test

            CPNE   #CompStrt;EOB_3              ; Start of another block?
            IBRA   Y;EOB_2                      ; count up

EOB_3       CPNE   #CompEnd;EOB_2               ; End Of Line?
            CPEQY  #0;EOB_4                     ; End of our block?
            DBRA   Y;EOB_2                      ; count down blocks

EOB_4       PLP
            BCC    ZAP_CHNS
            JSR    GETRAW                       ; eat closing }
            BRA    ZAP_CHNS

FIND_EOL    JSR    IFGOB                        ; Loop Until A Chain Or Else
            STA    LSTTOK
            LDNEX  LSTTXT;FIND_EOL              ; Doing Text, no other test
            CPEQ   #Chain2;EOL_1                ; End Of Line?
            CPNE   #Else;FIND_EOL               ; Is There An Else Clause?
EOL_1       PLP
            BRA    ZAP_CHNS

ZAP_C       JSR    GETRAW
ZAP_CHNS    IFEQ   (PRGPTR);#Chain;ZAP_C        ; skip chains
            CPEQ   #Chain2;ZAP_C
            RTS

*===============================
* Gobble Program Bytes
*===============================

IFGOB       STZ    SETRAM1                      ; Switch In Subs
            JSR    IFGOB1
            STZ    SETRAM2                      ; Switch Out Subs
            RTS

*===============================
* Name: FOR - Handle For-Next Statement
*===============================

FOR         IFLTX  FORLVL;#16;DO_FOR1           ; enough room?
            LDA    #Forfull
            JMP    BADERR

DO_FOR1     LDY    #1                           ; get first char of name
DO_FOR2     LDPL   (PRGPTR),Y;DO_FOR4           ; if hi bit clear, not name
            JSR    TST_ALF                      ; is it alpha?
            BCC    DO_FOR3                      ; yes, part of name
            JSR    TST_NUM                      ; how about number?
            BCS    DO_FOR4                      ; nope, name done
DO_FOR3     AND    #Clrhi
            PHA                                 ; save byte
            INY                                 ; point to next byte
            CPLTY  #5;DO_FOR2                   ; at max size?

DO_FOR4     LDA    #0                           ; fill rest with 0s
DO_FOR5     CPGEY  #5;DO_FOR6                   ; at max size?
            PHA                                 ; save it
            IBNE   Y;DO_FOR5                    ; always

DO_FOR6     JSR    LET                          ; Do Assign
            LDX    FORLVL                       ; Get Level
            PULL   FORVARH,X                    ; save var name
            PULL   FORVARMH,X
            PULL   FORVARML,X
            PULL   FORVARL,X
            LDX    #To                          ; Gobble "TO" Statement
            JSR    GOBBLE
            JSR    INPNUM
            PHY
            PHA
            TXA
            LDX    FORLVL                       ; Save End Value
            STA    FORENDL,X
            PULL   FORENDM,X
            PULL   FORENDH,X
            MOV    #1;FORSTPL,X                 ; Save Default Step (1)
            STZ    FORSTPM,X
            STZ    FORSTPH,X
            IFNE   (PRGPTR);#Step;DO_FOR7       ; step specified?

            JSR    GETBYT                       ; Gobble "STEP"
            JSR    INPNUM                       ; Get Step
            PHY
            PHA
            TXA
            LDX    FORLVL
            STA    FORSTPL,X                    ; Save Desired Step
            PULL   FORSTPM,X
            PULL   FORSTPH,X
            ORA    FORSTPM,X                    ; Did They Try Step 0?
            ORA    FORSTPL,X
            BEQ    FOR_ERR                      ; The Dolt! Error Out

DO_FOR7     LDX    FORLVL                       ; Save FOR Address
            MOV    PRGPTR;FORLOCL,X
            MOV    PRGPTR+1;FORLOCH,X
            INC    FORLVL                       ; Inc Level
            RTS

FOR_ERR     JMP    SYNTAX

*===============================
* Name: NEXT - Handle "Next" Part Of For-Next Loop
*===============================

NEXT        LDNEX  FORLVL;DO_NXT2               ; Check For Next Without For
DO_NXT1     LDA    #Nonext
            JMP    BADERR

DO_NXT2     IFNE   (PRGPTR);#Number;DO_NXT4     ; variable must be #

            JSR    VARSET                       ; Get The Variable
            LDX    FORLVL                       ; Get Level
DO_NXT3     DBMI   X;DO_NXT1                    ; Bump Down One

            IFNE   FORVARL,X;VNAME;DO_NXT3      ; check for name
            IFNE   FORVARML,X;VNAME+1;DO_NXT3
            IFNE   FORVARMH,X;VNAME+2;DO_NXT3
            IFNE   FORVARH,X;VNAME+3;DO_NXT3

            INX                                 ; Bump Pointer Up 1
            STX    FORLVL                       ; This Resets The FOR Stack
            BRA    DO_NXT5                      ; For Dropped Levels

DO_NXT4     DEX                                 ; Back Down 1 Level
            MOV    FORVARL,X;VNAME              ; Restore Var Pointer
            MOV    FORVARML,X;VNAME+1
            MOV    FORVARMH,X;VNAME+2
            MOV    FORVARH,X;VNAME+3
            JSR    VARSET2                      ; Find Var In Memory
DO_NXT5     LDX    FORLVL
            DEX
            MOVD   VPTR;TEMP                    ; Move Pointer
            LDY    #2
            LDMI   FORSTPH,X;DO_NXT9            ; Doing Negative Step?

            IFLT   (TEMP),Y;FORENDH,X;DO_NXT12
            BEQ    DO_NXT6                      ; Hmmm, Check Mid Byte
            BRA    DO_NXT8                      ; Yes, We Are Done

DO_NXT6     DEY
            IFLT   (TEMP),Y;FORENDM,X;DO_NXT12
            BEQ    DO_NXT7                      ; Maybe, Check Low Byte
            BRA    DO_NXT8

DO_NXT7     DEY
            IFLT   (TEMP),Y;FORENDL,X;DO_NXT12
DO_NXT8     DEC    FORLVL
            RTS

DO_NXT9     IFEQ   (TEMP),Y;FORENDH,X;DO_NXT10
            BLT    DO_NXT8                      ; Yes, Finish Up
            BGE    DO_NXT12                     ; Nope, Loop

DO_NXT10    DEY                                 ; Are We Done With Mid Byte?
            IFEQ   (TEMP),Y;FORENDM,X;DO_NXT11
            BLT    DO_NXT8                      ; If Less, We Are Done
            BGE    DO_NXT12                     ; Not Done, Do Another

DO_NXT11    DEY                                 ; Are We Done With Low Byte?
            IFEQ   (TEMP),Y;FORENDL,X;DO_NXT8
            BLT    DO_NXT8                      ; If Less, We Are Done

DO_NXT12    MOV    FORLOCL,X;PRGPTR             ; Point To "FOR" Location
            MOV    FORLOCH,X;PRGPTR+1
            CLC                                 ; Add In Step Value
            AD     (TEMP);FORSTPL,X;(TEMP)
            LDY    #1
            AD     (TEMP),Y;FORSTPM,X;(TEMP),Y
            INY
            AD     (TEMP),Y;FORSTPH,X;(TEMP),Y
            RTS

*===============================
* Name: ON - Do ON Commands
*===============================

ON          IFEQ   (PRGPTR);#Nocar;GO_CAR       ; Is It ON NOCAR?
            CPEQ   #Onerr;GO_ERR                ; Is It ON ERROR?

            JSR    INPNUM                       ; Get Value
            JSR    GETBYT                       ; Get ON Type
            PHA                                 ; Save It
            JSR    GETRAW                       ; Get ON Count
            STA    TEMP                         ; Save Count Number
            STZ    TEMP+1
            ASL    TEMP                         ; Multiply By 2 For Index
            ROL    TEMP+1
            LDNEY  NUMB;DECIT                   ; Decrement Number
            DEC    NUMB+1
DECIT       DEC    NUMB
            CMP    NUMB                         ; In Range?
            PHP
            ASL    NUMB                         ; Multiply By 2 For Index
            ROL    NUMB+1
            PLP
            BEQ    DO_ON2
            BGE    DO_INDX

DO_ON2      PLA
ADD_CNT     ADD    PRGPTR;TEMP;PRGPTR           ; Add In Count To End Of ON
            RTS

GO_CAR      BRA    NOCAR
GO_ERR      BRA    ONERROR

DO_INDX     ADD    PRGPTR;NUMB;TEMP2            ; Point To ON Element
            JSR    ADD_CNT                      ; Point To End Of ON
            PLA                                 ; Get Back ON Type
            LDY    #1
            CPNE   #Goto;NOTGTO                 ; Is It ON GOTO?

ON_GO       PUSHA  (TEMP2)                      ; Do The GOTO
            LDA    (TEMP2),Y
            JMP    DO_GT2

NOTGTO      IFNEX  GSBLVL;#16;ON_DOIT           ; enough room?
            JMP    STKFUL                       ; No, Error

ON_DOIT     CPEQ   #Gosub;ON_GOSUB              ; Is It A Gosub?
            CPEQ   #Push;ON_PUSH                ; Is It A Push?
            JMP    SYNTAX

ON_GOSUB    MOV    PRGPTR;GSBSTKL,X             ; Save New Location
            MOV    PRGPTR+1;GSBSTKH,X
            INX                                 ; Increment Pointer
            STX    GSBLVL
            MOV    (TEMP2);PRGPTR
            MOV    (TEMP2),Y;PRGPTR+1
            RTS

ON_PUSH     MOV    (TEMP2);GSBSTKL,X
            MOV    (TEMP2),Y;GSBSTKH,X
            INX
            STX    GSBLVL
            RTS

*===============================
*   Name: DO_NOCD2 - Setup No Carrier Vector
*
*  Input: None
*
* Output: None
*===============================

NOCAR       JSR    GETBYT                       ; Skip NOCAR Token
            STZ    NOCDFLG                      ; Reset Carrier Vector
            JSR    GETRAW                       ; See If It Has A Vector
            CPNE   #Goto;DO_NOC2                ; Was It Goto?

            JSR    GETRAW                       ; Get Low Byte Of Routine
            STA    NOCDVEC
            JSR    GETRAW                       ; Get High Byte Of Routine
            STA    NOCDVEC+1
            DEC    NOCDFLG                      ; Turn On Routine
DO_NOC2     RTS

*===============================
*   Name: DO_OERR2 - Setup On Error Vector
*
*  Input: None
*
* Output: None
*===============================

ONERROR     JSR    GETBYT                       ; Skip ERROR Token
            STZ    ONERRFLG                     ; Reset Error Vector
            STZ    FROMERR                      ; Set No Error
            STZ    FROMERR+1
            JSR    GETRAW                       ; See If It Has A Vector
            CPNE   #Goto;DO_ERR2                ; Was It Goto?

            JSR    GETRAW                       ; Get Low Byte Of Routine
            STA    ONERRVEC
            JSR    GETRAW                       ; Get High Byte Of Routine
            STA    ONERRVEC+1
            DEC    ONERRFLG                     ; Turn On Routine
DO_ERR2     RTS

*===============================
* Name: RESUME - Resume Command
*===============================

RESUME      BREQW  FROMERR;NOERR                ; Was There An Error?

            LDX    FROMERR+1
            LDNE   FROMERR;BACKBYT              ; Replace Error Location
            DEX                                 ; go back one byte just in case
BACKBYT     DEC    A                            ; the error happened on eol
            STX    PRGPTR+1
            STA    PRGPTR

            LDRA   (PRGPTR);TSTIT2

TSTIT       JSR    IFGOB                        ; Loop Until A Chain
TSTIT2      STA    LSTTOK
            LDNEX  LSTTXT;TSTIT                 ; Doing Text, no other test
            CPEQ   #Chain;RESUM2                ; End Of Line?
            CPNE   #Chain2;TSTIT

RESUM2      STZ    LSTTXT                       ; Clear Text Mode
            RTS

NOERR       STZ    ONERRFLG                     ; Dont Trap This One
            LDA    #Noerr                       ; No Error Occurred
            JMP    BADERR
            LST    OFF

