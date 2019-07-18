            LST     RTN
            TTL     'LLUCE - Variable Handler'
            PAG
*===============================
* Contents:
*
* ARGTYP   - Get Argument Type
* CHKFRE   - Check Free Memory
* FREE     - Clean Up String Space
* GETDATA  - get 24 bit number from DATA
* GETNUMB  - get 24 bit number from NUMB
* INPARG   - Get An Argument
* INPMATH  - Get 24 Bit Number Or Expression For Math Op
* INPNARG  - Get 24 Bit Numeric Argument
* INPNARG6 - Get 16 Bit Argument
* INPNARG8 - Get 8 Bit Argument
* INPNUM   - Get 24 Bit Number Or Expression
* INPNUM0  - Get A 24 Bit Number
* INPNUM8  - Get 8 Bit Number
* INPNUM16 - Get 16 Bit Number
* INPPAR   - Get Number In Parentheses
* INPSARG  - Get String Argument
* INPSTR   - Get A String
* INPSTR0  - Get A String
* INSTR2   - Get String, Save Memory
* NUMBADD1 - add 1 to NUMB
* NUMBSUB1 - subtract 1 from NUMB
* NUMBZERO - check if NUMB is zero
* PUTNUM   - put 24 bit number in NUM
* SAVEDATA - save 24 bit number in DATA
* SAVENUMB - save 24 bit number in NUMB
* STRCMP   - Compare Strings
* STRCOPY  - Copy A String To String Space
* SVDATA   - save numeric data
* SVSTR    - save string data
* VARSET   - Set Pointers To Variable
* ZERONUM  - zero NUM
* Also contains all string compare routines
*===============================

*===============================
*   Name: VARSET - Set Pointers To Variable
*
*  Input: Program Pointer
*
* Output: VARNAM And VARPNT
*===============================

VARSET      JSR     GETBYT                       ; Get String/Number Token
            PHA
            LDX     #0
VARSET0     LDPL    (PRGPTR);VARSET0C            ; get pgm byte, + is not var name
            JSR     TST_ALF                      ; if alpha, is part of name
            BCC     VARSET0B
            JSR     TST_NUM                      ; if number, part of name
            BCS     VARSET0C

VARSET0B    JSR     GETBYT                       ; gotta increment the pointer
            AND     #Clrhi                       ; clear the high bit
            STA     VNAME,X                      ; and save it
            INX
            CPNEX   #4;VARSET0                   ; 4 chars max

VARSET0C    CPEQX   #4;VARSET0D                  ; zero the rest of it
            STZ     VNAME,X
            IBNE    X;VARSET0C

VARSET0D    PLA
            CPEQ    #Number;VARSET2              ; Handle Number
            CPEQ    #String;VARSET1              ; Handle String
            JMP     SYNTAX                       ; Syntax Error!

VARSET1     LDA     VNAME                        ; Show Its A String
            ORA     #Hibit
            STA     VNAME

VARSET2     PUSHW   TEMP2                        ; Save TEMP2

            MOVD    HIMEM;TEMP                   ; point to top of variable space
            STA     TEMP2+1

VARSET3     SEC                                  ; Temp = Temp - 8
            SB      TEMP;#vRecSize;TEMP
            STA     TEMP2
            BCS     VARSET4
            DEC     TEMP+1
            DEC     TEMP2+1

VARSET4     LDEQ    (TEMP);VARSET6               ; Check Byte 1, create new
            CPNE    VNAME;VARSET3

            LDY     #3
VARSET4A    IFNE    (TEMP),Y;VNAME,Y;VARSET3     ; check bytes
            DBNE    Y;VARSET4A

VARSET5     CLC                                  ; Vptr = Temp + 4
            AD      TEMP;#valOffs;VPTR
            TAX                                  ; A & X Points At Var
            AD      TEMP+1;#0;VPTR+1

            PULLW   TEMP2                        ; Restore TEMP2
            RTS

VARSET6     SEC
            LDA     TEMP+1
            SBC     LOMEM+1                      ; +(Himem-Lomem)/2
            LSR     A
            CLC
            ADA     LOMEM+1;MIDMEM+1             ; Compute Midmem Value
            STZ     MIDMEM
            SEC
            SB      TEMP2;#vRecSize;TEMP2
            BCS     VARSET7
            DEC     TEMP2+1

VARSET7     LDX     #vRecSize*2-1
            LDA     #0                           ; Fill rest with 0s
VARSET8     STA     (TEMP2)
            INCD    TEMP2
            DBPL    X;VARSET8

            LDY     #3
