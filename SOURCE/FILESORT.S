********************************
*                              *
*     Sequential File Sort     *
*                              *
********************************
            DATE
*-------------------------------

Id          =      5
Aux         =      3

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

]TYPE       =      ^overlays                         ; set file type
]AUX        =      overlays                          ; and aux type
            ORG    ]AUX                              ; must be this way
            TYP    ]TYPE

            DSK    /RAM5/FILESORT

            TTL    'LLUCE - File Sort'
            DO     LISTOBJ
            LST
            FIN

SRTSTR      =      a1
CSTRST      =      a2
CSTRLEN     =      a3
WORKLEN     =      a3+1
CSTREND     =      a4
MEMBTM      =      NODENUM
MEMTOP      =      MLI

            DB     Id
            DW     Aux
            DB     Aux/256!Aux!Id!$A5

            DA     PARMLSTS-CODESTRT
            DA     0

DiskErr     =      249
FileLock    =      250
VolProt     =      251
FileBig     =      253
BadParm     =      254
NoFile      =      255

*-------------------------------
* Syntax For Use With This Overlay
*
* Overlay "Filesort","Filename",Error
*
* Error Code Is Returned In Error
*
*   0 = No Error
* 249 = Another Disk Error
* 250 = File Locked
* 251 = Disk Write Protected
* 253 = File Too Large
* 254 = Invalid Parameter
* 255 = File Not Found
*-------------------------------
            ORG    $D000

CODESTRT    =      *

BEGIN       LDX    #ENDPARMS-PARMLSTS
MV_PARMS    LDA    PARMLSTS,X                        ; Move Parameter Lists
            STA    EOFLST,X
            DEX
            BPL    MV_PARMS

            JSR    GOBCOM                            ; Get file name
            JSR    MOVNAME

            JSR    GOBCOM                            ; Get error code variable
            JSR    INPNUM

            LDA    #%00110011                        ; Request All, Deny All
            JSR    PD_OPEN
            BCC    TSTSIZE

            LDA    #NoFile                           ; File not found
            BRA    ERROR

TSTSIZE     STA    RWREF                             ; Save references
            STA    MARKREF
            STA    EOFREF

            JSR    MLI                               ; Get file size
            DB     Geteof
            DW     EOFLST
            LDA    EOF+2                             ; Check file size
            BNE    TOOBIG

            LDA    EOF+1
            CMP    #>MEMTOP-MEMBTM
            BLT    SIZE_OK

TOOBIG      JSR    PD_CLOSE                          ; Close the file

            LDA    #FileBig                          ; File too large
ERROR       JMP    NOERR

SIZE_OK     STZ    SRTSTR                            ; Point to bottom of file
            LDA    #>MEMBTM
            STA    SRTSTR+1

            LDA    #-1
            STA    NUMBLKS                           ; Zero Number Of Blocks Read

READIT      INC    NUMBLKS                           ; Increment Blocks Read

            JSR    MLI                               ; Read in a chunk
            DB     Read
            DW     RWLST

            STZ    CSTRST                            ; Point To Start Of Buffer
            LDA    #>ENDMOD
            STA    CSTRST+1

            STZ    AUXWRT                            ; Putting stuff in aux ram

            LDY    #0
            LDX    #$10                              ; Move 4K
RD_MOVE     LDA    (SRTSTR),Y
            AND    #Clrhi
            STA    (CSTRST),Y
            INY
            BNE    RD_MOVE
            INC    SRTSTR+1
            INC    CSTRST+1
            DEX
            BNE    RD_MOVE

            STZ    MAINWRT                           ; Come back to main ram

            LDA    XFERED                            ; Finished Reading?
            BNE    RD_DONE
            LDA    XFERED+1
            CMP    #$10
            BEQ    READIT

RD_DONE     LDX    XFERED                            ; Calculate Top Of Memory
            LDA    XFERED+1
            STX    XTRABYTE
            STA    XTRABYTE+1

            STX    TEMP
            LDX    NUMBLKS

            LDA    #0                                ; Multiply
