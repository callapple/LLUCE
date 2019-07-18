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
NOLIST      =      Y
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

]TYPE       =      ^overlays                         ; set file type
]AUX        =      overlays                          ; and aux type
            ORG    ]AUX                              ; must be this way
            TYP    ]TYPE

            DSK    /MAIN/LLUCE/SYSTEM/SHELL

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
            DA     0                                 ; CRC Goes Here

PATH2       =      LNBUF+$80

            ORG    $D000

MAIN
            MOVD   MLI+1;ORIGMLI                     ; save patches
            MOVD   IRQVEC;ORIGIRQ
            MOVD   RESETVEC;ORIGRST
            LDX    #0
MOVEMOVE    MOV    MOVECODE,X;DO_MOVES,X
            DBNE   X;MOVEMOVE

            PDOS   Getpfx;KILLLST                    ; get and save prefix

            LDX    PATH2
SVOPFX      MOV    PATH2,X;ORIGPFX+QUITCODE-QUIT,X
            DBPL   X;SVOPFX

            LDX    SYSPFX                            ; set to LLUCE system pfx
MOVSPFX     MOV    SYSPFX,X;PATH2,X
            DBPL   X;MOVSPFX

            PDOS   Setpfx;KILLLST

            STZ    PRN
            JSR    GOBCOM                            ; get the filename
            JSR    MOVNAME
            LD16   #PATHNAME+EXITCODE-EXIT
            JSR    FRMFLN

            STZ    PREFIX+EXITCODE-EXIT              ; set for no prefix
            STZ    STARTUP+EXITCODE-EXIT             ; set no startup

            LDX    FLNAME
FINDPFX     LDA    FLNAME,X
            AND    #Clrhi
            CPEQ   #'/';FOUNDPFX
            DBPL   X;FINDPFX
            BRA    NOPFX

FOUNDPFX    STX    FLNAME
            LD16   #PREFIX+EXITCODE-EXIT
            JSR    FRMFLN

NOPFX       IFNE   (PRGPTR);#','+Hibit;NONAMES

            JSR    GOBCOM                            ; get the start name
            JSR    MOVNAME
            LD16   #STARTUP+EXITCODE-EXIT
            JSR    FRMFLN

EMPTYST     IFNE   (PRGPTR);#','+Hibit;NONAMES

            JSR    GOBCOM                            ; get the prefix
            JSR    MOVNAME
            LD16   #PREFIX+EXITCODE-EXIT
            JSR    FRMFLN

EMPTYPFX    IFNE   (PRGPTR);#','+Hibit;NONAMES

            JSR    GOBCOM                            ; get the save name
            JSR    MOVNAME
            LD16   #SAVEPATH+QUITCODE-QUIT
            JSR    FRMFLN

NONAMES     LD16   #PATHNAME+EXITCODE-EXIT
            JSR    EXISTS
            BCS    ERROR
            LD16   #STARTUP+EXITCODE-EXIT
            JSR    EXISTS
            BCS    ERROR
            LD16   #PREFIX+EXITCODE-EXIT
            JSR    EXISTS
            BCS    ERROR

            JSR    DO_CL3                            ; all files closed

            JSR    SYSSTORE                          ; save variables

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

            JSR    DO_MOVES                          ; move all code down
            BCS    MOVEERR
; put path where we can use it
            LDX    #0
MOVMOV2     MOV    MOVCODE2,X;MOVQUIT,X
            DBNE   X;MOVMOV2

            JSR    MOVQUIT

            JSR    SAVEBUF                           ; save LLUCE kernel

            LDX    #0
EXITLOOP    MOV    EXITCODE,X;EXIT,X
            MOV    EXITCODE+$100,X;EXIT+$100,X
            DBNE   X;EXITLOOP

            JSR    EXIT                              ; returns only if error

            JSR    RSTBUFF                           ; restore original

ERROR       STA    PRN
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

MOVEERR     JSR    ERROR
            JSR    SYSRCAL                           ; recall all variables
            LDA    #0                                ; reload last segment
            PHA
            PHA
            PHA
            PHA
            PHA
            PHA
            LDA    #$80                              ; continue last segment
            JSR    RELOAD                            ; no return from here

SAVEBUF     MOVD   #NODENUM;a1
            MOVD   MODULE;a2
            MOVD   #SYSTEM;a4
            SEC
            JSR    auxMove
            RTS

RSTBUFF     PHA
            MOVD   #SYSTEM;a1
            CLC
            ADC    MODULE+1
            STA    a2+1
            STZ    a2
            MOVD   #NODENUM;a4
            CLC
            JSR    auxMove
            PLA
            RTS

ORIGMLI     DW     0
ORIGIRQ     DW     0
ORIGRST     DW     0

            DS     \

QUITCODE    ORG    $A000

QUIT        CLD                                      ; for ProDOS

            LDX    #0                                ; move quit code up
