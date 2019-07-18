********************************
*                              *
*  Random Access File Sort     *
*                              *
********************************
            DATE
*-------------------------------

Id          =      5
Aux         =      6

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
GSBUG       =      N
            DO     NOLIST
LISTOBJ     =      N
LISTSYM     =      N
            ELSE
LISTOBJ     KBD    'List This Source? (Y/N)'
LISTSYM     KBD    'List Symbol Table? (Y/N)'
            FIN

            DO     LISTOBJ
            LST
            FIN
            LST    OFF
            USE    EQUATES/MACROS
            PUT    EQUATES/EQUATES
            PUT    EQUATES/OS.EQUATES
            PUT    EQUATES/DRIVEREQU
            PUT    EQUATES/ENTRY
            PUT    EQUATES/RAMAREA
            PUT    EQUATES/ERRORS
            PUT    EQUATES/TOKENS
            LST    RTN

]TYPE       =      ^overlays                     ; set file type
]AUX        =      overlays                      ; and aux type
            ORG    ]AUX                          ; must be this way
            TYP    ]TYPE

            DSK    /MAIN/LLUCE/SYSTEM/RNDSORT

            TTL    'LLUCE - Sort Random File'
            DO     LISTOBJ
            LST
            FIN

            DB     Id
            DA     Aux
            DB     Aux/256!Aux!Id!$A5

*-------------------------------
* Size Of Code To Check CRC
*-------------------------------

            DA     IOEND-BEGIN
            DA     0                             ; CRC Goes Here

            ORG    $D000

MEMBTM      =      NODENUM
MEMTOP      =      MLI

DiskErr     =      249
FileLock    =      250
VolProt     =      251
FileBig     =      253
BadParm     =      254
NoFile      =      255

*-------------------------------
* Syntax For Use With This Overlay
*
* Overlay "Rndsort","Filename",Size,Start
*
* Error Code Is Returned In Start
*
*   0 = No Error
* 249 = Another Disk Error
* 250 = File Locked
* 251 = Disk Write Protected
* 253 = File Too Large
* 254 = Invalid Parameter
* 255 = File Not Found
*-------------------------------

BEGIN       LDX    #IO-PARMLSTS
MOVEPDOS    MOV    PARMLSTS,X;EOFLST,X           ; Move Parameter Lists
            DBPL   X;MOVEPDOS

            JSR    GOBCOM                        ; Get File Name
            JSR    MOVNAME
            JSR    GOBCOM                        ; Get Record Size
            JSR    INPNUM
            SVXAY                                ; Save For Later
            JSR    GOBCOM                        ; Get Starting Record
            IFEQ   (PRGPTR);#Number;VAROK        ; Numeric next?

            RSTXAY                               ; Restore Stack
            LDA    #Typemiss                     ; Type Mismatch Error
            JMP    BADERR

VAROK       JSR    INPNUM                        ; Record 0 Or 1
            TXA
            BEQ    USEDEF
            LDX    #1
USEDEF      STX    USEZERO
            RSTXAY                               ; Get Back Record Size
            BNE    BADREC                        ; Must Be Less Than 256
            TAY
            BEQ    RECOK

BADREC      LDRA   #BadParm;ERROR

RECOK       STX    RECLEN                        ; Save Record Length
            LDY    #IOEND-IO                     ; Save $90 Area
SAVEZP      MOV    GET1,Y;SAVE90,Y
            DBPL   Y;SAVEZP

            LDY    #IOEND-IO                     ; Put I/O Stuff In
MOVESUBS    MOV    IO,Y;GET1,Y
            DBPL   Y;MOVESUBS

            LDA    #%00110011                    ; Request All, Deny All
            JSR    PD_OPEN                       ; Open File
            BCC    TSTSIZE

            LDA    #NoFile                       ; File Not Found
ERROR       JMP    NOERR

TSTSIZE     STA    EOFREF                        ; Save Reference Number
            STA    RWREF
            STA    MARKREF
            JSR    MLI                           ; Get Size Of File
            DB     Geteof
            DA     EOFLST
            LDNE   EOF+2;TOOBIG
            IFLT   EOF+1;#>MEMTOP-MEMBTM;SIZEOK

TOOBIG      JSR    PD_CLOSE                      ; Close The File
            LDNE   #FileBig;ERROR                ; It's Too Big

SIZEOK      STZ    TEMP2
            MOV    #>MEMBTM;TEMP2+1
            JSR    READIT
            MOVD   EOF;OPERAND                   ; Move Number Of Bytes
            LDX    #0                            ; Set Up To Calculate
            MOV    RECLEN;OPERATOR               ; Number Of Records
            BNE    LENOK
            INX
