            LST    RTN
            TTL    'LLUCE - Program Subroutines'
            PAG
*===============================
* Contents:
*
* ADDCRC   - Add Byte To CRC
* BINDEC8  - Binary To Decimal
* BLKEND   - end a block of code
* CHKDCD   - Check For Modem Carrier
* CHKTIME  - Check Time Limit
* CONV     - Convert To Upper Case
* COUNTUP  - inc temp2, dec temp3
* DECOUT   - 24 Bit Signed Integer To Decimal
* DECOUT0  - 24 Bit Unsigned Integer To Decimal
* END      - end of program
* EX_TOK   - Execute A Token
* GETBYT   - Get Program Byte W/List
* GETRAW   - Get A Program Byte
* GOBBLE   - Check For Character
* GOBCOM   - Check For Comma
* GOBEQU   - Check For Equal Token
* INCPRN   - Increment Print Pointer
* INCTEMP3 - Increment Temporary 3
* INCVARST - Increment String Pointer
* INPTYP   - Get Next Byte Type
* IVSET    - set input vector by X
* LIST     - List Running Program
* NIL      - do nothing (but inc random)
* NUM2TMP  - put 16 bit number in TEMP
* NUM2TMP2 - put 16 bit number in TEMP2
* NUM2TMP3 - put 16 bit number in TEMP3
* NUMIN    - Get Number From Program
* OVSET    - set output vector by X
* PAUSE    - Check For Pause
* RAMIN    - Get Byte From RAM Drive
* RAMOUT   - Send Byte To RAM Drive
* RUN      - run line or block
* RUNBLOCK - start a block of code
* RUNEOL   - run code to end of line
* RUNMAIN  - run code
* RUNMOD2  - execute code section
* RWPTRS   - put numbers in TEMP2 and TEMP3
* SETIVEC  - Set Input Vector
* SETOVEC  - Set Output Vector
* SYNTAX   - Generate a syntax error
* TMP3DWN  - count down TEMP3
* TST_ALF  - Check For Letter
* TST_NUM  - Check For Number
* WAIT     - Delay
* XNUMIN   - Decimal To Binary
* ZNUMIN   - Get Number From Pointer
*===============================

*===============================
*   Name: GETRAW - Get A Program Byte
*
*  Input: None
*
* Output: A - Program Byte
*===============================

GETRAW      LDA    (PRGPTR)                       ; Get A Program Byte
            PHP
            INCD   PRGPTR
            PLP
            RTS

*===============================
*   Name: GETBYT - Get Program Byte W/List
*
*  Input: None
*
* Output: A - Program Byte
*===============================

GETBYT      JSR    GETRAW                         ; Get Raw Data
            CPNE   #'"'+Hibit;GETBYT3             ; Is It Text?

            PHA
            EOR    LSTTXT                         ; Toggle Text Mode
            STA    LSTTXT
            PLA
GETBYT3     TSTPL  SHWTRC;GETBYT4                 ; Show Trace?

            JSR    LIST                           ; Show Trace
GETBYT4     CMP    #0
            RTS

NIL         STZ    LSTTXT                         ; Clear Text Flag
            INCD   RNDNUM
            RTS

*===============================
*   Name: GOBEQU - Check For Equal Token
*         GOBCOM - Check For Comma
*         GOBBLE - Check For Character
*
*  Input: Character To Check For
*
* Output: None
*===============================

GOBEQU      LDX    #Equal
            SKIP2                                 ; Skip Next Two Bytes
GOBCOM      LDX    #','+Hibit
GOBBLE      STX    GOBBYT                         ; Save Byte
            JSR    GETBYT                         ; Get Data
            CPEQ   GOBBYT;GOBBLE2                 ; All Is Well

            JMP    SYNTAX                         ; Syntax Error

*===============================
*   Name: INCPRN - Increment Print Pointer
*
*  Input: None
*
* Output: None
*===============================

INCPRN      INCD   PRN                            ; Increment Print Pointer
GOBBLE2     RTS

*===============================
*   Name: INCVARST - Increment String Pointer
*
*  Input: None
*
* Output: None
*===============================

INCVARST    INCD   VARSTR                         ; Increment String Pointer
            RTS

