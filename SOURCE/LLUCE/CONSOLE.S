            LST    RTN
            TTL    'LLUCE - Console Driver'
            PAG
********************************
*                              *
*         Video Driver         *
*  ProTERM Special Emulation   *
*                              *
*    Written By: Andy Wells    *
*                              *
********************************
* Jump Table Entry Points
*-------------------------------

VIDRDKY     JMP    V_SCRNRD
VIDSTORE    JMP    V_SCRNWR
VIDCOUT     JMP    V_COUT
VIDSCRL     JMP    V_SCROLL
VIDBAN      JMP    V_BANNER
VIDLST      JMP    V_CLRLST
VIDRDST     JMP    V_SETLN
VIDPOS      JMP    V_POSN

VIDCHAT     LDEQX  WNDTOP;V_CHAT5            ; Screen Top Protected?

            PUSHX  INVFLG                    ; save current stats
            PUSHX  MOUSEFLG
            PUSHX  CH
            PUSHX  CV

            CPNE   #-1;USE_NUM
            LDA    LASTMSG
USE_NUM     STA    LASTMSG

            TAY
            STZ    SETSTDZP
            STZ    SETRAM1
            MOVD   #VIDMSGS;PRN              ; set pointer
            DBMI   Y;V_CHAT2
V_CHAT0     JSR    INCPRN                    ; skip position byte
V_CHAT1     LDEQ   (PRN);V_CHAT4             ; get a char
            JSR    INCPRN                    ; bump pointer
            ASL    A                         ; end of text?
            BCC    V_CHAT1                   ; nope, loop
            DBPL   Y;V_CHAT0                 ; yes, bump counter, loop

V_CHAT2     LDY    #0
            LDA    (PRN)
            TAX
            STZ    SETALTZP
            JSR    V_POSN
            STZ    SETSTDZP
            JSR    INCPRN

V_CHAT3     LDA    (PRN)                     ; Get Data
            BEQ    V_CHAT4
            PHP
            AND    #Clrhi
            STZ    SETALTZP
            JSR    V_COUT
            STZ    SETSTDZP
            JSR    INCPRN
            PLP
            BPL    V_CHAT3                   ; End, Nope, Loop

V_CHAT4     STZ    SETALTZP
            STZ    SETRAM2
            PLXY                             ; Restore Old Position
            JSR    V_POSN
            PULL   INVFLG                    ; And Inverse Flag
            PULL   MOUSEFLG
V_CHAT5     RTS

*-------------------------------
* Clear The Screen
*-------------------------------

V_CLEAR     JSR    V_HOME                    ; Move Cursor To Screen Top

*-------------------------------
* Clear From Cursor To End Of Screen
*-------------------------------

V_CLREOP    PUSHA  CV                        ; Save Cursor Vert
            PUSHA  CH                        ; And Horiz
            JSR    V_CLREOL                  ; Clear To End Of This Line
            STZ    CH                        ; Cursor To Left
            LDX    CV                        ; Go Down A Line
V_CPLUP     INX
            CPEQX  WNDBTM;V_CLRDN            ; At Bottom?

            JSR    V_SETLN                   ; Set New Lines Address
            LDA    #' '+Hibit                ; Fill It With Spaces
            JSR    V_FILL
            BRA    V_CPLUP                   ; Try Next Line

V_CLRDN     PULL   CH                        ; Put The Cursor Back
            PLA
V_GOLINE    STA    CV                        ; Go To Line In A
            TAX
V_SETLN     CPEQX  V_OLDCV;V_BCDONE          ; Go To Line In X, same line, no calc

            PHA                              ; Save The Char
            TXA                              ; Set This New Line
            STA    V_OLDCV
            PHA                              ; Apples BASCALC Routine
            LSR    A
            AND    #%00000011
            ORA    #%00000100
            STA    BASE+1
            PLA
            AND    #%00011000
            BCC    BASCALC2

            ADC    #$7F
BASCALC2    STA    BASE
            ASL    A
            ASL    A
            ORA    BASE
            STA    BASE
            PLA
V_BCDONE    RTS

*-------------------------------
* Goto (X,A)
*-------------------------------

V_POSN      STX    CH                        ; Do A Goto X,Y
            TYA
            BRA    V_GOLINE

*-------------------------------
* Clear From Cursor To End Of Line
*-------------------------------

