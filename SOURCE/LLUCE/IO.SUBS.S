            LST    RTN
            TTL    'LLUCE - I/O Subroutines'
            PAG
*===============================
* Contents:
*
* BELLOUT  - Send A Bell To Output Device
* BSOUT    - Send A BS To Output Device
* CHKKEY   - Check For Input Character
* CLRBTM   - Reset Screen, Clear Bottom Line
* CLRBUF   - Clear Char Buffer
* COUT     - Print Char In A, Check For Input
* COUTLO   - Print char in A, strip high bit
* CROUT    - Send A CR/LF To Output Device
* DO_CHAT  - Chat With User
* DO_EXEC  - Set Exec Mode, Modem Output Off
* GO23     - Save Cursor, GotoXY(0,23)
* GETCHR   - Get Char From Buffer
* INPLN    - Get An Input Line
* KEYIN    - Get Character From Input Device
* LDCHCV   - Restore Cursor Position
* PR       - Print Text, Normal Or Banner
* PRBACK   - Print A Destructive Backspace
* PRMSG    - Print Message From Index
* PUTCHR   - Save Char In Buffer
* RDKEY    - Get Character From Input Device
* RSTLINE  - Print Saved Screen Line
* SDUMP    - Send Screen To Printer
* SETBTM   - Scroll Screen, Protect Last 2 Lines
* SHOWSTR  - Print String
* SHOW_ERR - Print An Error Message
* SPCOUT   - Send A Space To Output Device
* SVCHCV   - Save Cursor, GotoXY(0,A)
* SVLINE   - Save Screen Line
* V_RDCHAR - Read Character From Screen
* ZMDMOUT  - Send Data To Modem Only
*===============================

*===============================
*   Name: INPLN - Get An Input Line
*
*  Input: None
*
* Output: None
*===============================

INPLNA      JSR    CROUT                      ; Do CR Before Getting Line

INPLN       TSTMI  INCHAT;INPLN1C             ; Are They In Chat?

            JSR    CHKTIME                    ; Is Time Ok?
            BCC    INPLN1A                    ; Opps, Timeout!

INPLN1C     LDY    #0
INPLN1      JSR    KEYIN
            TSTPL  DOCHAT;INPLN1A             ; Do Chat?
            TSTPL  INCHAT;INPLN1B             ; In Chat?
            RTS                               ; Return Early

INPLN1B     LDA    #can                       ; Do We Need To Del Line?
            CPNEY  #0;INPLN2

            MOVX   #-1;INCHAT                 ; Set InChat mode
            JSR    DO_CHAT                    ; Do Actual Chat
            BRA    INPLN

INPLN1A     TSTMI  LOGOFF;JINPLN8             ; Check No Carrier/Timeout
            CPEQ   #cr;JINPLN6                ; Return
            CPEQ   #bs;INPLN2                 ; Back Space
            CPEQ   #can;INPLN2                ; Ctrl-X / Cancel
            CPNE   #del;INPLN3                ; Delete

INPLN2      CPEQY  #0;INPLN1                  ; Can We Back Up?

            PHA
            JSR    PRBACK                     ; Do Backspace
            DEY                               ; Decrease Char Count
            PLA
            CPEQ   #can;INPLN2                ; If Its A Cancel
            BRA    INPLN1

INPLN3      CPLT   #' ';INPLN1                ; If Its A Control Char...
            CPNEY  VIDLEN;INPLN4              ; Check For Max Length

            STA    LNBUF,Y                    ; Save Last Character
            LDA    INPMODE
            AND    #%00010000                 ; Do Word-Wrap?
            BEQ    INPLN3E                    ; Nope

            STY    TEMP                       ; Save Line Length
            IFEQ   LNBUF,Y;#' ';INPLNA        ; get last char, ok, Restart

            LDX    #0                         ; Setup For Inpln3B
INPLN3A     IFEQ   LNBUF,Y;#' ';INPLN3B       ; We Found A Space
            DBNE   Y;INPLN3A                  ; Keep Checking

            LDNEY  TEMP;INPLN3E               ; Get Back Length, no word wrap

