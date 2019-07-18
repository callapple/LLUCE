            LST    RTN
            TTL    'LLUCE - I/O Commands'
            PAG
*===============================
* Contents:
*
* ADDINT   - Add Interrupt Keys
* BAUD     - Return Users Baud Rate
* DO_NULLS - Set or get nulls
* DO_OFFSET - Set or get GotoXY offset
* DO_SED   - Set Interrupt Key To Spacebar (For Editor)
* DO_SER   - Print Serial # Of Software
* ECHOSTR  - Set Echo
* ERR      - Return Last Error Number
* EXEC     - Read Or Set Exec Flag
* GET      - Get A Single Character
* INPUT    - Input A Line Of Text Or Data
* KEY      - Check For Keypress
* MODEM    - Handle Modem Calls
* NODE     - Return System Node Number
* ONLINE   - Return Online Status
* PRINT    - Print Statement
* SETINT   - Set Interrupt Keys To Be Used
* SCRN     - Read, Set Or Execute Screen Stuff
* TERMINAL - Read/Set Terminal Number
* TONE     - Produce A Tone With Apple Speaker
* WAITSEC  - Delay One Second
* WIDTH    - Get Width From Index
* WINDOW   - Read Or Set Top Of Screen
*===============================

*===============================
* Name: PRINT - Print Statement
*===============================

PRINT       JSR    GETDEV
            JSR    SETOVEC                                       ; Set Output Vector
            BRA    N_PRINT

TST_EOL     JSR    INPTYP                                        ; Check For Eol
            BNE    N_PRINT

            RTS

*-------------------------------
* Execute Gotoxy
*-------------------------------

DO_XY       JSR    INPNUM8                                       ; Handle "@"
            DEX
            STX    CH                                            ; Set Position
            IFNE   (PRGPTR);#','+Hibit;N_PRINT                   ; Any Y Position?

            JSR    BYTNUM8                                       ; Get The Number
            DEX
            STX    CV                                            ; Set Position
            BRA    N_PRINT

PRT_COM     JSR    DO_OUT
N_PRINT     JSR    INPTYP                                        ; Get Data
            BNE    DO_PR
            JMP    DO_CR                                         ; Eol?

DO_PR       CPEQ   #tknExpr;CHK_TKN                              ; Token?
            CPEQ   #strLit;PRT_LIT                               ; Hard-Coded Text?
            CPEQ   #numLit;PRT_NUM                               ; Number?
            CPEQ   #strVar;CHK_TKN                               ; String Variable?
            CPEQ   #numVar;PRT_NUM                               ; Numeric Variable?

            JSR    GETBYT                                        ; Must Be Control
            AND    #Clrhi
            CPEQ   #',';PRT_COM
            CPEQ   #';';TST_EOL
            CPEQ   #'@';DO_XY                                    ; Position
            JMP    SYNTAX                                        ; Syntax Error

*-------------------------------
* Print A Literal
*-------------------------------

PRT_LIT     JSR    GETBYT                                        ; Eat Opening Quote
LIT_NXT     JSR    GETBYT                                        ; Get Next Char
            CPEQ   #'"'+Hibit;N_PRINT                            ; Closed Quote?
            JSR    DO_OUT
            BRA    LIT_NXT                                       ; And Loop

*-------------------------------
* Print A Number
*-------------------------------

PRT_NUM     JSR    INPNUM                                        ; Get Number
            JSR    DECOUT                                        ; Print It
            BRA    N_PRINT

*-------------------------------
* Check For And Handle Screen Stuff
*-------------------------------

CHK_TKN     IFLT   (PRGPTR);#ClsTkn;PRT_TKN                      ; Must Be In The Right Place
            CPGE   #EndEmul;PRT_TKN                              ; Make Sure About It
            JSR    GETBYT                                        ; Get Again, Skip To Next
            CPNE   #ClsTkn;CHK_TKN3
            LDA    #ClsTkn2                                      ; make it a CLRSCN
CHK_TKN3    SEC
            SBC    #HomeTkn
            JSR    EMULFUNC
GO_PRNT     JMP    N_PRINT

*-------------------------------
* Print From A Token
*-------------------------------

PRT_TKN     JSR    ARGTYP
            BCC    PRT_NUM                                       ; If It Is A Number

            JSR    INSTR2                                        ; Set Up Pointers
            TYA
            TAX
            INX
            LDY    #0
PRTSTR      DBEQ   X;GO_PRNT                                     ; Print Out String

            LDA    (STRLOC),Y
            JSR    DO_OUT
            IBRA   Y;PRTSTR

DO_CR       LDA    #cr                                           ; Print CR/LF
DO_OUT      JMP    (VECTOR)

            DO     DEMOPGM
COPNOT      REV    'LLUCE DEMO (C)1986-1993 L&L Productions: V'
            ELSE
COPNOT      REV    'LLUCE (C)1986-1993 L&L Productions: V'
            FIN
COPLEN      =      *-COPNOT

*===============================
* Name: MODEM - Handle Modem Calls
*===============================

