              TTL   'OVERLAYS - Equates'
              PAG
MSLOT         =     2                     Modem

*-------------------------------
* Misc bit masks

CaseDiff      =     $20
Ctrl          =     $40
Clrhi         =     $7F
Hibit         =     $80
HiNibble      =     $F0
LoNibble      =     $0F

*-------------------------------
* Compiler flags

Label         =     0
Labelend      =     $7F

*-------------------------------
* Sysop Command Keys
*-------------------------------

chat          =     'A'                   Chat
logout        =     'L'                   Log
prnscr        =     'P'                   Print
bartog        =     'T'                   Toggle
execon        =     'V'                   Exec

pauseChr      =     'Z'-Ctrl+Hibit
escKey        =     '['-Ctrl+Hibit        escape
pass          =     '_'-Ctrl              Show

clb           =     '^'-Ctrl              Clear

*-------------------------------
* Standard ASCII Codes
*-------------------------------

nul           =     '@'-Ctrl
soh           =     'A'-Ctrl              <soh>
ssoh          =     'A'-Ctrl+Hibit
stx           =     'B'-Ctrl              <stx>
sstx          =     'B'-Ctrl+Hibit        <sstx>
etx           =     'C'-Ctrl
eot           =     'D'-Ctrl              End
enq           =     'E'-Ctrl
ack           =     'F'-Ctrl              <ack>
bel           =     'G'-Ctrl              Bell
bs            =     'H'-Ctrl              Backspace
tab           =     'I'-Ctrl              Tab
lf            =     'J'-Ctrl              Linefeed
vt            =     'K'-Ctrl
ff            =     'L'-Ctrl
cr            =     'M'-Ctrl              Carriage
so            =     'N'-Ctrl
si            =     'O'-Ctrl
dle           =     'P'-Ctrl
xon           =     'Q'-Ctrl
dc2           =     'R'-Ctrl
xoff          =     'S'-Ctrl              Stop
dc4           =     'T'-Ctrl
nak           =     'U'-Ctrl              <nak>
syn           =     'V'-Ctrl
etb           =     'W'-Ctrl
can           =     'X'-Ctrl              Cancel
em            =     'Y'-Ctrl
sub           =     'Z'-Ctrl
esc           =     '['-Ctrl              escape
*fs      =     '\'-Ctrl
gs            =     ']'-Ctrl
rs            =     '^'-Ctrl
us            =     '_'-Ctrl
del           =     $7F                   Delete

*-------------------------------
* Local video control codes
*-------------------------------

csrbol        =     'A'-Ctrl              Cursor
csreol        =     'B'-Ctrl              Cursor
delchar       =     'D'-Ctrl              Delete
inschar       =     'F'-Ctrl              Insert
dobeep        =     'G'-Ctrl              Ring
csrback       =     'H'-Ctrl              Cursor
dotab         =     'I'-Ctrl              Tab
csrdwn        =     'J'-Ctrl              Cursor
csrup         =     'K'-Ctrl              Cursor
clrscn        =     'L'-Ctrl              Clear
crlf          =     'M'-Ctrl              Do
norm          =     'N'-Ctrl              Normal
inv           =     'O'-Ctrl              Inverse
realmous      =     'P'-Ctrl              Real
ptRepeat      =     'R'-Ctrl              Repeat
mous          =     'R'-Ctrl              Mouse
Tonecmd       =     'T'-Ctrl              ProTERM
csrfwd        =     'U'-Ctrl              Cursor
insline       =     'V'-Ctrl              insert
clreos        =     'W'-Ctrl              Clear
homeChar      =     'X'-Ctrl              Home
clreol        =     'Y'-Ctrl              Clear
delline       =     'Z'-Ctrl              Delete
ptAck         =     ']'-Ctrl
goxy          =     '^'-Ctrl              GotoXY

goxyOffs      =     32
vidWidth      =     80
vidHeight     =     24

locked        =     'L'-Ctrl
unlocked      =     'U'-Ctrl

*-------------------------------
* Editor Command Keys

bol           =     'B'-Ctrl              End
ctr           =     'C'-Ctrl              Center
dc            =     'D'-Ctrl              Delete
eol           =     'E'-Ctrl              End
ic            =     'F'-Ctrl              Insert
lwd           =     'Q'-Ctrl              Last
fs            =     'U'-Ctrl              Forward
nwd           =     'W'-Ctrl              Next
hak           =     'Y'-Ctrl              Hack

*-------------------------------
* Variable handler equates
*-------------------------------

