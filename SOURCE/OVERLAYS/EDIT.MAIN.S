            LST    RTN
            TTL    'EDITOR - Main Line Code'
            PAG
********************************
*                              *
*       Editor Main            *
*                              *
********************************
            DATE
*-------------------------------

EDITOR      JMP    DO_EDIT                    ; Skip Version Number
            DW     Version

DO_EDIT     STZ    EDMEMORY
            PHA
            MOVD   #EDBUF;EDLOC
            MOVD   #EDBUF+EBUFEND;EDITLEN
            PLA
            CPEQ   #Chain;ED_STX              ; Is It End Of Statement
            CPEQ   #Chain2;ED_STX             ; Is It End Of Line?

            JSR    GETBYT
            CPEQ   #Size;ED_SPC
            CPEQ   #Onerr;Q_HACK

            LDX    #Syntax
            JMP    BADERR

*===============================
* Entering The Editor
*===============================

ED_STX      TSX
            STX    EDSTACK                    ; Save Stack
            TXA
            SBC    #$20                       ; Move Stack 32 Levels Down
            TAX
            TXS
            MOV    #0;PROMPT                  ; Turn Off Prompts
            STA    EXE_DOT                    ; Enable Dot Commands
            STA    INTBUF                     ; Don't Allow Int's
            STA    INTOUT                     ; Make Sure Output Is On
            LDY    #0                         ; Output To Console/Modem
            JSR    SETOVEC
            JSR    FINDEND                    ; Setup End Pointers
            MOVD   EDLOC;PRN
            LDY    #0
            LDEQ   (PRN),Y;ED_LNCR            ; Check Contents Of Buffer
            BRA    ED_CMD                     ; Handle Command Line

*===============================
* Return Bytes In Editor
*===============================

ED_SPC      JSR    GET_SPC
DO_MATH2    LDY    #0
            ST24   DATA+1                     ; Save Result
            PHA
            MOV    #1;DATA                    ; Set Data Type 1
            PLA
            RTS

GET_SPC     JSR    FINDEND
            SEC
            LDA    EDPTR
            SBC    EDLOC                      ; Length = End - Start
            TAX
            LDA    EDPTR+1
            SBC    EDLOC+1
            RTS

Q_HACK      LDX    HACK_Q
            LDRA   #0;DO_MATH2

ED_LNCR     JSR    PRCRLF                     ; Add A Line Feed
ED_LN       MOV    WWFLAG;WWRAP               ; Get Word-Wrap Status
ED_LN0      LD16   EDPTR                      ; get a line of text
            JSR    GETEDLN
            ST16   EDPTR                      ; Save New End Address
            LDNE   WWEXTRA;ED_LN1

            LDA    #0                         ; Add In End Of Editor
            TAY
            STA    (EDPTR),Y
            BCS    ED_CMD                     ; If They Typed 'done'

ED_LN1      INCD   EDLINE                     ; Add Line To Editor
            SEC
            LDA    EDPTR+1                    ; Check For 3.75K
            SBC    EDITLEN+1
            BNE    ED_LN                      ; There Is Plenty

            STZ    WWRAP                      ; Turn Off Word-Wrap
            LDNE   WWEXTRA;ED_LN0             ; Is There Word-Wrap Data?

            JSR    SHOWSTR
            DB     cr
            ASC    'That Is 4K Worth'8D
ED_CMD      MOVD   #LNBUF;ARGPTR              ; Point To Line Buffer
            JSR    SHOWSTR
            DB     cr
            DCI    'Editing (?=Help) -> '
            JSR    ED_CMD2
            BRA    ED_CMD

ED_CMD2     JSR    GETCMD
            JSR    MATCH
            CHR    -1;ED_EX
            CHR    '?';ED_HLP
            CHR    'A';ED_ABT
            CHR    'C';ED_CONT
            CHR    'D';ED_DEL
            CHR    'E';ED_ED
            CHR    'H';ED_HLP2
            CHR    'I';ED_INS
            CHR    'L';ED_LST
            CHR    'N';ED_NEW
            CHR    'O';ED_OK
            CHR    'S';ED_OK
            CHR    'Z';ED_SIZE
            DB     0
            TSTPL  EXECFLG;ED_CMD3            ; Check For Sysop

            JSR    MATCH                      ; Check The Rest
            CHR    'R';ED_RD
            CHR    'W';ED_WRT
            DB     0
