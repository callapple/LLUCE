                      LST    OFF
                      LSTDO  OFF
*
* July 15, 1991
*
* This file is hereby dedicated to the public domain.
*                                 -- Andrew Nicholas
*
                      XC
                      TR
                      TR     ADR
Y                     =      1
y                     =      1
N                     =      0
n                     =      0
LISTOBJ               KBD    'List This Source? (Y/N)'
LISTSYM               KBD    'List Symbol Table? (Y/N)'
SAVEOBJ               KBD    'Save Object Code? (Y/N)'

                      DO     LISTOBJ
                      LST
                      FIN
                      LST    OFF

BUILDIIC              KBD    'Build IIc version? (Y/N)'
NOTBUILDIIC           =      1-BUILDIIC
BUILDFLUSH            KBD    'Build using mdmFlush calls? (GBBS v2.14 & later only) (Y/N)'
NOTBUILDFLUSH         =      1-BUILDFLUSH
BUILDDEBUG            KBD    'Build with debugging display? (Y/N)'
NOTBUILDDEBUG         =      1-BUILDDEBUG
                      DO     BUILDDEBUG
BUILDPRINT            KBD    'Build debug dumped to printer? (Y/N)'
                      ELSE
BUILDPRINT            =      0
                      FIN
NOTBUILDPRINT         =      1-BUILDPRINT

                      PUT    EQUATES
                      PUT    ZEQUATES
                      LST    RTN

                      ORG    $9E00

*-------------------------------------------------
* our jump table

                      JMP    FIRST                                                          ;init everything
                      JMP    SZBEGIN                                                        ;start sending
                      JMP    SZ                                                             ;send the file
                      JMP    SZEND                                                          ;finish the send

BYTECOUNT             DS     3
XBLOCKS               DS     3
PBLOCKS               DS     3

*-------------------------------------------------
* SZBEGIN -- init SZ and return the code we got

SZBEGIN               JSR    STARTUP

                      JSR    GETZRXINIT

                      STA    FAILFLAG                                                       ;set other way next time
                      CMP    #NO_ERROR
                      BEQ    :NO_ERROR

                      JSR    CANCEL
:NO_ERROR
                      JMP    SHUTDOWN

*-------------------------------------------------
* SZ -- send files via ZMODEM, whoopee!

SZ                    JSR    GOBCOM
                      JSR    MOVNAME

                      LDA    ACOSPATHLO
                      STA    POINTER
                      LDA    ACOSPATHHI
                      STA    POINTER+1

                      LDA    (POINTER)
                      STA    PATHNAME

                      LDY    #1
:LOOP                 LDA    (POINTER),Y
                      STA    PATHNAME,Y
                      INY
                      CPY    PATHNAME
                      BLT    :LOOP
                      BEQ    :LOOP

                      STZ    BYTES
                      STZ    BYTES+1
                      STZ    BYTES+2

                      STZ    BYTECOUNT
                      STZ    BYTECOUNT+1
                      STZ    BYTECOUNT+2

                      STZ    CONSECGOOD                                                     ;nothing good, and nothing bad
                      STZ    CONSECBAD

                      JSR    STARTUP

                      JSR    SZFILE

                      STA    FAILFLAG                                                       ;this will need to be changed
                      CMP    #NO_ERROR
                      BEQ    :NO_ERROR

                      JSR    CANCEL

:NO_ERROR
                      LDA    BYTECOUNT
                      STA    XBLOCKS
                      STA    PBLOCKS
                      LDA    BYTECOUNT+1
                      STA    XBLOCKS+1
                      STA    PBLOCKS+1
                      LDA    BYTECOUNT+2
                      STA    XBLOCKS+2
                      STA    PBLOCKS+2

                      LDX    #6                                                             ;divide bytes sent by 128 to find out
:XLOOP                LSR    XBLOCKS+2                                                      ;how many blocks were sent
                      ROR    XBLOCKS+1
                      ROR    XBLOCKS
                      DEX
                      BPL    :XLOOP

                      LDX    #8                                                             ;divide bytes sent by 512 to find out
:PLOOP                LSR    PBLOCKS+2                                                      ;how many blocks were sent
                      ROR    PBLOCKS+1
                      ROR    PBLOCKS
                      DEX
                      BPL    :PLOOP

                      LDA    #3                                                             ;say we used ZMODEM
                      STA    tmode
                      JMP    SHUTDOWN

*-------------------------------------------------
* SZEND -- finish up for SZ

SZEND                 JSR    STARTUP

*
* saybibi() -- say bibi to receiver, try to do it cleanly
*              send ZFIN and OO
SAYBIBI               JSR    ZEROPOS

                      LDA    #ZFIN
                      STA    FRAMETYPE
                      JSR    ZSENDHHEADER

                      JSR    ZGETHEADER

                      CMP    #ZFIN
                      BEQ    :GOTZFIN

                      CMP    #TIMEOUT
                      BEQ    :GOODBYE
                      CMP    #ABORT
                      BEQ    :GOODBYE
                      CMP    #ERROR
                      BNE    SAYBIBI
                      BRA    :GOODBYE

:GOTZFIN              LDA    #'O'
                      JSR    MDMOUT

                      LDA    #'O'
                      JSR    MDMOUT

                      LDA    #NO_ERROR                                                      ;tell it we got a ZFIN
:GOODBYE              STA    FAILFLAG

                      DO     NOTBUILDDEBUG
                      JSR    CLEARLASTLINE
                      FIN

                      DO     BUILDFLUSH                                                     ;one final deed just in case something was sitting
                      JSR    MDMFLUSH                                                       ;in our buffer
                      FIN

                      JMP    SHUTDOWN

*-------------------------------------------------
* GETZRXINIT -- get the receiver's init parameters
*               this routine is only ever called once

GETZRXINIT
                      LDA    #xon                                                           ;un-jam anything we screwed up
                      JSR    MDMOUT

                      LDA    #'r'                                                           ;send 'rz' followed by <cr>
                      JSR    MDMOUT
                      LDA    #'z'
                      JSR    MDMOUT
                      LDA    #cr
                      JSR    MDMOUT

                      STZ    ERRORS

:GOTZCOMMAND
                      JSR    ZEROPOS

                      LDA    #ZRQINIT                                                       ;say hello to the other side, your gonna
                      STA    FRAMETYPE                                                      ;get some files!
                      JSR    ZSENDHHEADER

