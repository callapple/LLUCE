*
* This source code is hereby dedicated to the public domain.
*                                 -- Andy Nicholas, 8/12/91
*
* Try to keep in mind that this source pre-dates the other 65c02 source
* by at least a whole year, and as a result doesn't do some things
* correctly like check for buffer overruns (which is extremely important
* if you get munged data and after trying to expand it find out that it's
* larger than 1k). -- andy
*
*
*
* zrdata32r -- get a data subpacket and return a result code
*              but in this case, use a 32-bit CRC and RLE
*
* outputs = (A) = result code
*...................................................................

ZRDATA32R     LDA   #$FFFF        ;init CRC32 to $FFFFFFFF
              STA   CRC32
              STA   CRC32+2

              STZ   RXBYTES
              STZ   RXBYTES+2

              STZ   RUN
              STZ   PHYSICAL      ;how many PHYSICAL chars we get?

              LDY   #0
:LOOP         JSR   ZGETCHAR
              AND   #$FF
              INC   PHYSICAL

              LDX   ESCAPED
              BEQ   :NOTESCAPED

              CMP   #ZCRCW
              BEQ   :GOOUT
              CMP   #ZCRCQ
              BEQ   :GOOUT
              CMP   #ZCRCG
              BEQ   :GOOUT
              CMP   #ZCRCE
              BNE   :NOTESCAPED
:GOOUT        BRL   :OUT

:NOTESCAPED
              JSR   UPDATECRC32

              LDX   RUN           ;is it running?
              BEQ   :NORUN

              CPX   #1            ;first or second charcater of the RLE?
              BEQ   COUNT

              LDX   D             ;stuff d of c characters into the buffer
:CLOOP        STA   [ZPTR],Y
              INY
              DEX
              BNE   :CLOOP

              STZ   RUN
              BRA   :LOOP

*
* we got the ZRESC, so now get d
*
:COUNT        CMP   #$20
              BGE   :COUNTVALID

              BRK                 ;something really screwed up

:COUNTVALID
              CMP   #$40
              BEQ   :PUTZRESC
              BLT   :SPACES

*
* must be valid count of d of c characters, so set it up properly
*
              SEC
              SBC   #$40
              STA   D

              INC   RUN           ;run now = 2
              BRL   :LOOP

*
* got a ZRESC in the incoming data stream, just stuffit
*
:PUTZRESC     LDA   #ZRESC
              STA   [ZPTR],Y
              INY

              STZ   RUN           ;reset run
              BRL   :LOOP

*
* d indicated that we are to produce (d-29) spaces
*
:SPACES       SEC
              SBC   #29
              TAX

              LDA   #' '          ;stuff that many spaces in the buffer
:SPACELOOP    STA   [ZPTR],Y
              INY
              DEX
              BNE   :SPACELOOP

              STZ   RUN           ;reset run
              BRL   :LOOP

*
* no run activated, so check to see if we need to activate one
*
:NORUN        CMP   #ZRESC
              BNE   :NOZRESC

              LDA   #1
              STA   RUN
              BRL   :LOOP

:NOZRESC      STA   [ZPTR],Y
              INY
              BRL   :LOOP

*
* hey! we're done! chewy, get us outta here...
*
:OUT          STA   FRAMEEND

              JSR   UPDATECRC32   ;add the frameend into the CRC

              JSR   ZGETCHAR
              AND   #$00FF
              STA   FRAMECRC32
              JSR   ZGETCHAR
              XBA
              AND   #$FF00
              ORA   FRAMECRC32
              STA   FRAMECRC32
              JSR   ZGETCHAR
              AND   #$00FF
              STA   FRAMECRC32+2
              JSR   ZGETCHAR
              XBA
              AND   #$FF00
              ORA   FRAMECRC32+2
              STA   FRAMECRC32+2

              JSR   INVERTCRC32

              LDA   CRC32
              CMP   FRAMECRC32
              BNE   :BADPACKET
              LDA   CRC32+2
              CMP   FRAMECRC32+2
              BEQ   :GOODPACKET

:BADPACKET
              LDA   #3
              JSR   PRINTSUB32    ;print the subpacket

              LDA   #ERROR        ;tell zfile to try again
              RTS

:GOODPACKET                       ;hey! it's good!
              STY   RXBYTES       ;yes, we could get a 0-length packet!

              LDY   PHYSICAL      ;how many characters did we REALLY get?
              LDA   #3
              JSR   PRINTSUB32    ;print the subpacket

              LDA   FRAMEEND      ;tell them the kind of frame we got
              RTS

* zsdata32r -- send a data subpacket and return a result code
*              use 32-bit CRC and RLE
*
* inputs = (A) = frameend (ZCRCW, ZCRCQ, ZCRCE, ZCRCG)
*           (X) = number of bytes to send in this subpacket
*           (Y) = where to start relative from the beginning of our buffer
*
* outputs = none
*...................................................................

ZSDATA32R
              STA   FRAMEEND
              STX   BYTES2SEND

              TYA
              STA   ZPTR
              LDA   ZBUFFER+2     ;don't anything since it won't
              STA   ZPTR+2        ;cross a bank boundary

              LDA   #$FFFF
              STA   CRC32
              STA   CRC32+2

              STZ   PHYSICAL

              CPX   #0            ;is it a zero length packet?
              BNE   :NOT0
              BRL   :NUTS         ;if it is, then just send the frameend