ED_CMD3     JSR    SHOWSTR
            DB     cr
            ASC    'Illegal Command'8D
            RTS

ED_HLP      JSR    SHOWSTR
            DB     cr
            ASC    'A)bort, C)ontinue, D)elete, E)dit'0D
            ASC    'H)elp, I)nsert, L)ist, N)ew, S)ave'0D
            ASC    'Z) Space Used'8D
            RTS

ED_HLP2     JSR    PD_GPFX                    ; Get Current Prefix
            LDY    FLNAME                     ; Save Prefix For Later
ED_HLP3     MOV    FLNAME,Y;LNBUF+$C0,Y
            DBPL   Y;ED_HLP3

            JSR    LOGSYS                     ; Set To System Prefix
            LDY    HLPFILE
ED_HLP4     MOV    HLPFILE,Y;FLNAME,Y
            DBPL   Y;ED_HLP4

            LDA    #%00100001                 ; Request Read, Deny Write
            JSR    IFOPEN                     ; Open Into An Unused Channel
            BCS    ED_HLP9

            JSR    DO_SED                     ; Make Spacebar Work
ED_HLP5     JSR    PD_RDBYT                   ; Get Data
            BCS    ED_HLP6                    ; End Of Data

            AND    #Clrhi
            JSR    COUT                       ; Show Data
            BIT    INTOUT                     ; Did They Interrupt?
            BPL    ED_HLP5                    ; Nope

            INC    INTOUT                     ; Re-Enable Output
ED_HLP6     INC    INTBUF
            JSR    PD_CLOSE                   ; Close File

ED_HLP7     LDY    LNBUF+$C0                  ; Reset Old Prefix
ED_HLP8     MOV    LNBUF+$C0,Y;FLNAME,Y
            DBPL   Y;ED_HLP8

            JMP    PD_SPFX

ED_HLP9     JSR    ED_HLP7
            JSR    SHOWSTR
            DB     cr
            ASC    'Error: '
            ASC    'Help File Could Not Be Opened'8D
            RTS

HLPFILE     STR    'system/Hlp.Edit'

ED_ABT      JSR    SHOWSTR
            DB     cr
            DCI    'Abort: Are You Sure? -> '
            JSR    GETCMD
            CPNE   #'Y';ED_RTS1

            JSR    ED_CLR                     ; Clear Editor
            JSR    SHOWSTR
            DB     cr
            ASC    'Aborted'8D
            JMP    ED_EX                      ; Return

ED_CONT     SEC
            LDA    EDPTR+1                    ; Enough Space?
            SBC    EDITLEN+1
            BEQ    ED_CON1                    ; Yep

            JSR    CONT                       ; Continue...
            PLA
            PLA
            JMP    ED_LN                      ; Get More Stuff

ED_CON1     JSR    SHOWSTR
            DB     cr
            ASC    'That Is 4K Worth'8D
            JMP    ED_EX                      ; Return

ED_RTS1     RTS

ED_DEL      JSR    SHOWSTR
            DB     cr
            DCI    'Delete Line (L,x-y) -> '
            JSR    INPLN
            JSR    CHKLIST                    ; Do List?
            BCS    ED_DEL                     ; Yes We Did

DOT_DEL     JSR    XYARG                      ; Get Arg's
            BEQ    ED_RTS1
            BCS    ED_ERR

            LD16   X_ARG                      ; Get Line Number
            JSR    FINDLN                     ; Find The Line
ED_DEL2     JSR    FNDLEN                     ; Get The Length
            TAY
            INY                               ; Kill CR
            LD16   TEMP
            JSR    DEL_TXT                    ; Delete The Line
            DECD   EDLINE                     ; Decrease Line Count
            JSR    INCXARG
            BCC    ED_DEL2                    ; Loop Until Done

CR_RET2     RTS

ED_ERR      JMP    CR_ERR                     ; Link To Error Routine

ED_ED       JSR    SHOWSTR
            DB     cr
            DCI    'Edit Line (L,x) -> '
            JSR    INPLN
            JSR    CHKLIST                    ; Do A List?
            BCS    ED_ED                      ; We Did

