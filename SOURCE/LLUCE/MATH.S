            LST    RTN
            TTL    'LLUCE - Math Routines'
            PAG
*===============================
* Contents:
*
* ABS      - 24 Bit Absolute Value
* ADDITION - 24 Bit Addition
* DECREMNT - decrement variable
* DIVIDE   - 24 Bit Division
* DO_MATH  - save 24 bit math data
* DO_MUL0  - Actual Multiply Routine
* INCREMNT - increment variable
* MATH_16  - save 16 bit math data
* MOD      - 24 Bit Modulo
* MULTIPLY - 24 Bit Multiplication
* SHFTLFT  - 24 Bit shift left
* SHFTRGT  - 24 Bit shift right
* SUBTRACT - 24 Bit Subtraction
* Also contains all logic and numeric compares
*===============================

*===============================
*   Name: SHFTLFT - 24 Bit shift left
*
*  Input: None
*
* Output: X, A, Y = Result
*===============================

SHFTLFT     PUSH3  NUMB                     ; Save Old Number
            JSR    INPMATH                  ; Get Next Part
            PULL3  DATA+1

SL_LOOP     ASL    DATA+1
            ROL    DATA+2
            ROL    DATA+3
            JSR    NUMBSUB1
            JSR    NUMBZERO
            BNE    SL_LOOP
            JSR    GETDATA
            JMP    DO_MATH                  ; Finish Up

*===============================
*   Name: SHFTRGT - 24 Bit shift right
*
*  Input: None
*
* Output: X, A, Y = Result
*===============================

SHFTRGT     PUSH3  NUMB                     ; Save Old Number
            JSR    INPMATH                  ; Get Next Part
            PULL3  DATA+1

SR_LOOP     LSR    DATA+3
            ROR    DATA+2
            ROR    DATA+1
            JSR    NUMBSUB1
            JSR    NUMBZERO
            BNE    SR_LOOP
            JSR    GETDATA
            JMP    DO_MATH                  ; Finish Up

*===============================
*   Name: ADDITION - 24 Bit Addition
*
*  Input: None
*
* Output: X, A, Y = Result
*===============================

INCREMNT    BVS    INC_3
            BCC    INC_2
INC_0       JSR    INPNUM0A
INC_1       JSR    NUMBADD1
            JSR    GETNUMB
            JMP    DO_LET8A

INC_2       JSR    GETNUMB
            SVXAY
            JSR    INC_1
            RSTXAY
            BRA    DO_MATH

INC_3       JSR    INC_0
            JSR    GETNUMB
            BRA    DO_MATH

ADDITION    PUSH3  NUMB                     ; Save Old Number
            JSR    INPMATH                  ; Get Next Part
            CLC
            PLA
            ADC    NUMB                     ; Do Add
            TAX                             ; Low Byte In X
            PLA
            ADC    NUMB+1
            TAY
            PLA
            ADC    NUMB+2
            PHA
            TYA                             ; Mid Byte In A
            PLY                             ; High Byte In Y
            BRA    DO_MATH                  ; Finish Up

*===============================
*   Name: SUBTRACT - 24 Bit Subtraction
*
*  Input: None
*
* Output: X, A, Y = Result
*===============================

DECREMNT    BVS    DEC_3
            BCC    DEC_2
DEC_0       JSR    INPNUM0A
DEC_1       JSR    NUMBSUB1
            JSR    GETNUMB
            JMP    DO_LET8A

DEC_2       JSR    GETNUMB
            SVXAY
            JSR    DEC_1
            RSTXAY
            BRA    DO_MATH

DEC_3       JSR    DEC_0
            JSR    GETNUMB
            BRA    DO_MATH

SUBTRACT    PUSH3  NUMB                     ; Save Initial Value
            JSR    INPMATH                  ; Get Other Amount
            SEC
            PLA
            SBC    NUMB
            TAX                             ; Do Actual Subtraction
            PLA
            SBC    NUMB+1
            TAY
            PLA
            SBC    NUMB+2
            PHA
            TYA
            PLY
            SKIP2

