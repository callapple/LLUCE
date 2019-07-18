            LST    RTN
            TTL    'LLUCE - Segment Loader'
            PAG
*===============================
* Contents:
*
* LD_MOD   - Load module into memory
* LOADOV   - Open and test overlay
* LOADOV0  - Load compiler or editor overlay
* LOGSYS   - Set to system prefix
* MOVMAME  - Move filename from program
* MOVNM0   - Move filename from pointer
* OVDONE   - Restore saved prefix
* OVERLAY  - Load overlay if not loaded
* PREFIX   - Get or set prefix
* SETSYSTM - Save prefix, log to system
*===============================

*===============================
*   Name: LD_MOD - Load Module Into Memory
*
*  Input: None
*
* Output: C = 0: Load Successful
*         C = 1: Unsuccessful Load
*===============================

LD_MOD      TSX                                    ; Save Stack Pointer
            STX    EDSTACK
            STZ    NOSOURCE                        ; Reset Source Flag
            IFLTX  FLNAME;#62;LD_MOD0              ; Room For .C Or .S?

            LDA    #Badfn
            JMP    BADERR                          ; Too Long!

LD_MOD0     INX
            MOV    #'.';FLNAME,X                   ; Tack On .S Extension
            INX
            STX    FLNAME                          ; Fix Name Length
            MOV    #'S';FLNAME,X
            JSR    PD_GINFO                        ; If An Error Here,
            LDX    FLNAME
            MOV    #'C';FLNAME,X
            BCC    TST_DATE
            DBRA   NOSOURCE;LOAD0B                 ; Flag Source Not Available

TST_DATE    MOVD   MOD_DATE;TEMP
            MOVD   MOD_TIME;TEMP2
            JSR    PD_GINFO                        ; If An Error Here,
            IFLT   TEMP+1;MOD_DATE+1;LOAD0B
            BNE    KILLSEG
            IFLT   TEMP;MOD_DATE;LOAD0B
            BNE    KILLSEG
            IFLT   TEMP2+1;MOD_TIME+1;LOAD0B
            BNE    KILLSEG
            IFLT   TEMP2;MOD_TIME;LOAD0B
KILLSEG     JSR    PD_KILL

LOAD0B      LDA    #%00100001                      ; Deny Write, Request Read
            JSR    PD_OPEN                         ; Compiled Module Available?
            BCS    LD_MOD2                         ; Nope

            PUSHA  MSGREF                          ; Save Msg Refnum
            MOV    REFNUM;MSGREF
            LD16   #LNBUF+$80                      ; Read Label Info
            JSR    PD_RBLK1
            MOVD   LNBUF+142;LOMEM                 ; Set Up Variable Space
            LD16   MODULE                          ; Read In Rest Of Module
            LDY    #$80
            JSR    PD_RDBLK
            BCS    NO_LD

            JSR    PD_CLOSE
            PULL   MSGREF                          ; Restore Msg Refnum
            IFNE   LNBUF+138;MODULE;LD_MOD2        ; load address ok?
            IFNE   LNBUF+139;MODULE+1;LD_MOD2
            IFNE   LNBUF+140;#'L';LD_MOD2          ; ID bytes ok?
            IFNE   LNBUF+141;#'P';LD_MOD2
            IFNE   LNBUF+254;VERSION;LD_MOD2       ; version ok?
            IFNE   LNBUF+255;VERSION+1;LD_MOD2
            CLC
NO_LD       LDX    EDSTACK                         ; Reset Stack Pointer
            TXS
            RTS                                    ; And We Are Done!

*===============================
* Go And Compile The Segment
*===============================

LD_MOD2     TSTPL  NOSOURCE;SVSEGNM                ; Source Present?
            LDA    #Modulenf
            JMP    BADERR

SVSEGNM     LD16   #FLNSV
            JSR    FRMFLN

            LDA    #Compiler
            JSR    TST_OVR

            LD16   #FLNSV                          ; Get back segment name
            JSR    TOFLN

            IFNE   OVERBUF+3;VERSION;BADVER        ; check compiler version
            IFEQ   OVERBUF+4;VERSION+1;VER_OK

BADVER      LDA    #Badver                         ; Do Error
            JMP    BADERR

VER_OK      JSR    OVERBUF                         ; Compile It
            CLC
            BRA    NO_LD

*===============================
*   Name: MOVMAME - Move Filename From Program
*         MOVNM0  - Move Filename From Pointer
*
*  Input: Program Pointer Or String Pointer
*
* Output: None
*===============================

COMNAME     JSR    GOBCOM
            BRA    MOVNAME

