            TTL   'LLUCE - Global Page'
            PAG
*-------------------------------
* To Be Created By The Config Program
*-------------------------------

NODENUM     =     $800                   ; AppleTalk node number
; or system node number
STRT_NM     =     $801                   ; Startup Name Location
MODULE      =     $803                   ; Segment Load Location

VERSION     =     $805                   ; Version Number

*-------------------------------
* Interrupt Characters
*-------------------------------

STPCHR      =     $807                   ; Stop Message Char
NXTCHR      =     $808                   ; Next Message Char

*-------------------------------
* Modem(0) Commands
*-------------------------------

M_QUIT      =     $809                   ; Quit Command
M_LOGIN     =     $80A                   ; Go Command
M_ANSWER    =     $80B                   ; Answer Command

E_WIDTH     =     $80C                   ; Index For Default

WWFLAG      =     $811                   ; Word-Wrap Flag For Editor

EDLOC       =     $812                   ; Editor Location
EDITLEN     =     $814                   ; size of editor buffer
EDMEMORY    =     $816                   ; If Negative, Buffer In Aux
FILTFLAG    =     $817                   ; Filter Active Flag

REFNUM      =     $818                   ; Reference Number To Use
MSGREF      =     $819                   ; Msg File Reference Number
BUF2ADR     =     $81A                   ; Address Of File Buffer 2

SHWTXT      =     $81C                   ; Showing Program Text
SHWTRC      =     $81D                   ; Show Program Trace

TOCONST     =     $81E                   ; Time Out Constant
KILCLTO     =     $820                   ; keyin local timeout
KIRMTTO     =     $821                   ; keyin remote timeout

ATAVAIL     =     $822                   ; AppleShare Active Flag
ATLAUNCH    =     $823                   ; Launched From AppleShare

SYSSTAT     =     $824                   ; System Flags Stored Here
; For Interrupt Flag
GSFLAG      =     $825                   ; Useing //gs flag
PDOSVEC     =     $826                   ; ProDOS Entry Point Address
IRQSAVE     =     $828                   ; original IRQ vector

TIMEDISP    =     $82A                   ; 0=24 Hour, $80=12 Hour

FLASHING    =     $82B                   ; GS screen color change flag
ANSIFLAG    =     $82C                   ; ANSI emulation flag
CONVFLAG    =     $82D                   ; emulation conversion flag

REMOTE      =     $82E                   ; Online Status
NNULLS      =     $82F                   ; Number Of Nulls

CRC         =     $830                   ; Returned CRC
SCREENTO    =     $832                   ; Screen Save Timer

QTIME       =     $834                   ; 834 time in text

ERRNO       =     $83F                   ; Last Error Number

FLNAME      =     $840                   ; Last Filename Used
SEG_NAME    =     $880                   ; Start Up Segment Pathname
SYSPFX      =     $8C0                   ; System Files Prefix

FILTER      =     PROFILT                ; Location of profanity filter

PRINTDVR    =     $900

PRINIT      =     $901                   ; Init Printer
LPROUT      =     $904                   ; Print Character In A
PRCLEAR     =     $907                   ; Clear Print Buffer

CLOCKDVR    =     $A00
CLKMODE     =     $A01

GETDATE     =     $A02
GETTIME     =     $A05
SETDATE     =     $A08

MODEMDVR    =     $B00
PROTOCOL    =     $B00
SLOT        =     $B00                   ; Serial Card Slot
INITSPD     =     $B01                   ; Initialize Speed
MDMSPEED    =     $B02
CALLSPD     =     $B02                   ; Speed Of Call

BYTCNT      =     $B03

MDMINIT     =     $B06
MDMRSET     =     $B09
MDMRING     =     $B0C
MDMANS      =     $B0F
MDMHANG     =     $B12
MDMIN       =     $B15
MDMOUT      =     $B18
MDMDCD      =     $B1B
MDMSSPD     =     $B1E
MDMINT      =     $B21
MDMDTR      =     $B24
MDMCBUF     =     $B27
MDMQUIT     =     $B2A

