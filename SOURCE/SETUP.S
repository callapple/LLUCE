            TTL    'Serial Number Encoder'
********************************
*                              *
* LLUCE Serial Number Encoder  *
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

            DSK    /MAIN/LLUCE/SETUP
            PUT    EQUATES/EQUATES
            PUT    EQUATES/OS.EQUATES
            LST    RTN

cls         =      ff+Hibit
DEFFLG      =      LSTPTR

FLNAME      =      LNBUF+$80

OURNAME     =      $800

IOBUFFER    =      $1800
PROGRAM     =      $2000
BUFSIZE     =      $9B00-PROGRAM

            JMP    ENTER

            HEX    EEEE
            DB     65
FNAME       DS     65

ENTER       LDA    #<HEREITIS
            STA    TEMP2
            LDA    #>HEREITIS
            STA    TEMP2+1
            LDA    #<START
            STA    PRN
            LDA    #>START
            STA    PRN+1
            LDX    #>ENDOFIT-HEREITIS+256
            LDY    #0                          ; Start Offset
ENC_COPY    LDA    (TEMP2),Y                   ; Copy Byte
            STA    (PRN),Y
            INY
            BNE    ENC_COPY

            INC    TEMP2+1
            INC    PRN+1
            DEX                                ; Count Down
            BNE    ENC_COPY

            STZ    OURNAME                     ; setup for partial path
            LDX    #1

            LDA    FLNAME+1                    ; partial or complete path?
            CMP    #'/'
            BEQ    PARTIAL

            LDX    #0                          ; move the current prefix
MVPFX       LDA    LNBUF,X
            STA    OURNAME,X
            INX
            CPX    LNBUF
            BLT    MVPFX
            BEQ    MVPFX

PARTIAL     LDY    #1                          ; start at filename start
MVOURNM     LDA    FLNAME,Y
            STA    OURNAME,X
            INX
            INY
            CPY    FLNAME
            BLT    MVOURNM
            BEQ    MVOURNM

            DEX
            STX    OURNAME

            LDX    FNAME                       ; Pathname Supplied?
            BEQ    DEFAULT                     ; Nope, Use Default

ENC_NAME    LDA    FNAME,X                     ; Move Supplied Path
            STA    FLNAME,X
            DEX
            BPL    ENC_NAME
            BRA    SET_DONE

DEFAULT     LDX    LLUCE_NM                    ; Move Default Path
DEFNAME     LDA    LLUCE_NM,X
            STA    FLNAME,X
            DEX
            BPL    DEFNAME

SET_DONE    STZ    CSW
            LDA    #$C3
            STA    CSW+1
            JMP    START

            DS     \
HEREITIS    =      *
            ORG    $900

START       LDA    #cls
            JSR    MONCOUT
            LDA    #$A                         ; Set Up For Get Info
            STA    INFOLST
            LDA    #<BUFSIZE                   ; Reset Buffer Size
            STA    REQUEST
            LDA    #>BUFSIZE
            STA    REQUEST+1
            JSR    MLI                         ; Get Info Of File
            DB     Getinfo
            DA     INFOLST
            BCS    ERROR
            JMP    FOUND

ERROR       CMP    #$44
            BNE    TRY45

            JSR    NOISE
            DCI    'Path not found'
            BRA    ERRFIN

TRY45       CMP    #$45
            BNE    TRY46

            JSR    NOISE
            DCI    'Volume not found'
            BRA    ERRFIN

TRY46       CMP    #$46
            BNE    FATAL

            JSR    NOISE
            DCI    'File not found'
            BRA    ERRFIN

FATAL       JSR    NOISE
            ASC    'Fatal disk error'0D0D
            DCI    'Press a key to quit '
            JSR    GETKEY
            JMP    SN_QUIT

ERRFIN      JSR    MONCROUT
            JSR    MONCROUT
            JSR    PRFN
            JSR    MONCROUT
            JMP    ASK_AGN

FOUND       JSR    SETUP
            DCI    'Reading '
            JSR    PRFN
            JSR    MONCROUT
            LDA    #Read
            JSR    DO_FILE                     ; Read In The File
            LDA    PROGRAM+2                   ; Point To Encoder Start
            LDX    PROGRAM+1
            STA    TEMP2+1
            STX    TEMP2
            SEC                                ; Get End Address
            SBC    #>PROGRAM                   ; Subtract Loading Adr.
            INX
            BNE    INC_PGM

            INC    A
INC_PGM     STX    REQUEST                     ; Store For Later Save
            STA    REQUEST+1
            LDY    #2                          ; Already Encoded?
            LDA    #$EE
            CMP    (TEMP2),Y
            BNE    ISDONE                      ; Yes

            INY
            CMP    (TEMP2),Y
            BEQ    DO_ENC                      ; Nope, Do It

