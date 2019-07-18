                         TTL   'LLUCE - OS equates'
                         PAGE
*---------------------------------------
* ProDOS Equates
*---------------------------------------

MLI                      =     $BF00                 MLI
JSPARE                   =     $BF03
PDATIME                  =     $BF06                 Clock
SYSERR                   =     $BF09                 Error
SYSDETH                  =     $BF0C                 System
SERR                     =     $BF0F                 Error

DEV1ADR                  =     $BF10                 Slot
DEV2ADR                  =     $BF20                 Slot

DEVNUM                   =     $BF30                 Last
DEVCNT                   =     $BF31                 Number
DEVLST                   =     $BF32                 Device

PDOSCPR                  =     $BF40                 Copyright

BITMAP                   =     $BF58                 Memory

BUFADRS                  =     $BF70                 1

INTADRS                  =     $BF80                 1

INTAREG                  =     $BF88                 A
INTXREG                  =     $BF89                 X
INTYREG                  =     $BF8A                 Y
INTSREG                  =     $BF8B                 S
INTPREG                  =     $BF8C                 P

INTBNKID                 =     $BF8D                 Memory
INTADDR                  =     $BF8E                 Address

DATE                     =     $BF90                 ProDOS
TIME                     =     $BF92                 ProDOS

LEVEL                    =     $BF94                 File
BUBIT                    =     $BF95                 Backup
SPARE1                   =     $BF96

MACHID                   =     $BF98                 Machine
SLTBYT                   =     $BF99                 Slot
PFIXPTR                  =     $BF9A                 Prefix
MLIACTV                  =     $BF9B                 MLI
CMDADR                   =     $BF9C                 MLI
PSAVEX                   =     $BF9E                 X
PSAVEY                   =     $BF9F                 Y

LANGID1                  =     $BFF4
LANGID2                  =     $BFF5
IBAKVER                  =     $BFFC
IVERSION                 =     $BFFD
KBAKVER                  =     $BFFE
KVERSION                 =     $BFFF

fnMaxLen                 =     15

*-------------------------------
* ProDOS command numbers

Setint                   =     $40                   Set
Clrint                   =     $41                   Remove

* AppleTalk Commands

Ashare                   =     $42                   AppleTalk
SpclOpen                 =     $43                   Special
RangeLok                 =     $44                   Byte

* Direct Commands

Rd_Block                 =     $80                   Used
Wr_Block                 =     $81                   Write
Gettime                  =     $82                   Read

* Housekeeping Commands

Quit                     =     $65                   Quit

Create                   =     $C0                   Create
Destroy                  =     $C1                   Delete
Rename                   =     $C2                   Rename
Setinfo                  =     $C3                   Set
Getinfo                  =     $C4                   Get
Online                   =     $C5                   Get
Setpfx                   =     $C6                   Set
Getpfx                   =     $C7                   Get

* File Handling Commands

Open                     =     $C8                   Open
Newline                  =     $C9                   Set
Read                     =     $CA                   Read
Write                    =     $CB                   Write
Close                    =     $CC                   Close
Flush                    =     $CD                   Flush
Setmark                  =     $CE                   Set
Getmark                  =     $CF                   Get
Seteof                   =     $D0                   Set
Geteof                   =     $D1                   Get
Setbuf                   =     $D2                   Set
Getbuf                   =     $D3                   Get

*-------------------------------
* ProDOS main file types
*-------------------------------

Txt                      =     4                     Text
Dir                      =     $F                    Directory
Awp                      =     $1A                   AppleWorks

object                   =     $2B                   object
interp                   =     $2C                   interpreted
langdata                 =     $2D                   language
codefile                 =     $2E                   p8
Src                      =     $B0                   APW

llcode                   =     $0B                   L&L
comsrc                   =     $1B                   communications

* full file types

overlays                 =     $2B8004               overlay
compiled                 =     $2C8006               compiled
messages                 =     $2D8004               message
drivers                  =     $2E8005               drivers
llucesrc                 =     $B00B1B               LLUCE
sysfile                  =     $FF2000               system

*---------------------------------------
* File Storage Types

Seedling                 =     1                     Create
Sapling                  =     2                     Sapling
Tree                     =     3                     Tree
Pascal                   =     4                     Pascal
Extended                 =     5                     Extended
Linklist                 =     $D                    Directory

*---------------------------------------
* ProDOS access bits

readEnable               =     $01
writeEnable              =     $02
fileInvisible            =     $04                   Invisible
backupNeeded             =     $20                   backup
renameEnable             =     $40                   rename
destroyEnable            =     $80                   destroy

*---------------------------------------
* ProDOS error codes

