            LST     RTN
            TTL     'EDITOR - Subroutines'
            PAG
********************************
*                              *
*      Editor Subroutines      *
*                              *
********************************
* Easy Dispatch Routine [Must Save Y]
*===============================

MATCH       STA     SAVE_X                    ; Save Match Char
            STY     SAVE_Y
            PULLW   TEMP3                     ; Get Address Of Data-1
            LDY     #1
MATCH2      LDEQ    (TEMP3),Y;MATCH4
            CPEQ    SAVE_X;MATCH3

            INY
            INY                               ; Y = Y + 3
            IBNE    Y;MATCH2                  ; Loop

MATCH3      INY
            LDA     (TEMP3),Y
            TAX
            INY
            LDNE    (TEMP3),Y;MATCH5          ; Do It CHANGE TO BRA LATER

MATCH4      INY                               ; Increase Count
            TYA
            CLC
            ADC     TEMP3                     ; Add In Offset
            TAX
            LDA     #0
            ADC     TEMP3+1
MATCH5      ST16    TEMP3                     ; Save Address

            LDY     SAVE_Y
            LDA     SAVE_X
            JMP     (TEMP3)                   ; Return To Caller

*===============================
* Center A Line Of Text
*===============================

CENTER      LDX     #0                        ; Start Index's
            LDY     #-1
CENTER2     INY
            CPEQY   TEMP2;CENTER5

            IFEQ    (TEMP),Y;#' ';CENTER2     ; kill lead spaces

CENTER3     MOV     (TEMP),Y;LNBUF+128,X      ; Get Data
            INX
            INY
            CPEQ    #' ';CENTER4

            STX     TEMP2+1                   ; Update Length
CENTER4     CPNEY   TEMP2;CENTER3             ; Are We Done?

            SEC
            LDA     VIDLEN                    ; Find Out How Many
            SBC     TEMP2+1                   ; Spaces To Add
            LSR     A
CENTER5     PHP
            LDY     #0                        ; Go To Beginning Of Line
            PLP
            SEC
            BEQ     CENTER8                   ; Opps, Don't Add Any

            TAX
            CLC
            ADA     TEMP2+1;TEMP2+1           ; Get New Total Length
            LDA     #' '
CENTER6     STA     (TEMP),Y                  ; Add In Leading Spaces
            INY
            DBNE    X;CENTER6

CENTER7     MOV     LNBUF+128,X;(TEMP),Y      ; Copy Data Back
            INX
            INY
            CPNEY   TEMP2+1;CENTER7           ; Done Yet?

            CLC
CENTER8     RTS

*-------------------------------
* Print Small Help File
*-------------------------------

DOT_HLP     JSR     SHOWSTR                   ; List Dot Commands
            DB      cr
            ASC     'Legal (.) Dot Commands:'0D0D
            ASC     '.A = Abort  '
            ASC     '.H = Help  '
            ASC     '.Dx-Y = Delete'0D
            ASC     '.N = New    '
            ASC     '.O = Ok    '
            ASC     '.Ex   = Edit'0D
            ASC     '.Z = Space  '
            ASC     '.S = Save  '
            ASC     '.Ix   = Insert'0D
            ASC     '.P = Prompt            '
            ASC     '.Lx-Y = List'0D8D
            RTS

*-------------------------------
* Input A Command
*-------------------------------

GETCMD      MOV     #%10000000;INPMODE        ; Set Upper, No Blank Lines
            JSR     INPLN                     ; Get Input
            MOV     #%10100000;INPMODE        ; Upper, Blanks Are Ok
            LDA     LNBUF
            TSTPL   LOGOFF;GETCMD2            ; Any Problems?
            JMP     ED_EX                     ; Quit Editor

GETCMD2     RTS

*-------------------------------
* Find A Line Number
*-------------------------------

FINDLN      ST16    TEMP2                     ; Save Line Number
            MOVD    EDLOC;TEMP                ; Point To Editor
            LDY     #0
FINDLN2     DECD    TEMP2                     ; Count Down Lines
            DEC     A                         ; BUG FIX: 11/18/92
            ORA     TEMP2+1                   ; Are We Done?
            BNE     FINDLN4                   ; Nope

            LD16    TEMP                      ; Get Address Of Line
            RTS

FINDLN4     LDA     (TEMP),Y                  ; Get Byte
            INCD    TEMP
            CPNE    #cr;FINDLN4               ; Done Searching?
            BRA     FINDLN2                   ; Yep

*===============================
* Get Length Of Line
*===============================

FNDLEN      LDY     #-1
FNDLEN2     INY
            IFNE    (TEMP),Y;#cr;FNDLEN2      ; count line length

            TYA
            CLC                               ; No Match
            RTS

*===============================
* Compare Data With String
*===============================

