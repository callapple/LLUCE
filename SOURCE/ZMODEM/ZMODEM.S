*
* July 15, 1991
*
* This file is hereby dedicated to the public domain.
*                                 -- Andrew Nicholas
*
                 LST   RTN

*-------------------------------------------------
* ZGETHEADER -- get header function (will recognize binary or hex headers)

ZGETHEADER
                 LDA   #0
:GOTZPAD         STA   LASTC
                 STZ   CANCOUNT

:ZGETLOOP
                 JSR   GETC             ;get a character -- at this point, it could be
                 BCS   :NOABORT         ;something spurious, a bunch of CAN's (ZDLE's), or
                 RTS                    ;ZPADs preceding a frame, or the ZDLE for the start
                                        ;of a frame

*
* Or, here's a bit of trivia -- the GS's serial port can't keep up with 19.2Kb,
* or even 9600 baud... so, it's possible to "miss" the ZDLE signifying the end
* of a subpacket which leaves us reading the middle of a stream of the next
* subpacket.  2 subpackets thus become concatenated.  This is not good.
*
* A partial solution is to have the ZGETHEADER routines understand that it
* might be called when they'll be reading the middle of a data stream which
* contains a whole lot of bytes which don't particularly mean much.
*
* Also, we need to ensure that the character which preceded the ZDLE is a
* ZPAD character because if we start to read the middle of a packet, we
* might be reading ZDLE sequences where a character is being escaped, but
* in no way means that a new packet is beginning...
*

:NOABORT         CMP   #ZPAD            ;eat all ZPADs coming through
                 BEQ   :GOTZPAD         ;ok to reset count of ZDLE's if we got ZPAD
                 CMP   #ZDLE            ;the number of ZDLE's (CANs) in a row
                 BNE   :NEXTC

                 INC   CANCOUNT
                 LDA   CANCOUNT
                 CMP   #5
                 BLT   :ZGETLOOP

                 LDA   #ABORT
                 RTS

:NEXTC           LDX   CANCOUNT         ;if we have a spurious character and we haven't yet
                 BEQ   ZGETHEADER       ;seen a ZDLE, then it can't be a frame

                 LDX   LASTC            ;was the character before the ZDLE a ZPAD?
                 CPX   #ZPAD            ;it -must- be a ZPAD, so if it wasn't, something
                 BNE   ZGETHEADER       ;bogus is going on, try getting a packet again

                 STA   FRAMEKIND        ;what kind of packet was it?

                 CMP   #ZBIN            ;is it a ZBIN packet?
                 BNE   :NOTZBIN
                 JMP   :GOTZZBIN

:NOTZBIN         CMP   #ZBIN32          ;is it a ZBIN32 packet?
                 BNE   :NOTZBIN32
                 JMP   :GOTZZBIN32

:NOTZBIN32
                 CMP   #ZHEX            ;is it a ZHEX packet?
                 BNE   :NOTZHEX
                 JMP   :GOTZZHEX

:NOTZHEX         JMP   ZGETHEADER       ;then look for another packet or time out trying

*:NOTZHEX LDA  #ERROR     ;before skanky packet protection code was added, this
*        RTS              ;used to look like this...

*
* got a ZBIN header, so read the next 4 bytes and CRC them
*
:GOTZZBIN        STZ   CRC
                 STZ   CRC+1

                 JSR   ZGETCHAR         ;get frametype
                 STA   FRAMETYPE
                 JSR   CRCBYTE

                 JSR   ZGETCHAR         ;get position/flag bytes
                 STA   ZP0
                 JSR   CRCBYTE

                 JSR   ZGETCHAR
                 STA   ZP1
                 JSR   CRCBYTE

                 JSR   ZGETCHAR
                 STA   ZP2
                 JSR   CRCBYTE

                 JSR   ZGETCHAR
                 STA   ZP3
                 JSR   CRCBYTE

                 JSR   ZGETCHAR
                 STA   FRAMECRC+1
                 JSR   ZGETCHAR         ;get the CRC characters
                 STA   FRAMECRC

                 CMP   CRC
                 BNE   :BADBINFRAME
                 LDA   FRAMECRC+1
                 CMP   CRC+1
                 BEQ   :GOODBINFRAME