ISDONE      JSR    NOISE
            DCI    'This copy of '
            JSR    PRFN
            JSR    PRINT
            ASC    ' is already encoded'8D
            JMP    ASK_AGN

DO_ENC      LDY    #4                          ; Get location of serial #
            LDA    (TEMP2),Y
            PHA
            INY
            LDA    (TEMP2),Y
            STA    TEMP2+1
            PLA
            STA    TEMP2                       ; Is it a demo copy?
            ORA    TEMP2+1
            BNE    DO_ENC2
            JMP    DEF                         ; yes, don't alter serial number

DO_ENC2     STZ    DEFFLG
            JSR    SETUP
            DCI    'Last serial number was: '
            LDA    SERIAL
            JSR    MONPRBYTE
            LDA    SERIAL+1
            JSR    MONPRBYTE
            JSR    MONCROUT

            JSR    SETUP                       ; Check To Use Default
            DCI    'Use next serial number?'
            JSR    GETYN
            BNE    DEF                         ; Use The Default

            JSR    SETUP
            DCI    'Enter new serial number -> '
            LDA    #'>'+Hibit
            STA    MONPROMPT
            LDA    #0
            STA    MONMODE
            JSR    MONINPLN
            CPX    #5
            BLT    SIZE1
            JMP    DO_ENC

SIZE1       CPX    #0
            BNE    SIZE2
            JMP    DO_ENC

SIZE2       LDY    #0
            JSR    MONGETNUM
            LDA    a2
            STA    SERIAL+1
            LDA    a2+1
            STA    SERIAL
            DEC    DEFFLG
DEF         JSR    SETUP
            DCI    'Encoding '
            JSR    PRFN
            LDA    TEMP2                       ; Changing serial number?
            ORA    TEMP2+1
            BNE    PUTSN0                      ; yes, do it
            JSR    PRINT
            DCI    ' (DEMO)'
            JSR    MONCROUT                    ; no, CR and do CRC
            BRA    PUTSN3

PUTSN0      JSR    PRINT
            DCI    ' #'
            BIT    DEFFLG                      ; If Not Default, Don't Read
            BPL    PUTSN1

            LDA    SERIAL+1
            CLC
            BRA    PUTSN2

PUTSN1      SED                                ; Add 1 In Decimal Mode
            CLC                                ; (0000-9999)
            LDA    SERIAL+1
            ADC    #1
            STA    SERIAL+1
PUTSN2      PHA                                ; Save For Later
            LDA    SERIAL
            ADC    #0
            STA    SERIAL
            CLD
            LDY    #3                          ; Start Of Actual Serial #
            JSR    SVNUM                       ; Stuff In Program
            PLA                                ; Get Next Byte
            JSR    SVNUM
            JSR    MONCROUT

            JSR    DO_SER

PUTSN3      STZ    SETALTZP                    ; Will Die If Not Done
            LDA    #1                          ; Tell The Encode Routine
            STA    TEMP                        ; That It's Ok To Do It's
            INC    A                           ; Thing.
            STA    TEMP+1
            JSR    PROGRAM                     ; Make It Do It's Thing
            STZ    SETSTDZP                    ; Back To Normal
            PHY                                ; Save CRC
            PHA
            LDX    #3                          ; Move Creation Date
MV_DATE     LDA    DATE2,X
            STA    DATE1,X
            DEX
            BPL    MV_DATE

            JSR    MLI                         ; Shoot The Old One
            DB     Destroy
            DA     KILLLIST
            JSR    SETUP
            DCI    'Writing '
            JSR    PRFN
            JSR    PRINT
            DCI    ' CRC=$'
            PLA
            JSR    MONPRBYTE
            PLA
            JSR    MONPRBYTE
            JSR    MONCROUT
            LDA    #7                          ; Set Up For Create
            STA    INFOLST
            JSR    MLI                         ; Make A New File
            DB     Create
            DA     INFOLST
            LDA    #Write                      ; Write It All Out
            JSR    DO_FILE
ASK_AGN     JSR    SETUP
            DCI    'Do another?'
            JSR    GETYN
            BEQ    SN_QUIT

            JSR    SETUP
            ASC    'Insert next disk'0D0D
            DCI    'Press RETURN to continue'
            JSR    GETKEY
            JMP    START                       ; Do It Again

SN_QUIT     JSR    MONCROUT
            JSR    MLI                         ; See You Later
            DB     Quit
            DA     QUITLST
            INC    SOFTEV                      ; How Did We Get Here?
            JMP    (MONRESET)                  ; Do A Cold Reset

GETKEY      JSR    MONKEYIN                    ; Get A Key
CONV        CMP    #'a'+Hibit                  ; Make Upper Case
            BLT    CONV2

            CMP    #'z'+1+Hibit
            BGE    CONV2

            SBC    #$1F
CONV2       RTS

GETYN       JSR    PRINT
            DCI    ' (Y/N): '