vRecSize      =     8                     ; size of variable record
nameOffs      =     0                     ; offset to variable name
valOffs       =     4                     ; offset to numeric variable
lenOffs       =     6                     ; offset to string length

*-------------------------------
* Other variable & type equates equates

eolChain      =     0
tknExpr       =     1
strLit        =     2
numLit        =     3
strVar        =     5
numVar        =     6

*-------------------------------
* Addresses
*-------------------------------
* Main standard memory
*-------------------------------

DRIVERS       =     $800                  Driver
MAINPGM       =     $F00                  Main

SYSTEM        =     $2000                 System

ENDMOD        =     $9B00

EDBUF         =     $9B00                 $1000
EDSIZE        =     $AB00-EDBUF           $1000
EBUFEND       =     EDSIZE-1

FBUF3         =     $AB00                 $400
INTBUF        =     $AF00                 $80
BITBUF        =     $AF80                 $80
BLKBUF        =     $B000                 $80
BLKBUF2       =     $B080                 $80
DIRBUF        =     $B100                 $200
FBUF1         =     $B300                 $400
FBUF2         =     $B700                 $400
MSGBUF        =     $BB00                 $400

*-------------------------------
* Main aux memory
*-------------------------------

SCRNBUF       =     $2000                 Screen
STRDEST       =     $4000                 Used
STORETOP      =     $BF00

*-------------------------------
* Aux ramcard memory Bank 2
*-------------------------------

OVERBUF       =     $D000                 Overlay

PROFILT       =     $F000                 $100
ENTRYPTS      =     $F100                 $100

RAMCARD       =     $F400                 $400
RAMAREA       =     $F800                 $300
SCRATCH       =     $FB00                 $400

*-------------------------------
* Aux ramcard memory Bank 1
*-------------------------------

CRCLO         =     $D000                 $100
CRCHI         =     $D100                 $100
RAMDRV        =     $D200                 $100
TYPEBUF       =     $D300                 $100

XTRAPGM       =     $D800                 $800

*-------------------------------
* Main ramcard memory Bank 1
*-------------------------------

ERRMSGS       =     $D500                 $400
PROGTEXT      =     $D900                 $400
VIDMSGS       =     $DD00                 $300

*-------------------------------
* General Offsets

L0            =     $000
L1            =     $100
L2            =     $200
L3            =     $300
L4            =     $400
L5            =     $500
L6            =     $600
L7            =     $700
L8            =     $800
L9            =     $900

*-------------------------------
* Overlay ID's

Compiler      =     1                     Compiler
Editid        =     2                     Editor
Protocol      =     3                     Transfer

*-------------------------------
* Zero Page Locations

TEMP          =     0                     2
TEMP2         =     2                     2
TEMP3         =     4                     2
LSTPTR        =     6                     2
PRGPTR        =     8                     2
PRN           =     $A                    2
VECTOR        =     $C                    2
VECTOR2       =     $E                    2
WHNPTR        =     $10                   2
FLGPTR        =     $12                   2
NIBPTR        =     $14                   2
BYTPTR        =     $16                   2
WORDPTR       =     $18                   2
VARSTR        =     $1A                   2
STRLOC        =     $1C                   2
STRLEN        =     $1E                   1
TTLLEN        =     $1F                   1

WNDLFT        =     $20                   1
WNDWDTH       =     $21                   1
WNDTOP        =     $22                   1
WNDBTM        =     $23                   1
CH            =     $24                   1
CV            =     $25                   1
GOTO_X        =     $26                   1
GOTO_Y        =     $27                   1
BASE          =     $28                   2
BASE2         =     $2A                   2
DOSPARM       =     $2C                   2
V_CALL        =     $2E                   1
LSTTOK        =     $2F                   1
FREMEM        =     $30                   1
MONMODE       =     $31                   1
MOUSEFLG      =     $31                   1
INVFLG        =     $32                   1
MONPROMPT     =     $33                   1
INTOUT        =     $34                   1
INTCHR        =     $35                   1
CSW           =     $36                   2
KSW           =     $38                   2
MONPC         =     $3A                   2
a1            =     $3C                   2
a2            =     $3E                   2
a3            =     $40                   2
a4            =     $42                   2
DVRCMD        =     $42
DVRUNIT       =     $43
DVRBUFF       =     $44

MONRND        =     $C9                   formerly