:BADBINFRAME
                 DO    BUILDDEBUG
                 LDA   #3               ;get packet called it
                 JSR   PRINTPACKET      ;*** temporary ***
                 FIN

                 LDA   #ERROR           ;something is really messed up
                 RTS

:GOODBINFRAME
                 DO    BUILDDEBUG
                 LDA   #3
                 JSR   PRINTPACKET      ;*** temporary ***
                 FIN

                 LDA   FRAMETYPE        ;we were good, return the frame type
                 RTS

*
* got a ZHEX header, so read the next 4 (hex) bytes and CRC them
*
:GOTZZHEX        STZ   CRC
                 STZ   CRC+1

                 JSR   ZGETHEX          ;get hex frametype byte
                 STA   FRAMETYPE
                 JSR   CRCBYTE

                 JSR   ZGETHEX          ;get position/flag bytes
                 STA   ZP0
                 JSR   CRCBYTE

                 JSR   ZGETHEX
                 STA   ZP1
                 JSR   CRCBYTE

                 JSR   ZGETHEX
                 STA   ZP2
                 JSR   CRCBYTE

                 JSR   ZGETHEX
                 STA   ZP3
                 JSR   CRCBYTE

                 JSR   ZGETHEX
                 STA   FRAMECRC+1
                 JSR   ZGETHEX          ;get our hex encoded CRC's.. ick
                 STA   FRAMECRC

                 JSR   GETC             ;wait 0.5 seconds for a character, hopefully
                 BCC   :NOTCR           ;the CR in a CR/LF sequence
                 CMP   #cr
                 BNE   :NOTCR           ;if not a CR, then don't bother getting the LF
                 JSR   GETC

:NOTCR           LDA   FRAMECRC
                 CMP   CRC
                 BNE   :BADHEXFRAME
                 LDA   FRAMECRC+1
                 CMP   CRC+1
                 BEQ   :GOODHEXFRAME

:BADHEXFRAME
                 DO    BUILDDEBUG
                 LDA   #4
                 JSR   PRINTPACKET      ;*** temporary ***
                 FIN

                 LDA   #ERROR           ;nope, something really messed up
                 RTS

:GOODHEXFRAME
                 DO    BUILDDEBUG
                 LDA   #4
                 JSR   PRINTPACKET      ;*** temporary ***
                 FIN

                 LDA   FRAMETYPE        ;we were good, return the frame type
                 RTS

*
* got a ZBIN32 header, so read the next 4 bytes and CRC32 them
*
:GOTZZBIN32
                 LDA   #$FF
                 STA   CRC32
                 STA   CRC32+1
                 STA   CRC32+2
                 STA   CRC32+3

                 JSR   ZGETCHAR         ;get frametype
                 STA   FRAMETYPE
                 JSR   UPDATECRC32

                 JSR   ZGETCHAR         ;get position/flag bytes
                 STA   ZP0
                 JSR   UPDATECRC32

                 JSR   ZGETCHAR
                 STA   ZP1
                 JSR   UPDATECRC32

                 JSR   ZGETCHAR
                 STA   ZP2
                 JSR   UPDATECRC32

                 JSR   ZGETCHAR
                 STA   ZP3
                 JSR   UPDATECRC32

                 JSR   ZGETCHAR
                 STA   FRAMECRC32
                 JSR   ZGETCHAR         ;get the CRC characters
                 STA   FRAMECRC32+1
                 JSR   ZGETCHAR
                 STA   FRAMECRC32+2
                 JSR   ZGETCHAR
                 STA   FRAMECRC32+3

                 JSR   INVERTCRC32

                 LDA   FRAMECRC32+3
                 CMP   CRC32+3
                 BNE   :BADBIN32FRAME
                 LDA   FRAMECRC32+2
                 CMP   CRC32+2
                 BNE   :BADBIN32FRAME
                 LDA   FRAMECRC32+1
                 CMP   CRC32+1
                 BNE   :BADBIN32FRAME
                 LDA   FRAMECRC32
                 CMP   CRC32
                 BEQ   :GOODBIN32FRAME

