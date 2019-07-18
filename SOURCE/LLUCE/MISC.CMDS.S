            LST    RTN
            TTL    'LLUCE - Misc Commands'
            PAG
*===============================
* Contents:
*
* ANSI     - Set/reset ANSI mode
* CLEAR    - Clear Command
* CONVERT  - Set/reset convert emulation flag
* DEBUG    - Break into debugger
* EDIT     - Edit Command
* FLASH    - Set GS screen color change
* LET      - Let Statement
* MODE     - Read Or Set Backspace Mode
* NET      - Lock Out Other Computer Writing
* NOT      - "Not" A Value
* PDL      - Read Status Of A Paddle
* RND      - Get A Random Number
* RNDSTR   - Generate A Random Character
* SET      - Set Up Variable Pointers
*===============================

*===============================
* Name: CLEAR - Clear Command
*===============================

CLEAR       IFEQ   (PRGPTR);#Gosub;CLRSTK       ; what clear?
            CPEQ   #Key;CLRKEY                  ; Key?
            CPNE   #'#'+Hibit;CLRSMT            ; How About Device?

*-------------------------------
* Clear A Device
*-------------------------------

            JSR    BYTNUM8
            CPEQX  #ioEditor;CLR_ED             ; Clear Editor?
            CPNEX  #ioRamDsk;CLRRTS             ; Ram Drive?

            MOV    #0;RAMPTR                    ; Clear Ram Drive
            JSR    RAMOUT
            STA    RAMPTR
CLRRTS      RTS

*-------------------------------
* Clear The Editor
*-------------------------------

CLR_ED      JMP    ED_CLR

*-------------------------------
* Clear The Gosub Stack
*-------------------------------

CLRSTK      STZ    GSBLVL                       ; Reset Gosub Stack
            BRA    EATBYT

*-------------------------------
* Clear The Keyboard Buffer
*-------------------------------

CLRKEY      STZ    TYPIN                        ; Reset Type-Ahead Buffer
            STZ    TYPOUT
EATBYT      JMP    GETBYT                       ; Gobble!

*-------------------------------
* Clear Statement
*-------------------------------

CLRSMT      STZ    SETRAM1                      ; Switch In Subs
            JSR    CLRSMT2
            STZ    SETRAM2                      ; Switch Out Subs
            STZ    DOLVL                        ; Reset IF stack pointer
            STZ    WHILELVL                     ; Reset WHILE stack pointer
            STZ    WHATLVL                      ; Reset what loop stack
            RTS

*===============================
* Name: LET - Let Statement
*===============================

LET         IFNE   (PRGPTR);#String;DO_LET0     ; Not String, Dont Check

            JSR    CHKFRE                       ; Check For Low Memory
DO_LET0     JSR    VARSET                       ; Set Pointers To Variable

            PUSHA  VNAME
            PUSHW  VPTR                         ; Save Var Address
            PUSHA  VNAME
            BMI    DO_LET0A

            IFLT   (PRGPTR);#Incremnt;DO_LET0A  ; assignment?
            CPGE   #Mod;DO_LET0A

            PHA                                 ; save type for later
            JSR    INPNUM0X
            CLV
            JSR    INPNUM2                      ; do function
            STA    TEMP+1
            PLA                                 ; get type back
            CMP    #Incremnt+2                  ; increment or decrement?
            LDA    TEMP+1
            BLT    INC_DEC                      ; yeah, dont need result
            BRA    DO_LET2

INC_DEC     PLA                                 ; throw out new? value
            PLA
            PLA
            PLA
            RTS

DO_LET0A    JSR    GOBEQU

            PLA
            PHA
            BPL    DO_LET1                      ; Or Number

            JSR    INPSTR                       ; Get String Address/Length
            BRA    DO_LET2

DO_LET1     JSR    INPNUM
DO_LET2     ST16   TEMP                         ; Save Data
            STY    SAVE_Y
            PLA
            PULLW  VPTR                         ; Point Back At Var

            PLA
            BPL    DO_LET9                      ; If Numeric

            LDY    #1                           ; Get Last Variable Address
            MOV    (VPTR);TEMP2
            MOV    (VPTR),Y;TEMP2+1
            BEQ    DO_LET6

            JSR    CHKMEM2                      ; In normal memory?
            BCC    DO_LET5                      ; yes, treat as normal

DO_LET3     INY                                 ; Get String Length
            LDA    (VPTR),Y
            TAX
            LDY    #0                           ; Move String
DO_LET4     MOV    (TEMP),Y;(TEMP2),Y
            INY
            CPGEY  STRLEN;DO_LET4B              ; past length of source str?
            DBNE   X;DO_LET4
            RTS

DO_LET4A    MOV    #' ';(TEMP2),Y               ; fill with spaces
            INY
DO_LET4B    DBNE   X;DO_LET4A
            RTS

DO_LET5     CPLT   LOMEM+1;DO_LET6              ; In Variable Space
            BNE    DO_LET9
            IFGE   TEMP;LOMEM;DO_LET9           ; Its In String Space

