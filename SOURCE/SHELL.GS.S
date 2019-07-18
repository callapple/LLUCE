********************************
*                              *
*  Shell to system file        *
*                              *
********************************
*
* This overlay allows shelling to any system program,
* and returning to LLUCE at the place you left off.
*
* Calling format is:
*
* overlay "shell","system.prog"
*   [,"startpath"][,"initial.pfx"][,"save.name"]
*
* All parameters must be in their proper place.
* What this means is that if you wish to have a
* save.name, but not a startpath or initial.pfx,
* you must still supply those parameters, but they
* should be empty strings ("").
*
* "system.prog" may be any program that executes at
* $2000.
*
* "startpath" is the path of the startup file for the
* program being run.
*
* "initial.pfx" is the prefix to set before executing
* system.prog.  If this is different from the folder
* containing "system.prog", "system.prog" must be a
* complete pathname.
*
* "save.name" is a filename to save memory to.
* The default is "LLUCE.SAVE" in the LLUCE.SYSTEM
* directory.  Move to a ramdisk for faster operation.
*
* NOTE: All pathnames MUST be complete pathnames
*       unless the partial path is in the CURRENT
*       directory (Lance!)
*-------------------------------
            DATE
*-------------------------------

Id          =      5
Aux         =      255

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
NOLIST      =      N
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
            LST    RTN

]TYPE       =      ^overlays                          ; set file type
]AUX        =      overlays                           ; and aux type
            ORG    ]AUX                               ; must be this way
            TYP    ]TYPE

            DSK    /MAIN/LLUCE/SYSTEM/SHELL.GS

            TTL    'LLUCE - Shell to system file'
            DO     LISTOBJ
            LST
            FIN

            DB     Id
            DA     Aux
            DB     Aux/256!Aux!Id!$A5

*-------------------------------
* Size Of Code To Check CRC
*-------------------------------

            DA     IOEND-MAIN
            DA     0                                  ; CRC Goes Here

PATH2       =      LNBUF+$80

            ORG    $D000

MAIN        MOVD   MLI+1;ORIGMLI                      ; save patches
            MOVD   IRQVEC;ORIGIRQ
            MOVD   RESETVEC;ORIGRST

            LDX    #0
MOVEMOVE    MOV    MOVECODE,X;DO_MOVES,X
            DBNE   X;MOVEMOVE

            PDOS   Getpfx;PFXLST                      ; get and save prefix

            LDX    PATH2
SVOPFX      MOV    PATH2,X;ORIGPFX+QUITCODE-QUIT,X
            DBPL   X;SVOPFX

            LDX    SYSPFX                             ; set to LLUCE system pfx
MOVSPFX     MOV    SYSPFX,X;PATH2,X
            DBPL   X;MOVSPFX

            PDOS   Setpfx;PFXLST

            STZ    PRN
            JSR    GOBCOM                             ; get the filename
            JSR    MOVNAME
            LDX    FLNAME
MOVFNAME    MOV    FLNAME,X;PATHNAME+EXITCODE-EXIT,X
            DBPL   X;MOVFNAME

            STZ    PREFIX+EXITCODE-EXIT               ; set for no prefix
            STZ    STARTUP+EXITCODE-EXIT              ; set no startup

            IFNE   (PRGPTR);#','+Hibit;NONAMES

            JSR    GOBCOM                             ; get the start name
            JSR    MOVNAME
            LDX    FLNAME
            BEQ    EMPTYST
MOVSTRT     MOV    FLNAME,X;STARTUP+EXITCODE-EXIT,X
            DBPL   X;MOVSTRT

EMPTYST     IFNE   (PRGPTR);#','+Hibit;NONAMES

            JSR    GOBCOM                             ; get the prefix
            JSR    MOVNAME
            LDX    FLNAME
            BEQ    EMPTYPFX
MOVPREFX    MOV    FLNAME,X;PREFIX+EXITCODE-EXIT,X
            DBPL   X;MOVPREFX

EMPTYPFX    IFNE   (PRGPTR);#','+Hibit;NONAMES

            JSR    GOBCOM                             ; get the save name
            JSR    MOVNAME
            LDX    FLNAME
            BEQ    NONAMES
MOVSAVNM    MOV    FLNAME,X;SAVEPATH+QUITCODE-QUIT,X
            DBPL   X;MOVSAVNM

NONAMES     LD16   #PATHNAME+EXITCODE-EXIT
            JSR    EXISTS
            BCS    ERROR2
            LD16   #STARTUP+EXITCODE-EXIT
            JSR    EXISTS
            BCS    ERROR2
            LD16   #PREFIX+EXITCODE-EXIT
            JSR    EXISTS
            BCC    ALL_OK