INPLN3B     INY
            JSR    PRBACK                     ; Back Up
            MOV    LNBUF,Y;LNBUF,X
            INX
            CPNEY  TEMP;INPLN3B               ; Loop Until All Data Copied

            STX    TEMP                       ; Save End Pointer
            JSR    CROUT                      ; Start A New Line
            LDY    #0
INPLN3C     LDA    LNBUF,Y
            JSR    COUTLO                     ; Print Data
            INY
            CPNEY  TEMP;INPLN3C
            JMP    INPLN1                     ; Go Back For More Input

JINPLN6     BEQ    INPLN6
JINPLN8     BMI    INPLN8

INPLN3E     JSR    BELLOUT                    ; Beep The Bell
            JMP    INPLN1

INPLN4      TSTPL  INPMODE;INPLN4A            ; Do We Convert?

            JSR    CONV                       ; Convert To Upper
INPLN4A     TSTVC  INPMODE;INPLN5             ; Check The Inpmode
            CPEQ   #',';INPLN5B               ; Dont Accept A Comma
            CPNE   #' ';INPLN5                ; Dont Accept A Space
            CPEQY  #0;INPLN5B                 ; For First Char Of The Line

INPLN5      STA    LNBUF,Y                    ; Save Char
            INY
            TSTMI  VIDECHO;INPLN5A            ; Special Echo?

            LDA    VIDECHO
INPLN5A     JSR    COUTLO                     ; Print It
INPLN5B     JMP    INPLN1                     ; Loop

INPLN6      MOV    #cr;LNBUF,Y                ; Save The Return
            CPNEY  #0;INPLN7                  ; Was Is Just A Return?

            LDA    INPMODE                    ; Accept A Blank Line?
            AND    #%00100000
            BNE    CROUT                      ; Yep

            JMP    INPLN                      ; Dont Take, CR, Start Over

INPLN8      MOV    #cr;LNBUF                  ; Return Blank Line
            RTS

*===============================
*   Name: PRBACK - Print A Destructive Backspace
*
*  Input: None
*
* Output: None
*===============================

PRBACK      JSR    BSOUT                      ; Print BS - Space - BS
            JSR    SPCOUT

*===============================
*   Name: BSOUT   - Send A BS To Output Device
*         BELLOUT - Send A Bell To Output Device
*         CROUT   - Send A CR/LF To Output Device
*         SPCOUT  - Send A Space To Output Device
*
*  Input: None
*
* Output: None
*===============================

BSOUT       LDA    #bs                        ; Execute A Backspace
            SKIP2
BELLOUT     LDA    #bel                       ; Execute A Bell
            SKIP2
CROUT       LDA    #cr                        ; Execute A CR
            SKIP2
SPCOUT      LDA    #' '                       ; Do A Space
INPLN7      JMP    COUTLO                     ; Print The Return And Exit

*===============================
*   Name: KEYIN - Get Character From Input Device
*
*  Input: None
*
* Output: A - Keyboard Character
*===============================

KEYIN       JSR    GETCHR                     ; Get Char From Buffer
            BNE    KEYIN5                     ; (If Present)

KEYIN2      LDA    #'_'
            JSR    VIDCOUT                    ; Print Cursor
            LDA    #bs
            JSR    VIDCOUT
            MOVD   TOCONST;TIMEOUT+2          ; [32=1 Minute] - 5 Minutes
            STZ    TIMEOUT+1                  ; Reset Medium Counter
            LDA    KILCLTO                    ; Local Time Constant
            TSTPL  REMOTE;KEYIN2B             ; Dont Change Anything

            LDA    KIRMTTO                    ; Get Modem Time Constant
KEYIN2B     STA    TIMEOUT
            STA    TIMEOUT+4
KEYIN3      DBNE   TIMEOUT;KEYIN3A            ; Count Down

            MOV    TIMEOUT+4;TIMEOUT          ; Reset Low-Byte Constant
            IBNE   TIMEOUT+1;KEYIN3A          ; Cycle 256 Counter

            LDA    TIMEOUT+2                  ; Check Time
            AND    #%00011111                 ; Do Bell?
            BNE    KEYIN3B

            JSR    BELLOUT                    ; Beep Bell