V_CLREOL    LDX    CH                        ; Get Cursor Location
V_CLLOOP    LDA    #' '+Hibit                ; Space To Fill
            JSR    V_SCRNWR                  ; Stuff It
            INC    CH                        ; Bump Cursor To Right
            IFNE   CH;#vidWidth;V_CLLOOP     ; At Left Of Screen?

            STX    CH                        ; Put Cursor Back
            RTS

*-------------------------------
* Execute A TAB
*-------------------------------

V_TAB       INC    CH                        ; Move Cursor To Right
            IFEQ   CH;#vidWidth;V_CRLF       ; End Of Line?

            AND    #%00000111                ; 8 Spaces Per Tab
            BNE    V_TAB                     ; Another If Not Done

            RTS

*-------------------------------
* Do Carriage Return/Line Feed
*-------------------------------

V_CRLF      STZ    CH                        ; Cursor To Left Of Screen

*-------------------------------
* Do Line Feed Only
*-------------------------------

V_LF        LDA    CV                        ; Go Down One Line
            INC    A
            CPNE   WNDBTM;V_GOLINE           ; At Bottom Of Screen?

*-------------------------------
* Scroll The Screen Up 1 Line
*-------------------------------

V_SCROLL    LDX    WNDTOP                    ; Get Starting Line
            JMP    V_SCRLUP                  ; Scroll The Screen Up

*-------------------------------
* Move Up 1 Line
*-------------------------------

V_UP        IFEQ   CV;WNDTOP;V_RTS1          ; At Top Of Screen?
            DBRA   A;V_GOLINE                ; move up, do it

*-------------------------------
* Move Forward 1 Space
*-------------------------------

V_FWD       IFEQ   CH;#vidWidth-1;V_CRLF     ; At End Of Line?
            INC    CH                        ; Nope, Move Forward
V_RTS1      RTS

*-------------------------------
* Move Back 1 Space
*-------------------------------

V_BACK      LDNE   CH;V_BACKUP               ; At Start Of Line?
            JSR    V_EOL                     ; Go To End Of Line
            BRA    V_UP                      ; And Up One If Possible

V_BACKUP    DEC    CH                        ; Go Back One Space
            RTS

*-------------------------------
* Insert A Character
*-------------------------------

V_INSCHR    IFEQX  CH;#vidWidth-1;V_IC2      ; At End Of Line?

            MOVY   #vidWidth-2;CH            ; Starting At End Of Line
V_ICLOOP    JSR    V_SCRNRD
            INC    CH                        ; Stuff It In Space To Right
            JSR    V_SCRNWR
            DEY                              ; Go Left One Space
            STY    CH
            CPMIX  CH;V_ICLOOP               ; At Insertion Point?
            BEQ    V_ICLOOP                  ; Make Sure

V_IC2       STX    CH                        ; Put Us Where We Were
            LDA    #' '+Hibit                ; Put In A Space
            JMP    V_SCRNWR

*-------------------------------
* Delete Character At Cursor
*-------------------------------

V_DELCHR    IFEQX  CH;#vidWidth-1;V_DC2      ; At End Of Line?

V_DCLOOP    INC    CH                        ; Get Next Char
            JSR    V_SCRNRD
            DEC    CH                        ; Put It In Our Space
            JSR    V_SCRNWR
            INC    CH                        ; Go To Next Space
            IFNE   CH;#vidWidth-1;V_DCLOOP   ; at end of line?

V_DC2       LDA    #' '+Hibit                ; Space Out Last Char
            JSR    V_SCRNWR
            STX    CH                        ; Put Back Cursor
            RTS

*-------------------------------
* Delete Line At Cursor
*-------------------------------

V_DELLN     LDX    CV                        ; Get Our Line

*-------------------------------
* Scroll Rest Of Screen Up
*-------------------------------

V_SCRLUP    JSR    V_SETLN                   ; Set It Up
            MOVD   BASE;BASE2                ; Move Its Location
            INX                              ; Set Next Line
            JSR    V_SETLN
            JSR    V_MVLINE                  ; Move The Line Base>Base2
            TXA
            TAY
            INY
            CPNEY  WNDBTM;V_SCRLUP           ; At End Of Screen?

*-------------------------------
* Clear Bottom Line Of Screen
*-------------------------------

V_CLRLST    LDX    WNDBTM                    ; Go To Bottom Line
            DEX
V_CLRX      LDA    #' '+Hibit                ; Filling It With Spaces

*-------------------------------
* Fill Line With Character In A
*-------------------------------