LENOK       STX    OPERATOR+1
            STZ    RESULT                        ; Divide Size Of File
            STZ    RESULT+1                      ; By Record Length
            CLC
            LDX    #16
DIV1        ROL    OPERAND
            ROL    OPERAND+1
            ROL    RESULT
            ROL    RESULT+1
            SEC
            LDA    RESULT
            SBC    OPERATOR
            TAY
            LDA    RESULT+1
            SBC    OPERATOR+1
            BCC    DIV2

            STY    RESULT
            STA    RESULT+1
DIV2        DBNE   X;DIV1

            ROL    OPERAND
            ROL    OPERAND+1
            MOVD   OPERAND;NUMRECS
            BREQW  RESULT;NOMOD                  ; Any Bytes Left Over?

            INCD   NUMRECS                       ; Add 1 To Number
            LD16   NUMRECS                       ; Get New File Size
            JSR    CALCADR
            MOVD   RESULT;EOF                    ; Save It For Later Write
NOMOD       DECD   NUMRECS                       ; Dec Number Of Records
            MOV    USEZERO;CURREC                ; Set Up Starting Record
            STA    TOPREC
            STZ    CURREC+1
            STZ    TOPREC+1
            JSR    PRHEX                         ; Print The Record Number

SORTNEXT    IFLT   CURREC+1;TOPREC+1;XPRNT
            IFLT   CURREC;TOPREC;XPRNT

            JSR    PRBSHEX                       ; Print Record Number
XPRNT       LD16   CURREC                        ; Calculate Record Address
            JSR    CALCADR
            ST16   TEMP                          ; Save Address Of Record
            LDEQ   RECLEN;R256                   ; Add In Record Length

            CLC
            ADA    TEMP;TEMP2
            AD     #0;TEMP+1;TEMP2+1
            BRA    COMPARE

R256        INC    TEMP2+1                       ; Record Length Is 256
COMPARE     LDY    #-1                           ; Set Starting Point
COMPARE2    INY
            CPEQY  RECLEN;NOSWAP                 ; More To Check?

            JSR    GET2                          ; Get Byte From First Rec
            JSR    CONV                          ; Make It Upper Case
            STA    CHARTEMP                      ; Save It For Later
            JSR    GET1                          ; Get Byte From Next Rec.
            JSR    CONV                          ; Make It Upper Case
            CPEQ   CHARTEMP;COMPARE2             ; What Do We Do?
            BLT    NOSWAP                        ; It's Less, Skip This One

            LDY    RECLEN                        ; Swap The Two Records
SWAP        DEY
            JSR    GET1
            PHA
            JSR    GET2
            JSR    PUT1
            PLA
            JSR    PUT2
            TYA
            BNE    SWAP

            LDNE   CURREC+1;GODOWN               ; Are We At First Record?
            IFEQ   CURREC;USEZERO;SORTNEXT       ; Are We Sure?

GODOWN      LDX    CURREC                        ; Decrement Record Number
            BNE    DOWN
            DEC    CURREC+1
DOWN        DEC    CURREC
            JMP    SORTNEXT                      ; Go Back And Compare

NOSWAP      INCD   CURREC                        ; Increment Record Number
            IFLT   CURREC;NUMRECS;GO_NEXT        ; At Last Record?
            IFGE   CURREC+1;NUMRECS+1;SAVEFILE
GO_NEXT     JMP    SORTNEXT

SAVEFILE    JSR    MLI                           ; Reset To Start Of File
            DB     Setmark
            DA     MARKLST
            STZ    TEMP
            MOV    #>MEMBTM;TEMP+1
            JSR    WRITEIT
            PHX                                  ; Save Error Code
            JSR    PD_CLOSE                      ; Close The File
            PLA
            BEQ    NOERR                         ; No Errors

            LDX    #VolProt
            CPEQ   #drvrWrtProt;RTNCODE          ; Write Protected
            DEX                                  ; FileProt
            CPEQ   #invalidAccess;RTNCODE        ; File Locked
            DEX                                  ; Another Error
RTNCODE     TXA
NOERR       PHA
            LDA    #bs                           ; Back Up 4 Spaces
            LDX    #4
            JSR    PMULT
            LDA    #'-'                          ; Print 4 -'s
            LDX    #4
            JSR    PMULT
            LDY    #0                            ; Save Error Code
            PLA
            STA    (VPTR),Y
            TYA                                  ; High Bytes Always 0
            INY
            STA    (VPTR),Y
            INY
            STA    (VPTR),Y
            LDY    #IOEND-IO                     ; Restore $90 Area