KEYIN3B     TSTPL  NOCDFLG;KEYIN3A            ; No Carrier Vector?
            TSTMI  EXECFLG;KEYIN3A            ; Check For Exec User
            DBNE   TIMEOUT+2;KEYIN3A          ; Count Down Minutes
            DBPL   TIMEOUT+3;KEYIN3A

            JMP    ZAPCALL                    ; Signal Logoff

KEYIN3A     JSR    CHKKEY                     ; Wait For Keypress
            BNE    KEYIN4                     ; Got One!

            TSTPL  DOCHAT;KEYIN3              ; Check Chat Flag

            LDA    #0                         ; Return Early
KEYIN4      PHA
            LDA    #' '
            JSR    VIDCOUT                    ; Remove Cursor
            LDA    #bs
            JSR    VIDCOUT
            PLA
KEYIN5      RTS

*===============================
*   Name: CHKKEY - Check For Input Character
*
*  Input: None
*
* Output: A - Character
*         A = 0: No Character
*===============================

CHKKEY      INCD   RNDNUM                     ; Setup Random Seed
            LDPL   KYBD;GET2                  ; Get char from Keyboard

            AND    #Clrhi
            STA    LASTIN                     ; Last Char From Local
            STA    KBDSTRB                    ; Clear strobe
            TSTPL  BUTN0;GET3                 ; Read Open-Apple

            JSR    CONV                       ; Make It Upper Case
            CPEQ   #prnscr;GET4               ; Print Screen?
            CPEQ   #chat;GET7                 ; Chat?
            CPEQ   #logout;GET8               ; Quick Logoff?
            CPEQ   #execon;GET9               ; Exec Mode?
            CPNE   #bartog;GET3               ; Toggle Bottom Bar?

            TSTMI  SHWTXT;GET8A               ; Go To Program Trace Mode?
            TSTMI  SHWTRC;GET8B               ; Exit Program Trace Mode?

            DEC    SHWTXT                     ; Show User Input
            PHY
            JSR    SETBTM
            JSR    GO23                       ; Save Horiz / Vert Position
            JSR    PR                         ; Print Message
            ASC    'INP:'00
            JSR    LDCHCV                     ; Restore Position
            DEC    WNDBTM                     ; Shorten Screen
            DEC    WNDBTM
            PLY
GET2        LDA    #0                         ; No Data
            DO     DEMOPGM
            RTS
            ELSE
            TSTPL  REMOTE;GET3B               ; Check Modem?

            JSR    CHKDCD                     ; Is There Carrier?
            BCC    GET3B                      ; Nope!

            JSR    MDMIN                      ; Check Modem
            BCC    GET3B                      ; No Data

            ROR    LASTIN                     ; Put Carry Set To High Bit
            AND    #Clrhi                     ; Strip High Bit
            FIN
GET3        TSTPL  SHWTXT;GET3B               ; Show Input?

            PHA
            ORA    #Hibit
            CPGE   #' '+Hibit;GET3A           ; Is It A Control?

            PHA
            LDA    #'^'+Hibit                 ; Show Control Lead-In
            JSR    VIDBAN
            PLA
GET3A       JSR    VIDBAN
            PLA
GET3B       CMP    #0                         ; Set Status
            RTS

GET4        BRA    SDUMP                      ; Go To Get4 (Screen Dump)

GET7        MOV    #-1;DOCHAT                 ; Signal Chat Is Needed
            BRA    GET2                       ; Finish Up

GET8        JMP    ZAPCALL                    ; Signal Logoff

GET8A       INC    SHWTXT                     ; Select Program Trace
            DEC    SHWTRC
            PHY                               ; Save Y
            JSR    GO23                       ; Save Current Horiz / Vert
            JSR    PR                         ; Print Message
            ASC    'PRG:'00
            JSR    LDCHCV                     ; Restore Position
            PLY                               ; Restore Y
            BRA    GET2

