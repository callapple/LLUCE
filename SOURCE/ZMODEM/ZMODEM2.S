*
* July 15, 1991
*
* This file is hereby dedicated to the public domain.
*                                 -- Andrew Nicholas
*
                LST   RTN

*-------------------------------------------------
* zglobals -- global data area for zmodem stuff

BAUDVALUES      DB    1                ;300
                DB    4                ;1200
                DB    8                ;2400
                DB    16               ;4800
                DB    32               ;9600
                DB    64               ;19200

BLOCKSIZES
                DW    128              ;300
                DW    256              ;1200
                DW    512              ;2400
                DW    1024             ;4800
                DW    1024             ;9600
                DW    1024             ;19200

DUBLBLOCKSIZES
                DW    256              ;300
                DW    512              ;1200
                DW    1024             ;2400
                DW    1024             ;4800
                DW    1024             ;9600
                DW    1024             ;19200

PREFIX
RZPATH
PATHNAME        DS    48

BAUDRATE        DB    0
CONSEDGOOD      DB    0                ;number of consecutive good blocks
CONSECBAD       DB    0                ;number of consecutive bad blocks

NAMELEN         DA    0                ;length of filename

ERRORS          DA    0

ZCOUNT          DW    0
BLKLEN          DW    0                ;how long a block should we send?
WHERE2START     DW    0
WHERE2END       DW    0
BYTES2SEND      DW    0
BYTES           DS    4
RXCOUNT         DS    4                ;number of bytes received
TXCOUNT         DS    4                ;number of bytes sent
TXBUFFERLEN     DA    0                ;number of bytes which can be streamed
TXBUFFERSIZE    DA    0                ;number of byte we're willing to stream
CANCOUNT        DB    0                ;number of can's received
ZBUFFEREND      DW    0

USEFC32         DB    0                ;use CRC32? boolean
ESCAPED         DA    0                ;boolean (was last character escaped?)

RXBYTES         ADRL  0                ;total # of bytes received
TXBYTES         ADRL  0                ;total # of bytes sent

GOTCR           DB    0                ;got a cr in a cr/lf sequence
ZCONVERT        DB    0
ZMANAGE         DB    0
ZTRANSPORT      DB    0

*
* byte positions within header array
*
FLAGS
RXPOSITION      ADRL  0                ;our receiver position (where we are)
TXPOSITION      ADRL  0                ;our transmitter position
SYNC            DA    0

*
* stuff for getting the other sides attention
*
ATTNLENGTH      DB    0
ATTENTION       DS    34

*
* parms lists for zmodem common to both sender and received
*
OPENPARMS
                DB    3
                DA    PATHNAME
                DA    FILEBUFFER2
                DB    0

CLOSEPARMS
                DB    1
                DB    0

MARKPARMS
                DB    2
                DB    0
                DS    3

*-------------------------------------------------
* PRINTSUB -- print a single subpacket in the window on the screen
*
* *** debugging use only ***

                DO    BUILDDEBUG
PRINTSUB
                STA   WHOCALLED
                STY   CHARSRECEIVED
                STX   CHARSRECEIVED+1

                LDA   FRAMEEND
                SEC
                SBC   #ZCRCE
                CMP   #4
                BLT   GOODF
                LDA   #4

GOODF           STA   OURFRAME

                LDA   #' '             ;clear out the old CRC info
                LDX   #31
:PCLOOP1        STA   PACKETT2,X
                INX
                CPX   #39
                BLT   :PCLOOP1

                LDX   #50
:PCLOOP2        STA   PACKETT2,X
                INX
                CPX   #58
                BLT   :PCLOOP2

                LDA   FRAMEEND
                JSR   PUTHEX
                STX   PACKETT2+11
                STA   PACKETT2+12

                LDA   CHARSRECEIVED+1
                JSR   PUTHEX
                STX   PACKETT2+21
                STA   PACKETT2+22

                LDA   CHARSRECEIVED
                JSR   PUTHEX
                STX   PACKETT2+23
                STA   PACKETT2+24

                LDA   WHOCALLED
                CMP   #2
                BLT   :CRC16

                LDA   CRC+3
                JSR   PUTHEX
                STX   PACKETT2+31
                STA   PACKETT2+32

                LDA   CRC+2
                JSR   PUTHEX
                STX   PACKETT2+33
                STA   PACKETT2+34

:CRC16          LDA   CRC+1
                JSR   PUTHEX
                STX   PACKETT2+35
                STA   PACKETT2+36

                LDA   CRC
                JSR   PUTHEX
                STX   PACKETT2+37
                STA   PACKETT2+38

                LDA   WHOCALLED
                TAX
                AND   #1
                BEQ   :NOFRAMECRC
                TXA
                CMP   #2
                BLT   :FRAMECRC16

                LDA   FRAMECRC+3
                JSR   PUTHEX
                STX   PACKETT2+50
                STA   PACKETT2+51

                LDA   FRAMECRC+2
                JSR   PUTHEX
                STX   PACKETT2+52
                STA   PACKETT2+53

