            TTL    'Overlay CRC Calculator'
********************************
*                              *
*          CRC Calculator      *
*                              *
********************************
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

            PUT    EQUATES/OS.EQUATES

]TYPE       =      ^sysfile                    ; set file type
]AUX        =      sysfile                     ; and aux type
            ORG    ]AUX                        ; must be this way
            TYP    ]TYPE

            DSK    /RAM5/SHOW.CRC
            DO     LISTOBJ
            LST
            FIN

PRN         =      6
PROMPT      =      $33
Cr          =      $8D
LNBUF       =      $200
FLNAME      =      $280

SOFTEV      =      $3F4

Quit        =      $65
Open        =      $C8
Read        =      $CA
Write       =      $CB
Close       =      $CC
Geteof      =      $D1                         ; Get End Of File Pointer

MLI         =      $BF00

KBD         =      $C000
SET40       =      $C00C
SETALTCH    =      $C00F
KBDSTRB     =      $C010

INIT        =      $FB2F
HOME        =      $FC58
INPLN       =      $FD6F
CROUT       =      $FD8E
PRBYTE      =      $FDDA
COUT        =      $FDED
SETNORM     =      $FE84
SETKBD      =      $FE89
SETVID      =      $FE93
RESET       =      $FFFC

            ORG    $2000

            JSR    SETNORM
            JSR    INIT
            JSR    SETVID
            JSR    SETKBD
            STZ    SET40                       ; Set 40 Columns
            STZ    SETALTCH
            LDA    #">"
            STA    PROMPT
            JSR    STARTCRC                    ; Set Up CRC Tables

RESTART     JSR    HOME                        ; Control L (Clear Screen)
            STZ    CRC                         ; Zero CRC Count
            STZ    CRC+1
            JSR    CROUT
            JSR    PRINT
            STR    "Filename -> "
            JSR    INPLN
            CPX    #0                          ; Null File Name?
            BNE    :MVNAME                     ; Nope

            JMP    EXIT

:MVNAME     STX    FLNAME                      ; Save Length Of Name
:NAMELUP    LDA    LNBUF,X                     ; Move Name
            AND    #$7F                        ; Clear Hi Bit
            CMP    #'a'                        ; Make It Upper Case
            BLT    :OK

            CMP    #'z'+1
            BGE    :OK

            SBC    #$1F
:OK         STA    FLNAME+1,X                  ; Save It
            DEX                                ; Next Byte
            CPX    #-1
            BNE    :NAMELUP

            JSR    MLI                         ; Open The File
            DB     Open
            DA     OPENLST
            BCC    :OPENOK

            JMP    OPENERR

:OPENOK     LDA    OPENREF                     ; Move Reference Numbers
            STA    READREF
            STA    WRITEREF
            STA    CLOSEREF
            STA    EOFREF
            JSR    MLI
            DB     Geteof
            DA     EOFLST
            JSR    PRINT                       ; Print Size Of Code
            DCI    "Code Size: $"
            LDA    EOF+2
            JSR    PRBYTE
            LDA    EOF+1
            JSR    PRBYTE
            LDA    EOF
            JSR    PRBYTE
            JSR    CROUT

:CRCLUP     JSR    RDBYTE                      ; Read Overlay Byte
            JSR    ADDCRC                      ; Add To Crc
            LDA    EOF                         ; Bump Size Pointer
            BNE    :DWNEOF2
            LDA    EOF+1
            BNE    :DWNEOF1
            DEC    EOF+2
:DWNEOF1    DEC    EOF+1
:DWNEOF2    DEC    EOF
            LDA    EOF                         ; Done?
            ORA    EOF+1
            ORA    EOF+2
            BNE    :CRCLUP                     ; Nope

            JSR    PRINT
            DCI    "Code CRC : $"
            LDA    CRC+1
            JSR    PRBYTE
            LDA    CRC                         ; Move CRC To Program
            JSR    PRBYTE
            JSR    CROUT