badCall                  =     $01                   bad
invalidPcount            =     $04                   invalid
busErr                   =     $06                   communications
invalidDevNum            =     $11                   invalid
drvrBadCode              =     $21                   bad
drvrBadParm              =     $22                   bad
irqTableFull             =     $25                   interrupt
drvrIOError              =     $27                   I/O
drvrNoDevice             =     $28                   device
drvrWrtProt              =     $2B                   device
drvrBadBlock             =     $2D                   invalid
drvrDiskSwitch           =     $2E                   disk
drvrOffLine              =     $2F                   device
badPathSyntax            =     $40                   invalid
tooManyFilesOpen         =     $42                   too
invalidRefNum            =     $43                   invalid
pathNotFound             =     $44                   subdirectory
volNotFound              =     $45                   volume
fileNotFound             =     $46                   file
dupPathname              =     $47                   create
volumeFull               =     $48                   volume
volDirFull               =     $49                   volume
badFileFormat            =     $4A                   version
badStoreType             =     $4B                   unsupported
eofEncountered           =     $4C                   end-of-file
outOfRange               =     $4D                   position
invalidAccess            =     $4E                   access
fileBusy                 =     $50                   file
unknownVol               =     $52                   unknown
paramRangeErr            =     $53                   parameter
vcbFull                  =     $55                   volume
badBufAddr               =     $56                   bad
dupVolume                =     $57                   duplicate
damagedBitMap            =     $5A                   block
networkError             =     $88                   generic

*---------------------------------------
* AppleTalk Call Equates
*---------------------------------------
* Misc Calls

ATInit                   =     1                     Initialize
ATGetInfo                =     2                     Get
ATGetGlobal              =     3                     Get
ATInstallTimer           =     4                     Install
ATRemoveTimer            =     5                     Remove
ATBoot                   =     6                     Boot
ATCancelTimer            =     $45                   Cancel

* Link Access Protocol Calls

LAPWrite                 =     7                     Write
ReadBuffer               =     8                     Read
AttachProt               =     9                     Attach
RemoveProt               =     $A                    Remove

* Datagram Delivery Protocol Calls

OpenSocket               =     $B                    Open
CloseSocket              =     $C                    Close
SendDatagram             =     $D                    Send

* Name Binding Protocol Calls

RegisterName             =     $E                    Register
RemoveName               =     $F                    Remove
LookupName               =     $10                   Lookup
ConfirmName              =     $11                   Confirm
NBPKill                  =     $46                   Cancel

* AppleTalk Transaction Protocol

SendATPReq               =     $12                   Send
CancelAPReq              =     $13                   Cancel
OpenATPSocket            =     $14                   Open
CloseATPSocket           =     $15                   Close
GetATPReq                =     $16                   Get
SendATPResp              =     $17                   Send
AddATPResp               =     $18                   Add
RelATPCB                 =     $19                   Release

* Zone Information Protocol

GetMyZone                =     $1A                   Get
GetZoneList              =     $1B                   List

* AppleTalk Session Protocol

SPGetParms               =     $1C                   Get
SPGetStatus              =     $1D                   Get
SPOpenSession            =     $1E                   Open
SPCloseSession           =     $1F                   Close
SPCommand                =     $20                   Send
SPWrite                  =     $21                   Write

* Printer Access Protocol

PAPStatus                =     $22                   Get
PAPOpen                  =     $23                   Open
PAPClose                 =     $24                   Close
PAPRead                  =     $25                   PAP
PAPWrite                 =     $26                   PAP
PAPUnload                =     $27                   PAP

* Remote Print Manager

PMSetPrinter             =     $28                   Set
PMCloseSession           =     $47                   Close

* ProDOS Filing Interface

FIUserPrefix             =     $2A                   Get
FILogin                  =     $2B                   Log
FILoginCont              =     $2C                   Log
FILogOut                 =     $2D                   Log
FIMountVol               =     $2E                   Mount
FIListSessions           =     $2F                   List
FITimeZone               =     $30                   Set
FIGetSrcPath             =     $31                   Get
FIAccess                 =     $32                   Set/Get
FINaming                 =     $33                   Set/Get
ConvertTime              =     $34                   Convert
FISetBuffer              =     $36                   Set

*---------------------------------------
* AppleTalk error codes