QUITUP      MOV    $1000,X;QUIT,X
            MOV    $1100,X;QUIT+$100,X
            MOV    $1200,X;QUIT+$200,X
            DBNE   X;QUITUP
            JMP    QUITCONT

QUITCONT    PDOS   Setpfx;OPFXLST

            PDOS   Open;OSAVELST
            MOV    OSAVEREF;RDREF
            PDOS   Read;RDLST                        ; read zp and page 3
            PDOS   Close;OCLSLST

            IFNE   DEV1ADR;DEV2ADR+6;KILLRAM         ; /RAM
            IFEQ   DEV1ADR+1;DEV2ADR+7;NORAM         ; installed?

KILLRAM     LDX    DEVCNT                            ; Find Any Ramdisk
FNDRAM      LDA    DEVLST,X                          ; Get Device Id Byte
            TAY
            AND    #$B3                              ; Low Nibble Is Type
            CPEQ   #$B3;MVDEV                        ; Is It A RAM Disk?

            DBPL   X;FNDRAM                          ; Go To Next Device
            BRA    NORAM

MVDEV       MOV    DEVLST+1,X;DEVLST,X               ; Copy Bytes Down
            INX
            CPLTX  #13;MVDEV                         ; Finished With List?
            STZ    DEVLST+13                         ; zap last byte

            DEC    DEVCNT                            ; 1 Less Device

            LD16   DEV2ADR+6                         ; save driver info
            STZ    SETALTZP                          ; in alt zp
            ST16   RAMDRVR
            STY    RAMDEV
            STZ    SETSTDZP

            MOVD   DEV1ADR;DEV2ADR+6                 ; set no device

            TYA
            AND    #HiNibble
            STA    UNIT                              ; Save Unit Number
            PDOS   Online;ONLINE                     ; This Clears Device

NORAM       MOVD   ORIGIRQ;IRQVEC

            MOV    MODULE+1;LOADADR2+2
            STZ    SETALTZP
            LDY    #1                                ; move zero page down
            LDA    #>0
            JSR    MOVEOUT
            STZ    SETSTDZP
            LDY    #1                                ; restore interrupt buffer
            LDA    #>INTBUF
            JSR    MOVEOUT
            LDY    #16
            LDA    #>MAIN                            ; Move D000-DFFF main bank 1
            STZ    SETRAM1
            JSR    MOVEOUT
            STZ    SETALTZP
            LDY    #16
            LDA    #>MAIN                            ; Move D000-DFFF aux bank 1
            JSR    MOVEOUT
            STZ    SETRAM2
            LDY    #15
            LDA    #>PROFILT                         ; Move F000-FEFF aux bank 2
            JSR    MOVEOUT

            STZ    SETRAM2                           ; Select Ram Card
            STZ    SETRAM2
            STZ    SETALTZP

            MOVD   ORIGMLI;MLI+1
            MOVD   ORIGRST;RESETVEC
            EOR    #$A5
            STA    SOFTEV

            STZ    AUTOLOG                           ; Clear auto logon flag
            STZ    V_MODE
            STZ    BLINK
            STZ    DISP80                            ; Switch To 80 Column Mode
            STZ    STORE80                           ; Enable Page Select
            STZ    ALTCHRS                           ; Mousetext Available

            MOV    #vidWidth;V_OLDCV                 ; 80 Columns Wide

            LDA    LORES                             ; ** It Makes Things Work !!
            LDA    ANU_ON                            ; Annunc_On
            LDA    KBDSTRB

            MOV    #$60;USERVEC                      ; Put RTS For User-Routine

            LDA    #ff                               ; clear any junk
            JSR    VIDCOUT

            JSR    SYSRCAL                           ; recall all variables
            LDA    #0                                ; reload last segment
            PHA
            PHA
            PHA
            PHA
            PHA
            PHA
            LDA    #$80                              ; continue last segment
            JSR    RELOAD                            ; no return from here

MOVEOUT     STA    SAVEADR2+2
            LDX    #0
LOADADR2    LDA    NODENUM,X
SAVEADR2    STA    NODENUM,X
            DBNE   X;LOADADR2
            INC    LOADADR2+2
            INC    SAVEADR2+2
            DBNE   Y;LOADADR2
            RTS

OPFXLST     DB     1
            DA     ORIGPFX

OSAVELST    DB     3
            DA     SAVEPATH
            DA     FBUF1
OSAVEREF    DB     0

RDLST       DB     4                                 ; Write from $200-$3FF
RDREF       DB     0
            DW     NODENUM
RDREQ       DW     0
            DW     0

OCLSLST     DB     1
            DB     0

ONLINE      DB     2
UNIT        DB     0
            DA     LNBUF+$81

            DS     $A280-*

SAVEPATH    STR    'LLUCE.SAVE'                      ; our save name
            DS     $40-*+SAVEPATH,' '                ; DON'T TOUCH
