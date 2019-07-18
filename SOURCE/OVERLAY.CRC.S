            TTL    'Overlay CRC Calculator'
********************************
*                              *
*  Overlay CRC Calculator      *
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
            DO     LISTOBJ
            LST
            FIN
            LST    OFF

]TYPE       =      ^sysfile                    ; set file type
]AUX        =      sysfile                     ; and aux type
            ORG    ]AUX                        ; must be this way
            TYP    ]TYPE

            DSK    /RAM5/OVERLAY.CRC
            PUT    EQUATES/EQUATES
            PUT    EQUATES/OS.EQUATES
            LST    RTN

FLNAME      =      LNBUF+$80

            JSR    MONSNORM
            JSR    MONINIT
            JSR    MONSVID
            JSR    MONSKBD
            STZ    DISP40                      ; Set 40 Columns
            STZ    ALTCHRS
            LDA    #'>'+128
            STA    MONPROMPT
            JSR    STARTCRC                    ; Set Up CRC Tables

RESTART     JSR    MONCLS                      ; Control L (Clear Screen)
            STZ    CRC                         ; Zero CRC Count
            STZ    CRC+1
            JSR    MONCROUT
            JSR    PRINT
            DCI    'Filename -> '
            JSR    MONINPLN
            CPX    #0                          ; Null File Name?
            BNE    MVNAME                      ; Nope

            JMP    EXIT

MVNAME      STX    FLNAME                      ; Save Length Of Name
NAMELUP     LDA    LNBUF,X                     ; Move Name
            AND    #$7F                        ; Clear Hi Bit
            STA    FLNAME+1,X                  ; Save It
            DEX                                ; Next Byte
            CPX    #-1
            BNE    NAMELUP

            JSR    MLI                         ; Open The File
            DB     Open
            DA     OPENLST
            BCC    OPENOK

            JMP    OPENERR

OPENOK      LDA    OPENREF                     ; Move Reference Numbers
            STA    READREF
            STA    WRITEREF
            STA    CLOSEREF
            STA    MARKREF
            LDX    #0                          ; Read First 8 Bytes
ID          JSR    RDBYTE
            STA    IDBYTES,X
            INX
            CPX    #8
            BLT    ID

            JSR    MONCROUT
            JSR    PRINT                       ; Print ID Byte
            DCI    'ID  Byte : '
            LDA    IDBYTES
            JSR    MONPRBYTE
            JSR    MONCROUT
            JSR    PRINT                       ; Print Auxiliary Type
            DCI    'Aux Type : '
            LDA    IDBYTES+2
            JSR    MONPRBYTE
            LDA    IDBYTES+1
            JSR    MONPRBYTE
            JSR    MONCROUT
            JSR    PRINT                       ; Print Checksum Of ID
            DCI    'Checksum : '
            LDA    IDBYTES+3
            JSR    MONPRBYTE
            JSR    MONCROUT
            JSR    PRINT                       ; Print Size Of Code
            DCI    'Code Size: '
            LDA    IDBYTES+5
            JSR    MONPRBYTE
            LDA    IDBYTES+4
            JSR    MONPRBYTE
            JSR    MONCROUT
            LDA    #0                          ; Checksum Overlay ID
            LDX    #0
IDCSUM      EOR    IDBYTES,X
            INX
            CPX    #4
            BLT    IDCSUM

            EOR    #$A5                        ; ID Ok?
            BEQ    IDOK

            JMP    IDERR                       ; Nope

IDOK        LDA    IDBYTES+4                   ; Move Code Size
            STA    TEMP
            LDA    IDBYTES+5
            STA    TEMP+1
CRCLUP      JSR    RDBYTE                      ; Read Overlay Byte
            JSR    ADDCRC                      ; Add To Crc
            LDA    TEMP                        ; Bump Size Pointer
            BNE    DWNSIZE

            DEC    TEMP+1