GET9        MOV    #Hibit;DOCHAT              ; Signal Exec Mode Is Wanted
            BRA    GET2

GET8B       JSR    SVCHCV
            INC    SHWTRC                     ; Select Nothing
            JSR    CLRBTM
GET8C       BRA    GET2

*===============================
*   Name: SDUMP - Send Screen To Printer
*
*  Input: None
*
* Output: None
*===============================

SDUMP       PHXY                              ; Save X & Y
            LDX    #0                         ; Start At Line 0
SDUMP1      PHX
            LDY    #0                         ; Start At Char Zero
            PHY
SDUMP2      JSR    V_RDCHAR                   ; Read Char From Screen
            JSR    LPROUT                     ; Print Char On Printer
            PLY
            INY
            CPNEY  WNDWDTH;SDUMP2             ; At Window Width?

            LDA    #cr                        ; Add CR To Line
            JSR    LPROUT
            PLX
            INX
            CPNEX  #vidHeight;SDUMP1          ; At Last Line?

            JSR    LPROUT                     ; Add Extra CR
            PLXY                              ; Restore X & Y
            BRA    GET8C                      ; Go Back To Get

*===============================
*   Name: CLRBTM - Reset Screen, Clear Bottom Line
*
*  Input: None
*
* Output: None
*===============================

CLRBTM      INC    WNDBTM                     ; Select Bottom 2 Lines
            INC    WNDBTM
            PHXY
            JSR    VIDLST                     ; Clear Line 24
            JSR    LDCHCV
            PLXY
            RTS

*===============================
*   Name: SETBTM - Scroll Screen, Protect Last 2 Lines
*
*  Input: None
*
* Output: None
*===============================

SETBTM      IFLTY  CV;#vidHeight-2;BTM_RTS    ; Do We Need To Scroll?

            DEY                               ; Move Cursor Up 2 Lines
            DEY
            STY    CV                         ; Save New Cursor Position
            JSR    VIDSCRL                    ; Scroll Data
            JMP    VIDSCRL

BTM_RTS     RTS

*===============================
*   Name: GO23   - Save Cursor, GotoXY(0,23)
*         SVCHCV - Save Cursor, GotoXY(0,A)
*
*  Input: None
*
* Output: None
*===============================

GO23        LDA    #vidHeight-1
SVCHCV      PHA
            MOV    CH;OLDCH                   ; Save Old Values
            MOV    CV;OLDCV
            STZ    CH                         ; Position To 0,[Inparg]
            PULL   CV
            RTS

*===============================
*   Name: LDCHCV - Restore Cursor Position
*
*  Input: None
*
* Output: None
*===============================

LDCHCV      PHXY                              ; Save Both X & Y
            LDX    OLDCH                      ; Position
            LDY    OLDCV
            JSR    VIDPOS
            PLXY
            RTS

*===============================
*   Name: RDKEY - Get Character From Input Device
*
*  Input: None
*
* Output: Keypress - 0 if none
*===============================

RDKEY       JSR    GETCHR                     ; Get Char From Buffer
            BNE    OUT_RTS                    ; (If Present)

            PHX
            LDX    CV
            JSR    VIDRDST                    ; Set Up Line Position
            JSR    VIDRDKY                    ; Get Current Char
            STA    BLINK                      ; Save It
            PLX
            STZ    TIMEOUT                    ; Setup Counter For Timeout
            MOV    #4;TIMEOUT+1
RDKEY2      PHA
            JSR    VIDRDKY                    ; Read Char From Screen
            STA    VID_Y                      ; Save It
            IFNE   #'_'+Hibit;VID_Y;RDKEY1    ; Nope, Show The '_'

            LDA    BLINK                      ; Show Original Char
RDKEY1      JSR    VIDSTORE
            PLA
            TSTPL  REMOTE;RDKEY3              ; we are local

            IBNE   TIMEOUT;RDKEY3             ; Do High Counter
            DBNE   TIMEOUT+1;RDKEY3           ; do main counter

            JSR    MDM1_2
            JSR    ZAPCALL                    ; Return Without Carrier
            BNE    RDKEY4