ORIGPFX     DS     $40                               ; Prefix to return to
            ORG

EXITCODE    ORG    $1000

EXIT        LDEQ   RAMDEV;NODRVR                     ; /RAM removed?

            MOVD   RAMDRVR;DEV2ADR+6

            INC    DEVCNT
            LDY    DEVCNT
FIXDEV      MOV    DEVLST-1,Y;DEVLST,Y
            DBNE   Y;FIXDEV
            MOV    RAMDEV;DEVLST
            STZ    SETSTDZP                          ; set to standard zp
            AND    #HiNibble
            STA    DVRUNIT
            MOV    #3;DVRCMD                         ; format command
            MOVD   #SYSTEM;DVRBUFF
            LDA    SETRAM2
            JSR    FMTDVR
            BCS    EXITERR

NODRVR      STZ    SETSTDZP                          ; set to standard zp
            STZ    SETROM

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

            LDEQX  STARTUP;GOSYS                     ;any startup path?
            IFNE   SYSTEM;#$20;GOSYS                 ; place for startup?
            IFNE   #$EE;SYSTEM+3;GOSYS
            CPNE   SYSTEM+4;GOSYS
            IFLT   STARTUP;SYSTEM+5;GOSYS

MVSTART     MOV    STARTUP,X;SYSTEM+6,X              ; move in path
            DBPL   X;MVSTART

GOSYS       JMP    SYSTEM

FMTDVR      JMP    (DEV2ADR+6)

EXITERR     STZ    SETRAM2                           ; Select Ram Card
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

MOVECODE    ORG    $A000

DO_MOVES    MOV    MODULE+1;SAVEADR+2
            LDY    #1                                ; move zero page up
            LDA    #>0
            JSR    MOVEIN
            LDY    #1                                ; save interrupt buffer
            LDA    #>INTBUF
            JSR    MOVEIN
            LDY    #16
            LDA    #>MAIN                            ; Move D000-DFFF main bank 1
            STZ    SETSTDZP
            STZ    SETRAM1
            JSR    MOVEIN
            STZ    SETALTZP
            LDY    #16
            LDA    #>MAIN                            ; Move D000-DFFF aux bank 1
            JSR    MOVEIN
            STZ    SETRAM2
            LDY    #15
            LDA    #>PROFILT                         ; Move F000-FEFF aux bank 2
            JSR    MOVEIN

            SEC
            LDA    SAVEADR+2
            SBC    #>NODENUM
            STA    WRREQ+1
            STA    RDREQ+1+QUITCODE-QUIT

            STZ    SETSTDZP

            PDOS   Destroy;KILLLST                   ; kill file...
            PDOS   Create;CRTLST                     ; make new one
            BCS    SAVEERR
            PDOS   Open;OPENLST                      ; open our file
            BCS    SAVEERR

            MOV    OPENREF;WRREF

            PDOS   Write;WRLST
            PHP
            PHA
            PDOS   Close;CLOSELST
            PLA
            PLP
SAVEERR     STZ    SETALTZP
            STZ    SETRAM2
            RTS

MOVEIN      STA    LOADADR+2
            LDX    #0
LOADADR     LDA    NODENUM,X
SAVEADR     STA    NODENUM,X
            DBNE   X;LOADADR
            INC    LOADADR+2
            INC    SAVEADR+2
            DBNE   Y;LOADADR
            RTS

OPENLST     DB     3
            DA     PATH2
            DA     FBUF1
OPENREF     DB     0

WRLST       DB     4                                 ; Write from $200-$3FF
WRREF       DB     0
            DW     NODENUM
WRREQ       DW     0
            DW     0

CLOSELST    DB     1
            DB     0

KILLLST     DB     1
            DA     PATH2

CRTLST      DB     7
            DA     PATH2
            DB     $E3                               ; standard access
            DB     ^overlays                         ; LLUCE data file
            DW     overlays                          ; Non-packed file
            DB     1                                 ; standard file
            DW     0                                 ; use current date/time
            DW     0

INFOLST     DB     $A
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
            DS     \
            ORG

MOVCODE2    ORG    LNBUF

MOVQUIT     LDX    #0
MOVEDOWN    MOV    QUITCODE,X;QUIT,X
            MOV    QUITCODE+$100,X;QUIT+$100,X
            MOV    QUITCODE+$200,X;QUIT+$200,X
            DBNE   X;MOVEDOWN
            STZ    SETSTDZP
            STZ    SETRAM1
            LDX    #0
MOVEUP      MOV    QUIT,X;$D100,X
            MOV    QUIT+$100,X;$D200,X
            MOV    QUIT+$200,X;$D300,X
            DBNE   X;MOVEUP
            STZ    SETALTZP
            STZ    SETRAM2
            RTS

            ORG
IOEND       =      *

            LST    OFF
            DO     LISTSYM
            LST
            FIN
            TTL    'SHELL - Symbol Table'