CMPSTR      LDY     #0                        ; Start At Byte 0
CMPSTR2     LDA     (TEMP),Y
            INY
            JSR     CONV                      ; Make Into Upper
            EOR     QTEXT,X                   ; Check Against Exit Text
            INX
            ASL     A
            BNE     CMPSTR3                   ; Opps, No Match
            BCC     CMPSTR2                   ; Keep Checking

            SKIPCC
CMPSTR3     CLC
            RTS

*===============================
* Handle Single Argument
*===============================

XARG        BREQW   EDLINE;XYCLR              ; Is There Data?

            JSR     CHKLAST
            MOVD    ARGPTR;TEMP3              ; Set Up Pointers
            JSR     NUMIN
            ST16    X_ARG
            JMP     CHKRNG                    ; Get Legality

XYCLR       SEC
            RTS

*===============================
* Handle Arguments
*===============================

XYARG       MOVD    #1;X_ARG                  ; Init First Pointer To 1
            JSR     CHKLAST
            MOVD    EDLINE;Y_ARG              ; Init Ptr 2 To Last Line
            ORA     Y_ARG                     ; Check For No Data
            BEQ     XYCLR                     ; Opps, Problem

            MOVD    ARGPTR;TEMP3              ; Point To Data
            LDY     #0
            IFEQ    (TEMP3),Y;#cr;XYARG6      ; blank line?
            CPEQ    #',';XYARG2               ; Check Separator
            CPEQ    #'-';XYARG2
            JSR     NUMIN                     ; Get First Number
            ST16    X_ARG
            ST16    Y_ARG
            JSR     CHKRNG
            BCS     XYARG5                    ; Opps, Out Of Range

            LDY     #0
            IFEQ    (TEMP3),Y;#',';XYARG2     ; more?
            CPNE    #'-';XYARG4

XYARG2      INCD    TEMP3                     ; Increment Temp3
            MOVD    EDLINE;Y_ARG              ; Save Ending Editor Line
            LDY     #0
            IFEQ    (TEMP3),Y;#cr;XYARG4      ; x- format?

            JSR     NUMIN
            ST16    Y_ARG                     ; Save Second Number
            JSR     CHKRNG
            BCS     XYARG5

            IFLT    X_ARG+1;Y_ARG+1;XYARG4    ; check high
            IFGE    Y_ARG;X_ARG;XYARG4        ; if >=, ok

            SEC
            SKIPCC                            ; Skip The CLC With A BCC
XYARG4      CLC
XYARG5      LDA     #1                        ; Not Just A Return
            RTS

XYARG6      CLC
            LDA     #0                        ; Just A Return
            RTS

*===============================
* Make Sure Line Number Is In Range
*===============================

CHKRNG      STX     SAVE_X                    ; Save Data
            STA     SAVE_Y
            ORA     SAVE_X                    ; Is There A Number?
            BEQ     CHKRNG2                   ; Nope, It's 0

            IFLT    EDLINE+1;SAVE_Y;CHKRNG2   ; its out of range
            IFLTX   EDLINE;SAVE_X;CHKRNG2     ; its out of range

            LDA     #1                        ; Clear Return Flag
            CLC                               ; All's Well
            SKIPCS
CHKRNG2     SEC                               ; Opps, Out Of Range
            RTS

*===============================
* Check For 'last Line' Reference
*===============================

CHKLAST     TSTPL   EXE_DOT;CHKRNG2           ; Execing Dot Command?

            LDY     #0
            LDA     (ARGPTR),Y                ; Get Byte
            JSR     CONV
            CPNE    #'L';CHKRNG2              ; No Match, Return

            PLA
            PLA
            LD16    EDLINE
            ST16    X_ARG
            ST16    Y_ARG
            BRA     CHKRNG                    ; Make Sure Line Is Legal

*===============================
* Move Up Xarg Pointer And See If We're Done
*===============================

INCXARG     IFNE    X_ARG;Y_ARG;INCXARG2
            IFNE    X_ARG+1;Y_ARG+1;INCXARG2

            SEC                               ; We're Done
            RTS

INCXARG2    CLC
            INCD    X_ARG                     ; Move Counter
INCXARG3    RTS

*===============================
* Show Last 3 Lines
*===============================

SHWLAST     MOVD    EDLINE;Y_ARG              ; Point To Last Line
            ORA     Y_ARG
            BEQ     INCXARG3                  ; No Data

            SEC
            SB      Y_ARG;#2;X_ARG            ; Get X Line Number
            TAX
            SB      Y_ARG+1;#0;X_ARG+1
            JSR     CHKRNG                    ; Is It Ok?
            BCC     SHWLAST2                  ; Yep

            MOVX    #1;X_ARG                  ; start at line 1
            DEX
            STX     X_ARG+1
SHWLAST2    JMP     ED_SHLN                   ; Show Last 3 Lines...

*===============================
* Delete Y Bytes Of Text
*===============================

DEL_TXT     ST16    TEMP3                     ; save pointer
DEL_TX2     STY     SAVE_Y                    ; Save # Chars To Kill
            PUSHW   TEMP3                     ; save old pointer