MATH_16     LDY    #0
DO_MATH     JSR    SAVEDATA                 ; Save Result
            PHA
            MOV    #1;DATA                  ; Set Data Type 1
            PLA
            RTS

*===============================
*   Name: MULTIPLY - 24 Bit Multiplication
*
*  Input: None
*
* Output: X, A, Y = Result
*===============================

MULTIPLY    JSR    DO_MLDV                  ; Command Mult/Divd
            JSR    DO_MUL0                  ; Do Multiply

*===============================
* Finish Up Routine For Signed Operands
*===============================

DO_MLD2     LD24   RESULT                   ; Is It Apparently Neg.?
            BPL    DO_MLD3                  ; Nope, In Range

            LDA    #Numtobig
            JMP    BADERR                   ; Number Too Large

DO_MLD3     TSTPL  SIGN;DO_MATH             ; Supposed To Be Positive?

            JSR    NEGAXY                   ; Invert It..
            BRA    DO_MATH

DO_MLDV     JSR    GETNUMB                  ; Save First Number
            STY    SIGN                     ; Set For Negative
            JSR    DO_ABS1                  ; Make Sure Its Positive
            JSR    SAVEDATA
            JSR    INPNUM0                  ; Get Next Number
            LDA    NUMB+2
            EOR    SIGN                     ; (+/+)=+ (-/-)=+
            STA    SIGN                     ; (-/+)=- (+/-)=-
            JSR    GETNUMB
            JSR    DO_ABS1
            JMP    SAVENUMB

*===============================
*   Name: DO_MUL0 - Actual Multiply Routine
*
*  Input: None
*
* Output: None
*===============================

DO_MUL0     STZ    SETRAM1
            JSR    DO_MUL00
            BRA    DRAM4

*===============================
*   Name: DIVIDE - 24 Bit Division
*
*  Input: None
*
* Output: X, A, Y = Result
*===============================

DIVIDE      JSR    DO_DIV1                  ; Do Divide
            JMP    DO_MLD2

*===============================
*   Name: MOD - 24 Bit Modulo
*
*  Input: None
*
* Output: X, A, Y = Result
*===============================

MOD         JSR    DO_DIV1                  ; Do Divide
            MOV24  REMAIN;RESULT            ; Get Remainder
            JMP    DO_MLD2                  ; Finish Up

DO_DIV1     JSR    DO_MLDV
            STZ    SETRAM1
            JSR    DO_DIV1A
DRAM4       STZ    SETRAM2
            RTS

*===============================
*   Name: ABS - 24 Bit Absolute Value
*
*  Input: None
*
* Output: X, A, Y = Result
*===============================

ABS         JSR    INPARG
            JSR    GETNUMB                  ; Get Number
            JSR    DO_ABS1                  ; Get Abs
            JMP    DO_MATH                  ; Finish Up

DO_ABS1     CPPLY  #0;DO_ABS2               ; If It Is Already Ok

NEGAXY      JSR    NOT_XAY

            IBNE   X;DO_ABS2                ; And Add 1
            IBNE   A;DO_ABS2

            INY
DO_ABS2     RTS

NOT_XAY     EOR    #-1                      ; Not Positive, Invert It
            PHA
            TXA
            EOR    #-1
            TAX
            TYA
            EOR    #-1
            TAY
            PLA
            RTS

*===============================
* Compare Routines
*===============================

EQUAL       JSR    CP_ST                    ; Compare For Equal
            JSR    CMPEQ
            JMP    DO_MATH

NOTEQU      JSR    CP_ST                    ; Compare If Not Equal
            JSR    CMPEQ                    ; Just Inverse Compare Equal
            JSR    INVERT
            JMP    DO_MATH

LESS        JSR    CP_ST                    ; Compare If Less Than
            JSR    CP_LTGT
            JSR    CMPLT
            BRA    CP_END