ERROR2      JMP    ERROR

ALL_OK      JSR    DO_CL3                             ; all files closed

*-------------------------------
* Done accessing LLUCE code
*-------------------------------

            PHP
            SEI
            MOVD   PDOSVEC;MLI+1
            MOVD   IRQSAVE;IRQVEC
            PLP

            LDX    SAVEPATH+QUITCODE-QUIT
MOVPATH     MOV    SAVEPATH+QUITCODE-QUIT,X;PATH2,X
            DBPL   X;MOVPATH

            CLC                                       ; set native mode
            XCE
            REP    #%00110000
            MX     %00
            PHA
            PEA    $1000
            LDX    #$2003                             ; GetNewID
            JSL    $E10000
            PLA
            STA    USERID+QUITCODE-QUIT
            STA    ERRID
            PHA
            PHA
            PEA    1                                  ; $10000 bytes
            PEA    0
            PHA
            LDA    #$C018                             ; Locked, fixed, nocross, nospec
            PHA
            PEA    0
            PEA    0
            LDX    #$0902                             ; NewHandle
            JSL    $E10000
            PLX
            STX    TEMP
            PLX
            STX    TEMP+2
            BCC    GOT_HNDL
            MX     %11
            JSR    ERROR
            LDA    #0                                 ; reload last segment
            PHA
            PHA
            PHA
            PHA
            PHA
            PHA
            LDA    #$80                               ; continue last segment
            JSR    RELOAD                             ; no return from here

            MX     %00
GOT_HNDL    LDY    #2
            LDA    [TEMP],Y
            STA    SAVEBANK+QUITCODE-QUIT
            STA    TEMP3+2
            STZ    TEMP+2

            BRK    00

            JSR    DO_MOVES                           ; move all code out

            REP    #%00100000
            MX     #%01
            MOV    #EXITCODE;TEMP
            MOV    #EXIT;TEMP3
            SEP    #%00110000
            MX     %11
            LDX    #2
            LDY    #0
MOVELUP     MOV    (TEMP),Y;(TEMP3),Y
            DBNE   Y;MOVELUP
            DBNE   X;MOVELUP

            JSR    EXIT                               ; returns only if error

ERROR       STA    PRN

            CLC
            XCE
            REP    #%00110000                         ; restores all of LLUCE
            MX     %00
            MOV    #TEMP;TEMP
            STA    TEMP3

            SEP    #%00110000
            MX     %11
            LDX    #>MLI
            LDY    #0
RSTELUP     MOV    [TEMP3],Y;[TEMP],Y
            DBNE   Y;RSTELUP
            DBNE   X;RSTELUP

            REP    #%00010000
            MX     %00

            LDA    ERRID
            PHA
            LDX    #$1102                             ; DisposeAll
            JSL    $E10000

            SEP    #%00110000
            MX     %11
            SEC
            XCE

            PHP
            SEI
            MOVD   ORIGMLI;MLI+1
            MOVD   ORIGIRQ;IRQVEC
            MOVD   ORIGRST;RESETVEC
            EOR    #$A5
            STA    SOFTEV
            PLP
            RTS

EXISTS      ST16   TEMP
            CLC
            LDA    (TEMP)
            BEQ    IS_THERE
            TAY
MVEXIST     MOV    (TEMP),Y;PATH2,Y
            DBPL   Y;MVEXIST
            PDOS   Getinfo;INFOLST
IS_THERE    RTS

ORIGMLI     DW     0
ORIGIRQ     DW     0
ORIGRST     DW     0
ERRID       DW     0

            DS     \

QUITCODE    ORG    ENDMOD

QUIT        CLD                                       ; for ProDOS

            BRK    00

            CLC
            XCE
            REP    #%00110000
            MX     %00

            LDX    #0                                 ; move quit code up
QUITUP      MOV    $1000,X;QUIT,X
            MOV    $1100,X;QUIT+$100,X
            MOV    $1200,X;QUIT+$200,X
            DEX
            DBNE   X;QUITUP
            JMP    QUITCONT

