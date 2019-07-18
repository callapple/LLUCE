            LST    RTN
            TTL    'LLUCE - Memory Commands'
            PAG
*===============================
* Contents:
*
* BYTE   - Byte Command
* CALL   - Call A Machine-Language Routine
* FILL   - Fill A Range Of Memory
* FLAG   - Flag Command
* MOVE   - Move Memory
* NIBBLE - Nibble Command
* PEEK   - Peek A Location
* POKE   - Poke A Value
* RAM    - Get Location Of Scratch RAM
* WORD   - Word Command
*===============================

*===============================
* Name: FLAG - Flag Command
*===============================

FLAG        IFEQ   (PRGPTR);#'('+Hibit;FLAG2    ; Is There An Arg?

            TSTPL  IMMDEF;FLAG1                 ; Was It An Assignment?

            JSR    EQUNUM16                     ; Get Location
            ST16   FLGPTR
            RTS

FLAG1       LD16   FLGPTR                       ; Get Current Pointer
            JMP    MATH_16                      ; And Return

FLAG2       BIT    IMMDEF                       ; Check Exec Status
            PHP                                 ; And Save It
            JSR    INPNARG6                     ; Get Arg
            TXA
            AND    #%00000111                   ; Save Bit Number
            TAX
            MOV    BITVAL,X;TEMP2               ; Convert To Bit Value
            LSR    NUMB+1                       ; Divide By 8
            ROR    NUMB
            LSR    NUMB+1
            ROR    NUMB
            LSR    NUMB+1
            ROR    NUMB
            ADD    FLGPTR;NUMB;TEMP             ; Add In Flag Location
            PLP
            BMI    FLAG4                        ; Set Bit..

            LDA    (TEMP)                       ; Get Byte
            AND    TEMP2                        ; And Value
            BEQ    FLAG3

            LDA    #1                           ; Return Flag Setting
FLAG3       JMP    SVDATA

FLAG4       JSR    EQUNUM
            BREQW  FLGPTR;FLAG7                 ; Has FLAG pointer been set?

            BRNE3  NUMB;FLAG5                   ; Check For Zero

            LDA    TEMP2                        ; Get Bit
            EOR    #-1                          ; Make Into Mask
            AND    (TEMP)                       ; Kill Bit
            BRA    FLAG6                        ; Save

FLAG5       LDA    TEMP2                        ; Get Bit
            ORA    (TEMP)                       ; Add In
FLAG6       STA    (TEMP)                       ; Save
FLAG7       RTS

*===============================
* Name: NIBBLE - Nibble Command
*===============================

NIBBLE      IFEQ   (PRGPTR);#'('+Hibit;NIBBLE2

            TSTPL  IMMDEF;NIBBLE1               ; get address

            JSR    EQUNUM16
            ST16   NIBPTR                       ; Save Pointer
            RTS

NIBBLE1     LD16   NIBPTR                       ; Get Point To Nibble
            JMP    MATH_16

NIBBLE2     BIT    IMMDEF                       ; Is This An Assignment?
            PHP
            JSR    INPNARG6                     ; Get Arg
            LSR    NUMB+1                       ; Divide By 2
            ROR    NUMB
            ROR    A                            ; Put Low Bit (C) In N
            STA    TEMP2                        ; Save It
            ADD    NUMB;NIBPTR;TEMP             ; Add In Nibble Location
            PLP
            BMI    NIBBLE4                      ; Assignment

            LDA    (TEMP)                       ; Get Byte
            TSTPL  TEMP2;NIBBLE3

            LSR    A                            ; Shift Down
            LSR    A
            LSR    A
            LSR    A
NIBBLE3     AND    #%00001111                   ; Get Rid Of Any Extra
            JMP    SVDATA

NIBBLE4     JSR    EQUNUM8
            BREQW  NIBPTR;NIBBLE8               ; Pointer Set Yet?

            TXA                                 ; Get Data
            CPLT   #16;NIBBLE5                  ; In Range?

            LDA    #15                          ; Set To Max
NIBBLE5     STA    TEMP3                        ; Save
            ASL    A                            ; Save X 16
            ASL    A
            ASL    A
            ASL    A
            STA    TEMP3+1
            TSTMI  TEMP2;NIBBLE6                ; Do Appropriate Save

            LDA    (TEMP)                       ; Get Orig Byte
            AND    #%11110000                   ; Kill Old
            ORA    TEMP3                        ; Insert New
            BRA    NIBBLE7                      ; Save

NIBBLE6     LDA    (TEMP)                       ; Get Orig Byte
            AND    #%00001111                   ; Kill Old Stuff
            ORA    TEMP3+1                      ; Insert New