DWNSIZE     DEC    TEMP
            LDA    TEMP                        ; Done?
            BNE    CRCLUP                      ; Nope

            LDA    TEMP+1
            BNE    CRCLUP

            JSR    PRINT
            DCI    'Code CRC : '
            LDA    CRC                         ; Move CRC To Program
            STA    IDBYTES+6
            LDA    CRC+1
            STA    IDBYTES+7
            JSR    MONPRBYTE
            TXA
            JSR    MONPRBYTE
            JSR    MONCROUT
            JSR    MLI                         ; Set Mark Back To 0
            DB     Setmark
            DA     MARKLST
            LDX    #0                          ; Re-Write First 8 Bytes
WRID        LDA    IDBYTES,X
            STA    BYTE
            JSR    MLI
            DB     Write
            DA     WRITELST
            INX
            CPX    #8
            BLT    WRID

ANOTHER     JSR    MLI                         ; Close The File
            DB     Close
            DA     CLOSELST
            JSR    PRINT
            DB     cr
            ASC    'Do Another File? -> _'2088
K_WAIT      LDA    KYBD                        ; Wait For A Keypress
            BPL    K_WAIT

            BIT    KBDSTRB                     ; Clear Strobe
            CMP    #'N'+Hibit                  ; How About A No?
            BEQ    QUIT

            CMP    #'n'+Hibit                  ; How About A No?
            BEQ    QUIT

            CMP    #'Y'+Hibit                  ; Is It A Yes?
            BEQ    AGAIN

            CMP    #'y'+Hibit
            BNE    K_WAIT

AGAIN       JSR    MONCOUT                     ; Print Input
            JMP    RESTART                     ; Start Again

QUIT        JSR    MONCOUT                     ; Print Input
EXIT        JSR    MLI                         ; Try To Quit
            DB     Quit
            DA     QUITLST

*-------------------------------
* Should Never Get Here
*-------------------------------

            INC    SOFTEV                      ; Force Cold Start
            JMP    (MONRESET)

OPENERR     JSR    PRINT
            DB     cr
            ASC    'Error Opening File'8D
            BRA    ANOTHER

IDERR       JSR    PRINT
            DB     cr
            ASC    'Invalid Overlay ID'0D0D
            ASC    'Probably Not An Overlay'8D
            JMP    ANOTHER

RDERR       JSR    PRINT
            DB     cr
            ASC    'Error Reading File'8D
            PLA
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
            BRA    PR2

PR1         LDA    (PRN)
            PHP
            ORA    #Hibit
            JSR    MONCOUT
            PLP
            BMI    PR3

PR2         INC    PRN
            BNE    PR1

            INC    PRN+1
            BRA    PR1

PR3         LDA    PRN+1
            PHA
            LDA    PRN
            PHA
            RTS

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

MARKLST     DB     2
MARKREF     DB     0
            DB     0,0,0

BYTE        DB     0

IDBYTES     DS     8

*===============================
* Calculate CRC
*===============================

STARTCRC    LDX    #0                          ; Zero Crc Pages
CLRCRC      STZ    CRCBUFLO,X
            STZ    CRCBUFHI,X
            INX
            BNE    CLRCRC

FETCH       TXA                                ; Set Up CRC Table
            EOR    CRCBUFHI,X
            STA    CRCBUFHI,X
            LDY    #8
MKCRC       ASL    CRCBUFLO,X
            ROL    CRCBUFHI,X
            BCC    LOOP1

            LDA    CRCBUFHI,X
            EOR    #>$1021
            STA    CRCBUFHI,X
            LDA    CRCBUFLO,X
            EOR    #<$1021
            STA    CRCBUFLO,X
LOOP1       DEY
            BNE    MKCRC

            INX
            BNE    FETCH

            RTS

ADDCRC      EOR    CRC+1                       ; Add It To Crc
            TAX
            LDA    CRC
            EOR    CRCBUFHI,X
            STA    CRC+1
            LDA    CRCBUFLO,X
            STA    CRC
            RTS

CRC         DA     0

            DUM    CRC+2

            DS     \                           ; Set To Page Boundary
CRCBUFLO    DS     $100
CRCBUFHI    DS     $100
IOBUF       DS     $400
            DEND
            LST    OFF
            DO     LISTSYM
            LST
            FIN

