********************************
*                              *
*    Text compiler             *
*                              *
********************************
* Copyright 1986-1993 By L&L Productions
*-------------------------------
*
* Usage:  OVERLAY "COMP.TXT"[,n]
*
*  If n > 0, write text to memory
*  If n = 0, or not supplied, read text from file
*-------------------------------

Id          =      5
Aux         =      254

            LST    OFF
            LSTDO  OFF
            XC
            TR
            TR     ADR
            EXP    ONLY
Y           =      1
y           =      1
N           =      0
n           =      0
NOLIST      =      Y
            DO     NOLIST
LISTOBJ     =      N
LISTSYM     =      N
            ELSE
LISTOBJ     KBD    'List This Source? (Y/N)'
LISTSYM     KBD    'List Symbol Table? (Y/N)'
            FIN
            LST    OFF
            USE    EQUATES/MACROS
            PUT    EQUATES/EQUATES
            PUT    EQUATES/OS.EQUATES
            PUT    EQUATES/ENTRY
            PUT    EQUATES/DRIVEREQU
            PUT    EQUATES/RAMAREA

]TYPE       =      ^overlays                    ; set file type
]AUX        =      overlays                     ; and aux type
            ORG    ]AUX                         ; must be this way
            TYP    ]TYPE

            DSK    /MAIN/LLUCE/SYSTEM/COMP.TXT

            TTL    'LLUCE - Text compiler'
            DO     LISTOBJ
            LST
            FIN

            DB     Id
            DA     Aux
            DB     Aux/256!Aux!Id!$A5

*-------------------------------
* Size Of Code To Check For CRC
*-------------------------------

            DA     CODEEND-CODESTRT
            DA     0                            ; CRC Goes Here
            LST    OFF
            ORG    $D000

CODESTRT    =      *

            STZ    WHERETO
            IFNE   (PRGPTR);#','+Hibit;USE_DEF

            JSR    GOBCOM
            JSR    INPNUM
            CPEQX  #0;USE_DEF

            DEC    WHERETO
USE_DEF     TSTPL  WHERETO;LOADFILE

            LDX    #0
MOVECODE    MOV    COPYCODE,X;PUTCHAR,X
            DBNE   X;MOVECODE
            BRA    COMP

LOADFILE    JSR    PD_GPFX
            LD16   #OLDPFX
            JSR    FRMFLN
            LD16   #SYSPFX
            JSR    TOFLN
            JSR    PD_SPFX

            LD16   #FILENAME
            JSR    TOFLN
            JSR    IFOPEN
            BCC    COMP

            MOV    #-1;PRN
            RTS

COMP        BRK    00

COMP2       JSR    COPYLINE
            JSR    COMPILE
            BCS    COMPERR
            BNE    COMP2

ENDSEC1     LDA    #>PROGTEXT-ERRMSGS
            JSR    SETPTR

SECTION2    JSR    COPYLINE
            JSR    COMPILE
            BCS    COMPERR
            BNE    SECTION2

ENDSEC2     LDA    #>VIDMSGS-ERRMSGS
            JSR    SETPTR

SECTION3    JSR    COPYLINE
            CPEQX  #0;ENDSEC3

            JSR    INPNUMB
            JSR    WRTCHAR
            JSR    COPYLINE
            JSR    COMPILE
            BCS    COMPERR
            BNE    SECTION3

ENDSEC3     CLC
COMPERR     PHP
            TSTMI  WHERETO;EXIT

            JSR    PD_CLOSE                     ; close the file

            LD16   #OLDPFX                      ; reset the prefix
            JSR    TOFLN
            JSR    PD_SPFX

EXIT        LDA    #0
            PLP
            BCC    EXIT2
            DEC    A
EXIT2       STA    PRN
            RTS

COMPILE     LDX    #0
COMPLUP     LDEQ   LNBUF,X;ERROR
            CPEQ   #'.';TSTEND2
            CPEQ   #'\';HNDLBKSL
CHKENDLN    LDY    LNBUF+1,X
            CPNEY  #cr;STDCHAR
            INX
            ORA    #Hibit
STDCHAR     PHP
            JSR    WRTCHAR
            INX
            PLP
            BPL    COMPLUP
            LDA    #cr
            CLC
            RTS

HNDLBKSL    IFEQ   LNBUF+1,X;#'\';NXTCHAR
            CPLT   #'a';NOTLC
            SBC    #$20
NOTLC       CPLT   #'A';NOTALF
            CPGE   #'_'+1;NOTALF
            SEC
            SBC    #Ctrl
NXTCHAR     IBRA   X;CHKENDLN

NOTALF      CPNE   #'?';ESCBAD
            LDA    #$7F
            BRA    NXTCHAR

ESCBAD      LDA    #'\'
            BRA    STDCHAR

TSTEND2     LDY    LNBUF+1,X
            CPNEY  #cr;STDCHAR
            LDA    #0
            JSR    WRTCHAR
            JSR    WRTCHAR
            LDA    #0
            CLC
            RTS

ERROR       SEC
            RTS

INPNUMB     STZ    TEMP

            LDX    #0

NUMBER2     IFLT   LNBUF,X;#'0';NUMBER5         ; is it a number?
            CPGE   #'9'+1;NUMBER5
            AND    #LoNibble
            PHA
            LDA    TEMP
            ASL    A
            ASL    A
            CLC
            ADC    TEMP
            ASL    A
            STA    TEMP
            CLC
            PLA
            ADC    TEMP
            STA    TEMP
            IBRA   X;NUMBER2

NUMBER5     LDA    TEMP
            RTS

COPYLINE    LDX    #0
COPYLUP     JSR    EDIN
            STA    LNBUF,X
            TAY
            BEQ    CPYDONE
            INX
            CPNE   #cr;COPYLUP
CPYDONE     RTS

WRTCHAR     TSTPL  WHERETO;WRFILE
            JMP    PUTCHAR

WRFILE      JMP    PD_WRBYT

SETPTR      TSTPL  WHERETO;POSFILE
            JMP    SETPOS

POSFILE     LDX    #0
            LDY    #0
            JMP    PD_SPOS

COPYCODE    ORG    FREESPACE

PUTCHAR     STZ    SETSTDZP                     ; enable message area
            STZ    SETRAM1

TEXTPTR     STA    ERRMSGS                      ; get the byte

            INCD   TEXTPTR+1                    ; increment pointer

            STZ    SETALTZP                     ; put overlay back
            STZ    SETRAM2
            RTS

SETPOS      CLC
            ADC    #>ERRMSGS
            STA    TEXTPTR+2
            STZ    TEXTPTR+1
            RTS

            ORG

CODEEND     =      *

WHERETO     DB     0
FILENAME    STR    'LLUCE.TEXT'
OLDPFX      DS     $40
            LST    OFF
            DO     LISTSYM
            LST
            FIN