:BADBIN32FRAME
                 DO    BUILDDEBUG
                 LDA   #5               ;get CRC-32 packet called it
                 JSR   PRINTPACKET      ;*** temporary ***
                 FIN

                 LDA   #ERROR           ;something is really messed up
                 RTS

:GOODBIN32FRAME
                 DO    BUILDDEBUG
                 LDA   #5
                 JSR   PRINTPACKET      ;*** temporary ***
                 FIN

                 LDA   FRAMETYPE        ;we were good, return the frame type
                 RTS

*-------------------------------------------------
* ZGETHEX -- get 2 bytes from the input stream and munge a single byte from
*            both bytes
*
* outputs = (A)

ZGETHEX          JSR   ZGETCHAR         ;get the high NIBBLE
                 LDX   ESCAPED
                 CPX   #ABORT
                 BEQ   :DONE

                 CMP   #$3A             ;is it 'a'?
                 BGE   :ISALPHA

                 SEC
                 SBC   #$30
                 BRA   :SECONDCHAR

:ISALPHA         SEC
                 SBC   #$57

*
* got the first character, now get the second and then combine them into a
* single binary character and return it in (A)
*
:SECONDCHAR
                 ASL   A
                 ASL   A
                 ASL   A
                 ASL   A
                 STA   CHAR1

                 JSR   ZGETCHAR
                 CMP   #'9'+1
                 BGE   :GOTZALPHA2

                 SEC
                 SBC   #'0'
                 ORA   CHAR1
:DONE            RTS

:GOTZALPHA2
                 SEC
                 SBC   #$57
                 ORA   CHAR1
                 RTS

CHAR1            DA    0

*-------------------------------------------------
* ZSENDBHEADER -- send a zmodem binary header

ZSENDBHEADER
                 LDA   USEFC32
                 BEQ   :NOFC32
                 JMP   ZSENDBHEADER32

:NOFC32          LDA   #ZPAD            ;* ZDLE ZBIN
                 JSR   MDMOUT

                 LDA   #ZDLE
                 JSR   MDMOUT

                 LDA   #ZBIN
                 JSR   MDMOUT

                 STZ   CRC
                 STZ   CRC+1

                 LDA   FRAMETYPE
                 JSR   CRCBYTE
                 JSR   ZPUTCHAR         ;ZDLE encode it

                 LDA   ZF3
                 JSR   CRCBYTE
                 JSR   ZPUTCHAR         ;ZDLE encode it

                 LDA   ZF2
                 JSR   CRCBYTE
                 JSR   ZPUTCHAR         ;ZDLE encode it

                 LDA   ZF1
                 JSR   CRCBYTE
                 JSR   ZPUTCHAR         ;ZDLE encode it

                 LDA   ZF0
                 JSR   CRCBYTE
                 JSR   ZPUTCHAR         ;ZDLE encode it

                 LDA   CRC+1            ;send the CRC (high byte)
                 JSR   ZPUTCHAR
                 LDA   CRC              ;send the CRC (low byte)
                 JSR   ZPUTCHAR

                 DO    BUILDFLUSH
                 LDA   FRAMETYPE        ;flush the reverse channel if it's not zdata
                 CMP   #ZDATA           ;this should reduce noise a bit
                 BEQ   :NOFLUSH

                 JSR   MDMFLUSH
:NOFLUSH
                 FIN

                 DO    BUILDDEBUG
                 LDA   #0
                 JSR   PRINTPACKET      ;*** temporary ***
                 FIN
                 RTS

*-------------------------------------------------
* ZSENDBHEADER32 -- send a zmodem 32-bit binary header

