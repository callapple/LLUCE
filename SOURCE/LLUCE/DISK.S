            LST    RTN
            TTL    'LLUCE - Disk Routines'
            PAG
*===============================
* Contents:
*
* APPEND   - Append To A Disk File
* CHAIN    - Chain To Another Program Segment
* CLOSE    - Close A Disk File
* COMPRES  - Compress Variables
* COPY     - Copy Data From Device To Device
* CREATE   - create A File
* DISKIN1  - Input From File 1
* DISKIN2  - Input From File 2
* DISKIN3  - Input From File 3
* DO_CL3   - Close All Disk Files
* DO_CLFL  - Close Or Flush All Disk Files
* DSKOUT1  - Send Character To File 1
* DSKOUT2  - Send Character To File 2
* DSKOUT3  - Send Character To File 3
* EOF      - Check For Disk File End
* EXIST    - Test For Existing File
* FLUSH    - Flush Data To Disk File
* GETDEV   - Get Device Number
* GET_CHNL - Get Disk Channel Number
* IFOPEN   - Open File With Unused Channel
* KILL     - Delete A File Or Message
* LOCK     - Set File Read Only
* MARK     - Get Or Set Disk File Mark
* NAME     - Rename A File
* OPEN     - Open A File
* POSITION - Set Position Into Disk File
* READ     - Read Data From Device
* RECALL   - Recall Variables From Disk File
* SIZE     - Get Size Of Disk File
* SSYSTEMP - set system prefix and temp file name
* STORE    - Store Variables In Disk File
* SYSRCAL  - Recall Variables From System Temp
* SYSSTORE - Store variables in system temp
* TYPE     - Display A Disk File
* UNCOMP   - Un-Compress Variables
* UNLOCK   - Set File Read/Write/Delete/Rename
* WRITE    - Write Data To Device
* EXIT     - Exit from LLUCE
*===============================

*===============================
*   Name: CREATE - Create A File
*
*  Input: Program Pointer
*
* Output: None
*===============================

CREATE      JSR    MOVNAME                      ; Get Filename
            LDY    #Txt                         ; Make A TXT File
            IFEQ   (PRGPTR);#','+Hibit;MAKE0    ; Different Type??

            LDA    #0
            TAX
            BRA    MAKE3

MAKE0       JSR    GOBCOM                       ; Eat The Comma
            IFNE   (PRGPTR);#Msg;MAKE1          ; Create Message File?

            JMP    MAKEMSG

MAKE1       JSR    INPNUM8                      ; Get The Filetype
            PHX                                 ; Save It
            LDA    (PRGPTR)                     ; Is There A Subtype Parm?
            TAY
            LDA    #0                           ; Set To 0 In Case None
            TAX
            CPNEY  #','+Hibit;MAKE2             ; no sub type

            JSR    COMNUM16                     ; Get The Subtype
MAKE2       PLY                                 ; Restore The Main Type
MAKE3       JMP    PD_MAKE                      ; Create It

*===============================
*   Name: KILL - Delete A File Or Message
*
*  Input: Program Pointer
*
* Output: None
*===============================

KILL        IFEQ   (PRGPTR);#'#'+Hibit;KILL2A   ; Kill Message?
            JSR    MOVNAME                      ; Get Filename
            JMP    PD_KILL                      ; Delete It

KILL2A      JMP    KILL2

*===============================
*   Name: NAME - Rename A File
*
*  Input: Program Pointer
*
* Output: None
*===============================

NAME        JSR    MOVNAME                      ; Get Original Name
            LD16   #LNBUF
            JSR    FRMFLN
            JSR    COMNAME                      ; Get New Name
            JMP    PD_NAME                      ; Rename It

*===============================
*   Name: EXIST - Test For Existing File
*
*  Input: Program Pointer
*
* Output: None
*===============================

EXIST       JSR    INPSARG                      ; Get The File Name
            LDY    STRLEN
            JSR    MOVNM0                       ; Set Up The File Name
            JSR    PD_GINFO                     ; Get Files Info, Test Error
            LDA    #1
            BCC    EXIST2

            DEC    A
EXIST2      JMP    SVDATA

*===============================
*   Name: UNLOCK - Set File Read/Write/Delete/Rename
*         LOCK   - Set File Read Only
*
*  Input: Program Pointer
*
* Output: None
*===============================

UNLOCK      LDA    #%11100011                   ; Access Bits For Unlock
            SKIP2