DOT_ED      JSR    XARG                       ; Get Line Number
            BEQ    CR_RET2                    ; Just A Return
            BCS    ED_ERR                     ; Opps, A Problem

            JSR    PRCRLF
            LD16   X_ARG                      ; Get Line Number
            JSR    FINDLN                     ; Get Address
            JSR    FNDLEN                     ; Get Length
            STA    TEMP2
            PHA                               ; Save Orig Length
            TAX
            BEQ    ED_ED3

            LDY    #0
ED_ED2      MOV    (TEMP),Y;LNBUF,Y           ; Move Data To Lnbuf
            INY
            DBNE   X;ED_ED2

ED_ED3      PUSHW  TEMP                       ; Save Address
            MOVD   #LNBUF;TEMP                ; Point At Lnbuf
            JSR    SHOWLN                     ; Show Line Number
            JSR    LSTLINE                    ; Print Line
            TSTVC  NONBS;ED_ED4               ; Check Bs Mode, print line again

            JSR    ED_BEGIN                   ; Back Up
            BEQ    ED_ED5                     ; Always

ED_ED4      JSR    PRCRLF                     ; Add A Return
            JSR    SHOWLN                     ; Show The Line Number
            MOVY   #0;TEMP2                   ; Kill Line
ED_ED5      INC    WWRAP                      ; Toggle Word Wrap Off
            JSR    GETEDLN2                   ; Edit Line
            DEC    WWRAP                      ; Put Word Wrap To Old State
            PULLW  TEMP3                      ; Save Old Line Address
            PLA
            BCS    CR_RET2                    ; If They Typed 'done'

            SEC
            SBC    TEMP2                      ; Find Out Length
            BEQ    ED_ED7                     ; Hmm, Same Length!
            BCC    ED_ED6

            TAY
            JSR    DEL_TX2                    ; Make Room
            BRA    ED_ED7

ED_ED6      EOR    #-1                        ; Make Positive
            TAY
            INY
            JSR    INS_TX2                    ; Insert
ED_ED7      LDY    #0
            LDX    TEMP2                      ; Get Length
            INX
ED_ED8      MOV    LNBUF,Y;(TEMP3),Y          ; Copy Line Back
            INY
            DBNE   X;ED_ED8

            JMP    PRCRIF                     ; Add Extra Lf (Maybe)

CR_ERR      JSR    SHOWSTR
            DB     cr
            ASC    'Illegal Line Number'8D
            JMP    PRCRIF                     ; Add Extra Lf (Maybe)

ED_INS      JSR    SHOWSTR
            DB     cr
            DCI    'Insert Line (L,x) -> '
            JSR    INPLN
            JSR    CHKLIST                    ; Do A List?
            BCS    ED_INS

DOT_INS     JSR    XARG
            BEQ    CR_RET
            BCS    CR_ERR

            JSR    SHOWSTR
            DB     cr
            ASC    'Insert Text: '
            ASC    'Type "DONE" When Finished'0D8D

ED_INS2     LD16   #LNBUF                     ; Point To Line
            JSR    GETEDLN                    ; Get A Line Of Stuff
            BCS    ED_INS7

            LDY    TEMP2                      ; Save Length
            INY                               ; Add 1 For CR
            STY    SAVE_Y
            LD16   X_ARG
            JSR    FINDLN                     ; Locate Line
            LDY    SAVE_Y
            JSR    INS_TXT                    ; Insert Text
            LDY    #0
ED_INS3     MOV    LNBUF,Y;(TEMP3),Y          ; Copy In New Line
            INY
            DBNE   SAVE_Y;ED_INS3

            LDX    #0
            CPEQX  WWEXTRA;ED_INS5            ; Word-Wrap?

ED_INS4     LDA    LNBUF,Y                    ; Get Next Bit Of Data
            INY
            STA    LNBUF,X                    ; Move Back
            INX
            CPNEX  WWEXTRA;ED_INS4            ; Done?

ED_INS5     INCD   X_ARG                      ; Inc Line To Insert At
            IBNE   EDLINE;ED_INS2             ; Inc Line Count
            IBRA   EDLINE+1;ED_INS2

ED_INS7     TSTPL  EXE_DOT;CR_RET             ; Is It I Command?
            JMP    CONT                       ; Continue

CR_RET      RTS

