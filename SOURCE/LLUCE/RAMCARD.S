            LST    RTN
            PAG
*===============================
* Misc Path/File Names
*===============================

SEGSAVE     DS     $40

EDNAME      STR    'EDITOR'                       ; System Editor's Name
            DS     $10-*+EDNAME,' '               ; DON'T TOUCH

COMPNAME    STR    'COMPILER'                     ; System Compiler's Name
            DS     $10-*+COMPNAME,' '             ; DON'T TOUCH

SYSNAME     STR    'SYSTEM'                       ; Name Of System Sub-Dir
            DS     $10-*+SYSNAME,' '              ; DON'T TOUCH

*===============================
* Fake Serial Number For Peepers
*===============================

FAKESN      ASC    'GP140001'

            TTL    'LLUCE - Date Text'

*===============================
* Day Of Week For Extended Date
*===============================

DAYS        ASC    'Sun.'
            ASC    'Mon.'
            ASC    'Tue.'
            ASC    'Wed.'
            ASC    'Thu.'
            ASC    'Fri.'
            ASC    'Sat.'

*===============================
* Months Text
*===============================

MONTHS      ASC    'Jan '
            ASC    'Feb '
            ASC    'Mar '
            ASC    'Apr '
            ASC    'May '
            ASC    'Jun '
            ASC    'Jul '
            ASC    'Aug '
            ASC    'Sep '
            ASC    'Oct '
            ASC    'Nov '
            ASC    'Dec '

DATETXT     ASC    '03/23/89'

DOWSTR      DB     0
            ASC    'Thu. Mar 23, 1989'

MTKNS       DB     0,3,3,6,1,4,6,2,5,0,3,5

            TTL    'LLUCE - Vectors'

*===============================
* String Compare Vectors
*===============================

JSTRCP      DW     ST_NOT                         ; 6B <>
            DW     ST_LTEQ                        ; 6D <=
            DW     ST_GTEQ                        ; 6D =>
            DW     ST_EQ                          ; 6E =
            DW     ST_LT                          ; 6F <
            DW     ST_GT                          ; 70 >

*===============================
* Addresses
*===============================
* Input Channel Vectors
*===============================

INPVEC      DW     KEYIN                          ; 0  Console Keyboard
            DW     DISKIN1                        ; 1  Disk Channel 1
            DW     DISKIN2                        ; 2  Disk Channel 2
            DW     DISKIN3                        ; 3  Disk Channel 3
            DW     NO_INP                         ; 4  Console Input
            DO     DEMOPGM
            DW     NO_INP
            ELSE
            DW     MDMIN                          ; 5  Modem Input
            FIN
            DW     NO_INP                         ; 6  Line Printer
            DW     RDMSG                          ; 7  Msg Input
            DW     RDMAIL                         ; 8  Read Mail
            DW     EDIN                           ; 9  Editor Input
            DW     RAMIN                          ; 10 Ram Drive Input

*===============================
* Output Channel Vectors
*===============================

OUTVEC      DW     COUT                           ; 0  Console Output
            DW     DSKOUT1                        ; 1  Disk Channel 1
            DW     DSKOUT2                        ; 2  Disk Channel 2
            DW     DSKOUT3                        ; 3  Disk Channel 3
            DW     VIDCOUT                        ; 4  Local Console
            DO     DEMOPGM
            DW     NO_OUT
            ELSE
            DW     ZMDMOUT                        ; 5  Modem Output
            FIN
            DW     LPROUT                         ; 6  Line Printer
            DW     WRMSG                          ; 7  Msg Output
            DW     NO_OUT                         ; 8  Read Mail [None]
            DW     EDOUT                          ; 9  Editor Output
            DW     RAMOUT                         ; 10 Ram Drive Output

*===============================
* Device In Use Defaults
*===============================

DEVTBL      DB     -1,0,0,0,-1,-1,-1,0,0,-1,-1
            TTL    'LLUCE - Misc Tables'

*===============================
* Input Mode Bytes
*===============================

MODEBYT     DB     %10000011                      ; Default, Get 1 Byte Only
            DB     %11000001                      ; Upper/No Blanks/No Comma
            DB     %10100000                      ; Upper And Return
            DB     %00100000                      ; Accept All And Return
            DB     %01100000                      ; No Blanks/No Comma/Return