LOCK        PUSHA  #%00100001                   ; Access Bits For Lock
            JSR    MOVNAME
            JSR    PD_GINFO
            PULL   ACCESS
            JMP    PD_SINFO

*===============================
*   Name: OPEN - Open A File
*
*  Input: Program Pointer
*
* Output: None
*===============================

OPEN        LDA    (PRGPTR)                     ; What Access?
            TAY
            LDA    #001100011                   ; Full Access, Deny All
            CPEQY  #Readtkn;DO_OPN0             ; Read Only?
            CPNEY  #Writetkn;DO_OPN1            ; Write Only?

            LDA    #%00110010                   ; Deny All, Request Write
            SKIP2
DO_OPN0     PUSHA  #%00010001                   ; Deny Write, Request Read
            JSR    GETBYT
            PLA
            SKIP2
DO_OPN1     MOV    #$00110011;OPENACS           ; Request all, Deny all
            LDX    #'#'+Hibit
            JSR    GOBBLE                       ; Gobble "#"
            JSR    INPNUM8                      ; Get Channel To Open
            DBMI   X;DO_OPN8

            STX    TEMP2                        ; Save Buffer Number
            CPGEX  #ioFile3;DO_OPN8             ; In Range?

            LDMI   DEVUSE+1,X;DO_OPN9           ; See If Channel In Use

            JSR    COMNAME                      ; Move File Name
            LDY    TEMP2                        ; Get Buffer Number
            LDA    OPENACS
            JSR    PD_BOPEN                     ; Open The File
            LDX    TEMP2
            BCS    DO_OPN4                      ; No Error

            LDA    REFNUM
            SKIP2
DO_OPN4     MOV    #0;REFTAB,X                  ; Open Failed, Return A 0
            BCS    DO_OPN7

            DEC    DEVUSE+1,X                   ; Put "In Use"
DO_OPN7     RTS

DO_OPN8     JMP    BADDEV                       ; Bad Device Number

DO_OPN9     JMP    BADNAME

*===============================
*   Name: IFOPEN - Open File With Unused Channel
*
*  Input: A - Access Mode
*
* Output: Y - Channel Number
*===============================

IFOPEN      STA    OPENACS                      ; Save Open Mode
            LDY    #0
            LDX    #3
IFOPEN2     LDPL   DEVUSE+1,Y;IFOPEN3           ; Try all channels
            INY
            DBNE   X;IFOPEN2
            SEC                                 ; Opps, Couldnt Open
            RTS

IFOPEN3     LDA    OPENACS
            JMP    PD_BOPEN                     ; Open File

*===============================
*   Name: DISKIN1 - Input From File 1
*         DISKIN2 - Input From File 2
*         DISKIN3 - Input From File 3
*
*  Input: None
*
* Output: Char From File
*===============================

DISKIN1     PHX
            LDRAX  #ioFile1-1;DISKINX           ; Use Channel 1
DISKIN2     PHX
            LDRAX  #ioFile2-1;DISKINX           ; Use Channel 2
DISKIN3     PHX
            LDX    #ioFile3-1                   ; Use Channel 3
DISKINX     MOV    REFTAB,X;REFNUM
            JSR    PD_RDBYT
            PLX
            RTS

*===============================
*   Name: READ - Read Data From Device
*
*  Input: Program Pointer
*
* Output: None
*===============================

READ        JSR    DEVIVSET                     ; point to vector
            JSR    RWPTRS
READLOOP    JSR    DO_INP                       ; Read Data Into Memory
            STA    (TEMP2)
            JSR    COUNTUP
            BNE    READLOOP

            RTS

*===============================
*   Name: RECALL - Recall Variables From Disk File
*
*  Input: Program Pointer
*
* Output: None
*===============================

RECALL      JSR    CL3NAME                      ; Close files, get filename
RECALLIT    LDA    #%00110011                   ; Request All, Deny All
            JSR    PD_OPEN
            BCC    RCALL2                       ; All Is Fine

            JMP    BADNAME

RCALL2      JSR    CLRSMT

            MOVD   HIMEM;TEMP                   ; point to top of var space

RCALL3      SEC                                 ; source -= 8
            SB     TEMP;#vRecSize;TEMP
            BCS    RCALL4
            DEC    TEMP+1