ZSENDBHEADER32
                 LDA   #ZPAD            ;* ZDLE ZBIN
                 JSR   MDMOUT

                 LDA   #ZDLE
                 JSR   MDMOUT

                 LDA   #ZBIN32
                 JSR   MDMOUT

                 LDA   #$FF
                 STA   CRC32
                 STA   CRC32+1
                 STA   CRC32+2
                 STA   CRC32+3

                 LDA   FRAMETYPE
                 JSR   UPDATECRC32
                 JSR   ZPUTCHAR         ;ZDLE encode it

                 LDA   ZF3
                 JSR   UPDATECRC32
                 JSR   ZPUTCHAR         ;ZDLE encode it

                 LDA   ZF2
                 JSR   UPDATECRC32
                 JSR   ZPUTCHAR         ;ZDLE encode it

                 LDA   ZF1
                 JSR   UPDATECRC32
                 JSR   ZPUTCHAR         ;ZDLE encode it

                 LDA   ZF0
                 JSR   UPDATECRC32
                 JSR   ZPUTCHAR         ;ZDLE encode it

                 JSR   INVERTCRC32

                 LDA   CRC32
                 JSR   ZPUTCHAR
                 LDA   CRC32+1
                 JSR   ZPUTCHAR
                 LDA   CRC32+2
                 JSR   ZPUTCHAR
                 LDA   CRC32+3
                 JSR   ZPUTCHAR

                 DO    BUILDFLUSH
                 LDA   FRAMETYPE        ;flush the reverse channel if it's not zdata
                 CMP   #ZDATA           ;this should reduce noise a bit
                 BEQ   :NOFLUSH

                 JSR   MDMFLUSH
:NOFLUSH
                 FIN

                 DO    BUILDDEBUG
                 LDA   #2
                 JSR   PRINTPACKET      ;*** temporary ***
                 FIN
                 RTS

*-------------------------------------------------
* zSendHHeader -- send a hex header

zSendHHeader
                 LDA   #ZPAD            ;* * ZDLE ZHEX
                 JSR   MDMOUT
                 LDA   #ZPAD
                 JSR   MDMOUT

                 LDA   #ZDLE
                 JSR   MDMOUT

                 LDA   #ZHEX
                 JSR   MDMOUT

                 STZ   CRC
                 STZ   CRC+1

                 LDA   FRAMETYPE
                 JSR   CRCBYTE
                 JSR   SENDINHEX

                 LDA   ZF3
                 JSR   CRCBYTE
                 JSR   SENDINHEX

                 LDA   ZF2
                 JSR   CRCBYTE
                 JSR   SENDINHEX

                 LDA   ZF1
                 JSR   CRCBYTE
                 JSR   SENDINHEX

                 LDA   ZF0
                 JSR   CRCBYTE
                 JSR   SENDINHEX

                 LDA   CRC+1            ;send the CRC (high byte)
                 JSR   SENDINHEX
                 LDA   CRC              ;send the CRC (low byte)
                 JSR   SENDINHEX

                 LDA   #cr              ;these are here for ease of debugging
                 JSR   MDMOUT           ;they make hex packets show up on the receiver's
                 LDA   #lf              ;screen one per line
                 JSR   MDMOUT

                 LDA   FRAMETYPE        ;don't send trailing XON after
                 CMP   #ZACK            ;ZACK or ZFIN
                 BEQ   :DONE
                 CMP   #ZFIN            ;and especially don't send the cr/lf sequence
                 BEQ   :DONE            ;to proterm after the ZFIN because it echoes it!

                 LDA   #xon             ;this is here to unjam any networks that may have
                 JSR   MDMOUT           ;been jammed by spurious line noise

                 DO    BUILDFLUSH
                 JSR   MDMFLUSH         ;flush the reverse channel just in case
                                        ;but don't flush it if it's a ZACK of ZFIN
                                        ;so that we don't miss characters coming in from
                                        ;a ZCRCQ packet while we're sending the ZACK
                 FIN                    ;response

:DONE
                 DO    BUILDDEBUG
                 LDA   #1
                 JSR   PRINTPACKET      ;*** temporary ***
                 FIN
                 RTS

*-------------------------------------------------
* SENDINHEX -- output the character in (A) in hex

SENDINHEX
                 PHA
                 LSR   A                ;send the high nybble FIRST!!
                 LSR   A
                 LSR   A
                 LSR   A

                 JSR   :SENDDIGIT       ;send the rightmost nybble
                 PLA                    ;send the high nybble

:SENDDIGIT
                 AND   #$F
                 CLC
                 ADC   #'0'             ;make it ascii
                 CMP   #'9'+1
                 BGE   :CHARACTER       ;is it a character?
                 JSR   MDMOUT           ;nope
                 RTS

:CHARACTER
                 CLC
                 ADC   #$27
                 JSR   MDMOUT
                 RTS

