            LST   RTN
            TTL   'LLUCE - Global Page'
            PAG
*-------------------------------
* To Be Created By The Config Program
*-------------------------------

NODENUM     DB    0                      ; 800 AppleTalk node number
;     or system node number
            DA    SEG_NAME               ; 801 Startup Name Location
MODULE      DA    0                      ; 803 Segment Load Location

VERSION     DW    Version                ; 805 Version Number

*-------------------------------
* Interrupt Characters
*-------------------------------

STPCHR      DB    ' '                    ; 807 Stop Message Char
NXTCHR      DB    'N'                    ; 808 Next Message Char

*-------------------------------
* Modem(0) Commands
*-------------------------------

M_QUIT      DB    'Q'-Ctrl               ; 809 Quit Command
M_LOGIN     DB    'G'-Ctrl               ; 80A Go Command
M_ANSWER    DB    'A'-Ctrl               ; 80B Answer Command

E_WIDTH     DB    4                      ; 80C Index For Default
            DB    32,40,64,80

WWFLAG      DB    -1                     ; 811 Word-Wrap Flag For Editor

EDLOC       DA    EDBUF                  ; 812 Editor Location
EDITLEN     DW    EDBUF+EBUFEND          ; 814 size of edit buffer
EDMEMORY    DB    0                      ; 816 If Negative, Buffer In Aux
FILTFLAG    DB    1                      ; 817 Filter Active Flag

REFNUM      DB    0                      ; 818 Reference Number To Use
MSGREF      DB    0                      ; 819 Msg File Reference Number
            DA    FBUF2                  ; 81A Address Of File Buffer 2

SHWTXT      DB    0                      ; 81C Showing Program Text
SHWTRC      DB    0                      ; 81D Show Program Trace

TOCONST     DW    159                    ; 81E Time Out Constant
KILCLTO     DB    150                    ; 820 keyin local timeout
KIRMTTO     DB    36                     ; 821 keyin remote timeout

ATAVAIL     DB    0                      ; 822 AppleShare Active Flag
ATLAUNCH    DB    0                      ; 823 Launched From AppleShare

SYSSTAT     DB    0                      ; 824 System Flags Stored Here
;     For Interrupt Flag
GSFLAG      DB    0                      ; 825 Useing //gs flag
PDOSVEC     DA    0                      ; 826 ProDOS Entry Point Address
IRQSAVE     DW    0                      ; 828 original IRQ vector

TIMEDISP    DB    $80                    ; 82A 0=24 Hour, $80=12 Hour

FLASHING    DB    0                      ; 82B GS screen color change flag
ANSIFLAG    DB    0                      ; 82C ANSI emulation flag
CONVFLAG    DB    -1                     ; 82D emulation conversion flag

REMOTE      DB    0                      ; 82E Online Status
NNULLS      DB    0                      ; 82F Number Of Nulls

CRC         DA    0                      ; 830 Returned CRC
SCREENTO    DW    30                     ; 832 Screen Save Timer

QTIME       ASC   '12:00:00   '          ; 834 time in text

ERRNO       DB    0                      ; 83F Last Error Number

FLNAME      DS    $40                    ; 840 Last Filename Used
SEG_NAME    DS    $40                    ; 880 Start Up Segment Pathname
SYSPFX      DS    $40                    ; 8C0 System Files Prefix
            LST   OFF