RCALL4      LD16   TEMP
            LDY    #vRecSize
            JSR    PD_RBYTS

            LDEQ   (TEMP);RCALL5                ; end of variables?
            BPL    RCALL3                       ; its a number, get next

            LDY    #valOffs+1                   ; Where is it located?
            PUSHA  (TEMP),Y                     ; get location of variable
            INY
            LDA    (TEMP),Y                     ; and length
            TAY
            PLA
            CPGE   #>ENDMOD;RCALL3              ; in high memory?

            PHY
            LD16   VARSTR
            JSR    PD_RBYTS
            LDY    #valOffs
            MOV    VARSTR;(TEMP),Y
            INY
            MOV    VARSTR+1;(TEMP),Y

            CLC
            PLA
            ADA    VARSTR;VARSTR
            BCC    RCALL3
            IBRA   VARSTR+1;RCALL3

RCALL5      JSR    PD_CLOSE

            SEC
            LDA    VARSTR+1
            JMP    FIX_MID2

*===============================
*   Name: SYSRCAL - Recall Variables From System Temp
*
*  Input: None
*
* Output: None
*===============================

SYSRCAL     JSR    SSYSTEMP                     ; open system temp
            JSR    RECALLIT                     ; recall variables
            JMP    OVDONE                       ; reset back to prefix

*===============================
*   Name: DSKOUT1 - Send Character To File 1
*         DSKOUT2 - Send Character To File 2
*         DSKOUT3 - Send Character To File 3
*
*  Input: A - Character
*
* Output: None
*===============================

DSKOUT1     PHX
            LDRAX  #ioFile1-1;DSKOUTX           ; Use Channel 1
DSKOUT2     PHX
            LDRAX  #ioFile2-1;DSKOUTX           ; Use Channel 2
DSKOUT3     PHX
            LDX    #ioFile3-1                   ; Use Channel 3
DSKOUTX     PHA
            MOV    REFTAB,X;REFNUM
            PLA
            JSR    PD_WRBYT
            PLX
            BCS    WRERR

            RTS

WRERR       JMP    BADWRITE

*===============================
*   Name: WRITE - Write Data To Device
*
*  Input: Program Pointer
*
* Output: None
*===============================

WRITE       JSR    DEVOVSET                     ; set up vectors
            JSR    RWPTRS
WRITELUP    LDA    (TEMP2)                      ; Write Data
            JSR    DO_OUT
            JSR    COUNTUP
            BNE    WRITELUP

            RTS

*===============================
*   Name: STORE - Store Variables In Disk File
*
*  Input: Program Pointer
*
* Output: None
*===============================

STORE       JSR    CL3NAME                      ; Close files, move filename
STOREIT     LDY    #^overlays                   ; Compressed Data
            LD16   #overlays                    ; aux file type ($8002)
            JSR    PD_MAKE                      ; Create File
            LDA    #%00000011                   ; Request All, Deny All
            JSR    PD_OPEN                      ; Open File

            MOVD   HIMEM;TEMP                   ; point to top of variable space

STORE2      SEC                                 ; source -= 8
            SB     TEMP;#vRecSize;TEMP
            BCS    STORE3
            DEC    TEMP+1

STORE3      LDEQ   (TEMP);STORE5                ; end of variables?
            BMI    STORE4                       ; go handle strings

            LDY    #valOffs                     ; Is the value 0?
            LDA    (TEMP),Y
            INY
            ORA    (TEMP),Y
            INY
            ORA    (TEMP),Y
            BEQ    STORE2                       ; yes, skip it
            JSR    STORE6
            BRA    STORE2                       ; no, do next one

STORE4      LDY    #valOffs+2                   ; any string allocated?
            LDEQ   (TEMP),Y;STORE2

            JSR    STORE6
            LDY    #valOffs                     ; Where is it located?
            LDA    (TEMP),Y                     ; get location of variable
            TAX
            INY
            PUSHA  (TEMP),Y
            INY
            LDA    (TEMP),Y                     ; and length
            TAY
            PLA
            CPGE   #>ENDMOD;STORE2              ; in high memory?

            JSR    PD_WBYTS
            BRA    STORE2

STORE5      JSR    STORE6
            JMP    PD_CLOSE

STORE6      LD16   TEMP
            LDY    #vRecSize
            JMP    PD_WBYTS

*===============================
*   Name: SYSSTORE - Store variables in system temp
*
*  Input: None
*
* Output: None
*===============================

SYSSTORE    JSR    SSYSTEMP                     ; open system temp
            JSR    STOREIT                      ; recall variables
            JMP    OVDONE                       ; reset back to prefix

SSYSTEMP    JSR    SETSYSTM                     ; Point to system prefix
            MOV    #STEMPLEN;STRLEN             ; Length of filename
            MOVD   #SYSTEMP;STRLOC              ; Point to temp name
            JMP    MOVNM0                       ; Move name to buffer