RDKEY3      JSR    CHKKEY                     ; Check For Keypress
            BNE    RDKEY4                     ; Nope

            LDNE   MONRND;RDKEY3              ; Count Down High

            LDA    MONRND+1
            AND    #%00001111                 ; Blink?
            BNE    RDKEY3
            BRA    RDKEY2                     ; yes

RDKEY4      PHA
            LDA    BLINK
            JSR    VIDSTORE                   ; Put Back Character
            PLA
OUT_RTS     RTS

*===============================
*   Name: COUT - Print Char In A, Check For Input
*
*  Input: Character To Print
*
* Output: None
*===============================

COUTLO      AND    #Clrhi                     ; Clear High Bit
COUT        STX    COUT_X+1
            STY    COUT_Y+1
            TSTMI  INTOUT;OUT_RTS             ; If Output Interrupt
            STA    SAVE_X

            JSR    CHKKEY                     ; Check For A Char
            BEQ    COUT1B

            CPNE   #xoff;COUT0                ; Check For Ctrl-S

            JSR    KEYIN2                     ; Get A Char
            CPNE   #pass;COUT1B               ; Is It A Serial # Request?

            JSR    DO_SER
            BRA    COUT1B                     ; Dont Check For Int

            DO     DEMOPGM
SERNUM      REV    'E1.DEMO1'
            ELSE
SERNUM      REV    'E1.00000'
            FIN
SERLEN      =      *-SERNUM

COUT0       TSTPL  INTBUF;COUT1A              ; See If Ints Enabled

            PHA
            JSR    CONV                       ; Convert To Upper
            STA    COUT1+1                    ; Point To Parm [0-127]
            PLA
COUT1       TSTPL  INTBUF;COUT1A              ; *** Self-Modified

            STZ    INTBUF                     ; No More Ints
            DEC    INTOUT                     ; Turn On Output Interrupt
            IFEQ   #cr;LASTCHR;COUT1C         ; was last char a CR?

            JSR    COUT2                      ; Print CR
COUT1C      MOV    COUT1+1;INTCHR             ; Get Converted Byte
            TSTMI  INTBUF+127;OUT_RTS         ; Special Flag For (^X, ^N)

COUT1A      JSR    PUTCHR                     ; Save Char In Buffer
COUT1B      LDA    SAVE_X
COUT2       CPEQ   #0;OUT_RTS                 ; Any Data?

            STA    LASTCHR                    ; Save Last Character
            TSTMI  REMOTE;COUT3               ; Remote Call?
COUT2A      JMP    COUT2M                     ; Remote Call?

COUT3       =      *
            DO     DEMOPGM
            ELSE
            LDEQX  TERMNO;CO_NCHR2
            TSTMI  CONVFLAG;CO_DOCNV          ; convert emulation?
CO_NCHR2    JMP    CO_NCHR                    ; nope

CO_DOCNV    TSTPL  CO_XY;CO_NOTXY             ; gotoxy sequence?
            SEC
            SBC    #goxyOffs                  ; make into value
            IBEQ   CO_XY;CO_YDONE             ; which value?
CO_SETX     STA    GOTO_X                     ; doing X, save it
            BRA    COUT2A                     ; continue like nothing happened

CO_YDONE    STA    GOTO_Y                     ; doing Y, save it and send
            TSTMI  ANSIFLAG;CO_ANSI           ; ANSI?
            LDX    GOTO_X                     ; get X and Y
            LDY    GOTO_Y
            TSTPL  OFFSNUM;CO_STDXY           ; which order?
            PHXY                              ; reverse them
            PLX
            PLY
CO_STDXY    CLC                               ; send first value
            TXA
            ADC    OFFSNUM
            AND    #Clrhi
            JSR    MDMOUT
            CLC                               ; send other value
            TYA
            ADC    OFFSNUM
            AND    #Clrhi
CO_XY2      JSR    MDMOUT
            BRA    COUT2A                     ; like nothing happened