:FRAMECRC16
                LDA   FRAMECRC+1
                JSR   PUTHEX
                STX   PACKETT2+54
                STA   PACKETT2+55

                LDA   FRAMECRC
                JSR   PUTHEX
                STX   PACKETT2+56
                STA   PACKETT2+57

:NOFRAMECRC
                LDA   WHOCALLED
                ASL
                ASL
                TAX
                LDY   #0
:WHOLOOP        LDA   WHOTEXT,X
                STA   PACKETT2+63,Y
                INX
                INY
                CPY   #4
                BLT   :WHOLOOP

                LDA   #>PACKETT2
                LDX   #<PACKETT2
                JSR   PRINTCSTRING

                LDA   OURFRAME
                ASL
                TAY
                LDA   TADDR,Y
                TAX
                LDA   TADDR+1,Y
                JSR   PRINTCSTRING
                JMP   CROUT

PACKETT2        ASC   'SubPacket=$XX Chars=$XXXX CRC=$XXXXXXXX FrameCRC=$XXXXXXXX Who=     '00
WHOCALLED       DB    0
CHARSRECEIVED   DA    0
OURFRAME        DB    0

WHOTEXT         ASC   'zs  '           ;send
                ASC   'zr  '           ;receive
                ASC   'zs32'           ;send CRC-32
                ASC   'zr32'           ;receive CRC-32

TADDR           DA    TEXTZCRCE
                DA    TEXTZCRCG
                DA    TEXTZCRCQ
                DA    TEXTZCRCW
                DA    TEXTUNKNOWN

TEXTZCRCE       ASC   'ZCRCE'00
TEXTZCRCG       ASC   'ZCRCG'00
TEXTZCRCQ       ASC   'ZCRCQ'00
TEXTZCRCW       ASC   'ZCRCW'00

*-------------------------------------------------
* PRINTPACKET -- print a single frame on the screen
*
* *** debugging use only ***

PRINTPACKET
                STA   WHOCALLED2

                LDA   FRAMETYPE
                CMP   #20
                BLT   KNOWN
                LDA   #20
KNOWN           STA   OURFRAME2

                LDA   #' '             ;clear out the old CRC info
                LDX   #31
:PCLOOP1        STA   PACKETTEXT,X
                INX
                CPX   #39
                BLT   :PCLOOP1

                LDX   #50
:PCLOOP2        STA   PACKETTEXT,X
                INX
                CPX   #58
                BLT   :PCLOOP2

                LDA   FRAMETYPE
                JSR   PUTHEX
                STX   PACKETTEXT+7
                STA   PACKETTEXT+8

                LDA   ZP0
                JSR   PUTHEX
                STX   PACKETTEXT+11
                STA   PACKETTEXT+12

                LDA   ZP1
                JSR   PUTHEX
                STX   PACKETTEXT+15
                STA   PACKETTEXT+16

                LDA   ZP2
                JSR   PUTHEX
                STX   PACKETTEXT+19
                STA   PACKETTEXT+20

                LDA   ZP3
                JSR   PUTHEX
                STX   PACKETTEXT+23
                STA   PACKETTEXT+24

                LDA   WHOCALLED2
                CMP   #2
                BEQ   :CRC32
                CMP   #5
                BNE   :CRC16

:CRC32          LDA   CRC+3
                JSR   PUTHEX
                STX   PACKETTEXT+31
                STA   PACKETTEXT+32

                LDA   CRC+2
                JSR   PUTHEX
                STX   PACKETTEXT+33
                STA   PACKETTEXT+34

:CRC16          LDA   CRC+1
                JSR   PUTHEX
                STX   PACKETTEXT+35
                STA   PACKETTEXT+36

                LDA   CRC
                JSR   PUTHEX
                STX   PACKETTEXT+37
                STA   PACKETTEXT+38

                LDA   WHOCALLED2       ;if a receive routine called, then
                CMP   #3               ;we don't need to print the frameCRC, since
                BLT   :NOFRAMECRC      ;we aren't going to RECEIVE one...
                CMP   #5
                BNE   :FRAMECRC16

                LDA   FRAMECRC+3
                JSR   PUTHEX
                STX   PACKETTEXT+50
                STA   PACKETTEXT+51

                LDA   FRAMECRC+2
                JSR   PUTHEX
                STX   PACKETTEXT+52
                STA   PACKETTEXT+53

:FRAMECRC16
                LDA   FRAMECRC+1
                JSR   PUTHEX
                STX   PACKETTEXT+54
                STA   PACKETTEXT+55

                LDA   FRAMECRC
                JSR   PUTHEX
                STX   PACKETTEXT+56
                STA   PACKETTEXT+57

:NOFRAMECRC
                LDA   WHOCALLED2
                ASL   A
                ASL   A
                TAX
                LDY   #0
