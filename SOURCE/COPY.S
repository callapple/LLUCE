********************************
*                              *
*         File Copier          *
*                              *
********************************
            DATE
*-------------------------------

Id          =      5
Aux         =      2

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
            PUT    EQUATES/ERRORS
            LST    RTN

]TYPE       =      ^overlays                   ; set file type
]AUX        =      overlays                    ; and aux type
            ORG    ]AUX                        ; must be this way
            TYP    ]TYPE

            DSK    /RAM5/COPY

            TTL    'LLUCE - File Copier'
            DO     LISTOBJ
            LST
            FIN
*===============================
* File Copy Overlay
*===============================

            DB     Id
            DA     Aux
            DB     Aux/256!Aux!Id!$A5

*-------------------------------
* Size Of Code To Check For CRC
*-------------------------------

            DA     CODEEND-COPY
            DA     0                           ; CRC Goes Here

            ORG    $D000

COPY        JSR    GOBCOM                      ; Eat The Comma
            JSR    MOVNAME                     ; Get Source File Name
            LDA    #10                         ; Get Original Info
            STA    ENDMOD
            LDA    #<FLNAME
            STA    ENDMOD+1
            LDA    #>FLNAME
            STA    ENDMOD+2
            JSR    MLI
            DB     Getinfo
            DA     ENDMOD
            BCS    ERROR                       ; Doesn't Exist

            LDA    #%00100001                  ; Request Read, Deny Write
            JSR    PD_OPEN                     ; Open It If It Can
            BCS    ERROR                       ; If Not, Error

            LDA    REFNUM                      ; Save Source Ref Number
            STA    SRCREF
            STZ    ERRFLG
            JSR    GOBCOM                      ; Eat Next Comma
            JSR    MOVNAME                     ; Get Dest File Name
TRYOPEN     LDX    #5
MV_OLST     LDA    OPENLST,X
            STA    ENDMOD+$40,X
            DEX
            BPL    MV_OLST

            JSR    MLI                         ; Try To Open It
            DB     Open
            DA     ENDMOD+$40
            BCC    EXISTS                      ; It Exists, Use It

            LDA    ERRFLG                      ; First Try?
            BNE    ERROR                       ; No, Can't Do It

            LDA    #7
            STA    ENDMOD
            LDX    #$D                         ; Save Original File Stats
MV_FINFO    LDA    ENDMOD,X
            STA    FINFO,X
            DEX
            BPL    MV_FINFO

            LDX    #3                          ; Move Creation Date
MV_DATE     LDA    ENDMOD+$E,X
            STA    ENDMOD+8,X
            DEX
            BPL    MV_DATE

            LDA    #%11000011                  ; Set Full Access
            STA    ENDMOD+3
            JSR    MLI                         ; Create The New File
            DB     Create
            DA     ENDMOD
            BCS    ERROR

            INC    ERRFLG                      ; Flag File Created
            BRA    TRYOPEN

ERROR       LDA    #Usrerr+1                   ; Do Error
            JMP    BADERR

EXISTS      LDA    ENDMOD+$45                  ; Save Dest Ref Number
            STA    DSTREF
CPY_LOOP    LDA    SRCREF                      ; Get Source Reference
            STA    REFNUM
            LDX    #<ENDMOD                    ; Read A Chunk Of Source
            LDA    #>ENDMOD
            LDY    #32                         ; Read 32-128 Byte Pages, 4K
            JSR    PD_RDBLK
            BCS    CPY_DONE                    ; Error Means Done (Usually)

            LDA    DSTREF                      ; Get Destination Reference
            STA    REFNUM
            LDX    #<ENDMOD                    ; Write Chunk To Destination
            LDA    #>ENDMOD
            LDY    #32                         ; Write 32-128 Byte Pages
            JSR    PD_WRBLK
            BCC    CPY_LOOP                    ; Error Is No Good

            LDA    #Usrerr+2
            JMP    BADERR

CPY_DONE    LDA    #2                          ; Set Up For Eof Calls
            STA    ENDMOD
            LDA    SRCREF                      ; Get Eof Of Original
            STA    ENDMOD+1
            STA    REFNUM
            JSR    MLI
            DB     Geteof
            DA     ENDMOD
            JSR    PD_CLOSE                    ; And Close Original
            LDA    DSTREF                      ; Set Eof Of New File
            STA    ENDMOD+1
            STA    REFNUM
            JSR    MLI
            DB     Seteof
            DA     ENDMOD
            JSR    PD_CLOSE                    ; Close It Too
            LDX    #$D                         ; Set File Stats To Original
CPY_ACS     LDA    FINFO,X                     ; Mainly Sets Access Byte At
            STA    ENDMOD,X                    ; This Time
            DEX
            BPL    CPY_ACS

            JSR    MLI
            DB     Setinfo
            DA     ENDMOD
            RTS

OPENLST     DB     3
            DA     FLNAME
            DA     MSGBUF
            DB     0

ERRFLG      DS     1

SRCREF      DS     1
DSTREF      DS     1

FINFO       DS     $E
CODEEND     =      *
            LST    OFF
            DO     LISTSYM
            LST
            FIN
            TTL    'COPY - Symbol Table'