*===============================
* Bit Position Masks
*===============================

BITVAL      DB     1,2,4,8,16,32
SEV         DB     64,128

*===============================
* Misc Variables
*===============================

REFTAB      DS     3                              ; Reference Numbers
BUFADR      DB     >FBUF1,>FBUF2,>FBUF3,>MSGBUF
OFFSNUM     DB     0                              ; Goto XY offset & order

*===============================
* Some message system stuff
*===============================

            TTL    'LLUCE - Message File Data'

MSGINFO     =      *
BITSIZE     DB     0                              1
DIRSIZE     DB     0                              1
USEDBLKS    DW     0                              2
NUMFILES    ADRL   0                              4
HIMSGNUM    ADRL   0                              4
            DS     $14                            20

MSGPTR      DB     0                              1
RMXBLK      DW     0                              2
RDEND       DB     0                              1

MSGINIT     DB     0                              1

MSGPTR2     DB     0                              1
WRKBLK      DW     0                              2
WRTEND      DB     0                              1

RWDPTR      DB     0                              1
RWDBLK      DW     0                              2

DIRSEG      DW     0                              2
BITSEG      DB     0                              1
WMSGNUM     DB     0                              1

MSGNUM      DW     0                              2
POSBLK      DW     0                              2

            TTL    'LLUCE - Editor I/O Routines'

*===============================
* ----- Editor I/O Routines ----
*===============================
* Get A Character From Editor Buffer
*===============================

EDIN        ASL    RDRAMRD                        ; Get Memory Reading From
            PHP
            TSTMI  DEVCLR;EDIN1                   ; Reset?

            JSR    SET_EPTR

            DEC    DEVCLR                         ; Clear Flag

EDIN1       STZ    MAINREAD

            MOVD   EDPTR;EDIN2+1

            TSTPL  EDMEMORY;EDIN2                 ; Where Is Editor Buffer?

            STZ    AUXREAD                        ; In Aux Memory

EDIN2       LDEQ   -1;EDIN3                       ; Get Data

            INCD   EDPTR                          ; Point To Next Byte

EDIN3       STZ    MAINREAD
            PLP                                   ; Where From?
            BCC    EDIN4                          ; Main Memory
            STZ    AUXREAD                        ; Aux Memory
EDIN4       RTS

*===============================
* Put A Character In The Editor Buffer
*===============================

EDOUT       ASL    RDRAMWRT                       ; Save Memory Write
            PHP
            STA    PRN                            ; Save Char

            IFNE   EDPTR;EDITLEN;EDOUT1           ; at end?
            IFEQ   EDPTR+1;EDITLEN+1;ED_CLR3

EDOUT1      STZ    MAINWRT                        ; Set Write To Main
            TSTPL  EDMEMORY;EDOUT2                ; Where Is Editor Buffer?

            STZ    AUXWRT                         ; In Aux Memory

EDOUT2      MOVD   EDPTR;EDOUT3+1

            LDA    PRN                            ; Get Char Back
EDOUT3      STA    -1                             ; Save Byte

            INCD   EDPTR                          ; Inc Pointers To Next Byte
            BRA    ED_CLR1

*===============================
* Clear The Editor, Preserve Memory
*===============================

ED_CLR      STZ    EDLINE                         ; Zero Line Counter
            STZ    EDLINE+1

            JSR    SET_EPTR

            STZ    PRN
            ASL    RDRAMWRT
            PHP
            STZ    MAINWRT
            TSTPL  EDMEMORY;ED_CLR1
            STZ    AUXWRT

ED_CLR1     MOVD   EDPTR;ED_CLR2+1

ED_CLR2     STZ    -1
ED_CLR3     STZ    MAINWRT
            PLP                                   ; Where From?
            BCC    ED_CLR4                        ; Main Memory
            STZ    AUXWRT                         ; Aux Memory
ED_CLR4     LDA    PRN                            ; Get Char Back
            RTS

SET_EPTR    MOVD   EDLOC;EDPTR                    ; reset data pointer
            RTS
            DS     \
            LST    OFF