MODEM       JSR    INPTYP                                        ; get type of next token
            BEQ    MDMERR                                        ; REMOVE THIS

            JSR    GETBYT
            CPEQ   #Timestr;MDM3
            CPEQ   #Clear;MDM4
            CPEQ   #Ready;MDM0
            CPEQ   #Nocar;MDM1
            CPEQ   #OnlineTkn;MDM2
MDMERR      JMP    SYNTAX

*===============================
* Name: MDM2 - Setup Modem To Call Out
*===============================

MDM2        JSR    EQUNUM8                                       ; Get the baud rate

            LDY    #0
            TXA
            LSR    A
            LSR    A
            BEQ    SPDOK

            LSR    A                                             ; Divide By 2 Till 0
SPEED       INY
            CPEQY  #5;SPDOK                                      ; Only Up To 9600

            LSR    A                                             ; Divide By 2 Again
            BNE    SPEED

SPDOK       STY    MDMSPEED                                      ; Save The Speed In Default
            DO     DEMOPGM
            RTS
            ELSE
            JSR    MDMINIT                                       ; Init The Modem
            JMP    MDMRSET                                       ; Set It Up For Use
            FIN

*===============================
* Name: MDM3 - Set auto logon time
*===============================

MDM3        JSR    EQUSTR
            IFLTY  STRLEN;#12;M3_MVTIM                           ; is it legal?

            LDA    #Strtobig
            JMP    BADERR

M3_MVTIM    MOV    (STRLOC),Y;QTIME,Y                            ; Get Char And Save
            DBPL   Y;M3_MVTIM

            SEC                                                  ; Flag an auto logon
            ROR    AUTOLOG
            RTS

*===============================
* Name: MDM4 - Clear auto logon
*===============================

MDM4        STZ    AUTOLOG
            RTS

*===============================
* Name: MDM1 - Hang Up
*===============================

]TEMP       =      COPLEN/2

MDM1        JSR    CROUT                                         ; Start At Beginning Of Line
            LDY    #38-]TEMP                                     ; Center The Message
            LDA    #' '
M1_SPACE    JSR    COUT
            DBNE   Y;M1_SPACE

            LDY    #COPLEN-1                                     ; Print The Message
M1_PRNT     LDA    COPNOT,Y
            EOR    #COPLEN
            LSR    A
            JSR    COUT
            DBPL   Y;M1_PRNT

            STZ    PRN+1
            JSR    PRTVER                                        ; Print Version #
            JSR    SHOWSTR
            DB     cr,cr,cr+Hibit
MDM1_2      STZ    REMOTE                                        ; Set Local Modem
            DO     DEMOPGM
            RTS
            ELSE
            JMP    MDMHANG                                       ; Hang Up Phone
            FIN

*===============================
* Name: MDM0 - Handle Waiting For A Call
*===============================

MDM0        STZ    REMOTE
            DO     DEMOPGM
            ELSE
            JSR    MDMHANG                                       ; Hang Up Phone
            JSR    MDMRSET                                       ; Setup For Answer
            FIN
            JSR    CLRANSI                                       ; Clear ANSI mode (if set)

MDM0_X      STZ    SSAVED                                        ; Zero Screen Saved Flag
            STZ    EXECFLG                                       ; Reset Possible Exec Mode
            STZ    DOCHAT                                        ; Reset Chat Mode
            MOVD   SCREENTO;LSTVNAM                              ; Setup Screen Blank Time

            TSTPL  FLASHING;NOFLSH1                              ; flash enabled?, skip color save

            MOV    FGBG;LSTPTR
            MOV    BORDER;LSTPTR+1

NOFLSH1     MOVX   #-1;REMOTE                                    ; setup for local only
            STX    VIDECHO                                       ; Turn Off Any Echo
            MOV    TIMEDISP;CLKMODE                              ; Set Up 12/24 Hour Display
            PUSHA  #'@'                                          ; Start With Open Apple
            JMP    M0_TIME

MDM0_0      MOV    #60;PRN                                       ; Set for 1/2 Second

MDM0_1      LDPL   KYBD;MDM0_2                                   ; Check For Keypress

            STA    KBDSTRB                                       ; Clear Keyboard

            TSTPL  FLASHING;NOFLSH2                              ; flash enabled, as //e
            TSTPL  GSFLAG;MDM0_1A

NOFLSH2     TSTPL  SSAVED;MDM0_1A                                ; Screen Saved?

            STZ    SETRAM1                                       ; Switch In Subs
            JSR    RESTSCRN
            STZ    SETRAM2                                       ; Switch Out Subs
            PLA
            BRA    MDM0_X                                        ; Restart All

MDM0_1A     AND    #%00011111                                    ; Make Into [0-31] Range
            CPNE   M_LOGIN;MDM0_4                                ; do local

M0_AUTO     =      *
            DO     DEMOPGM
            ELSE
            JSR    MDMHANG                                       ; Hang Up (Disable AA)
            FIN
            STZ    REMOTE                                        ; Set To Local
            STZ    MDMSPEED                                      ; Set Speed To 0
MDM0_6      PLA
            JSR    CLRBUF                                        ; Clear Keyboard Buffer

            TSTPL  FLASHING;NOFLSH3                              ; flash enabled?

            JSR    M0_RESET