X_ARG         =     $50                   2
Y_ARG         =     $52                   2
EDLINE        =     $54                   2
EDPTR         =     $56                   2
ARGPTR        =     $58                   2
MSG_X         =     $5A                   1
MSG_Y         =     $5B                   1
SAVE_X        =     $5C                   1
SAVE_Y        =     $5D                   1
LASTIN        =     $5E                   1
EXECFLG       =     $5F                   1
DEVCLR        =     $60                   1
CMD           =     $61                   1

DOCHAT        =     $62                   1
INCHAT        =     $63                   1
LOGOFF        =     $64                   1
BUF_X         =     $65                   1
TYPIN         =     $66                   1
TYPOUT        =     $67                   1
IMMDEF        =     $68                   1

*-------------------------------
* AppleSoft Locations

LOMEM         =     $69                   2
DISK_X        =     $6B                   1
DISK_Y        =     $6C                   1
MIDMEM        =     $6D                   2
GSBLVL        =     $6F                   1
FORLVL        =     $70                   1
OLDEXEC       =     $71                   1
OLDRMT        =     $72                   1
HIMEM         =     $73                   2
TLEFT         =     $75                   2
CLKBASE       =     $77                   2
TIMEON        =     $79                   2
RAMPTR        =     $7B                   1
GOBBYT        =     $7C                   1
LST2ND        =     $7D                   1
LSTVAR        =     $7E                   1
LSTTXT        =     $7F                   1
INPMODE       =     $80                   1
; Bit 6: No Comma/Spaces
; Bit 5: Blank Line Ok
; Bit 4: Do Word-Wrap
VPTR          =     $81                   2
VNAME         =     $83                   4

SHOW_X        =     $87                   1
SHW_CNT       =     $88                   1
SHWIN         =     $89                   1
SHWOUT        =     $8A                   1
SHWREF        =     $8B                   1
XTERNAL       =     $8C                   1
VIDECHO       =     $8D                   1

*-------------------------------
* Variables Used By Editor

EDSTACK       =     $8E                   1
EXE_DOT       =     $8F                   1
SHWLN         =     $90                   1
WWRAP         =     $91                   1
WWEXTRA       =     $92                   1
PROMPT        =     $93                   1

VIDLEN        =     $94                   1
SSAVED        =     $95                   1
NOSOURCE      =     $95                   1
FROMERR       =     $96                   2
ONERRVEC      =     $98                   2
ONERRFLG      =     $9A                   1
NOCDFLG       =     $9B                   1
NOCDVEC       =     $9C                   2
TERMNO        =     $9E                   1

NONBS         =     $9F                   1
LSTVNAM       =     $A0                   4
AUTOLOG       =     $A4                   1
BLOCKFLG      =     $A5                   1
CURODEV       =     $A6                   1
DOLVL         =     $A7                   1
WHILELVL      =     $A8                   1
WHATLVL       =     $A9                   1
CO_XY         =     $AA                   1
CO_RPT        =     $AB                   1

RAMDEV        =     $AE                   1
RAMDRVR       =     $AF                   2

RNDNUM        =     $C9                   2

V_TEMP        =     $F8                   5
V_DATA        =     $FD                   3

LNBUF         =     $200                  Input
CHATBUF       =     $200
FREESPACE     =     $300                  free
RESETVEC      =     $3F2                  Reset
SOFTEV        =     $3F4                  Reset
USERVEC       =     $3F5                  User
IRQVEC        =     $3FE                  IRQ
LINE1         =     $400                  Screen
TOPRIGHT      =     $427                  Line
OLDCH         =     $47B                  80
OLDCV         =     $4FB                  80
V_MODE        =     $57B                  Video
V_OLDCV       =     $5FB                  Video
BLINK         =     $67B                  Blinking
LASTCHR       =     $6FB                  Last
VID_Y         =     $7FB                  Video
LINE23        =     $750                  Screen
LINE24        =     $7D0                  Screen

*-------------------------------
* Soft switches

KYBD          =     $C000                 Keyboard
CLR80STO      =     $C000                 Clear
STORE80       =     $C001                 Set
MAINREAD      =     $C002                 Read
AUXREAD       =     $C003                 Read
MAINWRT       =     $C004                 Write
AUXWRT        =     $C005                 Write
SETSLOTCXROM  =     $C006                 Use
SETINTCXROM   =     $C007                 Use
SETSTDZP      =     $C008                 Use
SETALTZP      =     $C009                 Use
SETINTC3ROM   =     $C00A                 Enable
SETSLOTC3ROM  =     $C00B                 Enable
DISP40        =     $C00C                 Set
DISP80        =     $C00D                 Set
CLRALTCHARS   =     $C00E                 Normal
ALTCHRS       =     $C00F                 Set