*-------------------------------------------------
* ZPUTCHAR -- output a character with ZDLE escaping in effect
*             all registers must be returned intact
*
* INPUTS: (A) = 8-bit character to output

ZPUTCHAR         PHA

                 CMP   #ZDLE
                 BEQ   :ESCAPE
                 AND   #$7F             ;protect both kinds of control chars
                 CMP   #$10             ;(both those with high-bits set and
                 BEQ   :ESCAPE          ;those that are reset)
                 CMP   #$11
                 BEQ   :ESCAPE
                 CMP   #$13
                 BEQ   :ESCAPE
                 CMP   #$D              ;CR
                 BNE   :NOESCAPE        ;not a control character

                 LDA   ZLASTCHAR
                 AND   #$7F
                 CMP   #$40             ;protect CR-@-CR
                 BNE   :NOESCAPE

:ESCAPE          LDA   #ZDLE
                 JSR   MDMOUT

                 PLA
                 STA   ZLASTCHAR
                 ORA   #%01000000       ;set bit 6
                 AND   #%11011111       ;reset bit 5 (so it appears as uppercase)
                 JSR   MDMOUT
                 RTS

:NOESCAPE        PLA
                 STA   ZLASTCHAR
                 JSR   MDMOUT
                 RTS

ZLASTCHAR        DA    0

*-------------------------------------------------
* ZGETCHAR -- get a character from the data stream with ZDLE escaping in effect
*             this has a 10 second timer on it

ZGETCHAR         LDA   #1
                 STA   CANCOUNT         ;set the abort count at 5 ZDLE's (can's) in a row
                                        ;starting from 1
                 JSR   MDMDCD
                 BCS   :DCDOK

:ABORT           LDA   #ABORT
                 STA   ESCAPED
                 RTS

:DCDOK           JSR   GETC
                 BCS   :GOTZC
                 STA   ESCAPED
                 RTS

:GOTZC           CMP   #ZDLE
                 BEQ   :ISDLE
                 TAX
                 AND   #$7F
                 CMP   #$10
                 BEQ   ZGETCHAR         ;ignore these characters
                 CMP   #$13
                 BEQ   ZGETCHAR         ;ignore these characters
                 TXA
                 STZ   ESCAPED
                 RTS

*
* we got a ZDLE character, translate the character which follows
*
:ISDLE           LDA   #1
                 STA   ESCAPED

                 JSR   GETC             ;the ZDLE escaped us
                 BCS   :GOTZCHAR
                 STA   ESCAPED
                 RTS

:GOTZCHAR        TAX
                 CMP   #ZDLE            ;if we got a ZDLE here, then that's the second
                 BNE   :NOTABORT        ;ZDLE in a row.  Someone is probably keyboarding
                                        ;control-x's at us, so we'd better see if we
                 INC   CANCOUNT         ;can get five of them, total
                 LDA   CANCOUNT         ;every time we get
                 CMP   #5
                 BLT   :ISDLE
                 BRA   :ABORT

:NOTABORT
                 CMP   #ZCRCE           ;it's already marked as escaped, so
                 BEQ   :ISFRAMEEND      ;we're ok
                 CMP   #ZCRCG
                 BEQ   :ISFRAMEEND
                 CMP   #ZCRCW
                 BEQ   :ISFRAMEEND
                 CMP   #ZCRCG
                 BEQ   :ISFRAMEEND

                 AND   #$7F
                 CMP   #$10
                 BEQ   :ISDLE           ;ignore these characters (line noise?)
                 CMP   #$13
                 BEQ   :ISDLE           ;ignore these characters (line noise?)

                 AND   #$40
                 BEQ   :TRYRUBOUT
                 TXA
                 AND   #$20
                 BNE   :TRYRUBOUT

                 TXA
                 EOR   #$40             ;flip bit 6
:ISFRAMEEND      RTS

:TRYRUBOUT       TXA
                 CMP   #ZRUB0
                 BEQ   :TRANSLATERUB0
                 CMP   #ZRUB1
                 BEQ   :TRANSLATERUB1
                 RTS

:TRANSLATERUB0                          ; rubout type #0
                 LDA   #$7F
                 RTS