NOFLSH3     LDA    #clrscn
            JSR    VIDCOUT                                       ; Clear Local Console
            JMP    PTERM

MDM0_4      CPNE   M_QUIT;MDM0_3                                 ; quit
            PLA
            JSR    RESET
            JMP    RESTART1                                      ; Quit

            DO     DEMOPGM
MDM0_3      =      *
MDM0_2      =      *
            ELSE
MDM0_3      CPNE   M_ANSWER;MDM0_2                               ; keep checking

            JSR    MDMANS                                        ; Answer Phone
MDM0_2      JSR    MDMRING                                       ; Check For Connect
            BCC    MDM0_2X                                       ; We Got A Connect

MDM0_5      JSR    MDMIN                                         ; Get Modem Input
            BCS    MDM0_5                                        ; And Gobble Until Gone
            BRA    MDM0_6
            FIN

MDM0_2X     JSR    USERVEC                                       ; Do User Sub-Routine

            TSTPL  FLASHING;NOFLSH4                              ; flash enabled, as //e
            TSTPL  GSFLAG;MDM0_2Y

NOFLSH4     TSTMI  SSAVED;MDM0_0                                 ; Screen Been Saved, no time
MDM0_2Y     LDPL   VBL;M0_PLUS                                   ; State Of Vertical Blank
            TSTPL  CMD;M0_DOWN                                   ; Was Last State Negative?

MDM0_1X     JMP    MDM0_1                                        ; Yes, No Change

M0_PLUS     TSTPL  CMD;MDM0_1X                                   ; Last State Positive?

M0_DOWN     STA    CMD                                           ; No, Change It
            DBNE   PRN;MDM0_1X                                   ; Decrement Counter

M0_TIME     JSR    GETTIME
            ST16   M0_STIME+1
            ST16   M0_CTIME+1
            STY    M0_CSIZE+1
            MOV    CNTROFF,Y;CH                                  ; Done This Way For Time
            MOV    #vidHeight-2;CV                               ; Set To Line 22
            LDX    #0                                            ; Print The Time
M0_STIME    LDA    -1,X
            AND    #Clrhi
            JSR    VIDCOUT
            INX
            DBNE   Y;M0_STIME

            PULL   LINE23+12                                     ; Put First Apple On Screen
            EOR    #%00000001                                    ; Invert It
            PHA                                                  ; Save Apple Type
            STA    LINE23+26                                     ; Put Second Apple On Screen
            AND    #%00000001                                    ; Done With A Second?
            BEQ    GO0_0

            TSTPL  FLASHING;NOFLSH5                              ; flash enabled, no colors

            LDA    FGBG
            INC    A
            AND    #LoNibble
            STA    PRN+1
            ASL    A
            ASL    A
            ASL    A
            ASL    A
            EOR    #HiNibble
            ORA    PRN+1
            STA    FGBG
            LDA    BORDER
            AND    #HiNibble
            ORA    PRN+1
            STA    BORDER

            TSTPL  GSFLAG;GO0_0

NOFLSH5     BREQW  LSTVNAM;GO0_0                                 ; Is Screen Blank On?
            DECD   LSTVNAM                                       ; Count down seconds
            BRNEW  LSTVNAM;GO0_0

            MOV    #-1;SSAVED                                    ; Flag Screen Saved
            STZ    SETRAM1                                       ; Switch In Subs
            JSR    SAVESCRN
            STZ    SETRAM2                                       ; Switch Out Subs
GO0_0       TSTPL  AUTOLOG;GO0_1

M0_CSIZE    LDX    #0                                            ; Length of time string
M0_CTIME    IFNE   -1,X;QTIME,X;GO0_1                            ; check the time
            DBPL   X;M0_CTIME
            JMP    M0_AUTO                                       ; Is equal, log on

GO0_1       JMP    MDM0_0

CNTROFF     DB     39,39,38,38,37,37,36,36,35,35,34,34

M0_RESET    MOV    LSTPTR;FGBG
            MOV    LSTPTR+1;BORDER
            RTS

*===============================
* Name: INPUT - Input A Line Of Text Or Data
*===============================

INPUT       JSR    CHKFRE                                        ; Check The Free Memory
            MOV    #%10000001;INPMODE                            ; Default Input Mode
            STZ    INTOUT                                        ; Reset Output Interrupt
            STZ    INTBUF
            JSR    GETDEV                                        ; Setup Dev Pointer
            JSR    SETIVEC                                       ; Set Input Vector
            STX    SHWIN                                         ; Save Channel #
IN_SET      IFEQ   (PRGPTR);#'"'+Hibit;IN_LIT                    ; Check For String
            CPEQ   #';'+Hibit;EAT_SEMI                           ; Possible Gobble
            CPNE   #'@'+Hibit;XDO_INP

            JSR    BYTNUM8                                       ; Get Argument
            CPGEX  #5;XDO_INP

            MOV    MODEBYT,X;INPMODE                             ; set new mode
            BRA    IN_SET

IN_LIT      JSR    GETBYT                                        ; Gobble Up
PR_LIT      JSR    GETBYT
            CPEQ   #'"'+Hibit;IN_SET                             ; Are We Done?

            JSR    COUTLO
            BRA    PR_LIT