*===============================
*   Name: INCTEMP3 - Increment Temporary 3
*
*  Input: None
*
* Output: None
*===============================

INCTEMP3    INCD   TEMP3
            RTS

*===============================
*   Name: CHKDCD - Check For Modem Carrier
*
*  Input: None
*
* Output: None
*===============================

CHKDCD      SEC
            DO     DEMOPGM
            RTS
            ELSE
            TSTPL  NOCDVEC;CHKDCD2                ; Bother To Check?
            TSTPL  REMOTE;CHKDCD2                 ; Are We Remote?

            JSR    MDMDCD                         ; Is There Carrier?
            BCS    CHKDCD2                        ; Yep

            JSR    MDM1_2                         ; Hang Up User
            FIN

ZAPCALL     MOV    #-1;LOGOFF                     ; Signal Logoff Needed
            CLC                                   ; No Carrier!
CHKDCD2     RTS

*===============================
*   Name: CHKTIME - Check Time Limit
*
*  Input: None
*
* Output: None
*===============================

CHKTIME     TSTPL  NOCDFLG;CHKTM5                 ; Bother To Check?
            TSTMI  LOGOFF;CHKTM4                  ; In Logoff Mode Already?
            BREQW  TIMEON;CHKTM5                  ; Is There A Limit?

            JSR    SECON                          ; Get Time On
            CPEQ   TIMEON+1;CHKTM2                ; Check Low Byte
            BGE    CHKTM3                         ; Opps, Time Out
            BRA    CHKTM5                         ; All Is Well

CHKTM2      CPLTX  TIMEON;CHKTM5                  ; Check Low

CHKTM3      LDA    #TimedOut
            JSR    PRTEXT
            JMP    ZAPCALL

CHKTM4      CLC                                   ; No Carrier / Timeout
            RTS

CHKTM5      SEC                                   ; All Is Well
            RTS

*===============================
*   Name: TST_ALF - Check For Letter
*
*  Input: A - Character To Check
*
* Output: C = 0, Is Letter
*         C = 1, Not Letter
*===============================

TST_ALF     PHA
            JSR    CONV                           ; Change To Uppercase
            CPLT   #'A';TST_AL2
            CPLT   #'Z'+1;TST_AL3
TST_AL2     SEC
TST_AL3     PLA
            RTS

*===============================
*   Name: TST_NUM - Check For Number
*
*  Input: A - Character To Check
*
* Output: C = 0, Is Number
*         C = 1, Not Number
*===============================

TST_NUM     PHA
            AND    #Clrhi                         ; Strip High Bit
            CPLT   #'0';TST_NM2
            CPLT   #'9'+1;TST_NM3
TST_NM2     SEC
TST_NM3     PLA
            RTS

*===============================
*   Name: CONV - Convert To Upper Case
*
*  Input: A - Character To Convert
*
* Output: A - Converted Character
*===============================

CONV        AND    #Clrhi                         ; Strip High Bit
            CPLT   #'a';CONV2
            CPGE   #'z'+1;CONV2
            SBC    #$1F                           ; Since Carry Is Clear, -$20
CONV2       RTS

*===============================
* Name: RUNMAIN - start a block of code
*===============================

RUNMAIN     JSR    RUNMOD2
            BRA    RUNMAIN

*===============================
* Name: RUNBLOCK - start a block of code
*===============================