ANOTHER     JSR    MLI                         ; Close The File
            DB     Close
            DA     CLOSELST
            JSR    PRINT
            DB     Cr
            ASC    "Do Another File? -> _"08
:WAIT       LDA    KBD                         ; Wait For A Keypress
            BPL    :WAIT

            BIT    KBDSTRB                     ; Clear Strobe
            CMP    #"N"                        ; How About A No?
            BEQ    :QUIT
            CMP    #"n"
            BEQ    :QUIT

            CMP    #"Y"                        ; Is It A Yes?
            BEQ    :AGAIN

            CMP    #"y"
            BNE    :WAIT

:AGAIN      JSR    COUT                        ; Print Input
            JMP    RESTART                     ; Start Again

:QUIT       JSR    COUT                        ; Print Input
EXIT        JSR    MLI                         ; Try To Quit
            DB     Quit
            DA     QUITLST

*-------------------------------
* Should Never Get Here
*-------------------------------

            INC    SOFTEV                      ; Force Cold Start
            JMP    (RESET)

OPENERR     JSR    PRINT
            DB     Cr
            ASC    "Error Opening File"0D
:N          BRA    ANOTHER

RDERR       JSR    PRINT
            DB     Cr
            ASC    "Error Reading File"0D
:N          PLA
            PLA
            JMP    ANOTHER

RDBYTE      JSR    MLI
            DB     Read
            DA     READLST
            BCS    RDERR

            LDA    BYTE                        ; Get Byte Read
            RTS

*-------------------------------
* Standard In-Line Print Routine
*-------------------------------

PRINT       PLA
            STA    PRN
            PLA
            STA    PRN+1
            JSR    INCPRN
:PLOOP      LDA    (PRN)
            PHP
            ORA    #$80
            JSR    COUT
            JSR    INCPRN
            PLP
            BMI    :PLOOP

            JMP    (PRN)

INCPRN      INC    PRN
            BNE    :DONE
            INC    PRN+1
:DONE       RTS

QUITLST     DB     4
            DS     8

OPENLST     DB     3
            DA     FLNAME
            DA     IOBUF
OPENREF     DB     0

READLST     DB     4
READREF     DB     0
            DA     BYTE
            DA     1                           ; Reading 1 Byte
            DA     0

WRITELST    DB     4
WRITEREF    DB     0
            DA     BYTE
            DA     1                           ; Writing 1 Byte
            DA     0

CLOSELST    DB     1
CLOSEREF    DB     0

EOFLST      DB     2
EOFREF      DB     0
EOF         DB     0,0,0

BYTE        DB     0

*===============================
* Calculate CRC
*===============================

STARTCRC    LDX    #0                          ; Zero Crc Pages
:CLRCRC     STZ    CRCLO,X
            STZ    CRCHI,X
            INX
            BNE    :CLRCRC

:FETCH      TXA                                ; Set Up CRC Table
            EOR    CRCHI,X
            STA    CRCHI,X
            LDY    #8
:MKCRC      ASL    CRCLO,X
            ROL    CRCHI,X
            BCC    :LOOP1

            LDA    CRCHI,X
            EOR    #$10
            STA    CRCHI,X
            LDA    CRCLO,X
            EOR    #$21
            STA    CRCLO,X
:LOOP1      DEY
            BNE    :MKCRC

            INX
            BNE    :FETCH

            RTS

ADDCRC      EOR    CRC+1                       ; Add It To Crc
            TAX
            LDA    CRC
            EOR    CRCHI,X
            STA    CRC+1
            LDA    CRCLO,X
            STA    CRC
            RTS

CRC         DA     0

            DUM    CRC+2

            DS     \                           ; Set To Page Boundary
CRCLO       DS     $100
CRCHI       DS     $100
IOBUF       DS     $400
            DEND
            LST    OFF
            DO     LISTSYM
            LST
            FIN