V_SHOW80    PHA
            JSR    V_SETLN                   ; Set Our Lines Location
            PLA
V_FILL      LDY    #vidWidth/2-1             ; 40 Chars * 2
V_FLOOP     STA    HISCR
            STA    (BASE),Y                  ; Stuff It On Page 1
            STA    LOWSCR
            STA    (BASE),Y                  ; And On Page 2
            DBPL   Y;V_FLOOP                 ; Finish It Off

            RTS

*-------------------------------
* Insert A Line At Cursor
*-------------------------------

V_INSLN     LDX    WNDBTM                    ; Start At Bottom Of Screen
            DEX
V_ILLOOP    JSR    V_SETLN                   ; Get Lines Location
            MOVD   BASE;BASE2                ; Put It In Tos Vector
            DEX                              ; Next Line Up
            JSR    V_SETLN
            JSR    V_MVLINE                  ; Move The Line
            CPNEX  CV;V_ILLOOP               ; At Cursors Line?
            BRA    V_CLRX                    ; Clear Cursors Line

*-------------------------------
* Process A Character
*-------------------------------

V_COUT      TSTMI  V_MODE;V_COUT1            ; Processing A Command?
            CPMI   #0;V_NULL                 ; high bit set?, ignore it

V_COUT1     SVXAY                            ; Save All Registers
            STY    VID_Y                     ; Need This Later
            JSR    V_SETCV                   ; Set Our Line
            JSR    V_COUT2                   ; Process The Char
            JSR    V_SETCV                   ; Reset The Line Again
            RSTXAY                           ; Get Back All Registers
V_NULL      RTS

*-------------------------------
* Handle All Characters
*-------------------------------

V_COUT2     TSTMI  V_MODE;V_SPCL             ; Processing A Command?

            CPGE   #' ';V_NORM               ; ctrl char, no, on scrn

            ASL    A                         ; Go To The Routine
            TAX
            JMP    (V_ADRS,X)

V_NORM      TSTMI  INVFLG;V_SETN             ; Are We In Normal Mode?
            TSTMI  MOUSEFLG;V_SETM           ; Mouse Text Mode?

            CPLT   #'@';V_PUTCHR             ; Put Char In Inverse Range
            CPGE   #'_'+1;V_PUTCHR

            AND    #%00111111
            BPL    V_PUTCHR

V_SETM      CPLT   #'@';V_SETN               ; Upper Case Range?
            CPLT   #'_'+1;V_PUTCHR

V_SETN      ORA    #Hibit
V_PUTCHR    LDY    VID_Y                     ; Needed This From Before
            JSR    V_SCRNWR                  ; Stuff The Char
            JMP    V_FWD                     ; And Go Forward

*-------------------------------
* Set Vertical Position
*-------------------------------

V_SETCV     LDX    CV                        ; Set Vertical Line
            JMP    V_SETLN

*-------------------------------
* Set Special Function Mode
*-------------------------------

V_SPCL      PHA                              ; Keep That Data
            LDA    V_MODE                    ; Get Parm Position
            EOR    #-1                       ; Make It Into Index
            TAX
            PULL   V_DATA,X                  ; Save It
            IBPL   V_MODE;V_SPCL1            ; Parms All Done, Execute

            RTS

V_SPCL1     LDX    V_CALL                    ; Whats Our Call Type?
            DBEQ   X;V_RPT                   ; Character Repeat?
            DBEQ   X;V_GOXY                  ; how about gotoxy?

            LDA    V_DATA+2                  ; Nope, Has To Be Tone
            ASL    A                         ; Create Tone Data
            TAX
            LDA    V_DATA+1
            ASL    A
            TAY
            LDA    V_DATA                    ; Pure Tone?
            ASL    A
            CPEQY  #2;V_PURE                 ; do it pure

            STXY   V_TEMP+1                  ; Grabbed From ProTERM
            LSR    A
            STA    V_TEMP
            MOV    V_TEMP+2;V_TEMP+4
TN_LUP1     MOV    V_TEMP+1;V_TEMP+3
            BIT    SPKR
TN_LUP2     DBNE   X;DTONE3
            DBMI   V_TEMP;ENDTONE

DTONE3      BIT    LOWSPEED
            BIT    LOWSPEED
            DBEQ   V_TEMP+3;TN_LUP1

            BIT    LOWSPEED
            BIT    LOWSPEED
            DBNE   V_TEMP+4;TN_LUP2

            MOV    V_TEMP+2;V_TEMP+4
            TSTRA  SPKR;TN_LUP2