CR_ERR0     JMP    CR_ERR                     ; Goto Error Routine

ED_LST      JSR    SHOWSTR
            DB     cr
            DCI    'List Line (x-y) -> '
            JSR    INPLN

DOT_LST     MOVY   #0;SHWLN                   ; Reset Line # Bit
            LDA    (ARGPTR),Y
            JSR    CONV
            CPNE   #'Y';ED_LST1               ; Show Numbers?
            MOV    #-1;SHWLN                  ; Show Line Numbers
            INCD   ARGPTR                     ; Point To Next Char
ED_LST1     JSR    XYARG
            BCS    CR_ERR0
            JSR    PRCRLF

ED_SHLN     LD16   X_ARG                      ; Get Line Number
            JSR    FINDLN                     ; Locate It

ED_LST2     TSTPL  SHWLN;ED_LST3              ; Show Line Number?
            JSR    SHOWLN                     ; Add The Line Number

ED_LST3     JSR    FNDLEN                     ; Get The Length
            STA    TEMP2
            JSR    LSTLINE                    ; List The Line
            SEC                               ; Advance Line Pointer
            AD     TEMP;TEMP2;TEMP            ; TEMP = TEMP + TEMP2 + 1
            BCC    ED_LST4
            INC    TEMP+1
ED_LST4     JSR    PRCRLF                     ; Add Cr
            JSR    INCXARG
            BCC    ED_LST2

            RTS

ED_NEW      JSR    SHOWSTR
            DB     cr
            DCI    'New: Erase And Start Over? -> '
            JSR    GETCMD

            CPNE   #'Y';ED_NEW2

            JSR    ED_CLR                     ; Clear Editor
            JSR    SHOWSTR                    ; Enter Message Now...
            DB     cr
            ASC    'Enter Message Now...'0D8D

            MOV    #0;EXE_DOT                 ; Allow Dot Commands
            JMP    ED_LN                      ; Get Message

ED_NEW2     RTS

ED_SIZE     JSR    PRCRLF
            JSR    GET_SPC                    ; Get Length Of Editor
            TAY
            CPNEX  #0;ED_SIZE2
            DEY
ED_SIZE2    DEX
            TYA
            LDY    #0
            JSR    DECOUT0                    ; Print Space Used
            JSR    SHOWSTR
            ASC    ' Bytes Used.'0D8D
            RTS

DOT_PMT     LDA    PROMPT
            EOR    #-1                        ; Toggle Prompt Status
            STA    PROMPT
            BEQ    ED_NEW2                    ; Don't Show Prompts

            JMP    PMTOUT                     ; Show First Prompt

*-------------------------------
* Common Read/Write
*-------------------------------

ED_RW       JSR    INPLN                      ; Input Data
            STY    FLNAME
ED_RW2      MOV    LNBUF,Y;FLNAME+1,Y
            DBPL   Y;ED_RW2

            RTS

ED_RD       JSR    SHOWSTR
            DB     cr
            DCI    'Read File (Name) -> '
            JSR    ED_RW

            LDA    #%00100001                 ; Request Read, Deny Write
            JSR    IFOPEN                     ; Try And Open
            BCS    ED_RD4                     ; Error, No Go

            MOVD   EDLOC;EDPTR                ; Point To Data

ED_RD2      JSR    PD_RDBYT                   ; Read In File
            PHP
            JSR    EDOUT
            PLP
            BCC    ED_RD2

ED_RD3      JSR    PD_CLOSE                   ; Finish Up
            JMP    FINDEND                    ; Fix Pointers

ED_RD4      JSR    SHOWSTR
            DB     cr
            ASC    'Error: Too Many Files Open'8D
            RTS

ED_RD5      JSR    ED_RD4
            BRA    ED_RD3

ED_WRT      JSR    SHOWSTR
            DB     cr
            DCI    'Write File (Name) -> '
            JSR    ED_RW                      ; Setup For Work

            JSR    PD_KILL                    ; Delete Existing File
            LDY    #Txt
            LDA    #0                         ; Aux Type Is 0
            TAX
            JSR    PD_MAKE                    ; Create A Text File
            LDA    #%00110010                 ; Request Write, Deny All
            JSR    IFOPEN
            BCS    ED_RD5                     ; Error
            STZ    DEVCLR                     ; Reset Device