EAT_SEMI    JSR    GETBYT                                        ; Gobble Semicolon
            BRA    IN_SET

XDO_INP     IFEQX  SHWIN;#0;DO_IN3D                              ; Use Console Input Routine

            LDX    #0
IN_LOOP     JSR    DO_INP                                        ; Get Input Line
            CPEQ   #lf;IN_LOOP                                   ; Gobble LF

            TAY                                                  ; Set Zero/Non-Zero Bit
            BNE    DO_IN3B

            LDA    #cr
DO_IN3B     STA    LNBUF,X                                       ; Save Char
            INX
            CPNE   #cr;IN_LOOP                                   ; Check For Eol
            BEQ    DO_IN3C                                       ; Yep

DO_IN3D     JSR    INPLN                                         ; Get Console Input Line
DO_IN3C     STZ    LNCNT                                         ; Reset To Start Of Line
DO_IN4      JSR    VARSET
            LDX    #cr
            IFNE   (PRGPTR);#','+Hibit;DO_IN5                    ; more input?

            JSR    GOBCOM                                        ; Gobble Up Char
            LDX    #','
DO_IN5      STX    TEMP2                                         ; Save Ending Character
            LDPL   VNAME;DO_IN8                                  ; Input A Number?

            LDY    #1
            MOV    VARSTR+1;(VPTR),Y                             ; Point At New String
            MOV    VARSTR;(VPTR)
            STZ    TEMP2+1                                       ; Zero Counter
            LDX    LNCNT
MOVE_IN     IFEQ   LNBUF,X;#cr;DO_IN7A                           ; get input

            INX
            CPEQ   TEMP2;DO_IN7A                                 ; Are We Done?

            STA    (VARSTR)                                      ; Copy
            INC    TEMP2+1                                       ; Inc Length Counter
            JSR    INCVARST
            BRA    MOVE_IN

DO_IN7A     STX    LNCNT
            LDY    #2
            LDEQX  TEMP2+1;DO_IN7C                               ; Get The Length

            LDA    INPMODE
            AND    #%00000010
            BEQ    DO_IN7C

            LDX    #1                                            ; Use Length 1
DO_IN7C     TXA
            STA    (VPTR),Y
DO_IN7B     IFNE   TEMP2;#cr;DO_IN4                              ; done?

            IFNE   (PRGPTR);#Or;NO_OUT                           ; Get Another Line?

            JSR    GETBYT                                        ; Gobble
            JMP    XDO_INP

DO_IN8      MOV    LNCNT;TEMP3                                   ; Point At Number
            MOV    #>LNBUF;TEMP3+1
            JSR    ZNUMIN                                        ; Get Number
            PHA
            TYA
            LDY    #2
            STA    (VPTR),Y
            DEY
            PULL   (VPTR),Y
            DEY
            TXA
            STA    (VPTR),Y
            MOVX   TEMP3;LNCNT
            IFEQ   LNBUF,X;#cr;DO_IN7B

            IBRA   LNCNT;DO_IN7B

DO_INP      JMP    (VECTOR2)                                     ; Get A Byte Of Input

NO_INP      LDA    #0                                            ; No Input Available
NO_OUT      RTS

*===============================
* Name: ECHOSTR - Set Echo
*===============================

ECHOSTR     JSR    EQUSTR
            LDA    #-1
            IFNEY  STRLEN;#1;DO_ECH2                             ; is it legal (1 char)?

            LDA    (STRLOC)                                      ; Get Char And Save
            AND    #Clrhi
DO_ECH2     STA    VIDECHO
            RTS

*===============================
* Name: DO_SED - Set Interrupt Key To Spacebar
*                (For Editor)
*===============================

DO_SED      SEC                                                  ; Set Flag
            SKIPCC                                               ; Skip Next Byte

*===============================
* Name: SETINT - Set Interrupt Keys To Be Used
*===============================

SETINT      CLC                                                  ; Fall Into Aint Routine
            PHP
            LDY    #$7F
            MOV    #0;INTOUT                                     ; Reset Output
SINT_ZRO    STA    INTBUF,Y                                      ; Clear Int Buffer
            DBPL   Y;SINT_ZRO                                    ; Loop And Fall Into Addint

            PLP                                                  ; Restore Status
            BCS    AINT0                                         ; Just Enable Spacebar

*===============================
* Name: ADDINT - Add Interrupt Keys
*===============================

ADDINT      JSR    INPARG                                        ; Get Arg
            LSR    A
            BCS    AINT1                                         ; Error, Should Be A String

            IFEQX  NUMB;#1;AINT0                                 ; Fix Stop Char
            CPNEX  #2;AINT3                                      ; Theres A Problem

            LDA    #-1
            LDX    NXTCHR                                        ; Flag "Next-Message" Char
            STA    INTBUF,X
AINT0       LDA    #-1
            LDX    STPCHR                                        ; Flag "Stop-Message" Char
            STA    INTBUF,X
            STA    INTBUF                                        ; Enable Ints
            STA    INTBUF+127                                    ; Special Int Flag
            STZ    INTCHR                                        ; Clear Int Char
            RTS