ADD         CLC                                      ; Add In Pages Read
            ADC    #$10
            DEX
            BPL    ADD

            CLC                                      ; Add in the extra bytes
            ADC    XTRABYTE+1
            CLC
            ADC    #>MEMBTM
            STA    TEMP+1

            STZ    AUXREAD                           ; Set Aux Memory
            STZ    AUXWRT

            LDX    #<MEMBTM                          ; Reset to start again
            LDA    #>MEMBTM
            STX    CSTRST
            STA    CSTRST+1
            JSR    PRHEX                             ; Show where we are
            JSR    SETNEXT                           ; Find end of line

TESTIT      LDY    CSTREND                           ; point to next line start
            LDX    CSTREND+1
            INY
            BNE    ENDOK
            INX
ENDOK       STY    CSTRST
            STX    CSTRST+1

            JSR    PRBSHEX                           ; Show location

            JSR    TESTEND                           ; At end of data?
            BCC    NOTEND                            ; Nope, sort

            JMP    FINISH                            ; Finish up

NOTEND      JSR    SETNEXT                           ; Point to next line

            LDX    #<MEMBTM                          ; Point to start of buffer
            LDA    #>MEMBTM
            STX    SRTSTR
            STA    SRTSTR+1

TSTNEXT     LDA    SRTSTR                            ; Finished with this chunk?
            CMP    CSTRST
            BNE    FINDLEN                           ; Nope, do next line
            LDA    SRTSTR+1
            CMP    CSTRST+1
            BEQ    TESTIT                            ; Yes, sort next line in

FINDLEN     LDY    #0                                ; Point to line start
LEN_LOOP    LDA    (SRTSTR),Y
            CMP    #cr                               ; End of line?
            BEQ    SAVELEN                           ; Yes
            INY
            BNE    LEN_LOOP

SAVELEN     INY                                      ; Save length
            STY    TEMP2

            LDX    CSTRLEN                           ; Work with shorter line
            CPX    TEMP2
            BGE    LEN_OK
            LDX    TEMP2
LEN_OK      STX    WORKLEN

            LDY    #-1                               ; Start at beginning
CHK_NEXT    INY                                      ; Bump pointer
            CPY    WORKLEN                           ; Done with line?
            BEQ    NOSWAP                            ; If so, it's equal

            LDA    (SRTSTR),Y                        ; Byte from line 1
            JSR    CONV                              ; Upper case it
            STA    PRN

            LDA    (CSTRST),Y                        ; Byte from line 2
            JSR    CONV                              ; Upper case it

            CMP    PRN
            BEQ    CHK_NEXT                          ; Same in both lines
            BGE    NOSWAP                            ; In order already

            JSR    INSERT                            ; Switch lines
            JMP    TESTIT                            ; Do next one

NOSWAP      CLC                                      ; Point to next line
            LDA    SRTSTR
            ADC    TEMP2
            STA    SRTSTR
            LDA    SRTSTR+1
            ADC    #0
            STA    SRTSTR+1

            CMP    CSTRST+1                          ; Done with block?
            BNE    TSTNEXT                           ; Nope
            LDA    SRTSTR
            CMP    CSTRST
            BNE    TSTNEXT

            JMP    TESTIT                            ; Do next one

FINISH      STZ    MAINWRT                           ; Set back to main RAM
            STZ    MAINREAD

            JSR    MLI                               ; Zero mark
            DB     Setmark
            DW     MARKLST

            STZ    CSTRST                            ; Point to buffer start
            LDA    #>MEMBTM
            STA    CSTRST+1

WRITE_LP    STZ    CSTRST                            ; Point To Start Of Buffer
            LDA    #>ENDMOD
            STA    CSTRST+1

            LDY    #0
            STZ    AUXREAD                           ; aux memory
            LDX    #$10                              ; Move 4K
WR_MOVE     LDA    (SRTSTR),Y
            STA    (CSTRST),Y
            INY
            BNE    WR_MOVE
            INC    SRTSTR+1
            INC    CSTRST+1
            DEX
            BNE    WR_MOVE

            STZ    MAINREAD                          ; back to main ram

            DEC    NUMBLKS                           ; Do all blocks
            BPL    DO_WRITE

            LDX    XTRABYTE                          ; set number of extra bytes
            LDA    XTRABYTE+1
            STX    REQUEST
            STA    REQUEST+1