SYSTEMP     ASC    'SYSTEMP'
STEMPLEN    =      *-SYSTEMP

*===============================
*   Name: CLOSE - Close A Disk File
*         FLUSH - Flush Data To Disk File
*
*  Input: Program Pointer
*
* Output: None
*===============================

CLOSE       SEC
            SKIPCC
FLUSH       CLC
            PHP
            JSR    GETDEV                       ; Get Device
            CPEQX  #ioBoth;DO_CLFL              ; None? (Or Dev0), close all
            CPNEX  #ioMsg;CLFL2                 ; Message File?

            PLP                                 ; Close Of Flush?
            PHP
            BCC    OK6                          ; Flush, Its Ok

            PLP                                 ; Close Is Not Allowed
            JMP    GETDEV2

OK6         LDRA   MSGREF;CF_FLUSH              ; Do The Flush

CLFL2       JSR    CHKDSK                       ; Make sure its a file
            TYA
            TAX                                 ; X = Y
            STZ    DEVUSE+1,X                   ; "Un Use" It
            LDEQ   REFTAB,X;CF_DONE             ; Get Refnum, not open

            STA    REFNUM
            PLP
            BCC    CF_FLUSH

            JMP    PD_CLOSE                     ; Close The Correct File(S)

CF_FLUSH    JMP    PD_FLUSH

CF_DONE     PLP
            RTS

*===============================
*   Name: DO_CLFL - Close Or Flush All Disk Files
*         DO_CL3  - Close All Disk Files
*
*  Input: Program Pointer
*         C = 0: Flush
*         C = 1: Close
*
* Output: None
*===============================

DO_CLFL     PLP
            BRA    CLFL

DO_CL3      SEC
CLFL        PHP
            LDX    #ioFile3-1                   ; Check Channel 3
DO_CL1      LDPL   DEVUSE+1,X;DO_CL4
            LDEQ   REFTAB,X;DO_CL4              ; Close Channel, not open

            STA    REFNUM
            PLP
            PHP                                 ; Close Or Flush?
            BCC    DO_FL                        ; Flush

            JSR    PD_CLOSE
            BRA    DO_CL4

DO_FL       JSR    PD_FLUSH
DO_CL4      DBPL   X;DO_CL1                     ; Next Lower Channel

            PLP                                 ; Close Or Flush?
            PHP
            BCC    DO_CL6                       ; Flush, Dont Flag Channels

            STZ    DEVUSE+1                     ; Close All Channels
            STZ    DEVUSE+2
            STZ    DEVUSE+3
DO_CL6      PLP
            BCS    CL6_DONE                     ; Close, Ignore Msg File

            MOV    MSGREF;REFNUM
            JMP    PD_FLUSH

CL6_DONE    RTS

*===============================
*   Name: MARK - Get Or Set Disk File Mark
*
*  Input: Program Pointer
*
* Output: None
*===============================

MARK        CLC                                 ; Ram Drive Allowed
            JSR    GET_CHNL                     ; Get Channel Number
            CPEQX  #ioRamDsk;DO_MRK5            ; Ram Drive?

            LDPL   DEVUSE,X;DO_MRK3             ; Not Current In Use
            TSTPL  IMMDEF;DO_MRK2               ; See If Mark Was Execed

            JSR    EQUNUM
            JMP    PD_SPOS

DO_MRK2     JSR    PD_GMARK                     ; Get The Mark
            BCC    DO_MRK4                      ; All Is Well

DO_MRK3     LDA    #1                           ; Error
            JMP    SVDATA

DO_MRK4     JMP    DO_MATH                      ; Return Location

DO_MRK5     TSTPL  IMMDEF;DO_MRK6               ; Did They Exec Command?

            JSR    EQUNUM8                      ; Get Pointer
            STX    RAMPTR                       ; Save
            RTS

DO_MRK6     LDA    RAMPTR                       ; Return Pointer
            JMP    SVDATA

*===============================
*   Name: POSITION - Set Position Into Disk File
*
*  Input: Program Pointer
*
* Output: None
*===============================

POSITION    JSR    DEVCKDSK                     ; Get device, make sure its a file
            MOV    REFTAB,Y;REFNUM              ; Save The Reference Number
            JSR    INPNUM16                     ; Get Record Length
            ST16   FLPOS                        ; Save Rec Length
            JSR    COMNUM16                     ; Get Record Number
            ST16   FLPOS+2                      ; Save Rec Number
            STZ    FLPOS+4                      ; Default Offset To 0
            IFNE   (PRGPTR);#','+Hibit;DO_POS2  ; Check For Last Arg...

            JSR    COMNUM8
            STX    FLPOS+4                      ; Save Byte Offset