KBDSTRB       =     $C010                 Clear
RDLCBANK2     =     $C011
RDLCRAM       =     $C012
RDRAMRD       =     $C013                 Read
RDRAMWRT      =     $C014                 Read
RDCXROM       =     $C015
RDALTZP       =     $C016
RDC3ROM       =     $C017
RD80COL       =     $C018
VBL           =     $C019                 Read
RDTEXT        =     $C01A
RDMIX         =     $C01B
RDPAGE2       =     $C01C
RDHIRES       =     $C01D
ALTCHARSET    =     $C01E
RD80VID       =     $C01F

*-------------------------------
* Color values

black         =     0
deepRed       =     1
darkBlue      =     2
purple        =     3
darkGreen     =     4
darkGray      =     5
medBlue       =     6
lightBlue     =     7
brown         =     8
orange        =     9
lightGray     =     10
pink          =     11
green         =     12
yellow        =     13
aquamarine    =     14
white         =     15

MONOCOLOR     =     $C021                 bit

FGBG          =     $C022
textColor     =     %11110000
bgColor       =     %00001111

VGCINT        =     $C023
intVGC        =     %10000000
int1sec       =     %01000000
intScan       =     %00100000
intExt        =     %00010000
en1sec        =     %00000100
enScan        =     %00000010
enExt         =     %00000001

MOUSEDATA     =     $C024
buttonNow     =     %10000000
deltaSign     =     %01000000
deltaMove     =     %00111111

KEYMODE       =     $C025
oa            =     %10000000
ca            =     %01000000
modUpd        =     %00100000
keypad        =     %00010000
repeat        =     %00001000
capsLock      =     %00000100
control       =     %00000010
shift         =     %00000001

DATAREG       =     $C026

KMSTATUS      =     $C027
mouseFull     =     %10000000
mouseIntEn    =     %01000000
dataFull      =     %00100000
dataIntEn     =     %00010000
keyFull       =     %00001000
keyIntEn      =     %00000100
mouseXY       =     %00000010
cmdFull       =     %00000001

ROMBANK       =     $C028                 Apple

NEWVIDEO      =     $C029
SHRen         =     %10000000
linear        =     %01000000
BWcolorDRH    =     %00100000

LANGSEL       =     $C02B
engUSA        =     %00000000
engUK         =     %00100000
french        =     %01000000
danish        =     %01100000
spanish       =     %10000000
italian       =     %10100000
german        =     %11000000
swedish       =     %11100000
NTSC_PAL      =     %00010000
language      =     %00001000

CHARROM       =     $C02C
SLTROMSEL     =     $C02D
slot7         =     %10000000
slot6         =     %01000000
slot5         =     %00100000
slot4         =     %00010000
slot2         =     %00000100
slot1         =     %00000010

VERTCNT       =     $C02E
HORIZCNT      =     $C02F

SPKR          =     $C030                 Toggle
DISKREG       =     $C031
sel35hd       =     %10000000
enab35        =     %01000000

SCANINT       =     $C032
clr1sec       =     %01000000
clrScan       =     %00100000

CLOCKDATA     =     $C033
CLOCKCTL      =     $C034
BORDER        =     $C034
clkXfer       =     %10000000
clkWrRd       =     %01000000
clkChipEn     =     %00100000
bColor        =     %00001111

SHADOW        =     $C035
noIOLc        =     %01000000
noAuxHGR      =     %00010000
noSHR         =     %00001000
noHGR2        =     %00000100
noHGR1        =     %00000010
noText        =     %00000001

CYAREG        =     $C036
sysSpeed      =     %10000000
shadowAll     =     %00010000
slt7mot       =     %00001000
slt6mot       =     %00000100
slt5mot       =     %00000010
slt4mot       =     %00000001

DMAREG        =     $C037
SCCBREG       =     $C038
SCCAREG       =     $C039
SCCBDATA      =     $C03A
SCCADATA      =     $C03B
SOUNDCTL      =     $C03C
soundBusy     =     %10000000
docRAMAcc     =     %01000000
adrAutoInc    =     %00100000
volume        =     %00001111

SOUNDDATA     =     $C03D
SOUNDADRL     =     $C03E
SOUNDADRH     =     $C03F

INTEN         =     $C041
enQsInt       =     %00010000
enVBLInt      =     %00001000
enSwInt       =     %00000100
enMoveInt     =     %00000010
enMouse       =     %00000001