:TRANSLATERUB1                          ; rubout type #1
                 LDA   #$FF
                 RTS

*-------------------------------------------------
* ZEROPOS -- zero ZP0..ZP3

ZEROPOS          LDX   #3
:LOOP            STZ   ZP0,X
                 DEX
                 BPL   :LOOP
                 RTS

*-------------------------------------------------
* CRCBYTE -- (A) gets toasted

CRCBYTE          PHA
                 PHX

                 EOR   CRC+1            ;add byte into CRC hi byte
                 TAX                    ;to make offset into tables

                 LDA   CRC              ;get previous lo byte back
                 EOR   CRCTABLEHI,X     ;add it to the proper table entry
                 STA   CRC+1            ;save it

                 LDA   CRCTABLELO,X     ;get new lo byte
                 STA   CRC              ;save it back

                 PLX
                 PLA
                 RTS                    ;all done

*-------------------------------------------------
* UPDATECRC32 -- update our CRC32
*
* inputs: (A) = byte to update CRC32
*
* outputs: all regs preserved

UPDATECRC32
                 PHA                    ;3
                 PHX                    ;3

                 EOR   CRC32            ;3
                 TAX                    ;2
                 LDA   CRC32TABLE1,X    ;4
                 EOR   CRC32+1          ;3
                 STA   CRC32            ;3
                 LDA   CRC32TABLE2,X    ;4
                 EOR   CRC32+2          ;3
                 STA   CRC32+1          ;3
                 LDA   CRC32TABLE3,X    ;4
                 EOR   CRC32+3          ;3
                 STA   CRC32+2          ;3
                 LDA   CRC32TABLE4,X    ;4
                 STA   CRC32+3          ;3

                 PLX                    ;4
                 PLA                    ;4
                 RTS                    ;cycles = 56

*-------------------------------------------------
* INVERTCRC32 -- invert the 32-bit CRC

INVERTCRC32
                 LDA   CRC32
                 EOR   #$FF
                 STA   CRC32

                 LDA   CRC32+1
                 EOR   #$FF
                 STA   CRC32+1

                 LDA   CRC32+2
                 EOR   #$FF
                 STA   CRC32+2

                 LDA   CRC32+3
                 EOR   #$FF
                 STA   CRC32+3
                 RTS

*-------------------------------------------------
* CANCEL -- send 8 CAN's followed by 10 backspaces

CANCEL           LDX   #0
:CLOOP           LDA   #can
                 JSR   MDMOUT
                 INX
                 CPX   #8
                 BLT   :CLOOP

                 LDX   #0
:BLOOP           LDA   #bs
                 JSR   MDMOUT
                 INX
                 CPX   #10
                 BLT   :BLOOP
                 RTS

                 LDA   #cr
                 JMP   MDMOUT

*-------------------------------------------------
* FIRST -- this is the entry point from the loader
*          and shouldn't be called by anyone else
*          other than the loader because we need to
*          put back the memory which we moved into
*          aux to clear space for the loader

FIRST            JSR   SAVEPTRS         ;save the zero page pointers we are about to use

                 LDA   #<$2000          ;source and destination are both $2000
                 STA   A1
                 STA   A4
                 LDA   #>$2000
                 STA   A1+1
                 STA   A4+1

                 LDA   #<$2200          ;source end
                 STA   A2
                 LDA   #>$2200
                 STA   A2+1

                 CLC                    ;aux to main
                 JSR   AUXMOVE          ;back to acos
                 JMP   RESTOREPTRS      ;restore the zero page pointers we just used

*-------------------------------------------------
* STARTUP -- startup by saving the memory in main
*            to aux

STARTUP          LDY   #3               ;last call to acos, set the output vector
                 JSR   SETOVEC

                 JSR   SAVEPTRS         ;save the zero page pointers we are about to use

                 LDA   #<$2000          ;source and destination are both $2000
                 STA   A1
                 STA   A4
                 LDA   #>$2000
                 STA   A1+1
                 STA   A4+1

                 LDA   #<$6600          ;source end
                 STA   A2
                 LDA   #>$6600
                 STA   A2+1

                 SEC                    ;main to aux
                 JSR   AUXMOVE          ;back to acos