CL3NAME     JSR    DO_CL3
MOVNAME     JSR    INSTR2                          ; Get Name (Dont Use Memory)
MOVNM0      MOVY   STRLEN;FLNAME                   ; Move Length Of Filename
            BEQ    NAMEOK                          ; If No Name, Return

CHKSYN      DBMI   Y;NAMEOK

            IFEQ   (STRLOC),Y;#'.';SYN_FRST        ; Is it a ., cant be first
            CPEQ   #'/';SYN_SEP                    ; Is it a separator?
            CPEQ   #'\';SYN_SEP
            CPEQ   #':';SYN_SEP

            JSR    TST_ALF
            BCC    SYN_OK                          ; All letters ok

            JSR    TST_NUM                         ; Numbers ok if not first
            BCC    SYN_FRST

            LDA    #'.'                            ; Invalid char, make '.'
SYN_FRST    CPNEY  #0;SYN_OK                       ; first char?, cant be # of .
            JMP    BADNAME

SYN_SEP     LDA    #'/'
SYN_OK      STA    FLNAME+1,Y                      ; Save it in buffer
            BRA    CHKSYN

*===============================
*   Name: OVERLAY - Load Overlay If Not Loaded
*
*  Input: Program Pointer
*
* Output: None
*===============================

OVERLAY     JSR    SETSYSTM                        ; Point To System Directory
            JSR    MOVNAME                         ; Move In The Name
            STZ    PRN                             ; Allow Any Overlay
            JSR    LOADOV                          ; Load It In
            JMP    OVERBUF                         ; Go To It

*===============================
*   Name: LOADOV0 - Load Compiler Or Editor Overlay
*
*  Input: X, A, Y - Pointer To Overlay Filename
*         PRN     - Overlay Type
*                   0 - Any Type
*                   1 - Compiler
*                   2 - Editor
*
* Output: None
*===============================

LOADOV0     ST16   STRLOC                          ; Save Overlay Name Pointer
            STY    STRLEN
            PUSHA  PRN                             ; Movname Kills PRN If List
            JSR    SETSYSTM                        ; Point To System Directory
            JSR    MOVNM0                          ; Move In The Name
            PULL   PRN
            JSR    LOADOV                          ; Load It In
NAMEOK      RTS

*===============================
*   Name: LOADOV - Open And Test Overlay
*
*  Input: None
*
* Output: None
*===============================

LOADOV      LDA    #%00100001                      ; Deny Write, Request Read
            JSR    IFOPEN                          ; Open The File
            BCS    LDOVERR

            STZ    PRN+1                           ; Zero Checksum
            LDX    #0                              ; Read In The 8 Id Bytes
LDOVLUP1    JSR    PD_RDBYT
            STA    OVIDTEST,X
            INX
            CPLTX  #8;LDOVLUP1

            LDA    #0                              ; Reset Test Counter
            LDX    #0                              ; Check Overlay IDs
LDOVLUP2    EOR    OVIDTEST,X
            INX
            CPLTX  #4;LDOVLUP2

            EOR    #%10100101                      ; And Checksum
            BNE    LDOVERR                         ; Checksum Bad, Error Out

            LDEQ   PRN;OV3                         ; Specific Overlay Type, any
            CPNE   OVIDTEST;LDOVERR                ; Correct Overlay Type?

OV3         LDX    #7                              ; Are They Whats There Now?
CPYID       IFNE   OVIDTEST,X;OVERLYID,X;DOLOADOV  ; nope, load it
            DBPL   X;CPYID

            JSR    OVCRCTST                        ; Check Overlay CRC
            BNE    DOLOADOV
            BRA    OVDONE                          ; Yes, Close It Up

*===============================
* Load In The Overlay
*===============================

DOLOADOV    MOVD   #OVERBUF;TEMP2                  ; Point To Overlay Buffer
            STZ    SAVE_Y                          ; Save First Flag
NXTCHNK     LD16   #LNBUF                          ; Read Next Chunk (If Any)
            LDY    #2                              ; Read 2 - 128 Byte Pages
            JSR    PD_RDBLK
            BCC    DOMOVE                          ; If There, Go Move It

*-------------------------------
* Nothing To Read:
*-------------------------------

            LDNE   SAVE_Y;DONE                     ; First Chunk?

LDOVERR     JSR    OVDONE                          ; Finish With The File
            STZ    ONERRFLG                        ; Cant Trap This One
            JMP    BADEXT

DOMOVE      JSR    MOVEOVER                        ; Move This Chunk
            INC    SAVE_Y                          ; Finished With First Chunk
            BCC    NXTCHNK                         ; Go Read It.