DO_LET6     LDY    #0                           ; String -> String Space
DO_LET7     CPEQY  SAVE_Y;DO_LET8               ; Done With String?

            MOV    (TEMP),Y;(VARSTR),Y          ; Move A Byte
            IBRA   Y;DO_LET7

DO_LET8     LDY    #1
            MOV    VARSTR+1;(VPTR),Y
            MOV    VARSTR;(VPTR)                ; Save Pointer/Add Length

            CLC
            ADA    SAVE_Y;VARSTR
            BCC    DO_LETA
            IBRA   VARSTR+1;DO_LETA             ; Go Save The Length

DO_LET8A    ST16   TEMP
            STY    SAVE_Y
DO_LET9     LDY    #1
            MOV    TEMP;(VPTR)                  ; Save Low Address Or Byte
            MOV    TEMP+1;(VPTR),Y              ; Save High Address Or Byte
DO_LETA     INY
            MOV    SAVE_Y;(VPTR),Y              ; Save Length Or High Byte
            STZ    TTLLEN                       ; Zero Old String Length
            RTS

*===============================
* Name: SET - Set Up Variable Pointers
*===============================

SET         IFEQ   (PRGPTR);#Msg;MSGSET

            JSR    VARSET                       ; Set Up Pointers
            JSR    GOBEQU
            IFNE   (PRGPTR);#'"'+Hibit;SET2     ; to null?

            JSR    GETBYT                       ; Gobble Quotes
            JSR    GETBYT
            MOVD   VARSTR;TEMP                  ; Point At Empty Space
            LDEQX  #0;SET3                      ; Set Length To Zero

SET2        PUSHW  VPTR                         ; Save Current Pointers
            JSR    INPNUM16                     ; Get Address Of String
            PHAX
            JSR    COMNUM8                      ; Get Length Of String
            PULLW  TEMP                         ; Restore Address Of String
            PULLW  VPTR                         ; Restore Orig Var Pointers
SET3        LDY    #2
            TXA                                 ; Save File Length
            STA    (VPTR),Y
            DEY
            MOV    TEMP;(VPTR)                  ; Save Low Byte Of Address
            MOV    TEMP+1;(VPTR),Y              ; Save High Byte Of Address
            RTS

*-------------------------------
* Print CHAT Or EXEC
*-------------------------------

MSGSET      JSR    GETBYT                       ; Eat msg token
            JSR    EQUNUM8
            TXA
            JMP    VIDCHAT                      ; Carry Through

*===============================
* Name: PDL - Read Status Of A Paddle
*===============================

PDL         JSR    INPNARG8                     ; Get Paddle Number
            BIT    SETROM                       ; Map In Monitor ROM
            JSR    PREAD                        ; Use Monitors Pdl Routine
            LDA    SETRAM2                      ; Select Ram Card
            MOV    SETRAM2;SETALTZP
            TYA
            JMP    SVDATA                       ; Return Value

*===============================
* Name: RNDSTR - Generate A Random Character
*===============================

RNDSTR      STZ    SETRAM1                      ; Switch In Subs
            JSR    DO_RNDS2
            STZ    SETRAM2                      ; Switch Out Subs
            JMP    SVSTR                        ; Save Location Of Char

*===============================
* Name: RND - Get A Random Number
*===============================

RND         JSR    INPNARG                      ; Get Range
            ST16   TEMP
            ORA    TEMP
            BEQ    DO_RN1

            LDA    RNDNUM
            EOR    #$96
            SBC    RNDNUM+1
            TAX
            LDEQ   TEMP+1;DO_RN4                ; Is It Below 256?

            LDA    RNDNUM+1                     ; Get Seed
            EOR    #$B4
            ADC    RNDNUM
DO_RN0      CPEQ   TEMP+1;DO_RN2
            BGE    DO_RN3                       ; Kill Number

DO_RN1      JMP    MATH_16                      ; Return Number

DO_RN2      CPEQX  TEMP;DO_RN1                  ; Check Low Byte
            BLT    DO_RN1                       ; All Is Well, Return

DO_RN3      PHA
            TXA
            SEC
            SBC    TEMP                         ; (AX) = (AX) - Range
            TAX
            PLA
            SBC    TEMP+1
            BRA    DO_RN0                       ; Loop And Check

DO_RN4      CPEQX  TEMP;DO_RN1
            BLT    DO_RN1
            PHA
            TXA                                 ; nope, subtract
            SEC
            SBC    TEMP
            TAX
            PLA
            BRA    DO_RN4

*===============================
* Name: NET - Lock Out Other Computer Writing
*===============================

NET         JSR    GETBYT                       ; Whats Up?
            CPEQ   #Unlock;NET_EN               ; Unlock The Net?
            CPEQ   #Lock;NET_DIS                ; Lock The Net?
            JMP    SYNTAX

NET_DIS     TSTMI  MLBUS;NET_DIS2               ; shift status to carry

            LDA    #Moment2
            JSR    PRTEXT
