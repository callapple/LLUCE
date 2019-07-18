            LST   OFF
*=================================================
* Printable Text
*=================================================

OSNAME      DA    0
            DA    :OS0        ; Location Of Each OS Name
            DA    :OS1
            DA    :OS2
            DA    :OS3
            DA    :OS4
            DA    :OS5
            DA    :OS6
            DA    :OS7
            DA    :OS8
            DA    :OS9
            DA    :OSA
            DA    :OSB
            DA    :OSC
            DA    :OSD

:OS0        ASC   'ProDOS Or SOS'00
:OS1        ASC   'DOS 3.3'00
:OS2        ASC   'reserved'00
:OS3        ASC   'DOS 3.2/1'00
:OS4        ASC   'Apple II Pascal'00
:OS5        ASC   'Macintosh MFS'00
:OS6        ASC   'Macintosh HFS'00
:OS7        ASC   'Macintosh XL'00
:OS8        ASC   'Apple CP/M'00
:OS9        ASC   'reserved'00
:OSA        ASC   'MS-DOS'00
:OSB        ASC   'High Sierra (CD-ROM)'00
:OSC        ASC   'ISO 9660 (CD-ROM)'00
:OSD        ASC   'AppleShare'00

STORE       ASC   ' Stored '
CRUNCH      ASC   'Crunched'
CRUSH       ASC   'Crushed '
DISTILL     ASC   'Distill '
HUFF        ASC   'Huffman '
IMPLODE     ASC   'Imploded'
LZW         ASC   '  LZW   '
LZWARI      ASC   'LZW-ARI '
PACK        ASC   ' Packed '
REDUCE      ASC   'Reduced '
RLE         ASC   '  RLE   '
SHRUNK      ASC   ' Shrunk '
SQU         ASC   'Squeezed'
SQUASH      ASC   'Squashed'
TYPE1       ASC   ' LZW/1  '
TYPE2       ASC   ' LZW/2  '
COMP12      ASC   ' Comp12 '
COMP16      ASC   ' Comp16 '
DLX1        ASC   'Deluxe/1'
DLX2        ASC   'Deluxe/2'
FOLDER      ASC   ' Folder '
UNK         ASC   'Unknown '

*=================================================
* Apple //GS Date/Time Format
*-------------------------------------------------

GSSEC       DB    0           ; Second  - 0 Through 59
GSMIN       DB    0           ; Minute  - 0 Through 59
GSHR        DB    0           ; Hour    - 0 Through 23
GSYR        DB    0           ; Current Year Minus 1900
GSDAY       DB    0           ; Day     - 0 Through 30
GSMNTH      DB    0           ; Month   - 0 Through 11, With
; 0=January
            DB    0           ; Filler Byte - Reserved = 00
GSWDAY      DB    0           ; Weekday - 1 Through 7, With
; 1=Sunday

NODATETX    ASC   '[No Date]'

MTHTXT      ASC   'Jan'
            ASC   'Feb'
            ASC   'Mar'
            ASC   'Apr'
            ASC   'May'
            ASC   'Jun'
            ASC   'Jul'
            ASC   'Aug'
            ASC   'Sep'
            ASC   'Oct'
            ASC   'Nov'
            ASC   'Dec'
            ASC   '???'

DSTR        ASC   '01-Jan-90'
TSTR        ASC   '12:00:00 '

*=================================================
* Constants
*=================================================

SEVEN       DB    7           ; Days In Week

SECMIN      DB    60          ; Seconds In A Minute
SECHOUR     DA    3600        ; Seconds In An Hour
SECDAY      ADRL  86400       ; Seconds In A Day
SECYEAR     ADRL  31536000    ; Seconds In A Year
SEC4YEAR    ADRL  126230400   ; Seconds In 4 Years

MTHLENS     DB    31,28,31,30,31,30,31,31,30,31,30,31

CODEEND     =     *

*=================================================
* Temporaries And Work Areas
*=================================================

LIBTYPE     DB    0

LASTMARK    ADRL  0

RESLEN      DB    0

NUMB        DS    4           ; Number Being Worked On
DATA        DS    9           ; Second Number Or Work Area
REMAIN      DS    4           ; Divide Remainder (MOD)
RESULT      DS    11          ; Result Of Multiply/Divide Or Mod
SAVE        DS    4           ; Used In Divide/Mod Only

SECS        ADRL  0           ; Seconds From 1904
SECTEMP     ADRL  0
LYEARS      DW    0           ; Number Of Leap Years
YRSAVE      DB    0           ; Number Of Remaining Years

START       =     *
            DUM   START       ; AppleSingle/AppleDouble
            DS    3           ; Apl Sng/Dbl Start Mark
OSID        DB    0           ; Apl Operating System ID
FNOFS       ADRL  0           ; Apl Filename Offset
FNLEN       ADRL  0           ; Apl Filename Length
CDLEN       ADRL  0           ; Apl Code Length
INFOFS      ADRL  0           ; Apl File Info Offset
INFLEN      ADRL  0           ; Apl File Info Length
DATOFS      ADRL  0           ; Apl Data Offset
DATLEN      ADRL  0           ; Apl Data Length
            DEND

            DUM   START       ; ZIP Work Area
CENTMRK     DS    3           ; Zip Central Dir Mark
            DEND

            DUM   START       ; ShrinkIt Work Area
PASSNO      DB    0           ; Shk Archive Pass Number
CUR_REC     ADRL  0           ; Shk Current Record
STRTMARK    ADRL  0           ; Shk Archive Start Mark
THRMARK     ADRL  0           ; Shk Thread Start Mark
TCOUNT      ADRL  0           ; Shk Thread Count
ENDTHRD     ADRL  0           ; Shk End Of Thread Records
SHK_NFNL    DW    0           ; Shk New Filename Length
FNAMOFFS    ADRL  0           ; Shk Filename Offset
SHK_NCML    DW    0           ; Shk New Comment Length
COMOFFS     ADRL  0           ; Shk Comment Offset
TCOMPR      ADRL  0           ; Shk Thread Compressed Len
TUCOMPR     ADRL  0           ; Shk Thread Uncomp Len
OCOMPR      ADRL  0           ; Shk Other Comp Size
COMMENTS    DB    0           ; Shk Comments Available Flag
SHK_DSK     DB    0           ; Shk Showing A Disk
            DEND

            DUM   START       ; ACU Work Area
RDEOF       ADRL  0           ; Acu Eof
RDSIZ       ADRL  0           ; Acu Size
            DEND

LOWSUBS     =     *