DO_POS2     MOVD   FLPOS;NUMB                   ; Setup For Multiply
            STZ    NUMB+2
            MOVD   FLPOS+2;DATA+1
            STZ    DATA+3
            JSR    DO_MUL0
            CLC
            LDA    RESULT
            ADC    FLPOS+4
            TAX                                 ; Save Low (X)
            LDA    RESULT+1
            ADC    #0                           ; Compute Med (A)
            PHA
            LDA    RESULT+2                     ; Get High (Y)
            ADC    #0
            TAY
            PLA
            JMP    PD_SPOS

*===============================
*   Name: APPEND - Append To A Disk File
*
*  Input: Program Pointer
*
* Output: None
*===============================

APPEND      JSR    DEVCKDSK                     ; Get device, make sure its a file
            MOV    REFTAB,Y;REFNUM              ; Get Refnum
            JMP    PD_APEND                     ; Append To File

*===============================
*   Name: SIZE - Get Size Of Disk File
*
*  Input: Program Pointer
*
* Output: None
*===============================

SIZE        SEC                                 ; No Ram Drive
            JSR    GET_CHNL                     ; Get Channel Number
            JSR    PD_GEOF                      ; Get The File Size
            JMP    DO_MATH

*===============================
*   Name: EOF - Check For Disk File End
*
*  Input: Program Pointer
*
* Output: None
*===============================

EOF         SEC                                 ; No Ram Drive
            JSR    GET_CHNL                     ; Get Channel Number
            JSR    PD_CKEOF                     ; Check For EOF
            TXA
            JMP    SVDATA                       ; Return Results

*===============================
*   Name: RELOAD - Reloads current segment or another
*
*  Input: A = Reload flags
*             No bits, start from segment start
*             Bit 7, continue from current PC
*
*         STACK
*   PC -> RTS            Word
*         NAMELENGTH     Byte
*         FILENAME       Pointer (Word)
*         LABELLENGTH    Byte
*         LABELNAME      Pointer (Word)
*
* Output: None
*===============================

RELOAD      STA    IMMDEF                       ; save load type
            PULLW  TEMP                         ; save return address
            PULL   STRLEN                       ; get filename info
            PULLW  STRLOC
            JSR    FIXFLAG
            JSR    MOVNM0                       ; move in name (if any)
            BNE    HADNAME                      ; name was supplied

            LD16   #SEGSAVE                     ; Restore last segment
            JSR    TOFLN                        ; name

HADNAME     PULL   STRLEN                       ; get link label (if any)
            PULLW  STRLOC
            JSR    FIXFLAG
            BRA    LINK1

FIXFLAG     ORA    STRLOC
            BEQ    FLAGFIXD
            STZ    IMMDEF
FLAGFIXD    RTS

*===============================
*   Name: CHAIN - Chain To Another Program Segment
*
*  Input: Program Pointer
*
* Output: None
*===============================

CHAIN       STZ    NOCDFLG
            STZ    ONERRFLG
            STZ    IMMDEF                       ; set to begin at start
            STZ    LNKLBL                       ; Def To No Link Label

            JSR    PD_GPFX                      ; Get Current Prefix
            LD16   #SEGSAVE                     ; Save segment prefix
            JSR    FRMFLN                       ; for later reload

            JSR    CL3NAME                      ; Close files, move filename

            JSR    SAVESEG

            IFNE   (PRGPTR);#','+Hibit;LINK4    ; Check For Link Label

            JSR    GOBCOM
            JSR    INPSTR                       ; Get Link Label

* Reload enters here

LINK1       STZ    LNKLBL                       ; Def To No Link Label
            LDEQ   STRLEN;LINK4                 ; skip if empty
            LDY    #0
LINK2       LDA    (STRLOC),Y                   ; Copy Label Name
            JSR    CONV
            INY
            CPNEY  STRLEN;LINK3                 ; Is This The Last Char?

            ORA    #Hibit
LINK3       STA    LNKLBL-1,Y                   ; Save Char
            CPNEY  #8;LINK2

            ORA    #Hibit                       ; Mark Last Char
            STA    LNKLBL-1,Y
LINK4       JSR    COMPRES                      ; Compress Variables
            JSR    LD_MOD                       ; Load In Module
            BCC    LINK_OK

            LDA    #Modulenf
            JMP    BADERR