:NOT0         LDY   #0
:LOOP         LDA   [ZPTR],Y      ;get the byte from the buffer
              AND   #$FF

*
* is it the ZRESC character? if so, then send it and $40 as the ZRESC trigger
*
              CMP   #ZRESC
              BNE   :NOTZRESC

              INC   PHYSICAL
              INC   PHYSICAL

              JSR   UPDATECRC32   ;put it into the CRC
              JSR   ZPUTCHAR

              LDA   #$40
              JSR   UPDATECRC32   ;put it into the CRC
              JSR   ZPUTCHAR
              INY
              CPY   BYTES2SEND
              BLT   :LOOP
              BRL   :NUTS

*
* not the ZRESC character, maybe it's whitespace?
*
:NOTZRESC
              CMP   #$20
              BNE   :NOTSPACES

              STY   STARTRUN
              STA   RUN
:SPACELOOP    INY                 ;get the next character forward
              LDA   [ZPTR],Y      ;(or not)
              AND   #$FF
              CMP   RUN
              BNE   :SPACEIT      ;if they don't match, do the run
              TYA
              SEC
              SBC   STARTRUN
              CMP   #28           ;did we RLE 28 (034) characters yet?
              BGE   :BIGRUN       ;yes, it's a large run of characters
              CPY   BYTES2SEND
              BLT   :SPACELOOP

*
* the run of spaces terminated (or didn't begin at all), so see what we got
*
:SPACEIT      STY   ENDRUN
              DEY                 ;1 less because we went beyond the run
              TYA
              SEC
              SBC   STARTRUN
              CMP   #3            ;got less than 3 characters ahead, so
              BGE   :GOTSPACERUN
              BRL   :GOTNONE      ;not enough characters to run

:GOTSPACERUN
              PHA
              LDA   #ZRESC
              JSR   UPDATECRC32   ;put it into the CRC
              JSR   ZPUTCHAR
              PLA

              CLC
              ADC   #$1E
              JSR   UPDATECRC32   ;put it into the CRC
              JSR   ZPUTCHAR

              INC   PHYSICAL
              INC   PHYSICAL

              LDY   ENDRUN
              CPY   BYTES2SEND
              BGE   :NUTS2
              BRL   :LOOP
:NUTS2        BRL   :NUTS

*
* we got a lot of spaces (>34) so just do the normal RLE on that bunch
*
:BIGRUN       LDY   STARTRUN      ;start it from here all over again
              LDA   RUN

*
* the current character wasn't whitespace, so see if we can RLE it anyhow
*
:NOTSPACES
              STY   STARTRUN
              STA   RUN           ;run is our character that's running
:RUNLOOP      INY                 ;get the next character forward
              LDA   [ZPTR],Y      ;(or not)
              AND   #$FF
              CMP   RUN
              BNE   :RUNIT        ;if they don't match, do the run
              TYA
              SEC
              SBC   STARTRUN
              CMP   #125          ;did we RLE 126 characters yet?
              BGE   :RUNIT
              CPY   BYTES2SEND
              BLT   :RUNLOOP

*
* the run terminated (or didn't begin at all), so see what we got
*
:RUNIT        STY   ENDRUN
              DEY                 ;1 less because we went beyond the run
              TYA
              SEC
              SBC   STARTRUN
              CMP   #4            ;got less than 4 characters ahead, so
              BLT   :GOTNONE      ;not enough characters to run

              PHA
              LDA   #ZRESC
              JSR   UPDATECRC32   ;put it into the CRC
              JSR   ZPUTCHAR
              PLA

              CLC
              ADC   #$41
              JSR   UPDATECRC32   ;put it into the CRC
              JSR   ZPUTCHAR

              LDA   RUN
              JSR   UPDATECRC32   ;put it into the CRC
              JSR   ZPUTCHAR

              INC   PHYSICAL
              INC   PHYSICAL
              INC   PHYSICAL

              LDY   ENDRUN
              CPY   BYTES2SEND
              BGE   :NUTS
              BRL   :LOOP

*
* the run didn't work, so just output this character
*
:GOTNONE      LDY   STARTRUN
              LDA   RUN           ;send whichever character we started
              JSR   UPDATECRC32   ;put it into the CRC
              JSR   ZPUTCHAR      ;send it with ZDLE encoding

              INC   PHYSICAL

              INY
              CPY   BYTES2SEND
              BGE   :NUTS
              BRL   :LOOP

*
* hey! we're done!
*
:NUTS         LDA   #ZDLE         ;ZDLE encode the FRAMEEND
              JSL   OUT_PORT
              LDA   FRAMEEND
              JSL   OUT_PORT

              LDA   FRAMEEND      ;CRC includes FRAMEEND
              JSR   UPDATECRC32

              JSR   INVERTCRC32

              LDA   CRC32
              JSR   ZPUTCHAR
              LDA   CRC32+1
              JSR   ZPUTCHAR
              LDA   CRC32+2
              JSR   ZPUTCHAR
              LDA   CRC32+3
              JSR   ZPUTCHAR

              LDA   FRAMEEND
              CMP   #ZCRCW
              BNE   :DONE

              LDA   #xon
              JSL   OUT_PORT

:DONE         LDY   PHYSICAL
              LDA   #2
              JSR   PRINTSUB32    ;print the subpacket

              RTS