AINT1       LSR    A                                             ; Put Arg Count Into Carry
            PHP
            LDA    (STRLOC)                                      ; Get Key
            JSR    CONV
            TAX
            MOV    #-1;INTBUF                                    ; Enable Int
            STA    INTBUF,X                                      ; Mark As An Int Key
            PLP
            BCS    ADDINT

RTS3        RTS

AINT3       JMP    MISSMTCH                                      ; Type Mismatch

*===============================
* Name: GET - Get A Single Character
*===============================

GET         JSR    CHKFRE                                        ; Make Sure Enough Memory
            MOV    #0;INTOUT                                     ; Reset Output
            STA    INTBUF
            JSR    VARSET                                        ; Setup Var
            LDPL   VNAME;AINT3                                   ; its a number

            JSR    CHKTIME                                       ; Check For Timeout
            BCC    RTS3                                          ; Opps, Timeout!

DO_GET1     JSR    KEYIN                                         ; Get The Char
            TSTPL  DOCHAT;DO_GET2                                ; all is well

            MOVX   #-1;INCHAT
            JSR    DO_CHAT                                       ; Handle Chat
            BRA    DO_GET1

DO_GET2     JSR    CONV
            STA    (VARSTR)                                      ; Save Character
            MOV    VARSTR;(VPTR)                                 ; Point To Char
            LDY    #1
            MOV    VARSTR+1;(VPTR),Y
            INY
            MOV    #1;(VPTR),Y                                   ; Length 1
            JMP    INCVARST                                      ; Inc String Space

*===============================
* Name: KEY - Check For Keypress
*===============================

KEY         JSR    CHKDCD                                        ; Make Key Check For Carrier
            LDA    #0                                            ; Null Character For Test
            JSR    COUT                                          ; Poll Modem/Keyboard
            JSR    INPTYP                                        ; get next token type
            BEQ    KEY0                                          ; end of statement/line

            JSR    GETBYT                                        ; get token
            CPEQ   #End;DO_KEY2                                  ; Check For STOP Char?
            CPEQ   #Next;DO_KEY3                                 ; Check For NEXT Char?
            CPEQ   #Flag;DO_KEY5                                 ; Check For Int Taking Place

KEY0        JSR    GETCHR                                        ; Check Buffer
            BRA    DO_KEY1

DO_KEY2     LDRAX  STPCHR;DO_KEY4                                ; Check Stop Char

DO_KEY3     LDX    NXTCHR                                        ; Check Next Char
DO_KEY4     LDA    #0
            CPNEX  INTCHR;DO_KEY1                                ; Did They Hit It?
            IBRA   A;DO_KEY1

DO_KEY5     LDA    INTOUT                                        ; Output Interrupted?
DO_KEY1     AND    #Clrhi
            JMP    SVDATA                                        ; Thats It

*===============================
* Name: WIDTH - Get Width From Index
*===============================

WIDTH       IFNE   (PRGPTR);#'('+Hibit;VWIDTH                    ; Is It A Normal Width Cmd?

            JSR    INPNARG8                                      ; Get Arg
            CPGEX  #5;W_ERR                                      ; In Range?

            LDA    E_WIDTH,X                                     ; Get Width
            JMP    SVDATA

VWIDTH      TSTMI  IMMDEF;VWIDTH1                                ; Get Cmd

            LDA    VIDLEN
            JMP    SVDATA

VWIDTH1     JSR    EQUNUM8                                       ; Get Video Width
            TXA
            BEQ    W_ERR                                         ; Opps Problem

            STX    VIDLEN
            RTS

W_ERR       JMP    SYNTAX

*===============================
* Name: WINDOW - Read Or Set Top Of Screen
*===============================

WINDOW      BCC    W_ERR                                         ; Read No Longer Supported

            JSR    GOBEQU                                        ; Set New Window Value
            LDRAY  #2;WINDOW2A                                   ; Start With Screen Top

WINDOW2     IFNE   (PRGPTR);#','+Hibit;WINDOW4                   ; more parms?

            JSR    GOBCOM                                        ; Eat The Comma
WINDOW2A    PHY                                                  ; Save Y For Later
            JSR    INPNUM8                                       ; Get Number
            PLY                                                  ; Restore Y
            TXA
            CPGE   WIN_PARM,Y;WINDOW3                            ; In Range?

            STA    WNDLFT,Y                                      ; Save It
WINDOW3     INY                                                  ; Point To Next
            CPEQY  #2;WINDOW4                                    ; done?
            CPNEY  #4;WINDOW2                                    ; done with top/bottom?
            LDRAY  #0;WINDOW2                                    ; set to left/width

WINDOW4     RTS

WIN_PARM    DB     23,23,80,80

*===============================
* Name: SCRN - Read, Set Or Execute Screen Stuff
*===============================

SCRN        PHP
            LSR    A                                             ; Convert Back Into Token
            SEC
            SBC    #HomeTkn                                      ; Convert To Index
            TAX
            PLP
            BCC    NGETVAL                                       ; Opps, Do read, not set

            PHA
            IFNE   (PRGPTR);#Equal;DO_SFUNC                      ; next an equal?

            JSR    EQUSTR
            CPGEY  #7+1;SCRNOVFL                                 ; 7 chars max
            PLA
            ASL    A                                             ; multiply by 8
            ASL    A
            ASL    A
            TAX
            TYA
            STA    CURREMUL,X                                    ; Set The Value
            LDY    #0                                            ; Copy the string