DEL_TX3     LDY     SAVE_Y
            MOV     (TEMP3),Y;(TEMP3)         ; Get Char
            INCD    TEMP3                     ; Increment Temp3
            CPNE    #0;DEL_TX3                ; Loop Until End Of Editor

            PULLW   TEMP3                     ; Restore Old Pointer
DEL_TX5     RTS

*===============================
* Insert Y Bytes Of Text
*===============================

INS_TXT     ST16    TEMP3                     ; save pointer
INS_TX2     STY     SAVE_Y                    ; Save # Chars To Insert
            LDA     (TEMP3)                   ; Flag Last Char
            ORA     #Hibit
            STA     (TEMP3)
INS_TX3     LDEQ    (TEMP3);INS_TX4           ; At End Of Data?
            INCD    TEMP3
            BRA     INS_TX3

INS_TX4     PUSHA   (TEMP3)                   ; Get Byte
            LDY     SAVE_Y
            AND     #Clrhi
            STA     (TEMP3),Y                 ; Move It
            PLA
            BMI     DEL_TX5

            DECD    TEMP3
            BRA     INS_TX4

*===============================
* Find End Of Editor
*===============================

FINDEND     MOVD    EDLOC;EDPTR               ; Point To Start Of Editor
            MOVY    #0;EDLINE                 ; Zero Line Counter
            STY     EDLINE+1
FINDEND2    LDEQ    (EDPTR),Y;FINDEND4        ; We Done?
            CPNE    #cr;FINDEND3              ; Is It End Of Line?
            INCD    EDLINE                    ; Inc Number Of Lines
FINDEND3    INCD    EDPTR
            BRA     FINDEND2                  ; Search Through

FINDEND4    RTS

*===============================
* Print A Backspace
*===============================

PRBS        TSTMI   NONBS;PRNONBS             ; Is It A Destructible Bs?
            JSR     BSOUT                     ; Print Bs
            JSR     SPCOUT
PRNONBS     JMP     BSOUT                     ; Do Non-Destructive Bs

*===============================
* Show The Line Number
*===============================

SHOWLN      LD16    X_ARG                     ; print line number
            LDY     #0
            JSR     DECOUT0
            JSR     PMTOUT                    ; Show Prompt
            BRA     PRCRLF                    ; Add A Return

*===============================
* Check And See If They Want To List
*===============================

CHKLIST     LDA     LNBUF                     ; Get Input
            JSR     CONV                      ; Make Upper
            CMP     #'L'
            CLC
            BNE     CHKLIST2                  ; They Don't Want To List

            JSR     SHOWSTR
            DB      cr
            DCI     'List Line (X-Y) -> '
            JSR     INPLN                     ; Read Input
            MOV     #-1;SHWLN                 ; Show Line Numbers
            JSR     ED_LST1                   ; Do List
            SEC                               ; Show We Did List
CHKLIST2    RTS

*===============================
* Continue Message
*===============================

CONT        JSR     SHOWSTR
            DB      cr
            ASC     'Continue Message Now...'0D8D
            MOV     #0;SHWLN                  ; Don't Show Line Numbers
            JSR     SHWLAST                   ; Show Last 3 Lines
            JMP     FINDEND                   ; Reset Pointers

*-------------------------------
* Convert Lower To Upper And Clear High Bit
*-------------------------------

CONV        AND     #Clrhi                    ; Strip High Bit
            CPLT    #'a';CONV2
            CPGE    #'z'+1;CONV2
            SBC     #$1F                      ; Since Carry Is Clear, -$20
CONV2       RTS

PRCRIF      TSTPL   EXE_DOT;CHKLIST2          ; dont do it

PRCRLF      LDA     #cr                       ; Print Return
            SKIP2
BSOUT       LDA     #bs
            SKIP2
SPCOUT      LDA     #' '
            SKIP2
PMTOUT      LDA     #'>'
COUTLO      AND     #Clrhi
            JMP     COUT

*===============================
* Convert Number In LNBUF To Hex
*===============================

NUMIN       ZERO24  NUM
            LDY     #0
NUMIN2      LDA     (TEMP3),Y
            AND     #Clrhi
            CPLT    #'0';NUMIN4
            CPGE    #'9'+1;NUMIN4
            AND     #$F
            STA     NUM+3
            MOV     #0;NUM+4
            STA     NUM+5
            LDX     #10
NUMIN3      ADD     NUM;NUM+3;NUM+3
            AD      NUM+2;NUM+5;NUM+5
            DBNE    X;NUMIN3

            MOV24   NUM+3;NUM
            INCD    TEMP3                     ; CHANGE TO INCD LATER
            BRA     NUMIN2

NUMIN4      LD24    NUM
            RTS

*-------------------------------
* End Of Message Commands
*-------------------------------

QTEXT       DCI     'DONE'
            DCI     '/EX'

CODEEND     =       *

CMD_CHR     DB      0
HACK_Q      DB      0