RESTZP      MOV    SAVE90,Y;GET1,Y
            DBPL   Y;RESTZP

            RTS

READIT      JSR    MLI                           ; Read In The File
            DB     Read
            DA     RWLIST
            LDY    #0
            STZ    TEMP
            MOV    #>ENDMOD;TEMP+1
            LDX    #$10                          ; Move 4K
MOVE_IN     LDA    (TEMP),Y
            AND    #Clrhi
            JSR    PUT2
            IBNE   Y;MOVE_IN

            INC    TEMP+1
            INC    TEMP2+1
            DBNE   X;MOVE_IN

            LDNE   XFERED;RDDONE                 ; Finished Reading?
            IFEQ   XFERED+1;#$10;READIT

RDDONE      RTS

WRITEIT     STZ    TEMP2
            MOV    #>ENDMOD;TEMP2+1
            LDY    #0
            LDX    #$10                          ; Move 4K
MOVE_OUT    JSR    GET1
            STA    (TEMP2),Y
            IBNE   Y;MOVE_OUT

            INC    TEMP+1
            INC    TEMP2+1
            DBNE   X;MOVE_OUT

            IFGE   EOF+1;#$10;DO_WRT             ; Finished With 4K Chunks?
            MOVD   EOF;REQUEST                   ; Write The Last Bit Out
            DEC    EOF+2                         ; Flag Last Chunk Written
DO_WRT      JSR    MLI                           ; Write File Back To Disk
            DB     Write
            DA     RWLIST
            TAX                                  ; Put Error Code In X
            SEC                                  ; Subtract 4K From File Size
            SB     EOF+1;#$10;EOF+1
            TSTPL  EOF+2;WRITEIT                 ; Finished?
            RTS

PMULT       PHA
            JSR    VIDCOUT
            PLA
            DBNE   X;PMULT

            RTS

CALCADR     ST16   OPERAND
            LDX    #0
            MOV    RECLEN;OPERATOR
            BNE    CALCADR2
            INX
CALCADR2    STX    OPERATOR+1
            STZ    RESULT
            STZ    RESULT+1
            LDX    #16
CALCADR3    LSR    OPERATOR+1
            ROR    OPERATOR
            BCC    CALCADR4

            CLC
            ADD    OPERAND;RESULT;RESULT
CALCADR4    ASL    OPERAND
            ROL    OPERAND+1
            DBNE   X;CALCADR3

            CLC
            LD16   RESULT
            ADC    #>MEMBTM
            RTS

CONV        CPLT   #'a';CONV2
            CPGE   #'z'+1;CONV2
            SBC    #$1F
CONV2       RTS

PRBSHEX     LDA    #bs
            LDX    #4
            JSR    PMULT
PRHEX       LDA    CURREC+1
            JSR    PRBYTE
            LDA    CURREC
PRBYTE      PHA
            LSR    A
            LSR    A
            LSR    A
            LSR    A
            JSR    PRHEXZ
            PLA
            AND    #$F
PRHEXZ      ORA    #'0'
            CPLT   #'9'+1;GOCOUT
            ADC    #6
GOCOUT      JMP    VIDCOUT

PARMLSTS    ORG    $380

EOFLST      DB     2
EOFREF      DB     0
EOF         DS     3

RWLIST      DB     4
RWREF       DB     0
            DA     ENDMOD
REQUEST     DA     $1000
XFERED      DA     0

MARKLST     DB     2
MARKREF     DB     0
            HEX    000000

            ORG

IO          ORG    $90

GET1        STZ    AUXREAD
            LDA    (TEMP),Y
            STZ    MAINREAD
            RTS

PUT1        STZ    AUXWRT
            STA    (TEMP),Y
            STZ    MAINWRT
            RTS

GET2        STZ    AUXREAD
            LDA    (TEMP2),Y
            STZ    MAINREAD
            RTS

PUT2        STZ    AUXWRT
            STA    (TEMP2),Y
            STZ    MAINWRT
            RTS

            ORG
IOEND       =      *

CHARTEMP    DB     0
USEZERO     DB     0
RECLEN      DB     0

OPERAND     DA     0
OPERATOR    DA     0

NUMRECS     DA     0
CURREC      DA     0
TOPREC      DA     0

SAVE90      DS     IOEND-IO

            LST    OFF
            DO     LISTSYM
            LST
            FIN
            TTL    'RNDSORT - Symbol Table'