VARSET8A    MOV     VNAME,Y;(TEMP),Y             ; Save the var name
            DBPL    Y;VARSET8A
            BRA     VARSET5                      ; Set Up Pointers

FIX_MID     SEC
            LDA     HIMEM+1                      ; Midmem=Lomem
FIX_MID2    SBC     LOMEM+1                      ; +(Himem-Lomem)/2
            LSR     A
            CLC
            ADA     LOMEM+1;MIDMEM+1             ; Compute Midmem Value
            STZ     MIDMEM
            RTS

*===============================
*   Name: INPNARG8 - Get 8 Bit Argument
*
*  Input: Program Pointer
*
* Output: A, X, Y Number Gotten
*===============================

INPNARG8    JSR     INPNARG                      ; Get The Argument
            BRA     TEST8                        ; Test For 8 Bits

*===============================
*   Name: INPNARG6 - Get 16 Bit Argument
*
*  Input: Program Pointer
*
* Output: A, X, Y Number Gotten
*===============================

INPNARG6    JSR     INPNARG                      ; Get The Argument
            BRA     TEST16                       ; Test For 8 Bits

*===============================
*   Name: INPNUM16 - Get 16 Bit Number
*
*  Input: Program Pointer
*
* Output: A, X, Y Number Gotten
*===============================

EQUNUM16    JSR     GOBEQU
            BRA     INPNUM16

COMNUM16    JSR     GOBCOM
INPNUM16    JSR     INPNUM                       ; Get The Number
            BRA     TEST16                       ; Test For 16 Bits

*===============================
*   Name: INPNUM8 - Get 8 Bit Number
*
*  Input: Program Pointer
*
* Output: A, X, Y Number Gotten
*===============================

EQUNUM8     JSR     GOBEQU
            BRA     INPNUM8

COMNUM8     JSR     GOBCOM
            BRA     INPNUM8

BYTNUM8     JSR     GETBYT
INPNUM8     JSR     INPNUM                       ; Get The Number
TEST8       CPPLY   #0;TEST8A                    ; Test for 8 bit number
            CPNEY   #-1;NUMERR
            CPEQ    #-1;TEST8B

TEST8A      BNE     NUMERR                       ; Test For 8 Bit Number
            CPNE    #0;NUMERR
TEST8B      RTS

TEST16      CPPLY   #0;TEST16A                   ; Test For 16 Bit Number
            CPY     #-1
TEST16A     BNE     NUMERR                       ; Yes, Error
            RTS

NUMERR      LDA     #Numtobig                    ; Execute Error
            JMP     BADERR

*===============================
*   Name: INPNUM - Get 24 Bit Number Or Expression
*
*  Input: Program Pointer
*
* Output: A, X, Y Number Gotten
*===============================

EQUNUM      JSR     GOBEQU
INPNUM      PUSHW   TEMP                         ; Save Temp Vars
            PUSHW   TEMP2
            JSR     INPNUM0                      ; Get Initial Number
INPNUMA     LDMI    (PRGPTR);INPNUMB
            CPEQ    #Hitoken;INPNUMB             ; High Order Token?
            CPGE    #Compare;INPNUMC             ; Dont Do Compare Operands

INPNUMB     PULLW   TEMP2                        ; Restore Temporaries
            PULLW   TEMP
            BRA     GETNUMB

INPNUMC     CLV
            JSR     INPNUM2                      ; Exec Token
            BRA     INPNUMA

*===============================
*   Name: INPMATH - Get 24 Bit Number Or Expression
*                   For Math Operations
*
*  Input: Program Pointer
*
* Output: A, X, Y Number Gotten
*===============================

INPMATH     JSR     INPNUM0                      ; Get Initial Number
INPMTH1     LDMI    (PRGPTR);GETNUMB
            CPLT    #Math;GETNUMB                ; Check For Math Operand
            CPGE    #Hitoken;GETNUMB

            CLV
            JSR     INPNUM2
            BRA     INPMTH1

*===============================
*   Name: INPPAR - Get Number In Parentheses
*
*  Input: Program Pointer
*
* Output: A, X, Y Number Gotten
*===============================

INPPAR      JSR     GETBYT                       ; Get The Byte
            JSR     INPNUM
            JSR     SAVENUMB                     ; Save Number
            JSR     GETBYT
            CPNE    #')'+Hibit;SYN1              ; Was Close There?

GETNUMB     LD24    NUMB                         ; Save The Number
            RTS

SYN1        JMP     SYNTAX                       ; Give Error

