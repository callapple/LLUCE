********************************
*                              *
*           Decoder            *
*                              *
********************************
            DATE
*-------------------------------

Id          =      5
Aux         =      10

            LST    OFF
            LSTDO  OFF
            XC
            TR
            TR     ADR
Y           =      1
Y           =      1
N           =      0
N           =      0
LISTOBJ     KBD    'List This Source? (Y/N)'
LISTSYM     KBD    'List Symbol Table? (Y/N)'
            PUT    EQUATES
            PUT    ENTRY
            ORG    Usefile

            TYP    Llucefil
            DSK    DECODE

            TTL    'LLUCE - VCII Text Decoder'
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
            BRA    BEGIN

BUFFER      DS     30
BUFFER2     DS     30

BEGIN       JSR    CHKBYT
            CMP    #","
            BEQ    DOIT
            RTS

DOIT        JSR    GOBCOM
            JSR    INPNUM
            STX    TEMP
            LDX    #0
:READIT     JSR    RDBYTE
            STA    BUFFER,X
            STA    BUFFER2,X
            INX
            CPX    TEMP
            BNE    :READIT
            DEC    TEMP
            STZ    TEMP+1
            LDX    #2
:MULT8      ASL    TEMP
            ROL    TEMP+1
            DEX
            BPL    :MULT8
            LDX    #0
            SEC
:DIV6       LDA    TEMP
            SBC    #6
            STA    TEMP
            LDA    TEMP+1
            SBC    #0
            STA    TEMP+1
            INX
            BCS    :DIV6
            INX
            STZ    TEMP2
LOOP1       CLC
            LDA    #0
            LDY    #6
LOOP2
]A          =      29
            LUP    30
            ROL    BUFFER2+]A
]A          =      ]A-1
            --^
            ROL
            DEY
            BNE    LOOP2
            CMP    #$40
            BLT    :GOOD
            LDA    #$3F
:GOOD       TAY
            LDA    XLATE,Y
            LDY    TEMP2
            STA    SCRATCH+256,Y
            INC    TEMP2
            DEX
            BNE    LOOP1
            LDA    #' '
:FILL       INY
            CPY    #64
            BLT    :FILL2
            RTS

:FILL2      STA    SCRATCH+256,Y
            BRA    :FILL

XLATE       ASC    'ABCDEFGHIJKLM?? '
            ASC    'NOPQRSTUVWXYZ: ('
            ASC    '0123456789??'
            HEX    27
            ASC    '. )??<>+-*/=&???,??'
CODEEND     =      *
            LST    OFF
            DO     LISTSYM
            LST
            FIN
            TTL    'Decoder - Symbol Table'
            PAG