CO_ANSI     LDA    GOTO_Y                     ; get X
            JSR    CO_XYDEC                   ; send it
            LDA    #';'                       ; and the separator
            JSR    MDMOUT
            LDA    GOTO_X                     ; get Y
            JSR    CO_XYDEC                   ; send it
            LDRA   #'H';CO_XY2                ; and the terminator

CO_NOTXY    TSTPL  CO_RPT;CO_NOTR             ; doing repeat?
            IBEQ   CO_RPT;CO_CDONE            ; which pass?
            BRA    CO_SETX

CO_CDONE    TAX                               ; set counter
            LDRA   GOTO_X;NUL_LOOP            ; get char

CO_NOTR     CPGE   #' ';CO_NCHR               ; check only if ctrl
            CPNE   #goxy;CO_NOXY              ; GotoXY Command?
            MOVX   #-2;CO_XY                  ; need 2 chars
            TSTPL  ANSIFLAG;CO_NOXY           ; is it ANSI?
            LDA    #esc                       ; send lead-in
            JSR    MDMOUT
            LDRA   #'[';CO_XY2

CO_NOXY     CPNE   #ptRepeat;CO_NORPT
            IFEQX  TERMNO;#255;CO_NCHR
            MOVX   #-2;CO_RPT
            BRA    CO_NCHR

CO_NORPT    LDX    #EndPTSE-V_NEWCHR          ; is it an emul char?
FND_EMU     CPEQ   V_NEWCHR,X;GOT_EMU
            DBPL   X;FND_EMU                  ; keep searching
            BRA    CO_NCHR                    ; not emulation

GOT_EMU     TXA                               ; get index
            ASL    A
            ASL    A
            ASL    A
            TAX
            LDEQ   CURREMUL,X;COUT2M          ; Get length

            TAY
SNDEMUL     INX
            LDA    CURREMUL,X                 ; Get one char
            JSR    MDMOUT                     ; send it
            DBNE   Y;SNDEMUL
            BRA    COUT2M

CO_NCHR     JSR    ZMDMOUT                    ; Output To Modem
            CPNE   #cr;COUT2M                 ; Was It A CR?

SNDNULS     LDEQ   NNULLS;COUT2M              ; Add Nulls?

            TAX
            LDA    #0
NUL_LOOP    JSR    MDMOUT                     ; Send A Null
            DBNE   X;NUL_LOOP

            FIN
COUT2M      IFNE   SAVE_X;#bel;CO_DOIT        ; Beep Speaker?

            TSTMI  LASTIN;COUT_X              ; Was Last Input Remote?

CO_DOIT     JSR    VIDCOUT

COUT_X      LDX    #0
COUT_Y      LDY    #0
            RTS

CO_XYDEC    JSR    MKDEC                      ; convert to decimal
            PHA                               ; save 10s and 1s
            PHX
            TYA                               ; any 100s?
            BEQ    CO_NO100                   ; nope
            ORA    #'0'                       ; make ascii
            JSR    MDMOUT
CO_NO100    PLA                               ; what about 10s?
            BEQ    CO_NO10                    ; nope
            ORA    #'0'                       ; make ascii
            JSR    MDMOUT
CO_NO10     PLA                               ; always 1s
            ORA    #'0'
            JMP    MDMOUT

*===============================
*   Name: PR - Print Text, Normal Or Banner
*
*  Input: None
*
* Output: None
*===============================

PR          PULLW  PRN
            PHY                               ; Save Y
PR2         JSR    INCPRN                     ; Get Next Byte
            LDEQ   (PRN);PR4                  ; Get Byte
            BMI    PR3A                       ; If High Bit, Banner Print

            JSR    VIDCOUT                    ; Otherwise Use Normal
            BRA    PR3B

PR3A        JSR    VIDBAN                     ; Print It
PR3B        JSR    PAUSE
            BRA    PR2

PR4         JSR    INCPRN                     ; Inc For Return
            PLY                               ; Restore Y
            JMP    (PRN)

*===============================
*   Name: SHOW_ERR - Print An Error Message
*
*  Input: A - Error Code
*
* Output: None
*===============================