atInvalidCmdErr          =     $0101                 Invalid
atMemoryErr              =     $0102                 Heap/memory
atTimerNotInstalledErr   =     $0103                 No
atSyncErr                =     $0104                 Syncronous
atTooManyTimes           =     $0105                 Too
atTimerCancelled         =     $0106
lapNoPacketErr           =     $0201                 No
lapEOBErr                =     $0202                 End
lapLenErr                =     $0203                 LAP
lapFailedErr             =     $0204                 Retry
lapTypeErr               =     $0205                 Illegal
lapDuplicateErr          =     $0206                 Duplicate
lapProtocolErr           =     $0207                 Too
lapTypeFoundErr          =     $0208                 Type
lapDataLostErr           =     $0209                 Data
ddpSktNumErr             =     $0301                 Too
ddpSktErr                =     $0302                 Socket
ddpSktOpenErr            =     $0303                 Socket
ddpSktTypeErr            =     $0304                 Invalid
ddpLenErr                =     $0305                 DDP
ddpBridgeErr             =     $0306                 No
nbpNameNumberErr         =     $0401                 Too
nbpNameExistErr          =     $0402                 Name
nbpNameFoundErr          =     $0403                 Name
nbpBufferErr             =     $0404                 User
nbpWildcardErr           =     $0405                 Wildcard
nbpNameErr               =     $0406                 Invalid
nbpAddressErr            =     $0407                 Incorrect
nbpProcessErr            =     $0408                 Too
nbpAbortErr              =     $0409                 NBP
nbpParmBlkNotFndErr      =     $040A                 NBP
atpDataLenErr            =     $0501                 ATP
atpSocketErr             =     $0502                 Invalid
atpControlBlkErr         =     $0503                 ATP
atpProcessErr            =     $0504                 Too
atpReleaseErr            =     $0505                 No
atpNoRespActive          =     $0506                 No
atpRespErr               =     $0507                 No
atpReqErr                =     $0508                 ATP
atpSktClosedErr          =     $0509                 socket
atpTooManySkts           =     $050A                 Too
atpTooManyResp           =     $050B                 Too
atpDDPSktErr             =     $050C                 Unable
atpSndRespRelErr         =     $050D                 ATP
zipNetworkErr            =     $0601                 Network
zipOverflow              =     $0602                 ZIP
zipNotFound              =     $0603                 ZIP
aspNetworkErr            =     $0701                 Network
aspSessNumErr            =     $0702                 Too
aspRefErr                =     $0703                 Invalid
aspSizeErr               =     $0704                 Size
aspBufErr                =     $0705                 Buffer
aspNoRespErr             =     $0706                 No
aspBadVersion            =     $0707                 Bad
aspTooManySessions       =     $0708                 Too
aspServBusyErr           =     $0709                 Server
aspSessionClosed         =     $070A                 Session
papSessNumErr            =     $0801                 Too
papRefErr                =     $0802                 Invalid
papQuantumErr            =     $0803                 Quantum
papCommandErr            =     $0804                 Too
papNameErr               =     $0805                 Name
papSessionErr            =     $0806                 Session
papNetworkErr            =     $0807                 Network
papServRespErr           =     $0808                 Server
papServBusyErr           =     $0809                 Server
papBuffSizeErr           =     $080A                 Buffer
papInUseErr              =     $080B                 PAP
rpmInvalidFlagErr        =     $0901
rpmInvalidTimeErr        =     $0902
pfiTooManySessErr        =     $0A01                 Too
pfiUnableOpenSessErr     =     $0A02                 Unable
pfiNoRespFrmSrvrErr      =     $0A03                 No
pfiLoginContErr          =     $0A04                 Login
pfiInvalidNameErr        =     $0A05                 Invalid
pfiInvalidSessNumErr     =     $0A06                 Invalid
pfiUnableOpenVolErr      =     $0A07                 Unable
pfiTooManyVolsOpenErr    =     $0A08                 Too
pfiVolNotMountedErr      =     $0A09                 Volume
pfiUnableSetCreatorErr   =     $0A0A
pfiBufferToSmallErr      =     $0A0B                 Buffer
pfiTimeFlagErr           =     $0A0C                 Time
pfiUnableTSetGroupErr    =     $0A0D                 Unable
pfiDirNotFoundErr        =     $0A0E                 Directory
pfiAccessDeniedErr       =     $0A0F                 Access
pfiMiscellaneousErr      =     $0A10                 Miscellaneous
pfiVolAlreadyMntedErr    =     $0A11                 Volume
pfiUnableGetCreatorErr   =     $0A12                 Unable
pfiAlrdyLggedOnSrvrErr   =     $0A13                 Already
pfiTimeError             =     $0A14                 Time
pfiUserNotAuthorizedErr  =     $0A15                 User
pfiParamterErr           =     $0A16                 Parameter
pfiSrvrGoingDownErr      =     $0A17                 Server
pfiBadUAMErr             =     $0A18                 Bad
pfiBadVersionNumErr      =     $0A19                 Bad