RUN         IFNE   (PRGPTR);#CompStrt;RUNEOL
            JSR    GETBYT                         ; skip the {
RUNBLOCK    JSR    RUNMAIN
            RTS

*===============================
* Name: RUNEOL - start a block of code
*===============================

RUNEOL      JSR    RUNMOD2
            IFNE   (PRGPTR);#Chain2;RUNEOL
            RTS

*===============================
* Name: RUNMOD2 - execute code section
*===============================

RUNMOD2     IFLT   (PRGPTR);#String+1;RUNMOD3     ; Is It A let?

            JSR    GETBYT                         ; Gobble
            CPMI   #0;SYNTAX                      ; Quick Check

RUNMOD3     STA    CMD                            ; Save Cmd
            SEC                                   ; Execed As A Command
            JSR    EX_TOK                         ; Exec It
            TSTPL  LOGOFF;RUNMOD4                 ; Log Off User?

            JSR    DO_CL3                         ; Close All Open Files

            STZ    LOGOFF                         ; Say we arent logging off

            LDEQ   NOCDFLG;KILLUSR                ; Any NOCAR handler?

            MOVD   NOCDVEC;PRGPTR                 ; Point To No Cd Routine
            STZ    NOCDFLG                        ; Reset Vector
RUNMOD4     RTS

SYNTAX      LDA    #Syntax                        ; Syntax Error
            SKIP2
KILLUSR     LDA    #SysTerm
            PLY                                   ; pop one level from stk
            PLY
            PLY
            PLY
            JMP    BADERR2

*===============================
* Name: BLKEND - end a block of code
*===============================

END         =      *
BLKEND      PLY
            PLY
            PLY
            PLY
            LSR    A                              ; restore token
            RTS

*===============================
*   Name: EX_TOK - Execute A Token
*
*  Input: Token
*
* Output: None
*===============================

EX_TOK      PHP
            ROR    IMMDEF                         ; Save Execution Status
            ASL    A                              ; A = A * 2
            BCS    EX_TOK2                        ; Opps, Not A Token!

            TAX                                   ; Use As Index
            PLP                                   ; Restore Run State
            JMP    (SYMADR,X)                     ; Exec Command

DO_TOK2     PHP                                   ; Save Status
            JSR    GETBYT                         ; Get Actual Command
            ASL    A                              ; Check High Bit
            BCS    EX_TOK2                        ; Invalid If Set

            TAX                                   ; Move To Index
            PLP                                   ; Restore Status
            JMP    (SYMADR2,X)                    ; Go

EX_TOK2     PLP                                   ; Remove From Stack
            JMP    SYNTAX                         ; Syntax Error

*===============================
*   Name: DECOUT0 - 24 Bit Unsigned Integer To Decimal
*                   (0-16777216)
*
*  Input: X, A, Y - Number To Convert
*
* Output: None
*===============================

DECOUT0     JSR    PUTNUM                         ; Save Number
            BRA    DECOUT1                        ; Do Normal Output

*===============================
*   Name: DECOUT - 24 Bit Signed Integer To Decimal
*                  (-8388608/8388607)
*
*  Input: X, A, Y - Number To Convert
*
* Output: None
*===============================

DECOUT      PHY                                   ; Save Status
            JSR    DO_ABS1                        ; Make Positive
            JSR    PUTNUM
            PLA
            BPL    DECOUT1                        ; Display Negative Sign?

            LDX    NUM+9                          ; Put - In String
            MOV    #'-';TXTNUM+1,X                ; Show It Is Negative
            INC    NUM+9
            JSR    DO_OUT                         ; Show The -
DECOUT1     LDX    #3
DEC1        STZ    NUM,X
            INX
            CPNEX  #9;DEC1
            SED                                   ; Making It Decimal
            LDY    #24                            ; Doing 24 Bits
DEC2        ASL    NUM                            ; Shift Bits
            ROL    NUM+1
            ROL    NUM+2
            PHY
            LDY    #3                             ; Add In With Carry
            LDX    #3
DECADD      AD     NUM,X;NUM,X;NUM,X
            INX
            DBPL   Y;DECADD

            PLY
            ROL    NUM+7
            DBNE   Y;DEC2                         ; Do Next Bit

            CLD                                   ; Back To Normal Mode
            LDY    #8                             ; Possible 8 Characters
DEC3        LDA    NUM+7                          ; Get First Character
            AND    #LoNibble                      ; Only Low Nibble
            BNE    DEC_GNUM                       ; Not Zero, Do It

            TSTPL  NUM+8;DEC_SKIP                 ; First Character?

DEC_GNUM    DEC    NUM+8                          ; Flag Non Zero Number
            ORA    #'0'                           ; Make It Ascii
            LDX    NUM+9                          ; Save Character
            STA    TXTNUM+1,X
            JSR    DO_OUT                         ; Print It
            INC    NUM+9                          ; Increment Pointer
DEC_SKIP    LDX    #3                             ; Shift 4 Bits
DEC4        ASL    NUM+1                          ; For Next Character
            ROL    NUM+2
            ROL    NUM+3
            ROL    NUM+4
            ROL    NUM+5
            ROL    NUM+6
            ROL    NUM+7
            DBPL   X;DEC4
            DBMI   Y;DEC_DONE                     ; count down chars
            BNE    DEC3                           ; More Than 1 To Follow

            STX    NUM+8                          ; Last One, Gotta Show It
            BRA    DEC3

DEC_DONE    MOV    NUM+9;TXTNUM                   ; Set Up Length
            RTS

*===============================
*   Name: NUMIN - Get Number From Program
*
*  Input: None
*
* Output: X, A, Y - Number Read
*===============================

NUMIN       JSR    ZERONUM                        ; Zero Info
            IFNE   (PRGPTR);#Minus;NUMIN2A        ; is this negative?

            DEC    NEGFLG                         ; Flag As Neg
            JSR    GETBYT                         ; Skip The -
NUMIN2A     LDPL   (PRGPTR);NUMIN4

            JSR    TST_NUM                        ; Is It A Number?
            BCS    NUMIN4                         ; Nope, Done

            JSR    GETBYT                         ; Get It Again
            JSR    XNUMIN                         ; Add It In
            BRA    NUMIN2A

*===============================
*   Name: ZNUMIN - Get Number From Pointer
*
*  Input: None
*
* Output: X, A, Y - Number Read
*===============================

ZNUMIN      JSR    ZERONUM                        ; Zero Info
            IFNE   (TEMP3);#'-';ZNUMIN2           ; is this negative?

            DEC    NEGFLG                         ; Flag As Neg
            INCD   TEMP3                          ; skip the -
ZNUMIN2     LDA    (TEMP3)                        ; Get Char
            JSR    TST_NUM                        ; Is It A Number?
            BCS    NUMIN4                         ; Nope, Were Done

            INCD   TEMP3

            JSR    XNUMIN                         ; Process Digit
            BRA    ZNUMIN2                        ; Loop

NUMIN4      LD24   NUM                            ; Return Value
            TSTPL  NEGFLG;NUMIN5                  ; Was It Negative?
            JSR    NEGAXY                         ; Make It Negative
NUMIN5      RTS

*===============================
*   Name: XNUMIN - Decimal To Binary
*
*  Input: A - Digit To Add In
*
* Output: None
*===============================

XNUMIN      AND    #LoNibble                      ; Clear Extra Bits Off
            STA    NUM+3                          ; Save It
            STZ    NUM+4                          ; Zero Rest Of Number
            STZ    NUM+5
            LDX    #10                            ; Multiply By 10 With New
NUMIN3      ADD    NUM;NUM+3;NUM+3                ; Number
            AD     NUM+2;NUM+5;NUM+5
            DBNE   X;NUMIN3
            MOV24  NUM+3;NUM                      ; Save The New Number
            RTS

*===============================
*   Name: LIST - List Running Program
*
*  Input: Token/Character
*
* Output: None
*===============================

LIST        SVXAY                                 ; Save A, X, Y
            TSTPL  LST2ND;LIST1                   ; Showing Secondary Token?

            STZ    LST2ND                         ; Clear Secondary Flag
            TAY
            PUSHA  #0
            LD16   #SYMTXT2                       ; Point To Second Table
            BRA    LIST8                          ; print it

LIST1       LDEQY  LSTVAR;LIST1A                  ; Are We Showing A Variable?
            JMP    LISTF                          ; Yes

LIST1A      LDNEX  LSTTXT;LIST5                   ; Are We In Text Mode?

LIST2       LDX    #'#'+Hibit
            CPEQ   #Number;LIST3                  ; Is It A Number?
            INX
            CPNE   #String;LIST4                  ; Is It A String?

LIST3       MOVY   #-1;LSTVAR                     ; Setup To Show Next 4 variable bytes
            TXA
            BRA    LIST5

LIST3A      DBRA   LST2ND;LIST6                   ; Flag Secondary

LIST4       CPEQ   #Hitoken;LIST3A                ; Secondary Tokens?
            CPEQ   #Chain2;LISTD                  ; Is It A Statement Link?
            CPPL   #0;LIST7                       ; Is It A Token?

LIST5       ORA    #Hibit                         ; Display Text
            CPGE   #' '+Hibit;LIST5B              ; control char?
            AND    #Clrhi                         ; make it inverse
            CPEQ   #bs;LIST5A
            CPEQ   #lf;LIST5A
            CPEQ   #vt;LIST5A
            CPNE   #cr;LIST5B
LIST5A      ADC    #$3F                           ; make it mousetext
LIST5B      JSR    VIDBAN
            JSR    PAUSE
LIST6       RSTXAY                                ; Restore X, A, Y
            RTS

LIST7       CPLT   #ThreeByte+1;LISTH
            PHA                                   ; Point To First Table
            TAY
            LD16   #SYMTXT
LIST8       ST16   LSTPTR
            STZ    SETRAM1
            DEY                                   ; Count Down First
LIST9       LDA    (LSTPTR)                       ; Get A Character
            INCD   LSTPTR                         ; Point To Next Character
            ASL    A                              ; We Done?
            BCC    LIST9                          ; Nope
            DBPL   Y;LIST9                        ; count down token

LISTB       LDA    (LSTPTR)                       ; Get Data
            PHP
            ORA    #Hibit                         ; Display It
            STZ    SETRAM2
            JSR    VIDBAN
            STZ    SETRAM1
            INCD   LSTPTR
            PLP
            BPL    LISTB

            STZ    SETRAM2
            PLA                                   ; Check For A Labeld Token
            CPEQ   #Goto;LISTD
            CPEQ   #Gosub;LISTD
            CPNE   #Push;LISTE

LISTD       LDA    #':'+Hibit                     ; Also Do Chain Statement
            JSR    VIDBAN
LISTE       LDRA   #' '+Hibit;LIST5

LISTF       TAX                                   ; get status back
            BPL    LISTG                          ; high bit clear is not var
            JSR    TST_ALF
LISTF2      BCC    LIST5
            JSR    TST_NUM
            BCC    LISTF2                         ; go show it

LISTG       STZ    LSTVAR                         ; Count Down Display Time
            JMP    LIST2                          ; treat as standard list

LISTH       TAX
            LDY    #1
            PUSHA  (PRGPTR)
            PUSHA  (PRGPTR),Y
            INY
            LDA    (PRGPTR),Y
            TAY
            PLA
            CPEQX  #TwoByte;LISTI
            PLX
            BCS    LISTJ
            LDY    #0
            TYA
            BEQ    LISTJ

LISTI       PLX
            LDY    #0
LISTJ       JSR    SAVENUMB
            PUSHW  VECTOR                         ; Save Current Vector Value
            MOVD   #NIL;VECTOR                    ; Suppress Output
            JSR    GETNUMB                        ; Print Number To Memory
            JSR    DECOUT
            PULLW  VECTOR                         ; Restore Vector
            LDX    #1
LISTK       LDA    TXTNUM,X                       ; Copy Byte
            ORA    #Hibit
            JSR    VIDBAN
            INX
            DBNE   TXTNUM;LISTK                   ; count the digits

            BRA    LISTE

*===============================
*   Name: PAUSE - Check For Pause
*
*  Input: None
*
* Output: None
*===============================

PAUSE       LDA    KYBD                           ; Check Local Keyboard
            ORA    #Hibit
            CPNE   #'Z'-Ctrl+Hibit;PAUSE2

            STA    KBDSTRB
PAUSE1      JSR    CHKKEY                         ; Wait For A Keypress
            BEQ    PAUSE1

PAUSE2      RTS

*===============================
*   Name: WAIT - Delay
*
*  Input: A - Delay Factor
*
* Output: None
*===============================

WAIT        SEC                                   ; GS Style Delay Routine
WAITLUP1    PHA
            BIT    LOWSPEED
WAITLUP2    SBC    #1
            BNE    WAITLUP2

            PLA
            SBC    #1
            BNE    WAITLUP1

            RTS

*===============================
*   Name: SETIVEC - Set Input Vector
*
*  Input: Y - Channel Number
*
* Output: X - Channel Index
*===============================

DEVIVSET    JSR    GETDEV
            BRA    IVSET

SETIVEC     TYA                                   ; Make Into Index
            ASL    A
            TAX
IVSET       MOV    INPVEC,X;VECTOR2               ; Set Vector
            MOV    INPVEC+1,X;VECTOR2+1
            RTS

*===============================
*   Name: SETOVEC - Set Output Vector
*
*  Input: Y - Channel Number
*
* Output: X - Channel Index
*===============================

DEVOVSET    JSR    GETDEV
            BRA    OVSET

SETOVEC     TYA                                   ; Make Into Index
            STA    CURODEV
            ASL    A
            TAX
OVSET       MOV    OUTVEC,X;VECTOR                ; Set Vector
            MOV    OUTVEC+1,X;VECTOR+1            ; Set Vector
            RTS

*-------------------------------
* Count Up Pointer, Counter Down
*-------------------------------

COUNTUP     INCD   TEMP2                          ; Increment
TMP3DWN     DECD   TEMP3                          ; Decrement Counter
            DEC    A                              ; Done?
            ORA    TEMP3+1
            RTS

NUM2TMP     JSR    INPNUM16
            ST16   TEMP
            RTS

NUM2TMP2    JSR    INPNUM16
            ST16   TEMP2
            RTS

RWPTRS      JSR    NUM2TMP2                       ; Point To Data
            JSR    GOBCOM                         ; Gobble Comma
; Get Length Of Read

NUM2TMP3    JSR    INPNUM16
            ST16   TEMP3
            RTS

*===============================
*   Name: INPTYP - Get Next Byte Type
*
*  Input: None
*
* Output: A = 0: Line/Command Link
*         A = 1: Expression
*         A = 2: Literal String
*         A = 3: Literal Number
*         A = 4: Token Or Unknown
*         A = 5: String Variable
*         A = 6: Numeric Variable
*===============================

INPTYP      STZ    SETRAM1                        ; Switch In Subs
            JSR    INPTYP2
            BRA    DRAM2

*===============================
*   Name: BINDEC8 - Binary To Decimal
*
*  Input: Byte To Convert
*
* Output: X,A Decimal Number As Text
*===============================

BINDEC8     STZ    SETRAM1                        ; Switch In Subs
            JSR    BINDEC82
            BRA    DRAM2

*===============================
*   Name: ADDCRC - Add Byte To CRC
*
*  Input: A - Byte To Add To CRC
*
* Output: None
*===============================

ADDCRC      STZ    SETRAM1                        ; Switch In Subs
            JSR    ADDCRC2
            BRA    DRAM2

*===============================
*   Name: RAMIN - Get Byte From RAM Drive
*
*  Input: None
*
* Output: A - Byte From Ramdrive
*===============================

RAMIN       STZ    SETRAM1                        ; Switch In Subs
            JSR    RAMIN2
            BRA    DRAM2

*===============================
*   Name: RAMOUT - Send Byte To RAM Drive
*
*  Input: A - Byte To Put In Ramdrive
*
* Output: None
*===============================

RAMOUT      STZ    SETRAM1                        ; Switch In Subs
            JSR    RAMOUT2
DRAM2       STZ    SETRAM2                        ; Switch Out Subs
            RTS

*===============================
*   Name: TOFLN - Move name in
*
*  Input: A,X - From location
*
* Output: N - 1 = No name
*===============================

TOFLN       ST16   PRN
            LDA    (PRN)
            BEQ    TOFLZERO
            TAY
TOFLMOVE    MOV    (PRN),Y;FLNAME,Y
            DBPL   Y;TOFLMOVE
TOFLZERO    RTS

*===============================
*   Name: FRMFLN - Move name out
*
*  Input: A,X - To location
*
* Output: N - 1 = No name
*===============================

FRMFLN      ST16   FMFLSTA+1
            LDX    FLNAME
            BEQ    FMFLZERO
FMFLMOVE    LDA    FLNAME,X
FMFLSTA     STA    -1,X
            DBPL   X;FMFLMOVE
FMFLZERO    RTS

SWITCH2     STZ    SETRAM2
            STZ    SETRAM2
            RTS
            LST    OFF