SHOW_ERR    CPEQ   #0;ERROR2                  ; Error?

            JSR    CROUT
            IFLT   ERRNO;#Usrerr;STDERR       ; User Defined Error?
            LDX    ERRNO                      ; Get Back Error Code
            LDA    #0                         ; Always Less Then 256
            TAY
            JSR    DECOUT                     ; Print The Code
            LDA    #Usrerr                    ; Print User Defined Message
STDERR      JSR    PRMSG
            JMP    CROUT                      ; And A CR

*===============================
*   Name: SHOWSTR - Print String
*
*  Input: None
*
* Output: None
*===============================

SHOWSTR     PULLW  PRN                        ; Save Calling Address
            PHXY
            JSR    INCPRN                     ; Get Next Byte
SHOWSTR2    LDA    (PRN)                      ; Get Data
            PHP
            JSR    COUTLO                     ; Show Char
            JSR    INCPRN
            PLP
            BPL    SHOWSTR2                   ; End, Nope, Loop

            PLXY
            JMP    (PRN)

*===============================
*   Name: PRMSG - Print Message From Index
*
*  Input: X - Message Number
*
* Output: None
*===============================

PRTEXT      TAY
            LDX    #PROGTEXT
            LDA    #PROGTEXT/256
            BRA    PRMSG0

PRMSG       TAY                               ; move into count
            LDX    #ERRMSGS                   ; set pointer
            LDA    #ERRMSGS/256
PRMSG0      STZ    SETSTDZP
            STZ    SETRAM1
            ST16   PRN
            DEY                               ; never a zero
PRMSG1      LDA    (PRN)                      ; get a char
            BEQ    PRMSG3
            INCD   PRN                        ; bump pointer
            ASL    A                          ; end of text?
            BCC    PRMSG1                     ; nope, loop
            DBPL   Y;PRMSG1                   ; yes, bump counter, loop

PRMSG2      LDA    (PRN)                      ; Get Data
            BEQ    PRMSG3
            PHP
            STZ    SETALTZP
            STZ    SETRAM2
            JSR    COUTLO                     ; Show Char
            STZ    SETSTDZP
            STZ    SETRAM1
            JSR    INCPRN
            PLP
            BPL    PRMSG2                     ; End, Nope, Loop

PRMSG3      STZ    SETALTZP
            STZ    SETRAM2
ERROR2      RTS

*===============================
*   Name: V_RDCHAR - Read Character From Screen
*
*  Input: None
*
* Output: None
*===============================

V_RDCHAR    PHX                               ; Save X
            JSR    VIDRDST                    ; X = Line To Read
            LDX    CH
            STY    CH                         ; Use Y As Offset
            JSR    VIDRDKY                    ; Get Data On Screen
            AND    #Clrhi
            CPGE   #' ';VREAD                 ; Convert Inverse

            ADC    #'@'                       ; Make Normal
VREAD       STX    CH
            PLX
            RTS

*===============================
*   Name: PUTCHR - Save Char In Buffer
*
*  Input: Character To Save
*
* Output: None
*===============================

PUTCHR      CPEQ   #clb;CLRBUF                ; Clear The Buffer?

            STZ    SETRAM1                    ; Switch In Subs
            JSR    PUTCHR2
            BRA    DRAM

*===============================
*   Name: CLRBUF - Clear Char Buffer
*
*  Input: None
*
* Output: None
*===============================

CLRBUF      STZ    TYPIN                      ; Zero Pointers
            STZ    TYPOUT
            RTS

*===============================
*   Name: GETCHR - Get Char From Buffer
*
*  Input: None
*
* Output: A - Character Read
*         A = 0: No Character
*===============================

GETCHR      LDA    #0                         ; Default To No Input
            STZ    SETRAM1                    ; Switch In Subs
            JSR    GETCHR2
            BRA    DRAM

*===============================
*   Name: SVLINE - Save Screen Line
*
*  Input: None
*
* Output: None
*===============================

SVLINE      STZ    SETRAM1
            JSR    SVLINE2
            BRA    DRAM