*===============================
*   Name: INPNUM0 - Get A 24 Bit Number
*
*  Input: Program Pointer
*
* Output: A, X, Y Number Gotten
*===============================

INPNUM0     ZERO24  NUMB                         ; Init Number
            LDA     (PRGPTR)                     ; Get Next Token
            CPEQ    #Chain;INPNUM0D              ; End Of Statement?
            CPEQ    #Chain2;INPNUM0D             ; End Of Line?
            CPEQ    #Number;INPNUM0A             ; Is It A Number?
            CPEQ    #String;INPNUM0B             ; Is It A String?
            CPLT    #ThreeByte+1;INPBYTES        ; is it a constant #?
            CPEQ    #'"'+Hibit;INPNUM0B          ; Is It A Literal
            CPEQ    #'('+Hibit;INPPAR            ; If An Expression
            CMP     #Strtyp                      ; Check If Other Token
            CLV
            BLT     INPNUM2

            CPLT    #Compare;INPNUM0B            ; Is It A String?
            CPPL    #0;INPNUM2X                  ; Is It A Token?

            JSR     TST_NUM                      ; Is It A Number?
            BCS     SYN1                         ; No, Error
            BRA     INPNUM0C

INPNUM0A    JSR     VARSET                       ; Set Up The Variable
INPNUM0X    LDA     (VPTR)                       ; Get Value Of Variable
            TAX                                  ; Low Byte Goes In X
            STX     NUMB
            LDY     #1
            PUSHA   (VPTR),Y                     ; middle byte in A (later)
            STA     NUMB+1
            INY
            LDA     (VPTR),Y
            TAY                                  ; High Byte In Y
            STY     NUMB+2
            PLA                                  ; Middle Byte
            RTS

INPNUM0B    JSR     STRCMP                       ; Get Value Of Expression
            STX     NUMB
INPNUM0Z    STZ     NUMB+1
            STZ     NUMB+2
            RTS

INPBYTES    STZ     NUMB                         ; zero out NUMB
            JSR     INPNUM0Z
            JSR     GETBYT                       ; get byte type
            TAX
            DEX                                  ; make into count
            DEX
            LDY     #0                           ; set NUMB index
INPBLUP     JSR     GETRAW                       ; get a byte (no check or list)
            STA     NUMB,Y                       ; save it
            INY
            DBNE    X;INPBLUP
            RTS

INPNUM0C    JSR     NUMIN                        ; Get The Number
            JSR     SAVENUMB                     ; Save Number
            CPPLY   #0;INPNUMX

            LDA     #Misssym
            SKIP2
INPNUM0D    LDA     #Missdata
            JMP     BADERR

INPNUM0E    JMP     MISSMTCH

INPNUM2X    BIT     SEV
INPNUM2     STZ     DATA                         ; Reset Data
            PHP
            JSR     GETBYT
            PLP
            CLC                                  ; Call From Somewhere Else
            JSR     EX_TOK                       ; Exec The Token
            LDA     DATA
            AND     #%00000001                   ; Did We Get Valid Data?
            BEQ     INPNUM0E                     ; Nope

            JSR     GETDATA                      ; Transfer Data
SAVENUMB    ST24    NUMB                         ; Save Number
INPNUMX     RTS

*===============================
*   Name: INPNARG - Get 24 Bit Numeric Argument
*
*  Input: Program Pointer
*
* Output: A, X, Y Number Gotten
*===============================

INPNARG     JSR     INPARG                       ; Do Input
            AND     #%00000001
            BNE     INPNUM0E                     ; If String, Error

            JMP     GETNUMB                      ; Return Values

*===============================
*   Name: INPSARG - Get String Argument
*
*  Input: Program Pointer
*
* Output: A, X = Pointer, Y = Length
*===============================

INPSARG     JSR     INPARG                       ; Do Input
            AND     #%00000001
            BEQ     INPNUM0E                     ; If Number, Error

            RTS

*===============================
*   Name: INPARG - Get An Argument
*
*  Input: Program Pointer
*
* Output: Pointer For Arguments
*         String Or Number
*===============================

INPARG      JSR     GETBYT                       ; Get Data
            CPEQ    #'('+Hibit;INPARG2           ; Check For Start/Continue
            CPNE    #','+Hibit;INPNUM0D          ; Of An Argument

INPARG2     JSR     ARGTYP                       ; Get Type (Number/String)
            PHP
            BCS     INPARG3

            JSR     INPNUM
            BRA     INPARG4

