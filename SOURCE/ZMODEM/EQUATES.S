*
* July 15, 1991
*
* This file is hereby dedicated to the public domain.
*                                        -- Andrew Nicholas
*
               LST   RTN

*-------------------------------------------------
* aux memory stuff

AUXMOVE        =     $C311       ;a1=source,a2=source end,a4=dest start
                                 ;carry set   = main --> aux
                                 ;carry clear = aux --> main

A1             =     $3C         ;and $3D
A2             =     $3E         ;and $3F
A3             =     $40         ;and $41
A4             =     $42         ;and $43

*-------------------------------------------------
* regular stuff

POINTER        =     $00         ;general purpose pointer
FAILFLAG       =     $0A
TMODE          =     $0B
HTAB           =     $24

NUM            =     $D0         ;used by long2Dec
DECIMAL        =     $D3         ;used by long2Dec

CRC            =     $E0         ;crc we calculated
CRC32          =     $E0         ;crc32 we calculated

FRAMECRC32     =     $E4         ;crc32 we got from the other end
FRAMECRC       =     $E4         ;crc we got from the other end

NOISE          =     $E8         ;number of pieces of line noise we got so far
FRAMEKIND      =     $E9         ;kind of frame (ZHEX, ZBIN, ZBIN32)
FRAMEEND       =     $EA         ;type of frame we sent or received
FRAMETYPE      =     $EB         ;frame type byte

ZPTR           =     $F0
CPTR           =     $F2
FPTR           =     $F4         ;POINTER to filename
ZSTART         =     $F6
ZEND           =     $F8
LASTC          =     $FA

ZP0            =     $FC         ;byte 0 of zmodem's file position
ZF3            =     $FC
ZP1            =     $FD         ;byte 1 of zmodem's file position
ZF2            =     $FD
ZP2            =     $FE         ;byte 2 of zmodem's file position
ZF1            =     $FE
ZP3            =     $FF         ;byte 3 of zmodem's file position
ZF0            =     $FF

lf             =     $0A
can            =     $18
cr             =     $0D
bs             =     $08
esc            =     $1B
xon            =     $11
xoff           =     $13

GOBCOM         =     $0386       ;acos routine to eat commas
INPNUM         =     $0389       ;get character into x reg
INPSTR         =     $038C       ;get a string
MOVNAME        =     $038F       ;get filename into filename buffer
BADERR         =     $0392       ;acos error handler
SETOVEC        =     $03A1       ;set output vector to y reg
*COUT    =     $03A4      ;Standard acos output routine
DECOUT         =     $03A7       ;print acc and x as integer...
ACOS_CREATE    =     $03AA       ;acos mli create call
ACOS_OPEN      =     $03AD       ;acos mli open call
ACOS_CLOSE     =     $03B0       ;acos mli close call
READBLK        =     $03B9       ;read some blocks
LOG            =     $03C8       ;move pathname into path buffer
ACOSPATHLO     =     $03CB       ;pathname addr lo from acos
ACOSPATHHI     =     $03CC       ;pathname addr hi from acos
ACOSREF        =     $03CD       ;reference # from acos mli call
COUT           =     $0906
LOCPRINT       =     $0906       ;print to the local screen
PRCOUT         =     $0C04       ;print a character on the printer
VIDEOSCROLL    =     $0909       ;scroll screen up 1 line
BAUD           =     $0E02       ;baud rate the caller is connected at
MDMIN          =     $0E15       ;modem driver input routine
MDMOUT         =     $0E18       ;modem driver output routine
MDMDCD         =     $0E1B       ;modem driver carrier detect
MDMFLUSH       =     $0E24       ;only exists in ACOS v2.14 and later
MLI            =     $BF00       ;prodos calls
KEY            =     $C000       ;read keyboard
STROBE         =     $C010       ;keyboard strobe
PTRIG          =     $C070       ;paddle trigger (used to slow down for accelerators)
*
* This is not the ACOS chrget routine.  This is an invalid
* entry point.  Probably was AppleSoft chrget $00B1
*
CHRGET         =     $03B1       ;acos get character routine

GETBYT         =     $0380       ;get next byte from segment
CHKBYT         =     $0383       ;check next byte in segment

CRCTABLELO     =     $2000       ;where the crc tables get moved into
CRCTABLEHI     =     $2000+$100  ;main memory from aux memory
CRC32TABLE1    =     $2000+$200
CRC32TABLE2    =     $2000+$300
CRC32TABLE3    =     $2000+$400
CRC32TABLE4    =     $2000+$500

ZBUFFER        =     $2000+$600
MAXBUFFERSIZE  =     $4000
FILEBUFFER1    =     $AE00
FILEBUFFER2    =     $B200
               LST   OFF