SVEMSTR     INX
            MOV    (STRLOC),Y;CURREMUL,X
            INY
            CPNEY  STRLEN;SVEMSTR
            RTS

SCRNOVFL    LDA    #Strtobig                                     ; Too big
            JMP    BADERR

NGETVAL     ASL    A                                             ; Make into offset
            ASL    A
            ASL    A
            TAX
            LDA    CURREMUL,X                                    ; Get the length
            TAY                                                  ; Put it where it belongs
            TXA
            CLC                                                  ; Add in the table location
            ADC    #<CURREMUL+1
            TAX
            LDA    #0
            ADC    #>CURREMUL+1
            JMP    SVSTR                                         ; Save it
*
*  Handle the local video
*
DO_CLS      PUSHA  #ClsTkn2-HomeTkn
DO_SFUNC    LDY    #ioBoth                                       ; set i/o to modem & screen
            JSR    SETOVEC
            PLA
EMULFUNC    PHA
            CPNE   #Gotoxy-HomeTkn;DO_FUNC2                      ; Is It A Gotoxy?

            JSR    INPNARG8                                      ; Get X parm
            STX    GOTO_X
            JSR    INPNARG8                                      ; and Y parm
            STX    GOTO_Y

DO_FUNC2    LDEQ   CURODEV;DO_FUNC3                              ; Wheres this going?, all
            CPNE   #ioLocal;DO_FUNC4                             ; screen only?

DO_FUNC3    PLX                                                  ; convert to local control
            PHX
            LDA    V_NEWCHR,X
            BEQ    DO_FUN3A
            JSR    VIDCOUT
DO_FUN3A    PLA
            PHA

            CPNE   #Gotoxy-HomeTkn;DO_FUNC4                      ; Is It A Gotoxy?

            CLC
            LDA    GOTO_X
            ADC    #goxyOffs                                     ; Add The Offset Value
            JSR    VIDCOUT                                       ; Print It
            CLC
            LDA    GOTO_Y
            ADC    #goxyOffs                                     ; Add The Offset Here Also
            JSR    VIDCOUT
*
*  Now do the remote stuff
*
            DO     DEMOPGM
DO_FUNC4    PLA
            RTS
            ELSE
DO_FUNC4    LDNE   CURODEV;DO_FUNC5                              ; anywhere but both mdm/scrn

            TSTMI  REMOTE;DO_FUNC5                               ; Online?
            PLA                                                  ; Nope
SCRNDONE    RTS

DO_FUNC5    PLA
            CPNE   #Gotoxy-HomeTkn;DO_FUNC6                      ; if not gotoxy, normal

            TSTMI  ANSIFLAG;DO_ANSI                              ; in ANSI mode?

DO_FUNC6    PHA
            ASL    A                                             ; make index
            ASL    A
            ASL    A
            TAX
            LDEQ   CURREMUL,X;NO_FUNC                            ; Get the length
            TAY                                                  ; Put it where it belongs
DO_FUNC7    INX
            LDA    CURREMUL,X                                    ; send the string
            JSR    SMDMOUT
            DBNE   Y;DO_FUNC7

NO_FUNC     PLA                                                  ; Get Back Call Type
            CPNE   #Gotoxy-HomeTkn;SCRNDONE                      ; Is It A Gotoxy?

            LDX    GOTO_X                                        ; get X & Y
            LDY    GOTO_Y
            TSTPL  OFFSNUM;SND_XY                                ; in YX order?
            PHXY                                                 ; no, reverse them
            PLX
            PLY
SND_XY      CLC                                                  ; send X & Y data
            TXA
            ADC    OFFSNUM                                       ; Add offset to X
            AND    #Clrhi
            JSR    SMDMOUT
            CLC
            TYA
            ADC    OFFSNUM                                       ; Add offset to Y
            AND    #Clrhi
            JMP    SMDMOUT

DO_ANSI     LDA    #esc                                          ; send leadin seq
            JSR    SMDMOUT
            LDA    #'['
            JSR    SMDMOUT
            LDA    GOTO_Y                                        ; Get back X
            JSR    XYDEC                                         ; Send number string
            LDA    #';'                                          ; send the separator
            JSR    SMDMOUT
            LDA    GOTO_X                                        ; Get back Y
            JSR    XYDEC                                         ; Send this string too
            LDRA   #'H';SMDMOUT                                  ; Send the terminator

MKDEC       LDY    #0                                            ; zero 100's
CP100       CPLT   #100;LT100                                    ; > 99?
            INY                                                  ; incerment 100s
            SEC
            SBC    #100                                          ; remove 100
            BRA    CP100                                         ; check again

LT100       LDX    #0                                            ; zero 10s
CP10        CPLT   #10;LT10                                      ; > 9?
            INX                                                  ; increment 10s
            SEC
            SBC    #10                                           ; remove 100
            BRA    CP10                                          ; check again

LT10        RTS

