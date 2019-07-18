*
* July 15, 1991
*
* This file is hereby dedicated to the public domain.
*                                 -- Andrew Nicholas
*
            LST   RTN

*-------------------------------------------------
* ZMODEM global equates

NO_ERROR    =     0
ERROR       =     -1          ;we got an error someplace
ABORT       =     -2          ;toast the zmodem connection
TIMEOUT     =     -3          ;we died someplace (10 seconds)
OVERFLOW    =     -4          ;someone (greg?) overflowed the input buffer
INTERRUPT   =     -5          ;someone interrupted us by a ZPAD, ZDLE sequence

ZPAD        =     '*'         ;052 padding character begins frames
ZDLE        =     24          ;Ctrl-X Zmodem escape - 'ala BISYNC DLE
ZDLEE       =     ZDLE+$40    ;Escaped ZDLE as transmitted
ZBIN        =     'A'         ;Binary frame indicator (CRC-16)
ZHEX        =     'B'         ;HEX frame indicator
ZBIN32      =     'C'         ;Binary frame with 32-bit FCS
ZBINR32     =     'D'         ;RLE packed frame with 32-bit FCS
ZVBIN       =     'a'         ;Binary frame indicator
ZVHEX       =     'b'         ;HEX frame indicator
ZVBIN32     =     'c'         ;Binary frame with 32-bit FCS
ZVBINR32    =     'd'         ;RLE packed Binary frame with 32-bit FCS
ZRESC       =     $7E         ;RLE flag/escape character
ZMAXHLEN    =     16          ;Max header information length NO-CHANGE
ZMAXSPLEN   =     1024        ;Max subpacket length NEVER CHANGE

*
* frame types
*
ZRQINIT     =     0           ;request receive init
ZRINIT      =     1           ;receive init
ZSINIT      =     2           ;send init sequence (optional)
ZACK        =     3           ;ACK to above
ZFILE       =     4           ;filename from sender
ZSKIP       =     5           ;to sender: skip this file
ZNAK        =     6           ;last packet was garbled
ZABORT      =     7           ;abort batch transfers
ZFIN        =     8           ;finish session
ZRPOS       =     9           ;resume data trans at this point
ZDATA       =     10          ;data packet(s) follow
ZEOF        =     11          ;end of file
ZFERR       =     12          ;fatal read or write error detected
ZCRC        =     13          ;request for file CRC and response
ZCHALLENGE  =     14          ;receiver's challenge
ZCOMPL      =     15          ;request is complete
ZCAN        =     16          ;other end canned session with CAN*5
ZFREECNT    =     17          ;request for free bytes on filesystem
ZCOMMAND    =     18          ;command from sending program
ZSTDERR     =     19          ;output to standard error, data follows

*
* ZDLE sequences
*
ZCRCE       =     'h'         ;CRC next, frame ends, header packet follows
ZCRCG       =     'i'         ;CRC next, frame continues nonstop
ZCRCQ       =     'j'         ;CRC next, frame continues, ZACK expected
ZCRCW       =     'k'         ;CRC next, ZACK expected, end of frame
ZRUB0       =     'l'         ;translate to rubout 0177
ZRUB1       =     'm'         ;translate to rubout 0377

*
* zdlread return values
*

*
* bit masks for ZRINIT flags byte ZF0
*
CANFDX      =     $0001       ;Rx can send and receive true FDX
CANOVIO     =     $0002       ;Rx can receive data during disk i/o
CANBRK      =     $0004       ;Rx can send a true break signal
CANRLE      =     $0008       ;Receiver can decode RLE
CANLZW      =     $0010       ;Receiver can uncompress
CANFC32     =     $0020       ;Receiver can use 32-bit frame check
ESCCTL      =     $0040       ;Rx expects ctl chars to be escaped
ESC8        =     $0080       ;Rx expects 8th bit to be escaped

*
* bit masks for ZRINIT flags byte ZF0
*
CANVHDR     =     $0001       ;variable headers OK

*
* parameters for ZSINIT frame
*
ZATTNLEN    =     32          ;Max length of attention string

* bit masks for ZSINIT flags byte ZF0

TESCCTL     =     $40         ;Tx expects ctl chars to be escaped
TESC8       =     $80         ;Tx expects 8th bit to be escaped

*
* parameters for ZFILE frame
*
ZCBIN       =     1           ;binary transfer - inhibit conversion
ZCNL        =     2           ;convert NL to local end of line
ZCRESUM     =     3           ;resume interrupted file transfer
ZMSKNOLOC   =     $80         ;skip file if not present at rx

* management options, one of those ored in ZF1

ZMMASK      =     $1F         ;mask for the choices below
ZMNEWL      =     1           ;transfer if source newer or longer
ZMCRC       =     2           ;transfer if different CRC or length
ZMAPND      =     3           ;append contents to existing file (if)
ZMCLOB      =     4           ;replace existing file
ZMNEW       =     5           ;replace if source newer
ZMDIFF      =     6           ;transfer if dates or lengths different
ZMPROT      =     7           ;protect destination file

* transport options, one of these in ZF2

ZTLZW       =     1           ;lempel-ziv compression
ZTRLE       =     2           ;run-length encoding

* extended options for ZF3, bit encoded

ZXSPARS     =     64          ;encoding for sparse file operations
ZCANVHDR    =     1           ;variable headers OK

*
* parameters for ZCOMMAND frame ZF0 (otherwise 0)
*
ZCACK1      =     1           ;acknowledge, then do command

*
* globals used by ZMODEM functions
*
RXPOS       =     0           ;received file position
TXPOS       =     4           ;transmitted file position
            LST   OFF

