********************************
*                              *
*     Find Open Record         *
*                              *
********************************
            DATE
*-------------------------------

Id          =      5
Aux         =      4

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
            PUT    EQUATES/EQUATES
            PUT    EQUATES/OS.EQUATES
            PUT    EQUATES/ENTRY
            PUT    EQUATES/DRIVEREQU
            PUT    EQUATES/RAMAREA
            LST    RTN

]TYPE       =      ^overlays                        ; set file type
]AUX        =      overlays                         ; and aux type
            ORG    ]AUX                             ; must be this way
            TYP    ]TYPE

            DSK    /RAM5/FINDOPEN

            TTL    'LLUCE - Find Open User Record'
            DO     LISTOBJ
            LST
            FIN

            DB     Id
            DA     Aux
            DB     Aux/256!Aux!Id!$A5

*-------------------------------
* Size Of Code To Check CRC
*-------------------------------

            DA     CODEEND-START
            DA     0                                ; CRC Goes Here

            ORG    $D000

*-------------------------------
* Calling Syntax Is:
*
* Overlay "Findopen","Search","Filename",X,F
*
* X = Record Length When Calling
* F = Field To Check
*
* Exit Codes, Returned In F
*
* F = -2 If Duplicate Is Found
* F = -1 If File Is Bad
* F = >0 First Empty Record
*-------------------------------

START       LDX    #CODEEND-READLOC
MVREAD      LDA    READLOC,X                        ; Move The Parameter List
            STA    READLST,X
            DEX
            BPL    MVREAD

            LDX    #HANDLE-CODEEND
ZEROST      STZ    CODEEND,X                        ; Zero All Parms
            DEX
            BPL    ZEROST

            JSR    GOBCOM                           ; Get Name To Search For
            JSR    INPSTR

            STY    LENGTH                           ; Save it
MVNAME      DEY
            LDA    (STRLOC),Y
            JSR    CONV
            STA    HANDLE,Y
            TYA
            BNE    MVNAME

            JSR    GOBCOM                           ; Get File Name To Search
            JSR    MOVNAME

            JSR    GOBCOM                           ; Get Record Length
            JSR    INPNUM
            STX    RECLEN                           ; Save Length And First Mark
            STA    RECLEN+1

            LDA    #1
            STA    COUNT
            STZ    COUNT+1

            JSR    GOBCOM
            JSR    INPNUM                           ; Get Field Number
            TXA                                     ; If 0, leave alone, if not
            BEQ    NOTZERO                          ; Subtract 1
            DEC    A
NOTZERO     STA    FIELDNO

            JSR    PD_OPEN                          ; Open the file
            BCC    GOODOPEN

            DEC    FIRSTREC                         ; Make -1 for error
            DEC    FIRSTREC+1
            DEC    FIRSTREC+2
            JMP    FINISH

GOODOPEN    LDA    REFNUM                           ; Save ref numbers
            STA    READREF
            STA    MARKREF

            JSR    PD_NEWLN                         ; Set newline mode
            BRA    ADDLEN

DO_READ     LDA    FIELDNO                          ; Set field to check
            STA    FIELD

            STZ    EDBUF                            ; Zero buffer for errors

            JSR    MLI                              ; Read the line
            DB     Read
            DA     READLST
            BCS    GO_FIN                           ; exit if error

            LDA    EDBUF                            ; Get first char
            AND    #Clrhi
            BEQ    FTEST                            ; If null, record empty, maybe

            CMP    #','                             ; Record Empty?
            BEQ    FTEST                            ; Yes, Flag First Empty, Maybe

            CMP    #cr                              ; Sure It's Empty?
            BEQ    FTEST                            ; Nope, Go Test It
            BRA    READAGN

FTEST       BIT    NUSED                            ; First Already Found?
            BMI    READAGN                          ; Yes, Skip It Then

            LDA    COUNT                            ; Move Count
            STA    FIRSTREC
            LDA    COUNT+1
            STA    FIRSTREC+1
            DEC    NUSED                            ; Flag First Found
            BRA    GONEXT

READLUP     STZ    EDBUF
            JSR    MLI                              ; Read In A Field
            DB     Read
            DA     READLST
GO_FIN      BCS    FINISH

READAGN     DEC    FIELD                            ; Count Down Fields
            BPL    READLUP

            LDY    #-1                              ; Check For Match
TSTLUP      INY
            CPY    LENGTH                           ; At End Of String?
            BEQ    FOUND                            ; No, Continue Checking

            LDA    EDBUF,Y                          ; Get Character
            JSR    CONV
            CMP    HANDLE,Y
            BEQ    TSTLUP

GONEXT      INC    COUNT                            ; Add 1 To Record Count
            BNE    ADDLEN
            INC    COUNT+1
ADDLEN      CLC
            LDA    MARK                             ; Add In Record Length
            ADC    RECLEN
            STA    MARK
            LDA    MARK+1
            ADC    RECLEN+1
            STA    MARK+1
            LDA    MARK+2
            ADC    #0
            STA    MARK+2
            JSR    MLI
            DB     Setmark
            DA     MARKLST
            JMP    DO_READ

FOUND       LDX    #-1                              ; Make It -2
            STX    FIRSTREC+2                       ; Duplicate Found
            STX    FIRSTREC+1
            DEX
            STX    FIRSTREC
FINISH      JSR    PD_CLOSE
            LDY    #1
            LDA    FIRSTREC
            STA    (VPTR)
            LDA    FIRSTREC+1
            STA    (VPTR),Y
            LDA    FIRSTREC+2
            INY
            STA    (VPTR),Y
            RTS

CONV        AND    #Clrhi
            CMP    #'a'
            BLT    CONV2
            CMP    #'z'+1
            BGE    CONV2
            SBC    #$1F
CONV2       RTS

READLOC     =      *

            ORG    $380

READLST     DB     4
READREF     DB     0
            DA     EDBUF
RECLEN      DA     0
            DA     0

MARKLST     DB     2
MARKREF     DB     0
MARK        DS     3

            ORG

CODEEND     =      *

NUSED       DB     0
COUNT       DA     0
FIRSTREC    DB     0,0,0
LENGTH      DB     0
FIELDNO     DB     0
FIELD       DB     0

HANDLE      =      *

            LST    OFF
            DO     LISTSYM
            LST
            FIN
            TTL    'FINDOPEN - Symbol Table'