V_PURE      STX    V_TEMP+1                  ; Also Grabbed From ProTERM
            PHY                              ; So Tones Are Same
V_PLOOP     DBNE   X;V_PURE2

            LDX    V_TEMP+1
            BIT    SPKR
V_PURE2     BIT    LOWSPEED
            DBNE   Y;V_PLOOP
            DBNE   A;V_PLOOP

            PLY
ENDTONE     RTS

*-------------------------------
* Execute A Gotoxy Function
*-------------------------------

V_GOXY      SEC                              ; Convert Line Data
            LDA    V_DATA
            SBC    #goxyOffs                 ; Subtract User Offset
            CPGE   #vidHeight;V_NOOP

            TAY                              ; Goes In Y
            SEC                              ; Horiz Data
            LDA    V_DATA+1
            SBC    #goxyOffs                 ; Subtract User Offset
            CPGE   #vidWidth;V_NOOP

            TAX                              ; Goes In X
            JMP    V_POSN                    ; Go There

*-------------------------------
* Execute Character Repeat Function
*-------------------------------

V_RPT       LDMI   V_DATA+1;V_NOOP           ; Get Char To Repeat
V_RPT2      JSR    V_COUT                    ; Send The Char
            DBNE   V_DATA;V_RPT2             ; Decrement Count
V_NOOP      RTS

*-------------------------------
* Scroll Bottom Line Of Screen
*-------------------------------

V_BANNER    PHAX
            LDX    #0
            STA    LOWSCR
BAN_LOOP    MOV    LINE24+2,X;HISCR
            STA    LINE24+2,X
            MOV    LINE24+3,X;LOWSCR
            STA    LINE24+2,X
            INX
            CPNEX  #vidWidth/2-2;BAN_LOOP

            PLAX
            STA    LINE24+39
            RTS

*-------------------------------
* Move Cursor To Upper Right
*-------------------------------

V_HOME      LDA    WNDTOP                    ; Go To Top Of Screen
            JSR    V_GOLINE

*-------------------------------
* Move Cursor To Screen Right
*-------------------------------

V_CRONLY    STZ    CH                        ; And To Left
            RTS

*-------------------------------
* Set Normal Mode
*-------------------------------

V_NORMAL    LDA    #-1                       ; Set Normal Mode
            LDRAX  #Clrhi;SETV_MD

*-------------------------------
* Set Mousetext Mode
*-------------------------------

V_MOUSE     LDX    #-1                       ; Set Mousetext Mode
            SKIP2

*-------------------------------
* Set Inverse Mode
*-------------------------------

V_INVRSE    LDX    #Clrhi                    ; Set Inverse Mode
            LDA    #Clrhi
SETV_MD     STA    INVFLG
            STX    MOUSEFLG
            RTS

*-------------------------------
* Read A Character From Screen
*-------------------------------

V_SCRNRD    CLC                              ; Reading
            SKIPCS

*-------------------------------
* Write A Character To Screen
*-------------------------------

V_SCRNWR    SEC                              ; Writing
            PHY                              ; Save Y
            PHP                              ; Save Call Type
            PHA                              ; And The Char For Write
            LDA    CH                        ; Which Screen?
            LSR    A
            TAY
            STA    HISCR                     ; Anticipate Page 2
            BCC    V_SCWR1                   ; It Is, Leave It On

            STA    LOWSCR                    ; Nope, Page 1
V_SCWR1     PLA                              ; Get Our Char Back
            PLP                              ; Is It A Write Call?
            BCC    V_SCWR2                   ; Nope, Its Read

            STA    (BASE),Y                  ; Put The Char On The Screen
            BCS    V_SCWR3                   ; Always Does This

V_SCWR2     LDA    (BASE),Y                  ; Get The Char From Screen
V_SCWR3     STA    LOWSCR                    ; Back To Page 1
            PLY                              ; Get Y Back
            RTS

*-------------------------------
* Move Cursor To End Of Line
*-------------------------------

V_EOL       MOV    #vidWidth-1;CH            ; Force To End Of Line
            RTS

*-------------------------------
* Setup For Tone Command
*-------------------------------

V_TONE      LDA    #-3                       ; 3 Parameters
            LDRAX  #3;V_SETMD                ; Tone Call