:LOOP                 JSR    ZGETHEADER

                      CMP    #20
                      BLT    :HEADER

                      CMP    #ERROR
                      BEQ    :GOTERROR
                      CMP    #ABORT
                      BEQ    :GOTABORT

                      INC    ERRORS                                                         ;must be TIMEOUT to get this far, if it is, then
                      LDA    ERRORS                                                         ;repeat the receive invitation
                      CMP    #5
                      BLT    :GOTZCOMMAND

                      LDA    #TIMEOUT
                      RTS

*
* wasn't anything else, something invalid
*
:RETURN               LDA    #ZNAK                                                          ;default = send ZNAK and try again
                      STA    FRAMETYPE
                      JSR    ZSENDHHEADER
                      JMP    :LOOP

:HEADER               ASL    A
                      TAX
                      JMP    (:ADDR,X)

:ADDR                 DA     :LOOP                                                          ;ZRQINIT        - 0
                      DA     :GOTZRINIT                                                     ;ZRINIT         - 1
                      DA     :RETURN                                                        ;ZSINIT         - 2
                      DA     :RETURN                                                        ;ZACK           - 3
                      DA     :RETURN                                                        ;ZFILE          - 4
                      DA     :RETURN                                                        ;ZSKIP          - 5
                      DA     :RETURN                                                        ;ZNAK           - 6
                      DA     :RETURN                                                        ;ZABORT         - 7
                      DA     :RETURN                                                        ;ZFIN           - 8
                      DA     :RETURN                                                        ;ZRPOS          - 9
                      DA     :RETURN                                                        ;ZDATA          - 10
                      DA     :RETURN                                                        ;ZEOF           - 11
                      DA     :RETURN                                                        ;ZFERR          - 12
                      DA     :RETURN                                                        ;ZCRC           - 13
                      DA     :GOTZCHALLENGE                                                 ;ZCHALLENGE - 14
                      DA     :RETURN                                                        ;ZCOMPL         - 15
                      DA     :GOTABORT                                                      ;ZCAN           - 16
                      DA     :RETURN                                                        ;ZFREECNT       - 17
                      DA     :GOTZCOMMAND                                                   ;ZCOMMAND     - 18
                      DA     :RETURN                                                        ;ZSTDERR        - 19

*
* someone goofed
*
:GOTERROR
                      LDA    #ERROR
                      RTS

*
* got ABORT
*
:GOTABORT
                      LDA    #ABORT
                      RTS

*
* got ZCHALLENGE?
*
:GOTZCHALLENGE
                      LDA    #ZACK                                                          ;echo the receiver's challenge number
                      STA    FRAMETYPE                                                      ;(number is already in ZP0..ZP3)
                      JSR    ZSENDHHEADER
                      JMP    :LOOP

*
* was it ZRINIT?
*
:GOTZRINIT
                      LDA    ZP1                                                            ;get our receiver's buffer length
                      CMP    #>MAXBUFFERSIZE
                      BGE    :FORCE8K

                      LDA    ZP1
                      BNE    :USETHEIRSIZE
                      LDA    ZP0
                      BEQ    :FORCE8K

:USETHEIRSIZE
                      LDA    ZP1
                      STA    TXBUFFERSIZE+1
                      CLC                                                                   ;largest possible buffersize
                      ADC    #>ZBUFFER
                      STA    ZBUFFEREND+1
                      LDA    ZP0
                      STA    TXBUFFERSIZE
                      STA    ZBUFFEREND
                      BRA    :USE8K

:FORCE8K              STZ    TXBUFFERSIZE
                      LDA    #>MAXBUFFERSIZE                                                ;was > 8k or CANOVIO, so use our
                      STA    TXBUFFERSIZE+1
                      CLC                                                                   ;largest possible buffersize
                      ADC    #>ZBUFFER
                      STA    ZBUFFEREND+1
                      STZ    ZBUFFEREND
:USE8K                STZ    USEFC32                                                        ;check for CRC32 stuff
                      LDA    ZF0
                      AND    #CANFC32
                      BEQ    :NOFC32
                      DEC    USEFC32
:NOFC32

*-------------------------------------------------
* SENDZSINIT -- send the ZSINIT parameters to our receiver (our attention
*               string) and wait for a ZACK response
SENDZSINIT
                      JSR    ZEROPOS

                      LDA    #ZSINIT
                      STA    FRAMETYPE
                      JSR    ZSENDBHEADER

                      LDA    #ZPAD
                      STA    ZBUFFER                                                        ;make '****' our attention string
                      STA    ZBUFFER+1
                      STA    ZBUFFER+2
                      STA    ZBUFFER+3
                      STZ    ZBUFFER+4                                                      ;store terminator

                      LDA    #5
                      STA    BYTES2SEND
                      STZ    BYTES2SEND+1

                      LDA    #<ZBUFFER                                                      ;where data is
                      STA    ZPTR
                      LDA    #>ZBUFFER
                      STA    ZPTR+1

                      LDX    #0                                                             ;can't be interrupted, they -need- this subpacket
                      LDA    #ZCRCW                                                         ;send our attention string afterwards
                      JSR    ZSDATA

                      STZ    ERRORS
:LOOP                 JSR    ZGETHEADER

                      CMP    #ABORT
                      BEQ    :GOTABORT
                      CMP    #ZCAN
                      BEQ    :GOTZCAN
                      CMP    #ZABORT
                      BEQ    :GOTZCAN
                      CMP    #ZACK                                                          ;timeout falls down here
                      BEQ    :DONE

                      INC    ERRORS
                      LDA    ERRORS
                      CMP    #6                                                             ;wait 1 minute, max
                      BLT    :LOOP

:GOTZCAN              LDA    #ERROR
:GOTABORT             RTS

:DONE                 LDA    #NO_ERROR                                                      ;we got a ZRINIT to get this far!
                      RTS

*-------------------------------------------------
* SZFILE() -- send a single file

SZFILE                JSR    MLI
                      DB     $C4
                      DA     GFIPARMS
                      BCS    :BAD

                      LDA    GFIPARMS+4                                                     ;we don't understand directories
                      CMP    #$F
                      BEQ    :BAD

                      LDA    GFIPARMS+7                                                     ;we don't understand forked files
                      CMP    #5
                      BEQ    :BAD

                      JSR    MLI                                                            ;open it
                      DB     $C8
                      DA     OPENPARMS
                      BCS    :BAD

                      LDA    OPENPARMS+5
                      STA    READPARMS+1
                      STA    CLOSEPARMS+1
                      STA    MARKPARMS+1
                      STA    EOFPARMS+1

                      JSR    MLI
                      DB     $D1
                      DA     EOFPARMS

                      JSR    ZSENDFILE

                      PHA
                      JSR    MLI                                                            ;close it!!
                      DB     $CC
                      DA     CLOSEPARMS
                      PLA

                      CMP    #ZSKIP
                      BEQ    :NOTNUTS
                      CMP    #ZRINIT
                      BNE    :NUTS