NET_DIS0    TSTPL  MLBUS;NET_DIS1               ; Check Again After Message

            JSR    WAITSEC                      ; Wait One Sec
            BRA    NET_DIS0

NET_DIS1    LDA    #MomntOut
            JSR    PRTEXT

NET_DIS2    STA    ANU_OFF                      ; Set Annun For Our Use
            LDRA   #'L'-Ctrl;NET_STUF           ; Show Lock Status

*-------------------------------
* Enable Other Computer Writing
*-------------------------------

NET_EN      STA    ANU_ON                       ; Give Up Use
            LDA    #'U'-Ctrl                    ; Show Unlock Status
NET_STUF    STA    TOPRIGHT                     ; In Right Corner
            RTS

*===============================
* Name: EDIT - Edit Command
*===============================

EDIT        LDA    (PRGPTR)                     ; Get The Next Byte

            TSTMI  IMMDEF;EDIT1                 ; Was It An Assignment?
            CPEQ   #Size;GO_EDIT

            LD16   #EDBUF
            JMP    MATH_16

EDIT1       CPEQ   #Equal;SETNAME

            LDX    #1                           ; Filter On
            CPEQ   #On;SETFILT

            DEX                                 ; Filter Off
            CPEQ   #Off;SETFILT
            CPNE   #Clear;GO_EDIT

            JSR    ED_CLR
            BRA    EDEAT

SETFILT     STX    FILTFLAG                     ; Set The Flag
EDEAT       JMP    GETBYT

SETNAME     JSR    GOBEQU                       ; Must Be A =
            JSR    MOVNAME                      ; Get The Filename
            IFGEY  FLNAME;#15;FNERR             ; Must Be End Name

ED_MVNAM    MOV    FLNAME,Y;EDNAME,Y            ; Move The Name
            DBPL   Y;ED_MVNAM

            RTS

FNERR       JMP    BADNAME

GO_EDIT     PHA                                 ; Save Call Number
            LDA    #Editid                      ; Load In An Editor Only
            JSR    TST_OVR
            BREQW  OVERBUF+3;EDVEROK            ; if version=0, do always
            IFNE   OVERBUF+3;VERSION;EDBADVER   ; check compiler version
            IFEQ   OVERBUF+4;VERSION+1;EDVEROK

EDBADVER    PLA                                 ; Restore Call Number
            LDA    #Badver                      ; Do Error
            JMP    BADERR

EDVEROK     PLA                                 ; Restore Call Number
            JMP    OVERBUF

*===============================
* Name: CONVERT - Set emulation conversion flag
* Name: FLASH - Set GS screen color change
*===============================

CONVERT     LDA    #CONVFLAG-NODENUM
            SKIP2
FLASH       LDA    #FLASHING-NODENUM
            PHA
            JSR    GETBYT                       ; Get flash mode
            LDY    #0
            CPEQ   #Off;SETFL                   ; Turning off?
            DEY
            CPNE   #On;FL_SYN                   ; Turning on?
SETFL       TYA
            PLX
            STA    NODENUM,X                    ; save mode
            RTS

FL_SYN      PLX
            JMP    SYNTAX

*===============================
* Name: ANSI - Set ANSI mode
*===============================

ANSI        BCC    GETAFLG                      ; Do read, not set

            JSR    GETBYT                       ; Get ANSI mode
            CPEQ   #On;SETANSI                  ; Turning on?
            CPNE   #Off;FL_SYN                  ; Turning off?

CLRANSI     TSTPL  ANSIFLAG;ANSISET             ; ANSI alreary off?

            STZ    ANSIFLAG
            STZ    SETRAM1                      ; Switch In Subs
            JSR    RstEMUL
            BRA    DRAM6

SETANSI     TSTMI  ANSIFLAG;ANSISET             ; ANSI already on?

            MOV    #-1;ANSIFLAG
            STZ    SETRAM1                      ; Switch In Subs
            JSR    SetANSI
DRAM6       STZ    SETRAM2                      ; Switch Out Subs
ANSISET     RTS

GETAFLG     LDA    ANSIFLAG                     ; get the flag
            JMP    SVDATA                       ; and return it

*===============================
* Name: MODE - Read Or Set Backspace Mode
*===============================

MODE        BCS    MODE1

            LDA    NONBS                        ; Get Mode
            ROL    A
            ROL    A
            ROL    A
            JMP    SVDATA

MODE1       MOV    #%01000000;NONBS             ; Non Destruct Bs Mode
            JSR    EQUNUM8                      ; Get Mode
            CPEQX  #1;MODE2                     ; It Was Non Destruct

            ASL    NONBS                        ; Set To Destruct
            CPEQX  #2;MODE2                     ; Set, So Exit

            ASL    NONBS                        ; Unknown Backspace
MODE2       RTS

DEBUG       =      *
            DO     DEMOPGM
            ELSE
            BRK
            BRK
            FIN
            RTS
            LST    OFF