XYDEC       JSR    MKDEC
            PHA                                                  ; A contains 1s
            PHX                                                  ; save 10s
            TYA                                                  ; get 100s
            BEQ    NO100                                         ; none, dont send
            ORA    #'0'                                          ; make ASCII
            JSR    SMDMOUT
NO100       PLA                                                  ; get 10s
            BEQ    NO10                                          ; none, dont send
            ORA    #'0'                                          ; make ASCII
            JSR    SMDMOUT
NO10        PLA                                                  ; get 1s
            ORA    #'0'                                          ; make ASCII
SMDMOUT     PHA                                                  ; save char
            LDEQ   CURODEV;S_MODEM                               ; where to?
            PLA                                                  ; get back char
            JMP    (VECTOR)                                      ; send to device

S_MODEM     PLA                                                  ; get char back
            JMP    MDMOUT                                        ; send to modem
            FIN

*===============================
* Set or get nulls
*===============================

DO_NULLS    BCS    NULLS1                                        ; Do Set Not Read

            LDRA   NNULLS;SAVEIT                                 ; Get nulls

NULLS1      JSR    EQUNUM8
            STX    NNULLS                                        ; Set nulls
            RTS

*===============================
* Set or get GotoXY offset
*===============================

DO_OFFSET   BCS    OFFSET1                                       ; Do Set Not Read

            LDRA   OFFSNUM;SAVEIT                                ; Get the offset

OFFSET1     JSR    EQUNUM8
            STX    OFFSNUM                                       ; Set the offset
            RTS

*===============================
* Name: ERR - Return Last Error Number
*===============================

ERR         LDA    ERRNO                                         ; Get Value
SAVEIT      JMP    SVDATA

*===============================
* Name: NODE - Return System Node Number
*===============================

NODE        LDRA   NODENUM;SAVEIT                                ; Get Network Node #

*===============================
* Name: ONLINE - Return Online Status
*===============================

ONLINE      LDRA   REMOTE;SAVEIT                                 ; Pass Remote Flag

*===============================
* Name: BAUD - Return Users Baud Rate
*===============================

BAUD        LDRA   CALLSPD;SAVEIT                                ; Get Callers Speed

*===============================
* Name: EXEC - Read Or Set Exec Flag
*===============================

EXEC        BCS    EXECCMD1                                      ; Opps Do Set Not Read

            LDRA   EXECFLG;SAVEIT

EXECCMD1    MOV    #%10111111;EXECFLG                            ; Set Exec Flag
            JSR    EQUNUM8                                       ; Set New Exec Flag
            CPNEX  #0;EXECCMD2                                   ; Its Already Set

            STX    EXECFLG                                       ; Set Exec To 0
EXECCMD2    RTS

*===============================
* Name: TERMINAL - Read/Set Terminal Number
*===============================

TERMINAL    BCS    SETTERM                                       ; Set It

            LDRA   TERMNO;SAVEIT                                 ; Get Terminal ID Number

SETTERM     JSR    EQUNUM8                                       ; Get The Number
            TXA
            BPL    TSET                                          ; Set It If Positive

            DO     DEMOPGM
TSET        STA    TERMNO
            RTS
            ELSE
            LDEQX  REMOTE;PTERM                                  ; Remote mode?

            JSR    WAITSEC                                       ; Wait One Second
            JSR    CHECKPT                                       ; is it Proterm special?
            BNE    TSET                                          ; yes, set it
            JSR    WAITSEC                                       ; Wait One Second
            JSR    WAITSEC                                       ; Wait One Second
            JSR    CHKANSI                                       ; how about ANSI
            BEQ    TSET
            PHA
            JSR    SETANSI                                       ; set ANSI mode
            PLA
TSET        STA    TERMNO
            CPNE   #0;T_DONE                                     ; was a terminal detected?
            LDX    #$C0
ZEROTRM     DEX                                                  ; zero the emulation table
            STZ    CURREMUL,X
            TXA
            BNE    ZEROTRM
T_DONE      JMP    WAITSEC                                       ; Wait One Second

CHECKPT     LDA    #'E'-Ctrl                                     ; Proterm Special Enq?
            JSR    MDMOUT                                        ; Send It
            LDY    #2                                            ; Wait A Max 3 Sec
WAITPT      JSR    WAITSEC                                       ; Wait Another Sec
            JSR    MDMIN                                         ; Get A Char (If There)
            DEY                                                  ; Bump Seconds Done One
            CPEQ   #']'-Ctrl;PTERM                               ; Proterm Special Ack

            TYA                                                  ; Done?
            BNE    WAITPT
            RTS

PTERM       LDX    #EndPTSE-V_NEWCHR
SETPT       TXA
            ASL    A                                             ; make index
            ASL    A
            ASL    A
            TAY
            MOV    #1;CURREMUL,Y                                 ; Set the length
            MOV    V_NEWCHR,X;CURREMUL+1,Y                       ; and the char
            DBPL   X;SETPT

            MOV    #goxyOffs;OFFSNUM
            MOV    #255;TERMNO                                   ; Acknowledged, Set It
            RTS

ANSIDA      HEX    1B5B356E00                                    ; Report status

CHKANSI     JSR    MDMIN                                         ; Clear anything waiting
            BCS    CHKANSI

            LDX    #0                                            ; Send the string