:NOTNUTS              LDA    #NO_ERROR
:NUTS                 RTS

:BAD                  LDA    #ERROR
                      RTS

*-------------------------------------------------
* ZSENDFILE -- send filename and related info

ZSENDFILE
                      STZ    ZPTR
                      LDA    #>ZBUFFER
                      STA    ZPTR+1

                      LDY    #0
                      LDX    #1
:NLOOP                LDA    PATHNAME,X
                      CMP    #'/'                                                           ;don't change case if it's a slash
                      BEQ    :STORE
                      CMP    #'.'                                                           ;or if it's a period
                      BEQ    :STORE
                      CMP    #'A'                                                           ;or if it's anything below the alpha chars
                      BLT    :STORE
                      CLC
                      ADC    #$20                                                           ;otherwise, change it to be lowercase
:STORE                STA    (ZPTR),Y
                      INX
                      INY
                      CPY    PATHNAME
                      BLT    :NLOOP

                      LDA    #0
                      STA    (ZPTR),Y

                      INY
                      PHY

                      LDA    EOFPARMS+2
                      STA    NUM
                      LDA    EOFPARMS+3
                      STA    NUM+1
                      LDA    EOFPARMS+4
                      STA    NUM+2

                      JSR    LONG2DEC

                      PLY
                      LDX    #0
:DECLOOP              LDA    DECIMAL,X
                      BEQ    :FOUNDLAST                                                     ;found last digit and terminator
                      STA    (ZPTR),Y
                      INY
                      INX
                      BRA    :DECLOOP

:FOUNDLAST
                      LDA    #0                                                             ;store terminating null
                      STA    (ZPTR),Y

                      INY
                      STY    BYTES2SEND
                      STZ    BYTES2SEND+1

                      STZ    ERRORS

                      DO     NOTBUILDDEBUG
                      JSR    PRINTSZSTAT                                                    ;print the status line

                      LDA    #28                                                            ;print the # of bytes to send
                      STA    HTAB

                      LDA    #>DECIMAL
                      LDX    #<DECIMAL
                      JSR    PRINTCSTRING
                      FIN

:LOOP                 LDA    #ZCBIN                                                         ;put the conversion, management
                      STA    ZF0                                                            ;and transport options in the header
                      LDA    #ZMCLOB
                      STA    ZF1
                      STZ    ZF2                                                            ;no transport options
                      STZ    ZF3

                      LDA    #ZFILE                                                         ;send a ZFILE frame followed by a ZCRCW
                      STA    FRAMETYPE

                      JSR    ZSENDBHEADER                                                   ;send it

                      LDA    #<ZBUFFER                                                      ;where data is
                      STA    ZPTR                                                           ;BYTES2SEND is already filled out
                      LDA    #>ZBUFFER
                      STA    ZPTR+1

                      LDX    #0                                                             ;can't be interrupted, they -need- this subpacket
                      LDA    #ZCRCW                                                         ;packet type
                      JSR    ZSDATA

                      JSR    ZGETHEADER

                      CMP    #20
                      BLT    :HEADER

:RETURN               CMP    #ABORT
                      BEQ    :GOTTIMEOUT
                      CMP    #TIMEOUT
                      BEQ    :GTZ
                      JMP    ZSENDFILE

:GTZ                  INC    ERRORS
                      LDA    ERRORS
                      CMP    #6
                      BGE    :GOTTIMEOUT
                      JMP    ZSENDFILE

:HEADER               ASL    A
                      TAX
                      JMP    (:ADDR,X)

:ADDR                 DA     :RETURN                                                        ;ZRQINIT    - 0
                      DA     :LOOP                                                          ;ZRINIT     - 1
                      DA     :RETURN                                                        ;ZSINIT     - 2
                      DA     :RETURN                                                        ;ZACK       - 3
                      DA     :RETURN                                                        ;ZFILE      - 4
                      DA     :GOTZSKIP                                                      ;ZSKIP      - 5
                      DA     ZSENDFILE                                                      ;ZNAK       - 6
                      DA     :GOTTIMEOUT                                                    ;ZABORT    - 7
                      DA     :GOTTIMEOUT                                                    ;ZFIN      - 8
                      DA     :GOTZRPOS                                                      ;ZRPOS      - 9
                      DA     :RETURN                                                        ;ZDATA      - 10
                      DA     :RETURN                                                        ;ZEOF       - 11
                      DA     :RETURN                                                        ;ZFERR      - 12
                      DA     :GOTZCRC                                                       ;ZCRC       - 13
                      DA     :RETURN                                                        ;ZCHALLENGE - 14
                      DA     :RETURN                                                        ;ZCOMPL     - 15
                      DA     :GOTTIMEOUT                                                    ;ZCAN      - 16
                      DA     :RETURN                                                        ;ZFREECNT   - 17
                      DA     :RETURN                                                        ;ZCOMMAND   - 18
                      DA     :RETURN                                                        ;ZSTDERR    - 19

*
* got a TIMEOUT, so return it
*
:GOTTIMEOUT
                      LDA    #TIMEOUT
                      RTS

*
* GOTZCRC
*
:GOTZCRC              LDA    #ERROR                                                         ;*** TEMPORARY ***
                      RTS

*
* GOTZSKIP
*
:GOTZSKIP
                      LDA    #ZSKIP
                      RTS

*
* GOTZRPOS
*
:GOTZRPOS
                      JSR    GETTXPOSITION                                                  ;munge position

                      LDA    TXPOSITION                                                     ;seek that position
                      STA    MARKPARMS+2
                      LDA    TXPOSITION+1
                      STA    MARKPARMS+3
                      LDA    TXPOSITION+2
                      STA    MARKPARMS+4

                      JSR    MLI
                      DB     $CE
                      DA     MARKPARMS
                      BCC    :GOODSEEK

                      LDA    #ERROR
                      RTS

*-------------------------------------------------

:GOODSEEK                                                                                   ;fall through to ZSENDFDATA
                      LDX    #0
:BLOOP                LDA    BAUDVALUES,X
                      CMP    BAUD
                      BEQ    :GOTBAUD
                      INX
                      CPX    #6
                      BLT    :BLOOP

                      LDX    #2                                                             ;default to 2400 baud if we can't find it
*
* find the baud rate by comparing what acos uses for the baud rate
* against a table of known values to change it into an index [0..5]
*
:GOTBAUD              STX    BAUDRATE
                      TXA
                      ASL    A
                      TAX
                      LDA    BLOCKSIZES,X
                      STA    BLKLEN
                      LDA    BLOCKSIZES+1,X
                      STA    BLKLEN+1