ED_WRT2     JSR    EDIN                       ; Get Data
            CPEQ   #0;ED_RD3                  ; That's The End

            JSR    PD_WRBYT                   ; Write Out Byte
            BCC    ED_WRT2                    ; All Is Well

            JSR    SHOWSTR                    ; Show Message
            DB     cr
            ASC    'Error Writing To File'8D

            JMP    ED_RD3                     ; Finish Up

DOT_OK      LDA    #0                         ; Add In Eof Char
            TAY
            STA    (TEMP),Y
ED_OK       TSTPL  EXECFLG;ED_FILTR           ; Exec User Online?
            JMP    ED_EX

ED_FILTR    LDEQ   FILTER;ED_DOTX             ; Is Filter In Place?
            LDEQ   FILTFLAG;ED_DOTX           ; Filter On?

            MOVD   EDLOC;TEMP                 ; Point To Editor Buffer
            BRA    ED_FILT7                   ; Start Routine

ED_FILT2    LDA    FILTER,X                   ; Go To Next Entry
            INX
            ASL    A                          ; At Last Char?
            BCC    ED_FILT2                   ; Nope

ED_FILT3    LDY    #0                         ; Start At First Byte
ED_FILT4    LDEQ   FILTER,X;ED_FILT6          ; Get Filter Char

            STA    TEMP2                      ; Save It
            LDA    (TEMP),Y                   ; Get Byte In Question
            JSR    CONV                       ; Convert To Upper
            EOR    TEMP2                      ; Check Against Filter
            ASL    A                          ; Put High Into Carry
            BNE    ED_FILT2                   ; No Match, Keep Checking

            INX                               ; Inc Pointers
            INY
            BCC    ED_FILT4                   ; Keep Checking String

            LDA    #'*'                       ; Change Text Into *'s
ED_FILT5    DEY
            STA    (TEMP),Y
            CPNEY  #0;ED_FILT5

ED_FILT6    INCD   TEMP
ED_FILT7    LDEQ   (TEMP);ED_DOTX             ; Get Byte

            JSR    CONV

            CPLT   #'A';ED_FILT6              ; Is It Even Good Data?
            CPGE   #'Z'+1;ED_FILT6

            LDEQX  #0;ED_FILT3                ; Start Both Index's At 0 CHANGE TO BRA LATER

ED_DOTX     STZ    HACK_Q

            MOVD   EDLOC;TEMP                 ; Set Start-1
            BRA    ED_DOTX3                   ; Always CHANGE TO BRA LATER

ED_DOTX2    INCD   TEMP
ED_DOTX3    LDEQ   (TEMP);ED_EX               ; Get First Char Of Line

            AND    #Clrhi                     ; Strip Off High Bit
            CPNE   #'.';ED_DOTX7              ; Is It A '.' Command?

            INCD   TEMP                       ; Point To Next Char
            LDEQ   (TEMP);ED_EX               ; Get Second Char Of Line

            JSR    CONV                       ; Make It Upper Case
            CPNE   #'X';ED_DOTX7              ; Is It A '.X' Command?

            MOV    #1;HACK_Q                  ; Flag Hack Attempted
            MOV    #'*';(TEMP)                ; '.X' Not Allowed,
ED_DOTX5    INCD   TEMP                       ; Get Next Char
            LDEQ   (TEMP);ED_EX               ; if end of buffer

ED_DOTX7    AND    #Clrhi
            CPNE   #cr;ED_DOTX5               ; End Of Line?
            BRA    ED_DOTX2                   ; Yes, Check For '.X' Again

ED_EX       LDX    EDSTACK
            TXS
            RTS

*===============================
* ----- Editor Routines -----
*===============================

GETEDLN     MOVY   #0;TEMP2                   ; line length
            ST16   TEMP                       ; Point To Data
            TSTPL  PROMPT;GETEDLN1            ; Are Prompts On?

            JSR    PMTOUT                     ; Display Prompt
GETEDLN1    LDEQ   WWEXTRA;GETEDLN2           ; Word-Wrap?

            STY    WWEXTRA                    ; Reset Word-Wrap
            STA    TEMP2                      ; Save Length
            JSR    LSTLINE                    ; List The Partial Line
            BEQ    GETED1                     ; Don't Want To Reset To 0!