LINK_OK     JSR    UNCOMP                       ; Un-Compress Variables
            TSTMI  IMMDEF;LINK4A                ; leave pointers?
            MOVD   MODULE;PRGPTR                ; were finally done!
LINK4A      LDEQ   LNKLBL;LINK9                 ; Link To A Label?

            LDX    #$80                         ; Start Table Pointer
LINK5       LDY    #0                           ; Start String Pointer
LINK6       LDEQ   LNBUF,X;LINK8                ; Get First Char
            INX
            CPNE   LNKLBL,Y;LINK7               ; Check It

            INY
            ASL    A                            ; Are We Done?
            BCC    LINK6                        ; Nope, Keep Checking

            TXA
            AND    #%11110000                   ; Round Down X
            TAX
            MOV    LNBUF+8,X;PRGPTR             ; Get Address And Save
            MOV    LNBUF+9,X;PRGPTR+1
LINK9       JMP    ERRENT                       ; Return

LINK7       TXA                                 ; Round Down X
            AND    #%11110000
            CLC
            ADC    #$10                         ; Go To Next Label
            TAX
            BCC    LINK5                        ; Keep Going If More Data

LINK8       LDA    #Linknf                      ; Link Label Not Found
            JMP    BADERR

SAVESEG     LDX    #0                           ; Save segment name for
            LDY    SEGSAVE
PUTSEGNM    MOV    FLNAME+1,X;SEGSAVE+1,Y       ; later reload
            INY
            INX
            CPNEX  FLNAME;PUTSEGNM
            STY    SEGSAVE
            RTS

*===============================
*   Name: COPY - Copy Data From Device To Device
*
*  Input: Program Pointer
*
* Output: None
*===============================

COPY        STZ    SHW_CNT                      ; Reset Line Count
            IFNE   (PRGPTR);#'('+Hibit;SHOW0A   ; check for # of lines

            JSR    INPNARG8                     ; Get Argument
            STX    SHW_CNT                      ; Save Count
SHOW0A      JSR    DEVIVSET                     ; Get source, save vector
            STY    SHWIN
            MOV    REFTAB-1,Y;REFNUM            ; Save Possible Refnum
            TYA
            BNE    SHOW0                        ; If Using Device, Skip

            JSR    MOVNAME                      ; Get Filename
SHOW0       IFNE   (PRGPTR);#','+Hibit;SHOW1

            JSR    GOBCOM                       ; Gobble
SHOW1       JSR    DEVOVSET                     ; save output vectors
            STY    SHWOUT
            IFGE   SHWIN;#ioFile3+1;SHOW3       ; get input device
            CPNE   #ioBoth;SHOW2                ; Is File Open?

            STZ    LNBUF
            LDA    #%00100001                   ; Deny Write, Request Read
            JSR    PD_OPEN                      ; Open The File
            BCS    SHWRTS                       ; Done

SHOW2       JSR    PD_NEWLN                     ; Setup For Rdline
            MOV    REFNUM;SHWREF                ; Save Refnum

*-------------------------------
* Input Line Of Data From A Disk File
*-------------------------------

SHOW3       TSTMI  XTERNAL;SHOW3X               ; Use External?

            IFGE   SHWIN;#ioFile3+1;SHOW3A      ; Char Device?

SHOW3X      MOV    SHWREF;REFNUM                ; Make Sure Refnum Is Valid
            LD16   #LNBUF                       ; Read up to 256 characters
            LDY    #2
            JSR    PD_RDBLK
            BCS    SHOW5                        ; Opps, End Of Data

SHWRTS      BRA    SHOW4

*-------------------------------
* Input A Line Of Data From A Character Device
*-------------------------------

SHOW3A      LDX    #0                           ; Start Pointer
SHOW3B      PHX
            JSR    DO_INP                       ; Get Data
            CPNE   #eot;SHOW3C                  ; End Of Section?

            LDA    #0                           ; Mark It
SHOW3C      STA    LNBUF,X                      ; Save
            TAY
            PLX
            INX
            CPEQY  #0;SHOW4                     ; Are We Done?
            CPNEY  #cr;SHOW3B                   ; End Of Line?

*-------------------------------
* Check For And Handle ".X" External
*-------------------------------

            IFEQ   SHWOUT;#ioEditor;SHOW4       ; is it to the CRT?

            LDA    LNBUF                        ; Is It A Dot?
            AND    #Clrhi
            CPNE   #'.';SHOW4
            LDA    LNBUF+1                      ; Check For "X"
            JSR    CONV
            CPNE   #'X';SHOW4
            LDA    LNBUF+2                      ; Is It A Space?
            AND    #Clrhi
            CPNE   #' ';SHOW4

            JSR    EXTERN                       ; Set Up External File
            TSTMI  XTERNAL;SHOW2                ; ok, file is open