*-------------------------------------------------
* ZSENDFDATA -- send file data

ZSENDFDATA
                      STZ    NOISE                                                          ;reset the noise counter

*
* check the number of consecutive bad blocks we've gotten -- if it's more
* than 0, halve the block size until it's down to 32 bytes.  If we can't do
* transfers with 32 byte packets, something is really goofy and we're going to
* have to abort the transfer... we keep halving the block sizes until we get a
* good packet to go through -- then we'll wait for 8 good ones to go through
* before upping the block size
*
                      LDA    CONSECBAD
                      BEQ    :READ8K

                      LSR    BLKLEN+1                                                       ;first get what the last packet size was and
                      ROR    BLKLEN                                                         ;halve it

                      LDA    BLKLEN+1                                                       ;then see if the packet is now 31 bytes or less
                      BNE    :NOt32
                      LDA    BLKLEN
                      CMP    #32
                      BGE    :NOt32

                      LDA    #32                                                            ;if, somehow the packet size gets really, really
                      STA    BLKLEN                                                         ;small, then make it default to 32 bytes
                      STZ    BLKLEN+1

:NOt32
*
* since this is the beginning of a series of blocks, try to read 8k from the
* source file
*
:READ8K               STZ    READPARMS+2                                                    ;where (ZBuffer)
                      LDA    #>ZBUFFER
                      STA    READPARMS+3

                      LDA    TXBUFFERSIZE                                                   ;howmuch (8k most times)
                      STA    READPARMS+4
                      LDA    TXBUFFERSIZE+1
                      STA    READPARMS+5

                      JSR    MLI
                      DB     $CA
                      DA     READPARMS
                      BCC    :GOODREAD

                      STZ    WHERE2START
                      STZ    WHERE2END
                      LDA    #>ZBUFFER                                                      ;set them equal to each other = zero
                      STA    WHERE2START+1                                                  ;length packet
                      STA    WHERE2END+1
                      JMP    SENDZCRCE                                                      ;aw nuts

:GOODREAD
                      LDA    READPARMS+6                                                    ;where's the end of the NNk buffer?
                      CLC                                                                   ;(watch out, it can be 0)
                      ADC    #<ZBUFFER
                      STA    WHERE2END
                      LDA    READPARMS+7
                      ADC    #>ZBUFFER
                      STA    WHERE2END+1

                      LDA    #<ZBUFFER
                      STA    WHERE2START
                      LDA    #>ZBUFFER
                      STA    WHERE2START+1

                      JSR    SENDZDATA

*-------------------------------------------------
* figure out the address and such for the next packet to be sent
* if we run to the end of the buffer, send a ZCRCW packet and wait for
* the response and then continue
*
* if we run out before the end of the buffer, send a ZCRCE packet and
* fall into the EOF seen routine

NEXTPACKET
                      JSR    MDMDCD
                      BCS    :DCDOK
                      LDA    #ABORT
                      RTS

:DCDOK                JSR    PRINTBYTES                                                     ;bytes which we have SENT, not "are sending"

*
* now check and see if we got 8 good blocks in a row -- if we did, double the
* block size, but only once throughout our transfer.  Also, pin the block
* size at 1k, never more than 1k because we'd break every known implementation
* of Zmodem derived from any of Chuck Forsberg's C code
*
* we'll only attempt this if there aren't any consecutive bad blocks pending
*
                      LDA    CONSECBAD
                      BNE    :CHECKBLKLEN
                      LDA    CONSECGOOD
                      CMP    #8
                      BLT    :CHECKBLKLEN

                      STZ    CONSECGOOD                                                     ;reset consecGOOD because it's the counter used to
;know when we are ready to double the block size

                      ASL    BLKLEN                                                         ;dubl the block sizes in case we're less than the
                      ROL    BLKLEN+1                                                       starting

                      LDA    BAUDRATE
                      ASL    A
                      TAX
                      LDA    BLKLEN+1                                                       ;see if the existing block size is -already-
                      CMP    DUBLBLOCKSIZES+1,X                                             ;as big as the dubl block size
                      BLT    :CHECKBLKLEN

                      LDA    DUBLBLOCKSIZES,X
                      STA    BLKLEN
                      LDA    DUBLBLOCKSIZES+1,X
                      STA    BLKLEN+1

*
* see if the block size is larger than the buffer that the receiver has -- if
* the receiver's buffer is smaller than our block size, make the block size
* the same size as the receiver's buffer
*
:CHECKBLKLEN
                      LDA    BLKLEN+1
                      CMP    TXBUFFERSIZE+1
                      BLT    :BLOCKOK
                      LDA    BLKLEN
                      CMP    TXBUFFERSIZE
                      BLT    :BLOCKOK

                      LDA    TXBUFFERSIZE+1
                      STA    BLKLEN+1
                      LDA    TXBUFFERSIZE
                      STA    BLKLEN
:BLOCKOK

*
* now, determine what kind of block to send -- if the block we are about
* to send is about to overflow the buffer, send a ZCRCW packet unless the
* end of the buffer and WHERE2END are different -- in that case, we've
* come to the EOF and we need to send a ZCRCE packet
*
                      LDA    WHERE2START                                                    ;add the length of the block that we are about to
                      CLC                                                                   ;send and see if it'll go beyond what we last read
                      ADC    BLKLEN                                                         ;into the buffer
                      TAX
                      LDA    WHERE2START+1
                      ADC    BLKLEN+1
                      CMP    WHERE2END+1
                      BLT    :NOTATEND                                                      ;if the packet about to be sent fall inside the
                      BNE    :SENDEND                                                       ;if not ==, then we must be way beyond the end
                      TXA                                                                   ;bytes that were read, then send either ZCRCG or
                      CMP    WHERE2END                                                      ;ZCRCW
                      BGE    :SENDEND                                                       ;but, if it's either even with the end or extends

:NOTATEND             LDA    CONSECBAD                                                      ;if we had any consecutive bad, then
                      BNE    SENDZCRCW                                                      ;the next packet is a normal size ZCRCW
                      LDA    NOISE                                                          ;if we got 3 pieces of line noise, drop down to
                      CMP    #4                                                             ;ZCRCW packets just in case
                      BGE    SENDZCRCW
                      JMP    SENDZCRCG                                                      ;send our next packet from the buffer