CHKANSI2    LDEQ   ANSIDA,X;SND_DN
            JSR    MDMOUT
            IBNE   X;CHKANSI2

SND_DN      MOV    #62;PRN                                       ; wait a while
            TAY
            LDX    #0                                            ; read at position 0
GETRESP     JSR    MDMIN                                         ; read a char (maybe)
            BCS    SVRESP                                        ; got one
            DBNE   Y;GETRESP
            DBNE   PRN;GETRESP                                   ; count down more
            BRA    CHKLINE

SVRESP      STA    LNBUF,X                                       ; save the char
            IBNE   X;GETRESP

CHKLINE     IFNE   LNBUF;#esc;NOTANSI                            ; must be esc[
            IFNE   LNBUF+1;#'[';NOTANSI
            LDX    #2
SKIPPRMS    LDA    LNBUF,X                                       ; check line for parameters
            INX
            CPLT   #'A';SKIPPRMS
            CPNE   #'n';NOTANSI                                  ; if not an n, not real ANSI
            LDA    #254
            RTS

NOTANSI     LDA    #0                                            ; no response, or not ANSI
            RTS

*===============================
* Name: WAITSEC - Delay One Second
*===============================

WAITSEC     LDX    #10
SEC_LUP     LDA    #$C3                                          ; 1/10 Sec
            JSR    WAIT
            DBPL   X;SEC_LUP

            RTS

*===============================
* Name: TONE - Produce A Tone With Apple Speaker
*===============================

TONE        MOV    #1;TEMP+1                                     ; Default To 1 Tone
            JSR    INPNARG8                                      ; Get Tone Argument
            STX    TEMP2
            JSR    INPNARG8                                      ; Get Duration/Tone2 Arg
            STX    TEMP                                          ; Save As Duration
            BCC    DO_TONE                                       ; Last Argument, All Correct

            IFNE   (PRGPTR);#','+Hibit;DO_TONE                   ; do single tone

            STX    TEMP+1                                        ; Save Second Tone
            JSR    INPNARG8                                      ; Get Real Duration
            STX    TEMP2                                         ; Save Duration
DO_TONE     IFNE   TERMNO;#255;NOPT                              ; Useing ProTERM?

            LDA    #Tonecmd                                      ; Tell Them This Is A Tone
            LDX    #TEMP2+1                                      ; Point To Arguments+1
            BRA    SENDIT

SENDARG     LDA    TEMP,X                                        ; Get An Argument
SENDIT      LDY    REMOTE                                        ; Remote User Online?
            DO     DEMOPGM
            ELSE
            BEQ    TRYLOC                                        ; No, Try Local

            JSR    MDMOUT                                        ; Send To Modem
            FIN
TRYLOC      TSTMI  LASTIN;DONEXT                                 ; Sysop At Keyboard?

            JSR    VIDCOUT                                       ; Send It
DONEXT      DBPL   X;SENDARG                                     ; Next One

NOPT        RTS

*===============================
* Name: DO_SER - Print Serial # Of Software
*===============================

            DO     DEMOPGM
DO_SER      RTS
            ELSE
DO_SER      JSR    KEYIN2                                        ; Check Serial # Show Access
            CPEQ   #'?';SER1

            RTS

SER1        MOVD   #SERNUM;TEMP                                  ; Print Serial #
            LDY    #SERLEN
            DEY
SER2        LDA    (TEMP),Y
            EOR    #SERLEN
            LSR    A
            JSR    MDMOUT
            DBPL   Y;SER2
            LDA    #' '
            JSR    MDMOUT
            MOV    #-1;PRN+1
            FIN

*-------------------------------
* Print Version Number
*-------------------------------

PRTVER      LDA    VERSION+1                                     ; print main version number
            JSR    PRBYTE
            LDA    #'.'                                          ; separate with a .
            JSR    PRHEX2
            LDA    VERSION                                       ; get minor version number
            PHA
            LSR    A                                             ; do the high nibble
            LSR    A
            LSR    A
            LSR    A
            JSR    PRTHEX
            CPGE   #'9'+1;NO_DOT                                 ; was it a non-release?
            LDA    #'.'                                          ; nope, show another .
            JSR    PRHEX2
NO_DOT      PLA                                                  ; now do the low nibble
            BRA    PRTHEX

PRBYTE      PHA                                                  ; Get High Nibble
            LSR    A
            LSR    A
            LSR    A
            LSR    A
            BEQ    PRBYTE2                                       ; Not 0, Print It
PRBYTE1     JSR    PRTHEX                                        ; Print Nibble
PRBYTE2     PLA                                                  ; Bet Back Byte
PRTHEX      AND    #%00001111                                    ; Strip Off Hi Nibble
            ORA    #'0'                                          ; Make It ASCII
            CPLT   #'9'+1;PRHEX2                                 ; Letter?

            ADC    #$26                                          ; Yes, Make It Lower Case
            DO     DEMOPGM
PRHEX2      JMP    COUT
            ELSE
PRHEX2      TSTMI  PRN+1;PRHEX3
            JMP    COUT
PRHEX3      JMP    MDMOUT
            FIN
            LST    OFF