*-------------------------------
* Output A Line Of Data To A Device
*-------------------------------

SHOW4       LDX    #0                           ; Start Pointer
SHOW4A      STX    SHOW_X
            LDEQ   LNBUF,X;SHOW5                ; Get Data, done with file

            CPNE   #lf;DOIT                     ; Strip All LFs
            CPEQX  #0;SHOW4B                    ; From Start Of Line

DOIT        PHA
            JSR    DO_OUT                       ; Output It
            PLA
SHOW4B      LDX    SHOW_X                       ; Get Back Pointer
            IBEQ   X;SHOW4C                     ; keep from locking up
            CPNE   #cr;SHOW4A                   ; Done With Line?

*-------------------------------
* Handle End Of Line Of Output
*-------------------------------

SHOW4C      LDEQ   SHW_CNT;SHOW4D               ; Is There A Line Limit?
            DBEQ   SHW_CNT;SHOW5                ; Count Down Lines

SHOW4D      IFEQ   SHWIN;#ioMail;JSHOW3         ; is this a read mail?
            LDNE   SHWOUT;JSHOW3                ; Is Output To The CRT?
            TSTPL  INTOUT;JSHOW3                ; Stop Output?

*-------------------------------
* Handle End Of Output And Return
*-------------------------------

SHOW5       TSTMI  XTERNAL;SHOW5B               ; External On?, close it
            LDNE   SHWIN;SHOW6                  ; Is This From A Disk File?

SHOW5B      MOV    SHWREF;REFNUM                ; Get Correct Refnum
            JSR    PD_CLOSE                     ; Close File
            TSTPL  XTERNAL;SHOW6

            INC    XTERNAL                      ; Turn Off Extrnal
JSHOW3      JMP    SHOW3                        ; And Continue

SHOW6       IFLT   SHWOUT;#ioLocal+1;EXTERN2    ; Console, Disk 1, 2 Or 3?

            LDA    #0                           ; Were Finished
            JMP    DO_OUT

EXTERN      MOVD   #LNBUF+3;STRLOC              ; Point To Filename
            MOV    #19;STRLEN                   ; Save Max String Length
            JSR    MOVNM0                       ; Move The Filename
            LDA    #%00100001                   ; Deny Write, Request Read
            JSR    IFOPEN                       ; Open File
            BCS    EXTERN2                      ; Opps, File Didnt Open

            DEC    XTERNAL                      ; Flag External Read On
EXTERN2     RTS

*===============================
*   Name: TYPE - Display A Disk File
*
*  Input: Program Pointer
*
* Output: None
*===============================

TYPE        JSR    MOVNAME                      ; Set Up Path/File Name
            JSR    PD_GINFO
            IFNE   (PRGPTR);#','+Hibit;TO_DEV

            JSR    GOBCOM
TO_DEV      JSR    DEVOVSET
            LDA    #%00100001                   ; Deny Write, Request Read
            JSR    PD_OPEN                      ; Open The File
            BCS    NOFILE                       ; No File Found

            IFEQ   FILETYPE;#Awp;AWPRNT         ; File Type AWP
            CPEQ   #Txt;STDFILE                 ; File Type TXT
            CPNE   #Src;TYPE_FIN                ; File Type SRC

STDFILE     LDX    #vidWidth-1                  ; Clear Out The Buffer
ZLNB        STZ    LNBUF,X
            DBPL   X;ZLNB

            LDA    #vidWidth                    ; Line Length Is 80 Max
            JSR    PD_TREAD                     ; Read In The Line
            BCS    TYPE_FIN                     ; Close If Error

            TSTMI  INTOUT;TYPE_FIN              ; Interrupted?

            LDX    #0                           ; Show The Line
TYPE_PR     LDEQ   LNBUF,X;TYPE_FIN

            JSR    COUTLO
            INX
            CPNEX  #vidWidth;TYPE_PR
            BEQ    STDFILE                      ; CHANGE TO BRA LATER

NOFILE      RTS

AWERR       JSR    CROUT
TYPE_FIN    JMP    PD_CLOSE

AWPRNT      LD16   #300
            JSR    PD_SMARK