:SENDEND              LDA    ZBUFFEREND                                                     ;is where we're supposed to end within
                      CMP    WHERE2END                                                      ;the data buffer the same place as the
                      BNE    :NOTENDYET
                      LDA    ZBUFFEREND+1
                      CMP    WHERE2END+1
                      BEQ    SENDZCRCW                                                      ;amount which we just read? (ie, not
:NOTENDYET            JMP    SENDZCRCE                                                      ;eof?) yep... send endpacket

*-------------------------------------------------
* SENDZCRCW -- send a ZCRCW packet.  Wait for the ZACK after it
*              then go fill up the buffer again and keep sending

SENDZCRCW
                      LDA    BLKLEN+1                                                       ;see if the block we are about to send
                      CLC                                                                   ;will overflow the receiver
                      ADC    WHERE2START+1
                      CMP    ZBUFFEREND+1
                      BGE    :ENDOFBUFFER

                      JSR    BYTESINBLKLEN                                                  ;send BLKLEN bytes
                      BRA    :SEND

:ENDOFBUFFER                                                                                ;send this many characters for the last
                      JSR    BYTES2ENDOFBUFFER                                              ;packet of the buffer
:SEND                 JSR    FROMWHERE2START

                      LDX    #1                                                             ;can be interrupted
                      LDA    #ZCRCW                                                         ;send the data subpacket
                      JSR    ZSDATA

                      STZ    NOISE                                                          ;unconditionally reset the line noise counter

                      CMP    #ABORT
                      BEQ    :NUTS

                      JSR    GETINSYNC                                                      ;wait for the ZACK

                      CMP    #ZACK
                      BEQ    :GOTZACK
                      CMP    #ZRPOS
                      BEQ    :GOTZRPOS                                                      ;otherwise, it was something else bad
:NUTS                 RTS

*
* got ZACK, so we can continue to send stuff
*
:GOTZACK              JSR    ADDBYTES2TXPOS
                      JSR    ADDBUFFER2BYTECOUNT
                      JSR    ADDBYTES2BYTES

                      INC    CONSECGOOD                                                     ;just another good block
                      STZ    CONSECBAD                                                      ;none bad since we got a good packet

                      LDA    BLKLEN+1                                                       ;see if the block we are about to send
                      CLC                                                                   ;will overflow the receiver
                      ADC    WHERE2START+1
                      CMP    ZBUFFEREND+1
                      BLT    :SENTFROMBUFFER
                      JMP    ZSENDFDATA

:SENTFROMBUFFER
                      JSR    ADDBYTES2WHERE2START

                      JSR    SENDZDATA
                      JMP    NEXTPACKET

*
* if we got a ZRPOS, something screwed up, the receiver dumped his buffer
* to disk, so we can reset to send another bufferful
*
:GOTZRPOS             INC    CONSECBAD
                      STZ    CONSECGOOD                                                     ;none good since someone just toasted a packet
                      JMP    ZSENDFDATA                                                     ;so maybe ZRPOS, so go get back in sync

*-------------------------------------------------
* SENDZCRCG -- send a ZCRCG packet and then go get more stuff immediately
*              if we aren't delayed.  If we are, then if we get ZRPOS, go
*              back to ZSENDFDATA and try all over again...

SENDZCRCG
                      JSR    BYTESINBLKLEN
                      JSR    FROMWHERE2START

                      LDX    #1                                                             ;can be interrupted
                      LDA    #ZCRCG                                                         ;send the data subpacket
                      JSR    ZSDATA

                      CMP    #ABORT
                      BEQ    :NUTS
                      CMP    #INTERRUPT
                      BEQ    :SYNCLOOP

                      JSR    ADDBYTES2WHERE2START
                      JSR    ADDBYTES2TXPOS
                      JSR    ADDBYTES2BYTES

                      INC    CONSECGOOD                                                     ;good packet!  cowabunga, dude!
                                                                                            ;and that means no consec bad packets
                      JMP    NEXTPACKET

:SYNCLOOP             JSR    GETINSYNC

                      CMP    #TIMEOUT
                      BEQ    :NUTS
                      CMP    #ABORT
                      BEQ    :NUTS
                      CMP    #ERROR                                                         ;did they screw it up?
                      BEQ    :NUTS                                                          ;yep
                      CMP    #ZSKIP                                                         ;did they try to skip?
                      BEQ    :NUTS                                                          ;yep
                      CMP    #ZRINIT                                                        ;did something weird happen?
                      BEQ    :NUTS                                                          ;yep?

                      INC    CONSECBAD
                      STZ    CONSECGOOD
                      JMP    ZSENDFDATA                                                     ;gotta be ZRPOS or ZACK

:NUTS                 RTS                                                                   ;take our result from GETINSYNC and return

*-------------------------------------------------
* hey! we're done! send the last data packet and get outta there!
*
* fall through and watch to see if the ZCRCE packet was ok.  If it wasn't,
* it'll be responded to by ZRPOS, in which case we go there and read some
* more and then maybe end up here yet again...

SENDZCRCE
                      JSR    BYTES2ENDOFBUFFER
                      JSR    FROMWHERE2START                                                ;send the data from WHERE2START

                      LDX    #1                                                             ;can be interrupted
                      LDA    #ZCRCE                                                         ;send the data subpacket
                      JSR    ZSDATA

                      CMP    #ABORT
                      BEQ    :DONE
                      CMP    #INTERRUPT
                      BEQ    :SAYWHATEOF

*
* awww shucks, we hit EOF or have the last section to send
*
:ATEOF                LDA    EOFPARMS+2                                                     ;our EOF
                      STA    ZP0
                      LDA    EOFPARMS+3
                      STA    ZP1
                      LDA    EOFPARMS+4
                      STA    ZP2
                      STZ    ZP3

                      LDA    #ZEOF                                                          ;send the ZEOF notification
                      STA    FRAMETYPE
                      JSR    ZSENDBHEADER

:SAYWHATEOF
                      JSR    GETINSYNC                                                      ;hope they say something nice

                      CMP    #20
                      BLT    :HEADER

*
* wasn't anything else, something invalid
*
:RETURN               CMP    #ABORT
                      BEQ    :DONE
                      CMP    #TIMEOUT
                      BEQ    :DONE

                      LDA    #ERROR
:DONE                 RTS

:HEADER               ASL    A
                      TAX
                      JMP    (:ADDR,X)