INPARG3     JSR     INPSTR
INPARG4     LDA     (PRGPTR)                     ; Check Next Byte
            LDX     #1
            CPEQ    #','+Hibit;INPARG5           ; Is There More?

            JSR     GETBYT                       ; Get The Rest
            LDX     #0
            CPNE    #')'+Hibit;INPNUM0D          ; Of Arg

INPARG5     TXA                                  ; Bit 0: Clear = Number
            PLP                                  ;          Set = String
            ROL     A                            ; Bit 1: Clear = Done
            CMP     #0                           ;          Set = More Args
            RTS

*===============================
*   Name: INSTR2 - Get String, Save Memory
*
*  Input: Program Pointer
*
* Output: String Pointer
*===============================

INSTR2      PUSHW   VARSTR                       ; Save String Pointer
            JSR     INPSTR                       ; Get The String
            PULLW   VARSTR                       ; Restore Old Pointer
            RTS

*===============================
*   Name: INPSTR - Get A String
*
*  Input: Program Pointer
*
* Output: String Pointer
*===============================

EQUSTR      JSR     GOBEQU
INPSTR      JSR     INPSTR0
            ST16    STRLOC                       ; Save Length And Location
            STY     STRLEN
            IFNE    (PRGPTR);#Math;INPSTRD       ; A Quick Exit Point

            PUSHW   VARSTR                       ; Save The New Pointer
            PHY
            JSR     GETBYT                       ; Save String Space Start
            JSR     STRCOPY
INPSTRB     PUSHW   VARSTR                       ; Save Current Pointer
            JSR     INPSTR0                      ; Get New String
            ST16    STRLOC
            STY     STRLEN
            PULLW   VARSTR                       ; Restore Var Pointers
            PULL    TTLLEN                       ; Update Length
            JSR     STRCOPY                      ; Copy The New String
            PUSHA   TTLLEN
            IFNE    (PRGPTR);#Math;INPSTRC       ; If There More, Do It

            JSR     GETBYT                       ; Gobble And Continue
            BRA     INPSTRB

INPSTRC     PULL    STRLEN                       ; Put Back Data
            PULLW   STRLOC
INPSTRD     LD16    STRLOC                       ; Get Back Stuff
            LDY     STRLEN
            RTS

*===============================
*   Name: INPSTR0 - Get A String
*
*  Input: Program Pointer
*
* Output: String Pointer
*===============================

INPSTR0     IFEQ    (PRGPTR);#'"'+Hibit;INPSTR1  ; If Text
            CPNE    #String;INPSTR5              ; Handle Token

            JSR     VARSET                       ; Point To Var
GETVINFO    LDY     #1
            PUSHA   (VPTR),Y                     ; Get High-Byte Of Pointer
            LDA     (VPTR)                       ; Get Low-Byte Of Pointer
            TAX
            INY
            LDA     (VPTR),Y                     ; Get The Length
            TAY
            PLA
            RTS

INPSTR1     JSR     GETBYT                       ; And Gobble First Quote
            LD16    PRGPTR                       ; Save String Location
            PHA
            LDY     #0
INPSTR2     JSR     GETBYT                       ; Calc String Length
            CPEQ    #'"'+Hibit;INPSTR4           ; Check For End
            IBNE    Y;INPSTR2

            PLA                                  ; Just To Be Sure
            LDA     #Strtobig                    ; String Overflow Error
            JMP     BADERR

INPSTR4     PLA                                  ; A,X,Y Now Have String Data
            RTS

INPSTR5     STA     DATA                         ; Reset Data Type
            JSR     GETBYT
            CLC                                  ; Called From Somewhere Else
            CLV
            JSR     EX_TOK                       ; Exec Token
            LDA     DATA
            AND     #%00000010
            BNE     GETDATA                      ; Type Mismatch

            JMP     MISSMTCH

GETDATA     LD24    DATA+1
            RTS

*===============================
*   Name: STRCMP - Compare Strings
*
*  Input: Program Pointer
*
* Output: X = 0: False
*         X = 1: True
*===============================

STRCMP      PUSHW   VARSTR                       ; Dont Gobble Any Space
            JSR     INPSTR                       ; Get String 1
            MOVD    STRLOC;TEMP3                 ; Save Pointers To Data
            MOV     STRLEN;TEMP2                 ; Save Length Of Data
            IFLT    (PRGPTR);#Compare;STRCMP8    ; Is There A Compare
            CPGE    #Logic;STRCMP8

            JSR     GETBYT                       ; Gobble Token
            SEC
            SBC     #Compare
            ASL     A
            PHA
            JSR     INPSTR                       ; Get Second String
            PLA
            TAX
            JMP     (JSTRCP,X)