YN_WAIT     JSR    GETKEY
            CMP    #'N'+Hibit                  ; Is In A NO?
            BEQ    GOT_NO                      ; If It Is, Quit

            CMP    #'Y'+Hibit                  ; Is It A Yes?
            BNE    YN_WAIT                     ; If It Isn't, Try Again

            JSR    PRINT                       ; Prompt For Next Disk
            ASC    'Yes'8D
            LDA    #1
            RTS

GOT_NO      JSR    PRINT
            ASC    'No'8D
            LDA    #0
            RTS

DO_FILE     STA    RWTYPE                      ; Save Read/Write
            JSR    MLI                         ; Open The File
            DB     Open
            DA     OPENLST
            LDA    OPENREF                     ; Move The References
            STA    RWREF
            STA    CLOSEREF
            JSR    MLI                         ; Read/Write The File
RWTYPE      DB     Read
            DA     RWLIST
            JSR    MLI                         ; Close It Up
            DB     Close
            DA     CLOSELST
            RTS

DO_SER      JSR    MLI                         ; Open The File
            DB     Open
            DA     OPENME
            LDA    MYOREF                      ; Move The References
            STA    MYWRREF
            STA    CLOSEREF
            STA    MYMRKREF
            JSR    MLI                         ; get our file size
            DB     Geteof
            DA     MYMRKLST
            SEC                                ; number is at eof-2
            LDA    MYMRK
            SBC    #2
            STA    MYMRK
            BCS    SETMRK
            DEC    MYMRK+1
SETMRK      JSR    MLI                         ; set the mark
            DB     Setmark
            DA     MYMRKLST
            JSR    MLI                         ; write the serial number
            DB     Write
            DA     MYWRLIST
            JSR    MLI                         ; close up
            DB     Close
            DA     CLOSELST
            RTS

*-------------------------------
* Print And Save Hex Byte
*-------------------------------

SVNUM       PHA                                ; Save Byte For Later
            LSR    A                           ; Move Down The High Nibble
            LSR    A
            LSR    A
            LSR    A
            ORA    #'0'                        ; Make Ascii
            STA    (TEMP2),Y                   ; Stuff It
            ORA    #Hibit
            JSR    MONCOUT
            DEY                                ; Next Number
            PLA                                ; Get Back Byte
            AND    #$F                         ; Strip Off High Nibble
            ORA    #'0'                        ; Make It Ascii
            STA    (TEMP2),Y                   ; Stuff It Too
            ORA    #Hibit
            JSR    MONCOUT
            DEY                                ; Point To Next Number
            RTS

*-------------------------------
* Print Following Text
*-------------------------------

NOISE       JSR    PRINT
            DB     cr,cr,bel,bel+Hibit
SETUP       JSR    PRINT
            DB     cr
            DCI    'SETUP: '
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

*-------------------------------
* Print Name Of File
*-------------------------------

PRFN        LDX    FLNAME                      ; Get Filename Length
            STX    PRN                         ; Save For Count
            LDY    #1                          ; Start At First Char.
FNLOOP      LDA    FLNAME,Y
            ORA    #Hibit                      ; Must Have Hi Bit Set
            JSR    CONV
            JSR    MONCOUT
            INY
            DEC    PRN                         ; Any More?
            BNE    FNLOOP                      ; Yes
            RTS

INFOLST     DB     10                          ; INFO/CREATE
            DA     FLNAME                      ; Path Name
            DB     0                           ; Access
            DB     0                           ; File Type
            DA     0                           ; Aux Type
            DB     0                           ; Storage Type
DATE1       DA     0                           ; Blocks Used/Create Date
            DA     0                           ; Mod Date/Create Time
            DA     0                           ; Mod Time
DATE2       DA     0                           ; Create Date
            DA     0                           ; Create Time

KILLLIST    DB     1
            DA     FLNAME

OPENLST     DB     3
            DA     FLNAME
            DA     IOBUFFER
OPENREF     DB     0

RWLIST      DB     4
RWREF       DB     0
            DA     PROGRAM
REQUEST     DA     BUFSIZE
            DA     0

CLOSELST    DB     1
CLOSEREF    DB     0

OPENME      DB     3
            DA     OURNAME
            DA     IOBUFFER
MYOREF      DB     1

MYMRKLST    DB     2
MYMRKREF    DB     0
MYMRK       DS     3

MYWRLIST    DB     4
MYWRREF     DB     0
            DA     SERIAL
            DA     2
            DA     0

QUITLST     DB     4
            DB     0
            DA     0
            DA     0
            DA     0

LLUCE_NM    STR    'LLUCE.SYSTEM'

SERIAL      DS     2
            ORG

ENDOFIT
            LST    OFF
            DO     LISTSYM
            LST
            FIN
            TTL    'SETUP - Symbol Table'