DO_WRITE    JSR    MLI                               ; Write the extra bytes
            DB     Write
            DW     RWLST

            BIT    NUMBLKS
            BPL    WRITE_LP

            PHA                                      ; Save any error code
            JSR    PD_CLOSE                          ; Close it up

            LDA    #bs                               ; wipe out address
            LDX    #4
            JSR    PMULT
            LDA    #'-'
            LDX    #4
            JSR    PMULT

            PLA                                      ; Restore error code
            BEQ    NOERR

            LDX    #VolProt                          ; Disk write protected
            CMP    #drvrWrtProt
            BEQ    RTNCODE

            DEX                                      ; Access not allowed
            CMP    #invalidAccess
            BEQ    RTNCODE

            DEX                                      ; All other errors
RTNCODE     TXA                                      ; Save error code
NOERR       LDY    #0
            STA    (VPTR),Y
            TYA
            INY
            STA    (VPTR),Y
            INY
            STA    (VPTR),Y

            STZ    MAINREAD                          ; must be in main memory
            STZ    MAINWRT
            RTS

INSERT      LDY    #0                                ; Save this string
KEEP1       LDA    (CSTRST),Y
            STA    LNBUF,Y
            INY
            CMP    #cr
            BNE    KEEP1

            LDX    CSTRST                            ; Move the rest into place
            LDA    CSTRST+1
            STX    STRLOC
            STA    STRLOC+1

MVNEXT      LDA    STRLOC
            BNE    DEC1OK
            DEC    STRLOC+1
DEC1OK      DEC    STRLOC

MOVE2       LDA    (STRLOC)
            STA    (TEMP3)

            LDA    STRLOC
            CMP    SRTSTR
            BNE    DODEC
            LDA    STRLOC+1
            CMP    SRTSTR+1
            BEQ    INSRTIT

DODEC       LDA    TEMP3
            BNE    DEC2OK
            DEC    TEMP3+1
DEC2OK      DEC    TEMP3

            JMP    MVNEXT

INSRTIT     LDY    #0                                ; Stick the line in
MOVE1       LDA    LNBUF,Y
            STA    (SRTSTR),Y
            INY
            CMP    #cr
            BNE    MOVE1

            RTS

SETNEXT     LDY    #0                                ; Get end of line
LENLUP1     LDA    (CSTRST),Y
            CMP    #cr
            BEQ    LENOK
            INY
            BNE    LENLUP1

LENOK       TYA
            INY
            STY    CSTRLEN

            CLC                                      ; Add line len to original
            ADC    CSTRST
            STA    CSTREND
            STA    TEMP3
            LDA    #0
            ADC    CSTRST+1
            STA    CSTREND+1
            STA    TEMP3+1

TOPOK       CLC
            RTS

TESTEND     LDA    CSTRST+1
            CMP    TEMP+1
            BLT    TSTEND2
            LDA    CSTRST
            CMP    TEMP
TSTEND2     RTS

CONV        CMP    #'a'
            BLT    CONV2
            CMP    #'z'+1
            BGE    CONV2
            SBC    #$1F
CONV2       RTS

PRBSHEX     LDA    #bs
            LDX    #4
            JSR    PMULT
PRHEX       LDA    CSTRST+1
            SEC
            SBC    #>MEMBTM
            JSR    PRBYTE
            LDA    CSTRST
PRBYTE      PHA
            LSR    A
            LSR    A
            LSR    A
            LSR    A
            JSR    PRHEXZ
            PLA
            AND    #$F
PRHEXZ      ORA    #'0'
            CMP    #'9'+1
            BCC    GOCOUT
            ADC    #6
GOCOUT      STZ    MAINREAD
            STZ    MAINWRT
            JSR    VIDCOUT
            STZ    AUXREAD
            STZ    AUXWRT
            RTS

PMULT       PHA
            JSR    GOCOUT
            PLA
            DEX
            BNE    PMULT
            RTS

PARMLSTS    =      *

            ORG    $380

EOFLST      DB     2
EOFREF      DB     0
EOF         HEX    000000

RWLST       DB     4
RWREF       DB     0
            DW     MEMBTM
REQUEST     DW     MLI-MEMBTM
XFERED      DW     0

MARKLST     DB     2
MARKREF     DB     0
            HEX    000000

NUMBLKS     DB     0
XTRABYTE    DW     0

            ORG

ENDPARMS    =      *
            LST    OFF
            DO     LISTSYM
            LST
            FIN
            TTL    'LLUCE - File Sort Symbol Table'
            PAG

