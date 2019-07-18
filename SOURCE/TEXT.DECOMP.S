********************************
*                              *
*    Text decompiler           *
*                              *
********************************
* Copyright 1986-1993 By L&L Productions
*-------------------------------
*
* Usage:  OVERLAY "DECOMP.TXT"[,n]
*
*  If n > 0, read text from memory
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

            DSK    /MAIN/LLUCE/SYSTEM/DECOMP.TXT

            TTL    'LLUCE - Text decompiler'
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

            ORG    $D000

CODESTRT    =      *

            JSR    ED_CLR
            STZ    WHEREFRM
            IFNE   (PRGPTR);#','+Hibit;USE_DEF

            JSR    GOBCOM
            JSR    INPNUM
            CPEQX  #0;USE_DEF

            DEC    WHEREFRM
USE_DEF     TSTPL  WHEREFRM;LOADFILE

            LDX    #0
MOVECODE    MOV    COPYCODE,X;GETCHAR,X
            DBNE   X;MOVECODE
            BRA    DECOMP

LOADFILE    JSR    PD_GPFX
            LD16   #OLDPFX
            JSR    FRMFLN
            LD16   #SYSPFX
            JSR    TOFLN
            JSR    PD_SPFX

            LD16   #FILENAME
            JSR    TOFLN
            JSR    IFOPEN
            BCC    DECOMP

            MOV    #-1;PRN
            RTS

DECOMP      JSR    READCHAR
            CPEQ   #0;ENDSEC1
            JSR    PUTCHAR
            BRA    DECOMP

ENDSEC1     LDA    #>PROGTEXT-ERRMSGS
            JSR    SETPTR
            JSR    SECTEND

SECTION2    JSR    READCHAR
            CPEQ   #0;ENDSEC2
            JSR    PUTCHAR
            BRA    SECTION2

ENDSEC2     LDA    #>VIDMSGS-ERRMSGS
            JSR    SETPTR
            JSR    SECTEND

SECTION3    JSR    READCHAR
            PHA
            JSR    READCHAR
            CPEQ   #0;ENDSEC3
            TAX
            PLA
            PHX
            JSR    MKDEC
            PHA
            TYA
            BEQ    NO100
            ORA    #'0'
            JSR    EDOUT
NO100       TXA
            BEQ    NO10
            ORA    #'0'
            JSR    EDOUT
NO10        PLA
            ORA    #'0'
            JSR    EDOUT
            LDA    #cr
            JSR    EDOUT
            PLA
            BRA    SEC3TXT

READ3TXT    JSR    READCHAR
SEC3TXT     JSR    PUTCHAR
            BCC    READ3TXT
            BRA    SECTION3

ENDSEC3     PLA
            TSTMI  WHEREFRM;EXIT

            JSR    PD_CLOSE                     ; close the file

            LD16   #OLDPFX                      ; reset the prefix
            JSR    TOFLN
            JSR    PD_SPFX

EXIT        STZ    PRN
            RTS

PUTCHAR     PHA
            CMP    #-1
            BEQ    NULL
            AND    #Clrhi
            CPNE   #'\';NOTBKSL                 ; is it a \?
            JSR    EDOUT                        ; yes, do 2 of them
NOTBKSL     CPGE   #' ';NOTCTRL
            PHA
            LDA    #'\'
            JSR    EDOUT
            PLA
            CLC
            ADC    #Ctrl
NOTCTRL     JSR    EDOUT
            PLA
            BPL    NOTEND
            LDA    #cr
            JSR    EDOUT
            SEC
            RTS

NOTEND      CLC
            RTS

NULL        LDA    #'\'
            JSR    EDOUT
            LDA    #'?'
            BRA    NOTCTRL

SECTEND     LDA    #'.'
            JSR    EDOUT
            LDA    #cr
            JMP    EDOUT

MKDEC       LDY    #0                           ; zero 100's
CP100       CPLT   #100;LT100                   ; > 99?
            INY                                 ; incerment 100s
            SEC
            SBC    #100                         ; remove 100
            BRA    CP100                        ; check again

LT100       LDX    #0                           ; zero 10s
CP10        CPLT   #10;LT10                     ; > 9?
            INX                                 ; increment 10s
            SEC
            SBC    #10                          ; remove 10
            BRA    CP10                         ; check again

LT10        RTS

READCHAR    TSTPL  WHEREFRM;RDFILE
            JMP    GETCHAR

RDFILE      JMP    PD_RDBYT

SETPTR      TSTPL  WHEREFRM;POSFILE
            JMP    SETPOS

POSFILE     LDX    #0
            LDY    #0
            JMP    PD_SPOS

COPYCODE    ORG    FREESPACE

GETCHAR     STZ    SETSTDZP                     ; enable message area
            STZ    SETRAM1

TEXTPTR     LDA    ERRMSGS                      ; get the byte

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

WHEREFRM    DB     0
FILENAME    STR    'LLUCE.TEXT'
OLDPFX      DS     $40
            LST    OFF
            DO     LISTSYM
            LST
            FIN