GREATER     JSR    CP_ST                    ; Compare If Greater Than
            JSR    CP_LTGT
            JSR    CMPGT
            BRA    CP_END

LESSEQU     JSR    CP_ST                    ; Compare <=
            JSR    CP_LTGT
            JSR    CMPGT                    ; Invert, >
            JSR    INVERT
            BRA    CP_END

GREQU       JSR    CP_ST                    ; Compare =>
            JSR    CP_LTGT
            JSR    CMPLT                    ; Invert, <
            JSR    INVERT
            BRA    CP_END

AND         JSR    CP_ST                    ; bitwise AND 2 Numbers
            LDA    NUMB
            AND    DATA+1
            TAX
            LDA    NUMB+2
            AND    DATA+3
            TAY
            LDA    NUMB+1
            AND    DATA+2
            BRA    CP_END

OR          JSR    CP_ST                    ; bitwise OR 2 Numbers
            LDA    NUMB
            ORA    DATA+1
            TAX
            LDA    NUMB+2
            ORA    DATA+3
            TAY
            LDA    NUMB+1
            ORA    DATA+2
            BRA    CP_END

XOR         JSR    CP_ST                    ; bitwise EOR 2 Numbers
            LDA    NUMB
            EOR    DATA+1
            TAX
            LDA    NUMB+2
            EOR    DATA+3
            TAY
            LDA    NUMB+1
            EOR    DATA+2
CP_END      JMP    DO_MATH

BIN_NOT     JSR    INPNUM                   ; bitwise NOT
            JSR    NOT_XAY
            BRA    CP_END

CP_ST       PUSH3  NUMB                     ; Compare Start
            JSR    INPMATH
            PULL3  DATA+1
            RTS

CP_LTGT     LDA    DATA+3                   ; Invert Sign Bits
            EOR    #Hibit
            STA    DATA+3
            LDA    NUMB+2
            EOR    #Hibit
            STA    NUMB+2
            RTS

*===============================
* Logic Operations
*===============================

LOGICAND    LDX    #0                       ; Logical AND 2 numbers
            JSR    NUMBZERO
            BEQ    CMP2
            BREQ3  DATA+1;CMP2
            BRA    CMP1

LOGICOR     LDX    #0                       ; Logical OR 2 numbers
            JSR    NUMBZERO
            BNE    CMP1
            BREQ3  DATA+1;CMP2
            BRA    CMP1

CMPEQ       LDX    #0                       ; Compare Equal
            IFNE   NUMB;DATA+1;CMP2
            IFNE   NUMB+1;DATA+2;CMP2
            IFNE   NUMB+2;DATA+3;CMP2
CMP1        INX
CMP2        LDA    #0
            TAY
            RTS

CMPLT       LDX    #0                       ; Compare Less Than
            IFLT   NUMB+2;DATA+3;CMP2
            BNE    CMP1
            IFLT   NUMB+1;DATA+2;CMP2
            BNE    CMP1
            IFEQ   NUMB;DATA+1;CMP2
            BLT    CMP2
            BGE    CMP1

CMPGT       LDX    #0                       ; Compare Greater Than
            IFLT   DATA+3;NUMB+2;CMP2
            BNE    CMP1
            IFLT   DATA+2;NUMB+1;CMP2
            BNE    CMP1
            IFEQ   DATA+1;NUMB;CMP2
            BLT    CMP2
            BRA    CMP1

*===============================
* Name: NOT - logical "Not" A Value
*===============================

LOGICNOT    JSR    INPNUM                   ; Get Value
            STXY   TEMP
            LDX    #1
            ORA    TEMP                     ; See If Zero Or Non-Zero
            ORA    TEMP+1
            BEQ    DO_NOT2

            DEX
DO_NOT2     TXA
            JMP    SVDATA                   ; Save Result

INVERT      PHA                             ; Change Bit 0
            TXA
            EOR    #%00000001
            TAX
            PLA
            RTS
            LST    OFF