GETEDLN2    LDY    #0

*===============================
* Get A Character -- Non Destructable
*===============================

GETED1      JSR    RDKEY
            JSR    GETED2
            BRA    GETED1

GETED2      JSR    MATCH
            CHR    -1;ED_EX                   ; Carrier Loss
            CHR    cr;EDLNCR                  ; Handle [Return]
            CHR    tab;ED_TAB                 ; Handle [Tab]
            CHR    bs;ED_BS                   ; Handle [Backspace, ^H]
            CHR    del;ED_DELBK               ; Handle [Delete]
            CHR    can;ED_CAN                 ; Handle [Cancel, ^X]
            CHR    ctr;ED_CNTR                ; Handle [Center, ^C]
            DB     0                          ; Finish This Set
            TSTVC  NONBS;GETED2A              ; Do They Have Correct Bs?
            JSR    MATCH
            CHR    fs;ED_FWD                  ; Handle [Forward Space, ^U]
            CHR    hak;ED_HACK                ; Handle [Truncate, ^T]
            CHR    dc;ED_DELFW                ; Handle [Delete Char, ^D]
            CHR    ic;ED_INSCH                ; Handle [Insert Char, ^F]
            CHR    bol;ED_BEGIN               ; Handle [Begin Line, ^B]
            CHR    eol;ED_END                 ; Handle [End Of Line, ^E]
            CHR    lwd;ED_LWORD               ; Handle [Last Word, ^L]
            CHR    nwd;ED_NWORD               ; Handle [Next Word, ^N]
            DB     0

GETED2A     CPEQ   #norm;GETED2C              ; Set Normal?
            CPEQ   #inv;GETED2C               ; Set Inverse?
            CPNE   #mous;GETED2B              ; Set Mouse?
            LDNE   #realmous;GETED2C          ; Substitute Real Character CHANGE TO BRA LATER

GETED2B     CPLT   #' ';GETED2E               ; Control?
GETED2C     CPEQY  VIDLEN;GETED3

            STA    (TEMP),Y                   ; Save Char
            JSR    COUTLO                     ; Output It
            CPNEY  TEMP2;GETED2D              ; At End Of Line?
            INC    TEMP2                      ; Inc End Of Line Pointer
GETED2D     INY                               ; Inc Data Pointer
GETED2E     RTS

GETED3A     TXA                               ; Restore Y
            TAY
GETED3B     LDA    #bel                       ; Ring Bell
            JMP    COUT

GETED3      TSTPL  WWRAP;GETED3B              ; Is Word Wrap On?
            CPEQ   #' ';EDLNCR                ; Was It An Even Break?
            STA    (TEMP),Y                   ; Save Char
            TYA                               ; Save Y
            TAX
GETED3C     DBEQ   Y;GETED3A                  ; Count Down

            IFNE   (TEMP),Y;#' ';GETED3C      ; check for space

            STY    TEMP2                      ; Save New Length
            LDY    #0
GETED3D     INY                               ; Count Number Of Extra's
            DEX                               ; First Char Doesn't Count
            JSR    PRBS                       ; Backup
            CPNEX  TEMP2;GETED3D              ; We Done?

            STY    WWEXTRA                    ; Remember Extra

EDLNCR      LDY    TEMP2                      ; Get Line Length
            MOV    #cr;(TEMP),Y               ; save return at end
            JSR    COUT                       ; Show It
            JSR    EDLNCR6                    ; DONE Or /EX?
            BCC    EDLNCR1                    ; Yes

            JMP    EDLNCR5

EDLNCR1     IFEQ   (TEMP);#'.';EDLNCR2        ; Dot Command?
            CPNE   #'/';EDLNCR4

EDLNCR2     STA    CMD_CHR
            TSTMI  EXE_DOT;EDLNCR4            ; Dot Commands Allowed?

            DEC    EXE_DOT                    ; Exec A Dot Command

            CLC
            MOV    TEMP;EDPTR                 ; Set Up Arg Pointer
            ADA    #2;ARGPTR
            MOV    TEMP+1;EDPTR+1
            ADA    #0;ARGPTR+1

            LDA    #0                         ; End Text
            TAY
            STA    (TEMP),Y
            INY
            LDA    (TEMP),Y                   ; Get Command

            JSR    EDLNCR3
            JSR    FINDEND                    ; Get New End Pointer
            MOVY   #0;EXE_DOT                 ; Get A New Line
            STY    TEMP2

            MOVD   EDPTR;TEMP                 ; Point Back To Data
            RTS