*-------------------------------------------------
* STARTUPCRC -- move the CRC tables into main
*
* once we do this, we've gone past the point of no return

                 LDA   #<$7000          ;source, $7000 in aux
                 STA   A1
                 LDA   #>$7000
                 STA   A1+1

                 LDA   #<$7600          ;source end
                 STA   A2
                 LDA   #>$7600
                 STA   A2+1

                 LDA   #<$2000          ;destination, $2100 in main
                 STA   A4
                 LDA   #>$2000
                 STA   A4+1

                 CLC                    ;aux to main
                 JSR   AUXMOVE          ;back to acos

                 LDX   #ZPEND-ZP-1      ;save the area of zero page we're going to
:LOOP            LDA   $D0,X            ;use
                 STA   ZP,X
                 DEX
                 BPL   :LOOP

                 JMP   RESTOREPTRS      ;restore the zero page pointers we just used

*-------------------------------------------------
* SHUTDOWN -- shut us down by restoring the memory from
*             $2000 through $6600 from aux back to main

SHUTDOWN         JSR   SAVEPTRS         ;save the zero page pointers we are about to use

                 LDA   #<$2000          ;source and destination are both $2000
                 STA   A1
                 STA   A4
                 LDA   #>$2000
                 STA   A1+1
                 STA   A4+1

                 LDA   #<$6600          ;source end
                 STA   A2
                 LDA   #>$6600
                 STA   A2+1

                 CLC                    ;aux to main
                 JSR   AUXMOVE          ;back to acos
                 JSR   RESTOREPTRS      ;restore the zero page pointers we just used

                 LDX   #ZPEND-ZP-1      ;restore the area of zero page we used
:LOOP            LDA   ZP,X
                 STA   $D0,X
                 DEX
                 BPL   :LOOP

                 LDY   #0               ;restore the normal output vector
                 JMP   SETOVEC

*-------------------------------------------------
* SAVEPTRS -- save A1..A4 in 'PTRS'

SAVEPTRS         LDX   #7
:LOOP            LDA   A1,X
                 STA   PTRS,X
                 DEX
                 BPL   :LOOP
                 RTS

*-------------------------------------------------
* RESTOREPTRS -- restore A1..A4 from 'PTRS'

RESTOREPTRS
                 LDX   #7
:LOOP            LDA   PTRS,X
                 STA   A1,X
                 DEX
                 BPL   :LOOP
                 RTS

*-------------------------------------------------
* PRINTBYTES -- print the current file offset in 'bytes'

PRINTBYTES
                 DO    NOTBUILDDEBUG
                 LDA   #16
                 STA   HTAB

                 LDA   BYTES
                 STA   NUM
                 LDA   BYTES+1
                 STA   NUM+1
                 LDA   BYTES+2
                 STA   NUM+2

                 JSR   LONG2DEC

                 LDA   #>DECIMAL
                 LDX   #<DECIMAL
                 JMP   PRINTCSTRING
                 ELSE
                 RTS
                 FIN

*-------------------------------------------------
* Data segment

ZP               DS    48
ZPEND

PTRS             DW    0                ;A1
                 DW    0                ;A2
                 DW    0                ;A3
                 DW    0                ;A4

*-------------------------------------------------
                 DO    BUILDIIC

*-------------------------------------------------
* INSTALLVBLINT -- install the vertical blanking interrupt in the system

INSTALLVBLINT
                 LDA   $C419            ;offset for InitMouse call
                 STA   :INIT+1
                 LDA   $C412            ;offset for setmouse call
                 STA   :MOUSE+1

                 PHP
                 SEI

                 JSR   MLI
                 DB    $40
                 DA    ALLOCPARMS

                 LDX   #$C4
                 LDY   #$40
:INIT            JSR   $C400            ;initmouse

                 LDA   #8               ;interrupt only from VBL
                 LDX   #$C4
                 LDY   #$40
:MOUSE           JSR   $C400

                 PLP
                 RTS

ALLOCPARMS       DB    2
                 DB    0                ;our interrupt number
                 DA    VBLINT           ;our routine

*-------------------------------------------------
* removeVBLINT -- deactivate our interrupt and take it out of the prodos
*                 interrupt handler table