NIBBLE7     STA    (TEMP)                       ; Save
NIBBLE8     RTS

*===============================
* Name: BYTE - Byte Command
*===============================

BYTE        IFEQ   (PRGPTR);#'('+Hibit;BYTE2

            TSTPL  IMMDEF;BYTE1                 ; Get Location?

            JSR    EQUNUM16
            ST16   BYTPTR                       ; Save New Pointer
            RTS

BYTE1       LD16   BYTPTR                       ; Return Current Pointer
            JMP    MATH_16

BYTE2       BIT    IMMDEF                       ; Is This An Assignment?
            PHP
            JSR    INPNARG6                     ; Get Arg
            ADD    NUMB;BYTPTR;TEMP             ; Add In Byte Location
            PLP
            BMI    BYTE3                        ; Yep -- ^^^^

            LDA    (TEMP)                       ; Get Data
            JMP    SVDATA

BYTE3       JSR    EQUNUM8                      ; Get Value
            BREQW  BYTPTR;BYTE4                 ; Pointer Set Yet?

            TXA
            STA    (TEMP)                       ; Save Value
BYTE4       RTS

*===============================
* Name: WORD - Word Command
*===============================

WORD        IFEQ   (PRGPTR);#'('+Hibit;WORD2

            TSTPL  IMMDEF;WORD1                 ; Get Location?

            JSR    EQUNUM16
            ST16   WORDPTR                      ; Save New Pointer
            RTS

WORD1       LD16   WORDPTR                      ; Return Current Pointer
            JMP    MATH_16

WORD2       BIT    IMMDEF                       ; Is This An Assignment?
            PHP
            JSR    INPNARG6                     ; Get Arg
            CLC                                 ; Divide By 2 (2 Bytes)
            ASL    NUMB
            ROL    NUMB+1
            ADD    NUMB;WORDPTR;TEMP            ; Add In Word Location
            PLP
            BMI    WORD3                        ; Yep -- ^^^^

            LDY    #1
            LDA    (TEMP)                       ; Get Data Low Byte
            TAX
            LDA    (TEMP),Y                     ; Hi Byte
            JMP    MATH_16

WORD3       JSR    EQUNUM16                     ; Get Value
            TAY
            BREQW  WORDPTR;WORD4                ; Pointer Set Yet?

            TYA
            LDY    #1
            STA    (TEMP),Y                     ; Save Value
            TXA                                 ; Low Byte In X
            STA    (TEMP)
WORD4       RTS

*===============================
* Name: RAM - Get Location Of Scratch RAM
*===============================

RAM         LDA    (PRGPTR)                     ; Use Default RAM?
            LDX    #0
            CPNE   #'('+Hibit;DEFRAM            ; Yes

            JSR    INPNARG8                     ; Get The Arg
            CPGEX  #4;RAM_ERR                   ; In Range (0-3)?

DEFRAM      CLC                                 ; Add To High Byte Of RAM
            TXA                                 ; Location
            ADC    #>SCRATCH
            LDX    #<SCRATCH
            JMP    MATH_16                      ; Return It

RAM_ERR     JMP    SYNTAX

*===============================
* Name: PEEK - Peek A Location
*===============================

PEEK        JSR    INPNARG6                     ; Get Arg
            ST16   TEMP
            LDA    (TEMP)                       ; Get Value
            JMP    SVDATA                       ; Return In

*===============================
* Name: POKE - Poke A Value
*===============================

POKE        JSR    NUM2TMP                      ; Get Place To Poke
            JSR    COMNUM8                      ; Get Value
            TXA
            STA    (TEMP)
            RTS

*===============================
* Name: CALL - Call A Machine-Language Routine
*===============================

CALL        JSR    NUM2TMP                      ; Get Address
            JMP    (TEMP)                       ; Transfer Control

*===============================
* Name: FILL - Fill A Range Of Memory
*===============================

FILL        JSR    RWPTRS
            JSR    COMNUM8                      ; Get Byte To Fill With
FILL2       TXA
            STA    (TEMP2)                      ; Fill
            JSR    COUNTUP
            BNE    FILL2                        ; Yes, Do More

            RTS

*===============================
* Name: MOVE - Move Memory
*===============================

MOVE        JSR    RWPTRS
            LDX    #To
            JSR    GOBBLE                       ; Gobble TO Statement
            JSR    NUM2TMP                      ; Get Destination Address
MOVE2       MOV    (TEMP2);(TEMP)               ; Copy Byte
            INCD   TEMP                         ; Increment Source
            JSR    COUNTUP
            BNE    MOVE2                        ; Nope

            RTS
            LST    OFF