:LOOP           LDA   WHOTEXT2,X
                STA   PACKETTEXT+63,Y
                INX
                INY
                CPY   #4
                BLT   :LOOP

                LDX   #<PACKETTEXT
                LDA   #>PACKETTEXT
                JSR   PRINTCSTRING

                LDA   OURFRAME2
                ASL   A
                TAY
                LDA   PADDR,Y
                TAX
                LDA   PADDR+1,Y
                JSR   PRINTCSTRING
                JMP   CROUT

PACKETTEXT      ASC   'Frame=$XX/$XX $XX $XX $XX CRC=$XXXXXXXX FrameCRC=$XXXXXXXX Who=     '00
WHOCALLED2      DB    0

WHOTEXT2        ASC   'SB  '           ;Send
                ASC   'SH  '
                ASC   'SB32'           ;send a binary CRC-32 packet
                ASC   'RB  '           ;Recv
                ASC   'RH  '
                ASC   'RB32'           ;receive a binary CRC-32 packet

OURFRAME2       DB    0

PADDR           DA    TEXTZRQINIT
                DA    TEXTZRINIT
                DA    TEXTZSINIT
                DA    TEXTZACK
                DA    TEXTZFILE
                DA    TEXTZSKIP
                DA    TEXTZNAK
                DA    TEXTZABORT
                DA    TEXTZFIN
                DA    TEXTZRPOS
                DA    TEXTZDATA
                DA    TEXTZEOF
                DA    TEXTZFERR
                DA    TEXTZCRC
                DA    TEXTZCHALLENGE
                DA    TEXTZCOMPL
                DA    TEXTZCAN
                DA    TEXTZFREECNT
                DA    TEXTZCOMMAND
                DA    TEXTZSTDERR
                DA    TEXTUNKNOWN

TEXTZRQINIT     ASC   'ZRQINIT'00
TEXTZRINIT      ASC   'ZRINIT'00
TEXTZSINIT      ASC   'ZSINIT'00
TEXTZACK        ASC   'ZACK'00
TEXTZFILE       ASC   'ZFILE'00
TEXTZSKIP       ASC   'ZSKIP'00
TEXTZNAK        ASC   'ZNAK'00
TEXTZABORT      ASC   'ZABORT'00
TEXTZFIN        ASC   'ZFIN'00
TEXTZRPOS       ASC   'ZRPOS'00
TEXTZDATA       ASC   'ZDATA'00
TEXTZEOF        ASC   'ZEOF'00
TEXTZFERR       ASC   'ZFERR'00
TEXTZCRC        ASC   'ZCRC'00
TEXTZCHALLENGE  ASC   'ZCHALLENGE'00
TEXTZCOMPL      ASC   'ZCOMPL'00
TEXTZCAN        ASC   'ZCAN'00
TEXTZFREECNT    ASC   'ZFREECNT'00
TEXTZCOMMAND    ASC   'ZCOMMAND'00
TEXTZSTDERR     ASC   'ZSTDERR'00
TEXTUNKNOWN     ASC   'Unknown'00

*-------------------------------------------------
* PUTHEX -- translate (A) into ascii hex in X&A

PUTHEX          STA   :HEXTEMP
                AND   #%11110000
                LSR   A
                LSR   A
                LSR   A
                LSR   A
                JSR   :DODIGIT
                TAX
                LDA   :HEXTEMP
                AND   #%00001111

:DODIGIT        ORA   #%00110000
                CMP   #'9'+1
                BCC   :OK
                CLC
                ADC   #7
:OK             RTS

:HEXTEMP        DB    00
                FIN

*-------------------------------------------------
* CROUT -- print a CR

CROUT           LDA   #cr
                JSR   COUT

                DO    BUILDPRINT
                LDA   #cr              ;uncommment these lines to dump to the printer
                JSR   PRCOUT
                FIN

                RTS

*-------------------------------------------------
* PRINTCSTRING -- print the cstring pointed to by X&A

PRINTCSTRING
                STX   CPTR
                STA   CPTR+1

                LDY   #0
:LOOP           LDA   (CPTR),Y
                BEQ   :DONE
                PHY
                PHA
                JSR   COUT
                PLA

                DO    BUILDPRINT
                JSR   PRCOUT           ;uncomment this line to dump to printer
                FIN

                PLY
                INY
                BRA   :LOOP

:DONE           RTS

*-------------------------------------------------
* PRINTPSTRING -- print the pstring pointed to by X&A

PRINTPSTRING
                STX   CPTR
                STA   CPTR+1

                LDA   (CPTR)
                STA   PSTRLENGTH

                LDY   #1
:LOOP           LDA   (CPTR),Y
                ORA   #$80
                PHY
                PHA
                JSR   COUT
                PLA

                DO    BUILDPRINT
                JSR   PRCOUT           ;uncomment this line to dump to printer
                FIN

                PLY
                INY
                CPY   PSTRLENGTH
                BLT   :LOOP
                BEQ   :LOOP

                RTS

PSTRLENGTH      DB    0
                LST   OFF