EDLNCR3     JSR    CONV                       ; Make Upper
            JSR    MATCH
            CHR    'I';DOT_INS
            CHR    'L';DOT_LST
            CHR    'D';DOT_DEL
            CHR    'E';DOT_ED
            CHR    'A';ED_ABT
            CHR    'H';DOT_HLP
            CHR    'N';ED_NEW
            CHR    'O';DOT_OK
            CHR    'S';DOT_OK
            CHR    'P';DOT_PMT
            CHR    'Z';ED_SIZE
            DB     0

            PLA
            PLA
            STZ    EXE_DOT

            MOV    CMD_CHR;(TEMP)             ; Restore The Command

EDLNCR4     PLA                               ; Return From Getline
            PLA

            SEC                               ; Return With End Address
            LDA    TEMP                       ; Of Line
            ADC    TEMP2                      ; Address=Start+Length+1
            TAX
            LDA    TEMP+1
            ADC    #0
            CLC                               ; Return Status:
            RTS                               ; CLC = All Is Ok

EDLNCR5     PLA
            PLA

            LD16   TEMP                       ; Get Old Address
            RTS                               ; SEC = Exit Edit Mode

EDLNCR6     IFNE   TEMP2;#4;EDLNCR7           ; was length correct?

            LDX    #0                         ; Was It 'DONE' ?
            JSR    CMPSTR
            BCS    EDLNCR9                    ; Yep

EDLNCR7     IFNEY  TEMP2;#3;EDLNCR8           ; Is Length Correct?

            LDX    #4                         ; Was It '/EX' ?
            JSR    CMPSTR
            BCS    EDLNCR9                    ; Yep

EDLNCR8     CLC
EDLNCR9     RTS

*===============================
* Handle A Tab
*===============================

ED_TAB      CPEQY  VIDLEN;ED_TAB2             ; At End Of Line?

            LDA    #' '                       ; Do A Space
            JSR    GETED2
            TYA
            AND    #7                         ; Are We At A 1/8 Inc?
            BNE    ED_TAB                     ; Nope

ED_TAB2     RTS

*===============================
* Go Forward 1 Space
*===============================

ED_FWD      SEC                               ; Can't Do Fs
            CPEQY  TEMP2;ED_FWD2              ; At End Of Line?

            LDA    (TEMP),Y                   ; Get Char
            JSR    COUTLO                     ; Output It
            INY                               ; Move Pointer
            CLC                               ; Can Do Fs
ED_FWD2     RTS

*===============================
* Truncate Contents Of Line
*===============================

ED_HACK     LDX    #0                         ; Kill 0 Chars
ED_HACK2    CPEQY  TEMP2;ED_HACK3             ; Are We Done?

            JSR    SPCOUT                     ; Kill Char
            INX                               ; Count It
            IBNE   Y;ED_HACK2

ED_HACK3    CPEQX  #0;ED_HACK4                ; We Done?

            JSR    BSOUT                      ; Do Bs
            DEC    TEMP2                      ; Move Back Line Count
            DEY                               ; Move Back Data Pointer
            DBNE   X;ED_HACK3                 ; Not Done, Loop

ED_HACK4    RTS

*===============================
* Delete Entire Line
*===============================

ED_CAN      JSR    ED_HACK                    ; Hack Line
            LDEQ   TEMP2;ED_CAN3              ; No Data To Kill

ED_CAN2     JSR    PRBS                       ; Destructive Bs
            DEY                               ; Back Up Data Pointer
            DBNE   TEMP2;ED_CAN2              ; Decrease Line Length

ED_CAN3     RTS

*===============================
* Delete 1 Character
*===============================

ED_DELFW    CPEQY  TEMP2;ED_DELF5             ; At End Of Line?

            STY    SAVE_Y
            DEC    TEMP2                      ; Decrease Line Count
            LDX    #1
ED_DELF2    CPEQY  TEMP2;ED_DELF3             ; done

            INY
            LDA    (TEMP),Y                   ; Move Each Char Back
            DEY
            STA    (TEMP),Y
            INY
            INX
            JSR    COUTLO                     ; Show Char
            BRA    ED_DELF2