removeVBLINT
                 LDA   $C412            ;offset for setmouse call
                 STA   :MOUSE+1

                 PHP
                 SEI

                 LDA   #0               ;interrupt from nothing
                 LDX   #$C4
                 LDY   #$40
:MOUSE           JSR   $C400

                 LDA   ALLOCPARMS+1
                 STA   DEALLOCPARMS+1

                 JSR   MLI
                 DB    $41
                 DA    DEALLOCPARMS

                 PLP
                 RTS

DEALLOCPARMS     DB    1
                 DB    0                ;interrupt # to remove

*-------------------------------------------------
* VBLINT -- a vertical blanking interrupt happened
*           so see if we caused it -- if not, ignore it
*
VBLINT           CLD                    ;needed for prodos interrupt routine

                 LDA   $C413            ;offset for servemouse
                 STA   :MOUSE+1

                 LDX   #$C4
                 LDY   #$40
:MOUSE           JSR   $C400
                 BCS   :DONE

                 LDA   #$FF
                 STA   LASTVBL

                 CLC
                 RTS

:DONE            SEC
                 RTS

*-------------------------------------------------
* GETC  - SEC=input, CLC=no input
*         wait up to 10 seconds before timing out
*         this routine only used on the IIc which
*         doesn't have a VBL signal, but has VBLint

GETC             STZ   LASTVBL
                 STZ   SIXTY            ;sixtieths of a second we've waited
                 STZ   SIXTY+1

:LOOP            JSR   MDMIN            ;get byte from modem
                 BCC   :NOIN            ;nothing there, adjust loop counters
                 RTS

:NOIN            JSR   MDMDCD           ;check for dropped carrier
                 BCS   :DCDOK
                 LDA   #ABORT
                 RTS

:DCDOK           LDA   KEY              ;check for those annoying keypresses
                 BPL   :NOPRESS
                 STA   STROBE
                 CMP   #esc+128
                 BNE   :NOPRESS
                 CLC
                 LDA   #ABORT
                 RTS

:NOPRESS         LDA   LASTVBL          ;has there been a change?
                 BEQ   :LOOP            ;indicating a transition

                 STZ   LASTVBL

                 INC   SIXTY
                 BNE   :NC
                 INC   SIXTY+1

:NC              LDA   SIXTY
                 CMP   WAITFOR
                 BNE   :LOOP
                 LDA   SIXTY+1
                 CMP   WAITFOR+1
                 BNE   :LOOP

                 CLC                    ;input was bad
                 LDA   #TIMEOUT
                 RTS

LASTVBL          DB    0
SIXTY            DW    0
                 FIN

*-------------------------------------------------
                 DO    NOTBUILDIIC

*-------------------------------------------------
* GETC  - SEC=input, CLC=no input
*         wait up to 10 second before timing out

GETC             STZ   LASTVBL
                 STZ   SIXTY            ;sixtieths of a second we've waited
                 STZ   SIXTY+1

:LOOP            JSR   MDMDCD           ;check for dropped carrier
                 BCS   :DCDOK

                 LDA   #ABORT
                 RTS

:DCDOK           JSR   MDMIN            ;get byte from modem
                 BCC   :NOIN            ;nothing there, adjust loop counters
                 RTS

:NOIN            LDA   KEY              ;check for those annoying keypresses
                 BPL   :NOPRESS
                 STA   STROBE
                 CMP   #esc+128
                 BNE   :NOPRESS
                 CLC
                 LDA   #ABORT
                 RTS

:NOPRESS         LDA   $C019            ;has there been a change?
                 AND   #$80             ;mask all but high bit
                 CMP   LASTVBL          ;look for a change in the value
                 BEQ   :LOOP            ;indicating a transition

                 STA   LASTVBL

                 INC   SIXTY
                 BNE   :NC
                 INC   SIXTY+1

:NC              LDA   SIXTY
                 CMP   WAITFOR
                 BNE   :LOOP
                 LDA   SIXTY+1
                 CMP   WAITFOR+1
                 BNE   :LOOP

                 CLC                    ;input was bad
                 LDA   #TIMEOUT
                 RTS

LASTVBL          DB    0
SIXTY            DW    0
                 FIN
                 LST   OFF