QUITCONT    LDA    SAVEBANK
            STA    TEMP3+2
            STZ    TEMP+2

            LDA    #ENDMOD                            ; saves all of LLUCE
            LDX    #TEMP
            TXY
            JSR    MOVEIN

            LDA    #MLI-FBUF3
            LDX    #FBUF3
            TXY
            JSR    MOVEIN

            SEP    #%00100000
            STZ    SETRAM1
            REP    #%00100000
            LDA    #$1000                             ; move D000-DFFF main bank 1
            LDX    #MAIN-$1000
            LDY    #MAIN
            JSR    MOVEIN

            SEP    #%00100000
            STZ    SETALTZP                           ; move D000-FEFF aux bank 1
            REP    #%00100000
            LDA    #$3000-$100
            LDX    #MAIN
            TXY
            JSR    MOVEIN

            LDA    USERID
            PHA
            LDX    #$1102                             ; DisposeAll
            JSL    $E10000

            SEP    #%00110000
            MX     %11
            SEC
            XCE

            PLP
            STZ    SETSTDZP

            IFNE   DEV1ADR;DEV2ADR+6;KILLRAM          ; /RAM
            IFEQ   DEV1ADR+1;DEV2ADR+7;NORAM          ; installed?

KILLRAM     LDX    DEVCNT                             ; Find Any Ramdisk
FNDRAM      LDA    DEVLST,X                           ; Get Device Id Byte
            TAY
            AND    #$B3                               ; Low Nibble Is Type
            CPEQ   #$B3;MVDEV                         ; Is It A RAM Disk?

            DBPL   X;FNDRAM                           ; Go To Next Device
            BRA    NORAM

MVDEV       MOV    DEVLST+1,X;DEVLST,X                ; Copy Bytes Down
            INX
            CPLTX  #13;MVDEV                          ; Finished With List?
            STZ    DEVLST+13                          ; zap last byte

            DEC    DEVCNT                             ; 1 Less Device

            LD16   DEV2ADR+6                          ; save driver info
            STZ    SETALTZP                           ; in alt zp
            ST16   RAMDRVR
            STY    RAMDEV
            STZ    SETSTDZP

            MOVD   DEV1ADR;DEV2ADR+6                  ; set no device

            TYA
            AND    #HiNibble
            STA    UNIT                               ; Save Unit Number
            PDOS   Online;ONLINE                      ; This Clears Device

NORAM       PHP
            SEI
            STZ    SETRAM2                            ; Select Ram Card
            STZ    SETRAM2
            STZ    SETALTZP

            MOVD   ORIGMLI;MLI+1
            MOVD   ORIGIRQ;IRQVEC
            MOVD   ORIGRST;RESETVEC
            EOR    #$A5
            STA    SOFTEV
            PLP

            STZ    AUTOLOG                            ; Clear auto logon flag
            STZ    V_MODE
            STZ    BLINK
            STZ    DISP80                             ; Switch To 80 Column Mode
            STZ    STORE80                            ; Enable Page Select
            STZ    ALTCHRS                            ; Mousetext Available
            STZ    VIDECHO                            ; Make Sure Characters

            MOV    #vidWidth;V_OLDCV                  ; 80 Columns Wide

            LDA    LORES                              ; ** It Makes Things Work !!
            LDA    ANU_ON                             ; Annunc_On
            LDA    KBDSTRB

            MOV    #$60;USERVEC                       ; Put RTS For User-Routine

            LDA    #ff                                ; clear any junk
            JSR    VIDCOUT

            LDA    #0                                 ; reload last segment
            PHA
            PHA
            PHA
            PHA
            PHA
            PHA
            LDA    #$80                               ; continue last segment
            JSR    RELOAD                             ; no return from here

MOVEIN      STX    TEMP
            STY    TEMP3
            SEP    %00010000
            MX     %01
            XBA
            TAX
            LDY    #0
INLOOP      MOV    [TEMP3],Y;[TEMP],Y
            DEY
            DBNE   Y;INLOOP
            INC    TEMP+1
            INC    TEMP3+1
            DBNE   X;INLOOP
            REP    %00010000
            RTS

RSTSAME     STX    TEMP
            STY    TEMP3
            SEP    %00010000
            MX     %01
            XBA
            TAX
            LDY    #0
RSTLOOP     MOV    (TEMP3),Y;(TEMP),Y
            DEY
            DBNE   Y;RSTLOOP
            INC    TEMP+1
            INC    TEMP3+1
            DBNE   X;RSTLOOP
            REP    %00010000
            RTS

ONLINE      DB     2
UNIT        DB     0
            DA     LNBUF+$81

SAVEBANK    DW     0
USERID      DW     0

            DS     $A280-*

SAVEPATH    STR    'LLUCE.SAVE'                       ; our save name
            DS     $40-*+SAVEPATH,' '                 ; DON'T TOUCH
ORIGPFX     DS     $40                                ; Prefix to return to
            ORG

EXITCODE    ORG    $1000

EXIT        SEP    #%00110000                         ; set emulation mode
            MX     %11
            SEC
            XCE

            PHP
            SEI

            LDEQ   RAMDEV;NODRVR                      ; /RAM removed?

            MOVD   RAMDRVR;DEV2ADR+6

            INC    DEVCNT
            LDY    DEVCNT