AWLOOP      LDA    #2                           ; Read In 2 Bytes
            JSR    PD_TREAD
            BCS    AWERR

            TSTMI  INTOUT;TYPE_FIN

            IFNE   LNBUF+1;#$D0;XLNEXT

            JSR    CROUT
            BRA    AWLOOP

XLNEXT      LDA    #$D1
            BCS    AWTSTEND

            LDA    #2                           ; Read Line Size
            JSR    PD_TREAD
            BCS    AWERR

            LDA    LNBUF+1
            AND    #Clrhi
            STA    SHW_CNT
            JSR    PD_TREAD                     ; Read The Line
            BCS    AWERR

            LDX    #0
PRINTAW     LDA    LNBUF,X                      ; Show The Line
            AND    #Clrhi
            CPLT   #' ';CTRLSKP

            JSR    COUT
CTRLSKP     INX
            CPNEX  SHW_CNT;PRINTAW              ; End Of Line?

            JSR    CROUT                        ; CR At End Of Line
            BRA    AWLOOP

AWTSTEND    IFEQ   LNBUF+1;#$FF;TYPE_FIN        ; End Of File?
            BNE    AWLOOP                       ; CHANGE TO BRA LATER

*===============================
*   Name: GETDEV - Get Device Number
*
*  Input: Program Pointer
*
* Output: Y = Channel Number
*         X = Channel Index
*===============================

GETDEV      LDX    #0
            LDY    #0
            IFNE   (PRGPTR);#'#'+Hibit;GETDEV1  ; Device Indicator?

            JSR    GETBYT                       ; Gobble #
            STZ    DEVCLR                       ; Reset Device Byte
            IFEQ   (PRGPTR);#Msg;GETMSG         ; Check For Message

            JSR    INPNUM8
            TSTMI  MSGINIT;GETMSG2              ; Is Channel 7 Setup?
            CPEQX  #ioMsg;GETDEV2               ; Trying To Use Channel 7?

GETMSG2     IFNE   (PRGPTR);#','+Hibit;GETDEV0

            JSR    GETBYT                       ; Gobble Comma
GETDEV0     LDPL   DEVUSE,X;GETDEV2             ; Is Channel In Use
            TXA
            TAY                                 ; Y = X
            ASL    A                            ; X = X * 2
            TAX
GETDEV1     RTS

GETMSG      JSR    GETBYT                       ; Gobble
            JSR    INPNUM16                     ; Get Msg Number
            ST16   MSGNUM                       ; Save
            STZ    MSGINIT                      ; Init Message
            LDRAX  #ioMsg;GETMSG2               ; Return Channel

GETDEV2     JMP    BADDEV

DEVCKDSK    JSR    GETDEV
; Make Sure Device Is A File
CHKDSK      DEY
            CPGEY  #ioFile3;GETDEV2             ; If Its Not A File...
            RTS

*===============================
*   Name: GET_CHNL - Get Disk Channel Number
*
*  Input: Program Pointer
*
* Output: X = Channel Number
*===============================

GET_CHNL    PHP
            JSR    INPNARG8                     ; Get Channel Number
            PLP
            BCS    CHNL_OK

            CPEQX  #ioRamDsk;CHNLDONE           ; Ram Drive?
CHNL_OK     CPEQX  #ioBoth;GETDEV2              ; No Channel 0
            CPGEX  #ioFile3+1;GETDEV2           ; Must Be Less Than 3
            MOV    REFTAB-1,X;REFNUM
CHNLDONE    RTS

*===============================
*   Name: COMPRES - Compress Variables
*
*  Input: Program Pointer
*
* Output: None
*===============================

COMPRES     STZ    SETRAM1                      ; Switch In Subs
            JSR    COMPRES2
            BRA    DRAM5

*===============================
*   Name: UNCOMP - Un-Compress Variables
*
*  Input: Program Pointer
*
* Output: None
*===============================

UNCOMP      STZ    SETRAM1                      ; Switch In Subs
            JSR    UNCOMP2
DRAM5       STZ    SETRAM2                      ; Switch Out Subs
            RTS

*===============================
*   Name: EXIT - Exit from LLUCE
*===============================

EXIT        JSR    INPTYP                       ; Get next byte type
            BEQ    DO_EXIT                      ; if end of line or statement

            JSR    MOVNAME                      ; Get the pathname

            MOV    #$EE;QUIT_TYP                ; flag as extended quit

            MOVD   #FLNAME;QUITPATH             ; point to the path

DO_EXIT     JMP    PD_QUIT                      ; do the quit
            LST    OFF