MMDELTAX      =     $C044
MMDELTAY      =     $C045
DIAGTYPE      =     $C046
INTFLAG       =     $C046
selfBurn      =     %10000000
mouseDown     =     %10000000
mouseLast     =     %01000000
an3Stat       =     %00100000
qsStat        =     %00010000
vblStat       =     %00001000
swStat        =     %00000100
moveStat      =     %00000010
irqStat       =     %00000001

CLRVBLINT     =     $C047
CLRXYINT      =     $C048

TXTCLR        =     $C050
TXTSET        =     $C051
MIXCLR        =     $C052
MIXSET        =     $C053
LOWSCR        =     $C054                 Set
HISCR         =     $C055                 Set
LORES         =     $C056                 Set
HIRES         =     $C057

SETAN0        =     $C058
CLRAN0        =     $C059
SETAN1        =     $C05A
ANU_OFF       =     $C05A                 Annunc
CLRAN1        =     $C05B
ANU_ON        =     $C05B                 Annunc
SETAN2        =     $C05C
CLRAN2        =     $C05D
SETAN3        =     $C05E
CLRAN3        =     $C05F

BUTN3         =     $C060
BUTN0         =     $C061
BUTN1         =     $C062
BUTN2         =     $C063
MLBUS         =     $C063                 Button
PADDL0        =     $C064
PADDL1        =     $C065
PADDL2        =     $C066
PADDL3        =     $C067

STATEREG      =     $C068
zpStat        =     %10000000
pg2Stat       =     %01000000
ramRStat      =     %00100000
ramWStat      =     %00010000
romRStat      =     %00001000
lc2Stat       =     %00000100
romBStat      =     %00000010
cxStat        =     %00000001

TESTREG       =     $C06D
CLRTM         =     $C06E
ENTM          =     $C06F

PTRIG         =     $C070

RDLC2         =     $C080
ROMIN         =     $C081
SETROM        =     $C082                 Switch
LCBANK2       =     $C083
SETRAM1       =     $C083                 Switch

RDLC1         =     $C088
ROMIN1        =     $C089
SETROM1       =     $C08A
LCBANK1       =     $C08B
SETRAM2       =     $C08B                 Switch

LOWSPEED      =     $C0EB                 Read

auxMove       =     $C311                 a1=source,a2=source
;   carry set   = main --> aux
;   carry clear = aux --> main

CLRROM        =     $CFFF

*-------------------------------
* Firmware entry points

PREAD         =     $FB1E                 Read
MONINIT       =     $FB2F                 Init
MONID1        =     $FBB3                 Machine
MONID2        =     $FBC0                 Machine
MONCLS        =     $FC58                 Clear
MONKEYIN      =     $FD0C
MONINPLN      =     $FD6F
MONCROUT      =     $FD8E
MONPRBYTE     =     $FDDA
MONCOUT       =     $FDED                 Character
IDROUTINE     =     $FE1F
MONSNORM      =     $FE84                 Set
MONSKBD       =     $FE89                 Set
MONSVID       =     $FE93                 Set
ENTRMON       =     $FF59                 Enter
MONGETNUM     =     $FFA7

INTVEC        =     $FFFA                 Interrupt
MONRESET      =     $FFFC

*-------------------------------
* Protocol error codes

noErrors      =     0
headerErr     =     1
blockErr      =     2
footerErr     =     3
tenErrors     =     10
rcvrCan       =     'X'-Ctrl
sysopCan      =     '['-Ctrl
lastBlkAbt    =     254
parmSyntax    =     255

*-------------------------------
* I/O vector numbers

ioBoth        =     0
ioFile1       =     1
ioFile2       =     2
ioFile3       =     3
ioLocal       =     4
ioModem       =     5
ioPrint       =     6
ioMsg         =     7
ioMail        =     8
ioEditor      =     9
ioRamDsk      =     10

*-------------------------------
* protocol send modes

xModem        =     0
yModem        =     1
yModem4k      =     2
crcXmdm       =     3

*-------------------------------
* protocol receive modes

rProDOS       =     1

rXModem       =     0
rXModemP      =     rXModem+rProDOS
rCRC          =     2
rCRCp         =     rCRC+rProDOS
r1k           =     4
r1kP          =     r1k+rProDOS
r4modem       =     6
r4modemP      =     r4modem+rProDOS

*-------------------------------
* send modes

batchMd       =     0
fileMd        =     1