:ADDR                 DA     :RETURN                                                        ;ZRQINIT    - 0
                      DA     :GOTZRINIT                                                     ;ZRINIT     - 1
                      DA     :RETURN                                                        ;ZSINIT     - 2
                      DA     :ATEOF                                                         ;ZACK       - 3
                      DA     :RETURN                                                        ;ZFILE      - 4
                      DA     :GOTZSKIP                                                      ;ZSKIP      - 5
                      DA     :RETURN                                                        ;ZNAK       - 6
                      DA     :RETURN                                                        ;ZCAN       - 7
                      DA     :RETURN                                                        ;ZFIN       - 8
                      DA     :GOTZRPOS                                                      ;ZRPOS      - 9
                      DA     :RETURN                                                        ;ZDATA      - 10
                      DA     :RETURN                                                        ;ZEOF       - 11
                      DA     :RETURN                                                        ;ZFERR      - 12
                      DA     :RETURN                                                        ;ZCRC       - 13
                      DA     :RETURN                                                        ;ZCHALLENGE - 14
                      DA     :RETURN                                                        ;ZCOMPL     - 15
                      DA     :GOTABORT                                                      ;ZCAN       - 16
                      DA     :RETURN                                                        ;ZFREECNT   - 17
                      DA     :RETURN                                                        ;ZCOMMAND   - 18
                      DA     :RETURN                                                        ;ZSTDERR    - 19

*
* someone aborted someplace
*
:GOTABORT
                      LDA    #ABORT
                      RTS

*
* got ZRPOS -- in other words, something screwed up the last packet
*              (the ZCRCE packet)
*              so seek to that position and try reading another chunk
*
:GOTZRPOS
                      JSR    GETTXPOSITION                                                  ;munge position

                      LDA    TXPOSITION                                                     ;seek that position
                      STA    MARKPARMS+2
                      LDA    TXPOSITION+1
                      STA    MARKPARMS+3
                      LDA    TXPOSITION+2
                      STA    MARKPARMS+4

                      JSR    MLI
                      DB     $CE
                      DA     MARKPARMS
                      BCC    :GOODSEEK

                      LDA    #ERROR
                      RTS

:GOODSEEK                                                                                   ;fall through to ZSENDFDATA
                      JMP    ZSENDFDATA                                                     ;go read another hunk

*
* got ZRINIT
*
:GOTZRINIT                                                                                  ;go back and say: we got another ZRINIT
                      JSR    ADDBUFFER2BYTECOUNT
                      JSR    ADDBYTES2TXPOS
                      JSR    ADDBYTES2BYTES
                      JSR    PRINTBYTES                                                     ;bytes which we have SENT, not "are sending"

                      LDA    #ZRINIT
                      RTS

*
* got ZSKIP
*
:GOTZSKIP                                                                                   ; we already closed, so just return
                      LDA    #ZSKIP
                      RTS

*-------------------------------------------------
* ADDBYTES2WHERE2START -- add BYTES2SEND to WHERE2START

ADDBYTES2WHERE2START
                      LDA    WHERE2START
                      CLC
                      ADC    BYTES2SEND
                      STA    WHERE2START                                                    ;next time start here
                      LDA    WHERE2START+1
                      ADC    BYTES2SEND+1
                      STA    WHERE2START+1
                      RTS

*-------------------------------------------------
* BYTESINBLKLEN -- send BLKLEN bytes (put it in BYTES2SEND)

BYTESINBLKLEN
                      LDA    BLKLEN
                      STA    BYTES2SEND
                      LDA    BLKLEN+1
                      STA    BYTES2SEND+1
                      RTS

*-------------------------------------------------
* BYTES2ENDOFBUFFER

BYTES2ENDOFBUFFER
                      LDA    WHERE2END                                                      ;send everything between us and the end
                      SEC                                                                   ;of the buffer
                      SBC    WHERE2START
                      STA    BYTES2SEND
                      LDA    WHERE2END+1
                      SBC    WHERE2START+1
                      STA    BYTES2SEND+1
                      RTS

*-------------------------------------------------
* FROMWHERE2START -- ZPTR points to WHERE2START's address

FROMWHERE2START
                      LDA    WHERE2START                                                    ;where data is
                      STA    ZPTR
                      LDA    WHERE2START+1
                      STA    ZPTR+1
                      RTS

*-------------------------------------------------
* ADDBUFFER2BYTECOUNT -- add the number of bytes that were in the
*                        buffer to the amount that we've already sent
*                        this count is only updated when we get a ZACK
*                        from the other side for a ZCRCW packet and when
*                        we sent the ZCRCE packet and got a ZRINIT back

ADDBUFFER2BYTECOUNT
                      LDA    WHERE2END
                      SEC
                      SBC    #<ZBUFFER
                      STA    BYTESINBUFFER
                      LDA    WHERE2END+1
                      SBC    #>ZBUFFER
                      STA    BYTESINBUFFER+1

                      LDA    BYTESINBUFFER
                      CLC                                                                   ;transmitted to the other side
                      ADC    BYTECOUNT
                      STA    BYTECOUNT
                      LDA    BYTESINBUFFER+1
                      ADC    BYTECOUNT+1
                      STA    BYTECOUNT+1
                      LDA    #0
                      ADC    BYTECOUNT+2
                      STA    BYTECOUNT+2
                      RTS

BYTESINBUFFER         DW     0

*-------------------------------------------------
* ADDBYTES2TXPOS -- add BYTES2SEND to TxPosition

ADDBYTES2TXPOS
                      LDA    BYTES2SEND
                      CLC
                      ADC    TXPOSITION
                      STA    TXPOSITION
                      LDA    BYTES2SEND+1
                      ADC    TXPOSITION+1
                      STA    TXPOSITION+1
                      LDA    #0
                      ADC    TXPOSITION+2
                      STA    TXPOSITION+2
                      RTS

*-------------------------------------------------
* ADDBYTES2BYTES -- add BYTES2SEND to Bytes (sent)

ADDBYTES2BYTES
                      LDA    BYTES2SEND
                      CLC
                      ADC    BYTES
                      STA    BYTES
                      LDA    BYTES2SEND+1
                      ADC    BYTES+1
                      STA    BYTES+1
                      LDA    #0
                      ADC    BYTES+2
                      STA    BYTES+2
                      RTS

*-------------------------------------------------
* send a complete ZDATA frame

SENDZDATA
                      LDA    TXPOSITION
                      STA    ZP0
                      LDA    TXPOSITION+1
                      STA    ZP1
                      LDA    TXPOSITION+2
                      STA    ZP2
                      LDA    TXPOSITION+3
                      STA    ZP3

                      LDA    #ZDATA                                                         ;send the ZDATA frame
                      STA    FRAMETYPE
                      JMP    ZSENDBHEADER