ED_DELF3    JSR    SPCOUT                     ; Delete Last Char
            LDY    SAVE_Y
ED_DELF4    JSR    BSOUT
            DBNE   X;ED_DELF4

ED_DELF5    RTS

*===============================
* Insert 1 Character
*===============================

ED_INSCH    CPEQY  TEMP2;ED_INSC4             ; At The End Of The Line?

            IFEQ   TEMP2;VIDLEN;ED_INSC4      ; at max width?

            STY    SAVE_Y
            LDX    #0                         ; Start Counter
            LDA    #' '                       ; Show A Space First
ED_INSC2    JSR    COUT
            INX                               ; Inc Count
            PHA
            MOV    (TEMP),Y;TEMP2+1           ; Get New Char
            PULL   (TEMP),Y                   ; Save Old Char
            LDA    TEMP2+1                    ; Get Back New
            INY
            CPLTY  TEMP2;ED_INSC2             ; We Done?
            BEQ    ED_INSC2

            INC    TEMP2                      ; Add 1 To Line Count
            LDY    SAVE_Y
ED_INSC3    JSR    BSOUT                      ; Backup
            DBNE   X;ED_INSC3

ED_INSC4    RTS                               ; Were Done

*===============================
* Goto Beginning Of Line
*===============================

ED_BEGIN    CPEQY  #0;ED_BGN3                 ; At Beginning?

ED_BGN2     JSR    BSOUT                      ; Back Up
            DBNE   Y;ED_BGN2

ED_BGN3     RTS

*===============================
* List A Line
*===============================

LSTLINE     LDY    #0                         ; Use Show To Eol

*===============================
* Goto End Of Line
*===============================

ED_END      CPEQY  TEMP2;ED_END2              ; At End Of Line?

            LDA    (TEMP),Y
            JSR    COUTLO                     ; Print Char (Move Forward)
            IBNE   Y;ED_END                   ; keep checking

ED_END2     RTS

*===============================
* Back Up To Last Word
*===============================

ED_LWORD    CPEQY  #0;ED_LWD2                 ; At Beginning?

            JSR    BSOUT                      ; Back Up
            DEY
            IFNE   (TEMP),Y;#' ';ED_LWORD     ; back 1 word?

ED_LWD2     RTS

*===============================
* Goto Next Word
*===============================

ED_NWORD    CPEQY  TEMP2;ED_NWD2              ; At End?

            LDA    (TEMP),Y                   ; Move Forward
            JSR    COUTLO
            INY
            IFNE   (TEMP),Y;#' ';ED_NWORD     ; At End Of Word?

ED_NWD2     RTS

*===============================
* Center Line Of Text
*===============================

ED_CNTR     LDEQ   TEMP2;ED_CNTR3             ; Any Data?

            JSR    ED_BEGIN                   ; Move Cursor To First Char
            JSR    CENTER                     ; Center Text
            BCS    ED_CNTR3                   ; Oops, A Problem

            PUSHA  TEMP2
            MOV    TEMP2+1;TEMP2              ; Save New Length
            JSR    LSTLINE                    ; Show The Line
            PULL   TEMP2
            IFGE   TEMP2+1;TEMP2;ED_CNTR2     ; Is New Line Smaller?

            JSR    ED_HACK                    ; Hack Rest Of Line
ED_CNTR2    MOV    TEMP2+1;TEMP2
ED_CNTR3    RTS

*===============================
* Back Up 1 Char
*===============================

ED_BS       CPEQY  #0;ED_RTS3                 ; At Beginning Of Line?

            TSTMI  NONBS;ED_BS2               ; Check Bs Mode, destruct
            BVC    ED_BS2                     ; Use Unknown Mode

            DEY
            JMP    BSOUT                      ; Do Bs

ED_BS2      DEY
            DEC    TEMP2
            JMP    PRBS

*===============================
* Handle Delete Character
*===============================

ED_DELBK    CPEQY  #0;ED_RTS3                 ; At Beginning?

            DEY                               ; Backup
            JSR    BSOUT
            JMP    ED_DELFW                   ; Delete Char

ED_RTS3     RTS
            LST    OFF