FIXDEV      MOV    DEVLST-1,Y;DEVLST,Y
            DBNE   Y;FIXDEV
            MOV    RAMDEV;DEVLST
            STZ    SETSTDZP                           ; set to standard zp
            AND    #HiNibble
            STA    DVRUNIT
            MOV    #3;DVRCMD                          ; format command
            MOVD   #SYSTEM;DVRBUFF
            LDA    SETRAM2
            JSR    FMTDVR
            BCS    EXITERR

NODRVR      STZ    SETSTDZP                           ; set to standard zp
            STZ    SETROM
            PLP

            LDEQ   PREFIX;SAMEPFX
            PDOS   Setpfx;SPFXLST
            BCS    EXITERR
SAMEPFX     PDOS   Open;OPENALST
            BCS    EXITERR
            MOV    OPENAREF;READAREF
            STA    CLSALST
            PDOS   Read;READALST
            BCS    EXITERR
            PDOS   Close;CLSALST
            BCS    EXITERR

            LDEQX  STARTUP;GOSYS                      ;any startup path?
            IFNE   SYSTEM;#$20;GOSYS                  ; place for startup?
            IFNE   #$EE;SYSTEM+3;GOSYS
            CPNE   SYSTEM+4;GOSYS
            IFLT   STARTUP;SYSTEM+5;GOSYS

MVSTART     MOV    STARTUP,X;SYSTEM+6,X               ; move in path
            DBPL   X;MVSTART

GOSYS       JMP    SYSTEM

FMTDVR      JMP    (DEV2ADR+6)

EXITERR     STZ    SETRAM2                            ; Select Ram Card
            STZ    SETRAM2
            STZ    SETALTZP
            RTS

OPENALST    DB     3
            DA     PATHNAME
            DA     FBUF1
OPENAREF    DB     0

READALST    DB     4
READAREF    DB     0
            DW     SYSTEM
            DW     MLI-SYSTEM
            DW     0

CLSALST     DB     1
CLSAREF     DB     0

SPFXLST     DB     1
            DA     PREFIX

            DS     \

PATHNAME    DS     $40
PREFIX      DS     $40
STARTUP     DS     $40
            DS     $40
            ORG
EXITEND     =      *

MOVECODE    ORG    ENDMOD+$400

            MX     %00
DO_MOVES    LDA    #MLI                               ; saves all of LLUCE
            LDX    #TEMP
            TXY
            JSR    MOVEOUT

            LDA    #$300                              ; move quit code down
            LDX    #QUITCODE
            LDY    #QUIT
            JSR    MOVESAME

            LDA    TEMP3+2
            SEP    #%00100000
            STZ    SETSTDZP                           ; this saves the quit code
            STZ    SETRAM1
            REP    #%00100000
            STA    TEMP3+2
            STZ    TEMP+2
            LDA    #$1000                             ; move D000-DFFF main bank 1
            LDX    #MAIN
            LDY    #MAIN-$1000
            JSR    MOVEOUT

            LDA    #$300                              ; put in our quit code
            LDX    #QUITCODE
            LDY    #$D100
            JSR    MOVESAME

            SEP    #%00100000
            STZ    SETALTZP                           ; move D000-FEFF aux bank 1
            REP    #%00100000
            LDA    #$3000-$100
            LDX    #MAIN
            TXY
            JSR    MOVEOUT

            SEP    #%00100000
            STZ    SETRAM2
            RTS

MOVEOUT     STX    TEMP
            STY    TEMP3
            SEP    #%00010000
            MX     %01
            XBA
            TAX
            LDY    #0
OUTLOOP     MOV    [TEMP],Y;[TEMP3],Y
            DEY
            DBNE   Y;OUTLOOP
            INC    TEMP+1
            INC    TEMP3+1
            DBNE   X;OUTLOOP
            REP    #%00010000
            RTS

MOVESAME    STX    TEMP
            STY    TEMP3
            SEP    #%00010000
            MX     %01
            XBA
            TAX
            LDY    #0
SAMELOOP    MOV    (TEMP),Y;(TEMP3),Y
            DEY
            DBNE   Y;SAMELOOP
            INC    TEMP+1
            INC    TEMP3+1
            DBNE   X;SAMELOOP
            REP    #%00010000
            RTS

PFXLST      DB     1
            DW     PATH2

INFOLST     DB     10
            DW     PATH2
            DB     0
            DB     0
            DW     0
            DB     0
            DW     0
            DW     0
            DW     0
            DW     0
            DW     0
            ORG
IOEND       =      *

            LST    OFF
            DO     LISTSYM
            LST
            FIN
            TTL    'SHELL - Symbol Table'