*-------------------------------
* Setup For Gotoxy Command
*-------------------------------

V_GOTOXY    LDX    #2                        ; Gotoxy Call
            SKIP2

*-------------------------------
* Setup For Repeat Command
*-------------------------------

V_REPEAT    LDX    #1                        ; Repeat Call
            LDA    #-2                       ; 2 Parameters
V_SETMD     STA    V_MODE
            STX    V_CALL
            RTS

*-------------------------------
* Do Standard Apple Beep
*-------------------------------

V_BELL      LDY    #$C0                      ; Standard Bell Routine
V_BLLOOP    LDA    #12
            JSR    WAIT
            LDA    SPKR
            DBNE   Y;V_BLLOOP
            RTS

*-------------------------------
* Move A Line From BASE To BASE2
*-------------------------------

V_MVLINE    LDY    #vidWidth/2-1             ; Move Line Base -> Base2
V_MLLOOP    STA    HISCR
            MOV    (BASE),Y;(BASE2),Y
            STA    LOWSCR
            MOV    (BASE),Y;(BASE2),Y
            DBPL   Y;V_MLLOOP

            RTS

*-------------------------------
* Command Character Translate Table
*-------------------------------

V_NEWCHR    DB     homeChar                  ; 80 Home Command
            DB     csrup                     ; 81 Cursor up
            DB     csrdwn                    ; 82 Cursor down
            DB     csrback                   ; 83 Cursor left
            DB     csrfwd                    ; 84 Cursor right
            DB     clreos                    ; 85 Clear to EOS
            DB     0                         ; 86 Clear to BOS
            DB     clrscn                    ; 87 Clear screen
            DB     clreol                    ; 88 Clear to EOL
            DB     0                         ; 89 Clear to BOL
            DB     0                         ; 8A Clear line
            DB     insline                   ; 8B insert line
            DB     delline                   ; 8C Delete line
            DB     inschar                   ; 8D Insert char
            DB     delchar                   ; 8E Delete char
            DB     norm                      ; 8F Normal Command
            DB     inv                       ; 90 Inverse Command
            DB     goxy                      ; 91 GotoXY Command
            DB     realmous                  ; 92 Real Mouse Character
            DB     Tonecmd                   ; 93 ProTERM Tone Command
EndPTSE     DB     0                         ; 94 Null command

*-------------------------------
* Control Character Subroutines
*-------------------------------

V_ADRS      DA     V_NULL                    ; 00 Not Used
            DA     V_CRONLY                  ; 01 Carriage Return Only
            DA     V_EOL                     ; 02 Cursor To End Of Line
            DA     V_NULL                    ; 03 Not Used
            DA     V_DELCHR                  ; 04 Delete Character
            DA     V_NULL                    ; 05 Not Used Here
            DA     V_INSCHR                  ; 06 Insert Character
            DA     V_BELL                    ; 07 Standard Beep
            DA     V_BACK                    ; 08 Backup One Character
            DA     V_TAB                     ; 09 Execute A Tab
            DA     V_LF                      ; 0A Execute A Line Feed
            DA     V_UP                      ; 0B Move Cursor Up 1 Line
            DA     V_CLEAR                   ; 0C Home And Clear Screen
            DA     V_CRLF                    ; 0D Do CR/LF
            DA     V_NORMAL                  ; 0E Set Normal Mode
            DA     V_INVRSE                  ; 0F Set Inverse Mode
            DA     V_MOUSE                   ; 10 Set Mousetext Mode
            DA     V_NULL                    ; 11 Not Used Here
            DA     V_REPEAT                  ; 12 Repeat Character
            DA     V_NULL                    ; 13 Not Used Here
            DA     V_TONE                    ; 14 Execute A Tone
            DA     V_FWD                     ; 15 Move Forward
            DA     V_INSLN                   ; 16 Insert A Line
            DA     V_CLREOP                  ; 17 Clear To End Of Screen
            DA     V_HOME                    ; 18 Cursor To Upper Right
            DA     V_CLREOL                  ; 19 Clear To End Of Line
            DA     V_DELLN                   ; 1A Delete Current Line
            DA     V_NULL                    ; 1B Not Used
            DA     V_NULL                    ; 1C Not Used
            DA     V_NULL                    ; 1D Not Used
            DA     V_GOTOXY                  ; 1E Gotoxy Command
            DA     V_NULL                    ; 1F Not Used

LASTMSG     DB     0

            LST    OFF