*-------------------------------------------------
* GETINSYNC -- sync up with the receiver (hey, we're sending, we can do that)

GETINSYNC
                      STZ    ERRORS
SYNCLOOP              JSR    ZGETHEADER

gotInSync             CMP    #20                                                            ;if it's not a valid packet, then
                      BLT    :HEADER                                                        ;something really screwed it up, ZNAK

:DEFAULT              CMP    #ABORT                                                         ;it and have them resend it (just wait
                      BEQ    :GOTABORT
*        CMP   #TIMEOUT
*        BEQ   :GOTTIMEOUT

                      LDA    #ZNAK                                                          ;until they do)
                      STA    FRAMETYPE
                      JSR    ZSENDBHEADER

                      INC    ERRORS
                      LDA    ERRORS
                      CMP    #6
                      BLT    SYNCLOOP

:GOTERROR             LDA    #ERROR
                      RTS

:HEADER               ASL    A
                      TAX
                      JMP    (:ADDR,X)

:ADDR                 DA     :DEFAULT                                                       ;ZRQINIT    - 0
                      DA     :GOTZRINIT                                                     ;ZRINIT     - 1
                      DA     :DEFAULT                                                       ;ZSINIT     - 2
                      DA     :GOTZACK                                                       ;ZACK       - 3
                      DA     :DEFAULT                                                       ;ZFILE      - 4
                      DA     :GOTZSKIP                                                      ;ZSKIP      - 5
                      DA     :DEFAULT                                                       ;ZNAK       - 6
                      DA     :GOTABORT                                                      ;ZABORT     - 7
                      DA     :GOTERROR                                                      ;ZFIN       - 8
                      DA     :GOTZRPOS                                                      ;ZRPOS      - 9
                      DA     :DEFAULT                                                       ;ZDATA      - 10
                      DA     :DEFAULT                                                       ;ZEOF       - 11
                      DA     :DEFAULT                                                       ;ZFERR      - 12
                      DA     :DEFAULT                                                       ;ZCRC       - 13
                      DA     :DEFAULT                                                       ;ZCHALLENGE - 14
                      DA     :DEFAULT                                                       ;ZCOMPL     - 15
                      DA     :GOTABORT                                                      ;ZCAN       - 16
                      DA     :DEFAULT                                                       ;ZFREECNT   - 17
                      DA     :DEFAULT                                                       ;ZCOMMAND   - 18
                      DA     :DEFAULT                                                       ;ZSTDERR    - 19

*
* aborted by user
*
:GOTABORT
                      LDA    #ABORT
                      RTS

*
* got a ZRINIT packet
*
:GOTZRINIT
                      LDA    #ZRINIT
                      RTS

*
* got a ZSKIP packet
*
:GOTZSKIP
                      LDA    #ZSKIP
                      RTS

*
* got a ZACK packet
*
:GOTZACK              LDA    #ZACK
                      RTS

*
* got a ZRPOS packet
*
:GOTZRPOS
                      JSR    GETTXPOSITION                                                  ;munge position

                      LDA    TXPOSITION                                                     ;seek that position
                      STA    MARKPARMS+2
                      LDA    TXPOSITION+1
                      STA    MARKPARMS+3
                      LDA    TXPOSITION+2
                      STA    MARKPARMS+4

                      JSR    MLI
                      DB     $CE
                      DA     MARKPARMS
                      BCS    :POSERROR

                      LDA    #ZRPOS
                      RTS

:POSERROR
                      LDA    #ERROR
                      JMP    :DEFAULT

*-------------------------------------------------
* GETTXPOSITION-- munge a longword from ZP0..ZP3 into TxPosition

GETTXPOSITION
                      LDA    ZP0
                      STA    TXPOSITION
                      LDA    ZP1
                      STA    TXPOSITION+1
                      LDA    ZP2
                      STA    TXPOSITION+2
                      LDA    ZP3
                      STA    TXPOSITION+3
                      RTS

*-------------------------------------------------
* ZSDATA -- send a data subpacket and return a result code
*
* inputs    (A) = frameend (ZCRCW, ZCRCQ, ZCRCE, ZCRCG)
*           (X) = boolean, packet can be interrupted by an incoming frame
*           BYTES2SEND = number of bytes to send in this subpacket
*           zptr = where to start relative from the beginning of our buffer
*
* outputs = none

ZSDATA                STA    FRAMEEND                                                       ;this is done for all ZSDATA routines!
                      STA    ZSINTERRUPT

                      LDA    USEFC32
                      BEQ    :NOFC32
                      JMP    ZSDATA32

:NOFC32               STZ    CRC                                                            ;init our crc
                      STZ    CRC+1

                      STZ    ZCOUNT
                      STZ    ZCOUNT+1

                      LDA    BYTES2SEND
                      BNE    :LOOP
                      LDA    BYTES2SEND+1                                                   ;is it a zero-length packet?
                      BNE    :LOOP
                      JMP    SENDSUBPACKETEND                                               ;if it is, then just send the end

*
* every time we send a character, we have to poll the hardware to see if
* a char has arrived because this driver isn't written for a system that
* has an interrupt buffer -- well, maybe not.
*
:LOOP                 LDA    ZSINTERRUPT
                      BEQ    :IGNORE

                      JSR    MDMIN                                                          ;check for the first of any ZPAD ('*') characters
                      BCC    :IGNORE
                      CMP    #ZPAD
                      BEQ    :INTERRUPT
                      CMP    #can
                      BNE    :NOISE                                                         ;or, also check for any CAN (ZDLE) characters

                      DO     BUILDFLUSH
                      JSR    SENDSUBPACKETEND
                      FIN

:INTERRUPT            LDA    #INTERRUPT
                      RTS

*
* nobody interrupted us, or if they did, they fed us line noise, so continue
* anyway
*
:NOISE                INC    NOISE

:IGNORE               LDA    (ZPTR)                                                         ;get the byte from the buffer
                      JSR    CRCBYTE                                                        ;put it into the crc
                      JSR    ZPUTCHAR                                                       ;send it with ZDLE encoding

                      INC    ZPTR
                      BNE    :NC1
                      INC    ZPTR+1
:NC1                  INC    ZCOUNT
                      BNE    :NC2
                      INC    ZCOUNT+1

:NC2                  LDA    BYTES2SEND
                      CMP    ZCOUNT
                      BNE    :GOLOOP
                      LDA    BYTES2SEND+1
                      CMP    ZCOUNT+1
                      BEQ    SENDSUBPACKETEND
:GOLOOP               JMP    :LOOP

*
* send the ZDLE, the frameEnd, the crc for the frame including the
* frameEnd, and possibly an XON character to unjam networks that a
* spurious XOFF may have nuked
*
SENDSUBPACKETEND
                      LDA    #ZDLE                                                          ;ZDLE encode the frameEnd
                      JSR    MDMOUT
                      LDA    FRAMEEND
                      JSR    MDMOUT

                      LDA    FRAMEEND                                                       ;crc includes frameEnd
                      JSR    CRCBYTE

                      LDA    CRC+1
                      JSR    ZPUTCHAR
                      LDA    CRC
                      JSR    ZPUTCHAR

                      LDA    FRAMEEND
                      CMP    #ZCRCW
                      BNE    :DONE

                      LDA    #xon
                      JSR    MDMOUT
:DONE
                      DO     BUILDDEBUG
                      LDY    BYTES2SEND
                      LDX    BYTES2SEND+1
                      LDA    #0
                      JSR    PRINTSUB                                                       ;print the subpacket
                      FIN

                      LDA    #NO_ERROR
                      RTS

*-------------------------------------------------
* ZSDATA32 -- send a data subpacket and return a result code
*
* inputs  = (A) = frameend (ZCRCW, ZCRCQ, ZCRCE, ZCRCG)
*           BYTES2SEND = number of bytes to send in this subpacket
*           zptr = where to start relative from the beginning of our buffer
*
* note: for CRC-32, frameend is set by ZSDATA before it arrives here
*
* outputs = none

ZSDATA32              LDA    #$FF                                                           ;init the crc32
                      STA    CRC32
                      STA    CRC32+1
                      STA    CRC32+2
                      STA    CRC32+3

                      STZ    ZCOUNT
                      STZ    ZCOUNT+1

                      LDA    BYTES2SEND
                      BNE    :LOOP
                      LDA    BYTES2SEND+1                                                   ;is it a zero-length packet?
                      BNE    :LOOP
                      JMP    SENDSUBEND32                                                   ;if it is, then just send the end

*
* every time we send a character, we have to poll the hardware to see if
* a char has arrived because this driver isn't written for a system that
* has an interrupt buffer
*
:LOOP                 LDA    ZSINTERRUPT
                      BEQ    :IGNORE

                      JSR    MDMIN                                                          ;check for 'andy' being the attention string
                      BCC    :IGNORE
                      CMP    #ZPAD                                                          ;-only- interrupt if it's *ZDLE or **ZDLE or
                      BEQ    :INTERRUPT                                                     ;the first of several ZCANs, or 'andy' from the
                      CMP    #can
                      BNE    :NOISE

                      DO     BUILDFLUSH
                      JSR    SENDSUBEND32                                                   ;used to send this to complete a frame
                      FIN

:INTERRUPT            LDA    #INTERRUPT
                      RTS

*
* nobody interrupted us, or if they did, they fed us line noise, so continue
* anyway
*
:NOISE                INC    NOISE

:IGNORE               LDA    (ZPTR)                                                         ;get the byte from the buffer
                      JSR    UPDATECRC32                                                    ;put it into the crc
                      JSR    ZPUTCHAR                                                       ;send it with ZDLE encoding

                      INC    ZPTR
                      BNE    :NC1
                      INC    ZPTR+1
:NC1                  INC    ZCOUNT
                      BNE    :NC2
                      INC    ZCOUNT+1

:NC2                  LDA    BYTES2SEND
                      CMP    ZCOUNT
                      BNE    :GOLOOP
                      LDA    BYTES2SEND+1
                      CMP    ZCOUNT+1
                      BEQ    SENDSUBEND32
:GOLOOP               JMP    :LOOP

*
* send the ZDLE, the frameEnd, the crc for the frame including the
* frameEnd, and possibly an XON character to unjam networks that a
* spurious XOFF may have nuked
*
SENDSUBEND32
                      LDA    #ZDLE                                                          ;ZDLE encode the frameEnd
                      JSR    MDMOUT
                      LDA    FRAMEEND
                      JSR    MDMOUT

                      LDA    FRAMEEND                                                       ;crc includes frameEnd
                      JSR    UPDATECRC32

                      JSR    INVERTCRC32

                      LDA    CRC32
                      JSR    ZPUTCHAR
                      LDA    CRC32+1
                      JSR    ZPUTCHAR
                      LDA    CRC32+2
                      JSR    ZPUTCHAR
                      LDA    CRC32+3
                      JSR    ZPUTCHAR

                      LDA    FRAMEEND
                      CMP    #ZCRCW
                      BNE    :DONE

                      LDA    #xon
                      JSR    MDMOUT

:DONE
                      DO     BUILDDEBUG
                      LDY    BYTES2SEND
                      LDX    BYTES2SEND+1
                      LDA    #2
                      JSR    PRINTSUB                                                       ;print the subpacket
                      FIN

                      LDA    #NO_ERROR
                      RTS

*-------------------------------------------------
* PRINTSZSTAT -- print the sender's status line

                      DO     NOTBUILDDEBUG
PRINTSZSTAT
                      JSR    CLEARLASTLINE

                      LDX    #<SZSTATLINE
                      LDA    #>SZSTATLINE
                      JSR    PRINTCSTRING

                      LDX    #<PATHNAME
                      LDA    #>PATHNAME
                      JMP    PRINTPSTRING

*-------------------------------------------------
* CLEARLASTLINE -- get rid of anything on the last line

CLEARLASTLINE
                      LDY    #0
                      STY    HTAB
:LOOP                 LDA    #" "
                      JSR    LOCPRINT
                      INY
                      CPY    #79
                      BLT    :LOOP
                      STZ    HTAB
                      RTS

SZSTATLINE            ASC    'Sending byte   #         of         file '00
                      FIN

*-------------------------------------------------
* append the common ZMODEM routines onto the end of SZ

WAITFOR               DW     120*11                                                         ;11 seconds, 2 seconds longer than RZ

ZSINTERRUPT           DB     0                                                              ;can this subpacket be interrupted?

GFIPARMS              DB     10
                      DA     PATHNAME
                      DB     0
                      DB     0                                                              ;filetype
                      DW     0                                                              ;auxtype
                      DB     0                                                              ;storage_type
                      DW     0
                      DW     0
                      DW     0
                      DW     0
                      DW     0

EOFPARMS              DB     2
                      DB     0
                      DS     3

READPARMS
                      DB     4
                      DB     0
                      DA     ZBUFFER
                      DW     $1000
                      DW     0

                      PUT    LONG2DEC                                                       ;always
                      PUT    ZMODEM                                                         ;always
                      PUT    ZMODEM2                                                        ;always

                      LST    OFF
                      DO     SAVEOBJ
                      SAV    SZ
                      FIN
                      DO     LISTSYM
                      LST
                      FIN