*===============================
*   Name: RSTLINE - Print Saved Screen Line
*
*  Input: None
*
* Output: None
*===============================

RSTLINE     STZ    SETRAM1
            JSR    RSTLINE2
DRAM        STZ    SETRAM2
            RTS

*===============================
*   Name: DO_EXEC - Set Exec Mode, Modem Output Off
*
*  Input: None
*
* Output: None
*===============================

DO_EXEC     LDA    #3
            JSR    VIDCHAT                    ; Show Exec On Message
            MOV    EXECFLG;OLDEXEC            ; Save Old Status
            MOV    REMOTE;OLDRMT
            MOV    #-1;EXECFLG                ; Set Exec Mode On
            LDA    #Moment1
            JSR    PRTEXT
            STZ    REMOTE                     ; Set To Local I/O Mode
            STZ    DOCHAT                     ; Reset Chat Flag
            STZ    INCHAT                     ; No Actually In Chat
            BRA    RSTLINE                    ; Restore Copy Of Line

EXEC2       LDA    #0                         ; Get Rid Of Exec Mode Flag
            JSR    VIDCHAT
            LDA    #ExecOut
            JSR    PRTEXT
            MOV    OLDEXEC;EXECFLG            ; Restore Exec State
            MOV    OLDRMT;REMOTE              ; Restore Remote State
            JSR    RSTLINE                    ; Put Back Extra
            TSTVS  DOCHAT;CHAT2               ; Check Chat Mode, do chat
            JMP    CHAT6                      ; Finish Up

*===============================
*   Name: DO_CHAT - Chat With User
*
*  Input: None
*
* Output: None
*===============================

DO_CHAT     BRNEW  TLEFT;CHAT1                ; Time Limit Saved?
            BREQW  TIMEON;CHAT1               ; Is There A Limit?

            JSR    SECON                      ; Get Time Used
            ST16   TLEFT
            SUB    TIMEON;TLEFT;TLEFT         ; set remaining time
CHAT1       JSR    SVLINE                     ; Save Current Line
            TSTVS  EXECFLG;EXEC2              ; exit exec mode
            TSTVS  DOCHAT;CHAT2
            JMP    DO_EXEC                    ; We Really Want Exec Mode

CHAT2       LDA    #SysopIn
            JSR    PRTEXT
            MOV    #%00110000;INPMODE         ; Accept Everything
            LDA    #2
            JSR    VIDCHAT                    ; Turn Off Chat Message
            STZ    DOCHAT                     ;reset chat
CHAT4       JSR    INPLN                      ; Get A Line Of Type
            TSTMI  LOGOFF;CHAT6
            TSTPL  DOCHAT;CHAT4               ; Exit?
            LDA    #SysopOut
            JSR    PRTEXT
            LDA    #0
            JSR    VIDCHAT                    ; Turn Off Chat Message
            JSR    RSTLINE                    ; Restore Line
            TSTVS  DOCHAT;CHAT6               ; Do They Want To Exec?
            JMP    DO_EXEC                    ; Yep

CHAT6       STZ    DOCHAT                     ; Clear Chat Flag
            STZ    INCHAT
            BREQW  TLEFT;CHATDONE             ; Any Time To Add In?
            BREQW  TIMEON;CHATDONE            ; How About A Limit?

            JSR    SECON                      ; Get Seconds On
            ST16   TIMEON                     ; Add In Time Remaining
            ADD    TLEFT;TIMEON;TIMEON
CHATDONE    STZ    TLEFT                      ; Flag Done With Hold
            STZ    TLEFT+1
            RTS

*===============================
*   Name: ZMDMOUT - Send Data To Modem Only
*
*  Input: Character To Send
*
* Output: None
*===============================

            DO     DEMOPGM
ZMDMOUT     RTS
            ELSE
ZMDMOUT     JSR    MDMOUT                     ; Send Data
            CPNE   #cr;ZMDM2                  ; Add LF To CR?

            LDA    #lf                        ; Send LF
            JSR    MDMOUT
            LDA    #cr                        ; Set Back To CR
ZMDM2       RTS
            FIN
            LST    OFF