*-------------------------------
* Buffer Full, Fall Through
*-------------------------------

DONE        JSR    OVCRCTST                        ; Check Overlay CRC
            BNE    LDOVERR

            LDX    #7                              ; Save The New Ids
MOVID       MOV    OVIDTEST,X;OVERLYID,X
            DBPL   X;MOVID

OVDONE      JSR    PD_CLOSE                        ; Close Up The File

            LD16   #PFXSAVE                        ; Reset to original prefix
            JSR    TOFLN

            JMP    SET_PFX                         ; Finished

*===============================
* Move Chunk Of Overlay
*===============================

MOVEOVER    MOVD   #LNBUF;TEMP                     ; Point To Buffer
            LDY    #0                              ; Move It All
MVOVLY      MOV    (TEMP),Y;(TEMP2),Y
            IBNE   Y;MVOVLY

            INC    TEMP2+1                         ; Point To Next Page
            LDA    TEMP2+1                         ; Buffer Full?
            CMP    #>OVERBUF+$2000
            RTS

*===============================
* Check Overlay Checksum & Type
*===============================

TST_OVR     STA    PRN
            CPNE   OVERLYID+3;GET_OVR              ; Correct Overlay?

            EOR    OVERLYID+2                      ; Valid Id Bytes?
            EOR    OVERLYID+1
            EOR    #%10100101
            EOR    OVERLYID
            BNE    GET_OVR                         ; No, Load

            JSR    OVCRCTST                        ; Check Overlay CRC
            BNE    GET_OVR

            RTS

*===============================
* Point To Overlay Name
*===============================

GET_OVR     PHXY                                   ; Load In The Editor
            IFNE   PRN;#Editid;GETCOMP             ; Looking For Editor?

            LD16   #EDNAME+1
            LDRAY  EDNAME;DO_OVR

GETCOMP     LD16   #COMPNAME+1
            LDY    COMPNAME
DO_OVR      JSR    LOADOV0                         ; Load It In
            PLXY
            RTS

*===============================
*   Name: SETSYSTM - Save Prefix, Log To System
*
*  Input: None
*
* Output: None
*===============================

SETSYSTM    JSR    PD_GPFX                         ; Get Current Prefix

            LD16   #PFXSAVE                        ; Save for later
            JSR    FRMFLN

            JSR    LOGSYS                          ; Set To The System Prefix

            LD16   #SYSNAME                        ; And add SYSTEM
            JSR    TOFLN
            BRA    SET_PFX                         ; Do It

*===============================
*   Name: LOGSYS - Set To System Prefix
*
*  Input: None
*
* Output: None
*===============================

LOGSYS      LD16   #SYSPFX                         ; Move system prefix
            JSR    TOFLN                           ; to filename buffer

SET_PFX     JSR    PD_SPFX                         ; Go And Set It
            BCC    PFXOK

            LDA    #Badpfx
            JMP    BADERR                          ; Prefix Not There

PFXOK       RTS

*===============================
*   Name: PREFIX - Get Or Set Prefix
*
*  Input: Program Pointer
*
* Output: Prefix/None
*===============================

PREFIX      BCC    GET_PFX                         ; Getting The Prefix

            IFEQ   (PRGPTR);#Chain;LOGSYS          ; is there a prefix?
            CPEQ   #Chain2;LOGSYS

            JSR    MOVNAME                         ; Get The Name
            LDEQ   FLNAME;LOGSYS                   ; Check For Prefix Given
            BRA    SET_PFX                         ; Go And Set It

GET_PFX     JSR    PD_GPFX                         ; Get Current Prefix
            LD16   #FLNAME+1                       ; point to string
            LDY    FLNAME
            JMP    SVSTR

*===============================
* Test Overlay CRC
*===============================

OVCRCTST    MOVD   #OVERBUF;TEMP                   ; Point To Overlay
            MOVD   OVIDTEST+4;TEMP2                ; Get Length To Test
            STZ    CRC
            STZ    CRC+1
OVCRCLUP    LDA    (TEMP)                          ; Add In A Byte
            JSR    ADDCRC
            INCD   TEMP                            ; Bump Pointer Up
            DECD   TEMP2                           ; Bump Counter Down
            DEC    A
            ORA    TEMP2+1
            BNE    OVCRCLUP

            IFNE   OVIDTEST+6;CRC;OVTST3           ; CRCs match?
            LDA    OVIDTEST+7
            CMP    CRC+1
OVTST3      RTS
            LST    OFF