STRCMP8     LDX     #0                           ; Length = 0, Not Valid
            LDEQ    TEMP2;STRCMP9                ; Length > 0, Return Valid
            LDX     #1
STRCMP9     PULLW   VARSTR                       ; Restore Stuff
            LDA     #0
            RTS

ST_EQ       JSR     STREQ                        ; Check If Equal
            BRA     STRCMP9

ST_NOT      JSR     STREQ                        ; Check If Equal
            JSR     INVERT                       ; Invert The Result
            BRA     STRCMP9

ST_LT       JSR     STRLT                        ; Check If Less Than
            BRA     STRCMP9

ST_GT       JSR     STRGT                        ; Check If Greater Than
            BRA     STRCMP9

ST_LTEQ     JSR     STRGT                        ; Check It Greater Than
            JSR     INVERT                       ; Invert Result
            BRA     STRCMP9

ST_GTEQ     JSR     STRLT                        ; Check If Less Than
            JSR     INVERT                       ; Invert Result
            BRA     STRCMP9

*===============================
* Compare Algorithms
*===============================

STREQ       IFNEX   TEMP2;STRLEN;RTNNUM0         ; check string length

            LDY     #-1
STREQ2      INY
            CPEQY   STRLEN;RTNNUM1               ; Are We Done?
            IFEQ    (TEMP3),Y;(STRLOC),Y;STREQ2  ; Do Check

RTNNUM0     LDX     #0                           ; No Match
            RTS

STRLT       IFGEX   TEMP2;STRLEN;STRLT2          ; save smaller length
            MOVX    STRLEN;TEMP2
STRLT2      LDY     #-1
STRLT3      INY
            CPEQY   TEMP2;RTNNUM0
            IFEQ    (TEMP3),Y;(STRLOC),Y;STRLT3
            BGE     RTNNUM0

RTNNUM1     LDX     #1
            RTS

STRGT       IFGEX   STRLEN;TEMP2;STRGT2          ; save smaller length
            MOVX    TEMP2;STRLEN
STRGT2      LDY     #-1
STRGT3      INY
            CPEQY   STRLEN;RTNNUM0
            IFEQ    (STRLOC),Y;(TEMP3),Y;STRGT3
            BGE     RTNNUM0
            BLT     RTNNUM1

*===============================
*   Name: CHKFRE - Check Free Memory
*
*  Input: None
*
* Output: None
*===============================

CHKFRE      LDX     VARSTR+1                     ; High Of Current Pointer
            INX
            CPGEX   MIDMEM+1;FREE                ; Are We Ok?
            RTS

*===============================
*   Name: ARGTYP - Get Argument Type
*
*  Input: Program Pointer
*
* Output: C = 1: String
*         C = 0: Number
*===============================

ARGTYP      STZ     SETRAM1
            JSR     ARGTYP0
            BRA     DRAM3

*===============================
*   Name: STRCOPY - Copy A String To String Space
*
*  Input: String Parameters
*
* Output: None
*===============================

STRCOPY     STZ     SETRAM1
            JSR     STRCOPY0
            BRA     DRAM3

*===============================
*   Name: FRE - Clean Up String Space
*
*  Input: None
*
* Output: None
*===============================

FREE        STZ     SETRAM1                      ; Switch In Subs
            JSR     DO_FRE2
DRAM3       STZ     SETRAM2                      ; Switch Out Subs
            RTS

PUTNUM      ST24    NUM                          ; Save Number
            STZ     NUM+9
            RTS

ZERONUM     ZERO24  NUM                          ; Zero Number
            STZ     NEGFLG
            RTS

SAVEDATA    ST24    DATA+1                       ; Save String Data
            RTS

SVSTR       JSR     SAVEDATA                     ; Save String Data
            MOV     #2;DATA
            RTS

SVDATA      STA     DATA+1                       ; Save 8 Bit Number Data
            STZ     DATA+2
            STZ     DATA+3
            MOVX    #1;DATA
            RTS

NUMBSUB1    LDNE    NUMB;NUMBSUBL
            LDNE    NUMB+1;NUMBSUBM
            DEC     NUMB+2
NUMBSUBM    DEC     NUMB+1
NUMBSUBL    DEC     NUMB
            RTS

NUMBADD1    IBNE    NUMB;NUMBADDX
            INCD    NUMB+1
NUMBADDX    RTS

NUMBZERO    LDA     NUMB
            ORA     NUMB+1
            ORA     NUMB+2
            RTS

            LST     OFF

