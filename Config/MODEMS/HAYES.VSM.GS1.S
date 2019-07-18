             TR
             TR    ADR
*-------------------------------
* GS Port Driver Bios - Slot #2
* written by Andy Nicholas on July 26, 1987
*-------------------------------

cr           equ   $0d
lf           equ   $0a

*-------------------------------

gsport2      ent


* Jump Table
*-------------------------------

             org   $e00

protocol     hex   00            ;serial card slot * 16
initspd      hex   05

callspd      dfb   0             ;speed of call

bytcnt       dfb   0,0,0

             jmp   init
             jmp   ringset
             jmp   ring
             jmp   answerRing
             jmp   hangup
             jmp   inp
             jmp   out
             jmp   getcarr
             jmp   setspeed
             jmp   setirq
             jmp   raisedtr

doinit       jmp   $c200
doread       jmp   $c200
dowrite      jmp   $c200
dostatus     jmp   $c200
doext        jmp   $c200

* init the serial port pascal locations
*-------------------------------

init         lda   $c20d         ;get init address
             sta   doinit+1
             lda   $c20e         ;get read address
             sta   doread+1
             lda   $c20f         ;get write address
             sta   dowrite+1
             lda   $c210         ;get status address
             sta   dostatus+1
             lda   $c212
             sta   doext+1

             rts

* input data
*-------------------------------

inp          phx   save          ;x
             phy
             ldx   #$c2          ;is there input ready?
             ldy   #$20
             lda   #1
             jsr   dostatus
             bcs   :inp2         yes,

             lda   #0
             clc
             bra   :inp3

:inp2        ldx   #$c2          ;yes, read
             ldy   #$20
             jsr   doread

             sec
:inp3        ply
             plx                 ;restore & return
             rts

* output data
*-------------------------------

out          phx                 ;save x
             phy                 ;save y
             pha                 ;save a

out1         ldx   #$c2          ;ready for send?
             ldy   #$20
             lda   #$00
             jsr   dostatus
             bcc   out1          ;nope

             pla   get           ;a
             ldx   #$c2
             ldy   #$20
             jsr   dowrite       ;send it

             ply   get           ;y
             plx   get           ;x
             rts

* setup for call
*-------------------------------

ringset      jsr   hangup

             lda   #0            ;let modem reset
             jsr   wait
             jsr   wait

             lda   #$00
             jsr   gsdtr

             ldy   initspd       ;set init speed
             jsr   setspeed

             lda   #0            ;slight delay (let modem do init)
             jsr   wait

             ldx   #$FF
rset2        inx   do            ;pre-inc
             lda   initstr,x     ;get modem init string
             beq   rset3         ;we are done

             jsr   out           ;output
             bra   rset2         ;loop (Z-bit set after wait)

rset3        lda   #6
             sta   countlo
             sta   counthi

rset4        ldy   #$FF
rset5        dey
             beq   decount

             jsr   inp
             bcc   rset5
             and   #$7f
             cmp   #'0'          ;check for "0" result
             beq   leave
             jmp   rset5

decount      dec   countlo
             bne   rset4
             dec   counthi
             bne   rset4
             jmp   ringset

leave        jsr   inp           ;grab the <cr> off the tail end of the "0"
             bcc   leave

             jsr   clearBuffer

             lda   #0
             sta   bytcnt        ;reset byte counter
             sta   bytcnt+1
             sta   bytcnt+2
noRing       clc
             rts                 ;return

*-------------------------------
* test for a ring and handle it

ring         jsr   inp           ;check for a char
             bcc   noRing        ;nope...

             and   #$7f          ;strip high
             cmp   #'2'          ;is it a 'ring'? (numeric)
             bne   notRing       ;nope, check for connect messages

********************************
grabCR       jsr   inp           ;grab the <cr> off the tail end of the "2"
             bcc   grabCR

answerRing   jsr   answer        ;the phone rang, so send 'ATA'

             clc
             rts

********************************
notRing      cmp   #'4'          ; is it a '40','46','47' or '48'?
             beq   :gotCode
             cmp   #'5'          ; is it a '50'?
             beq   :gotCode      ; Yes, check for carrier speed
             jmp   noRing

:gotCode     sta   code1
             ldy   #1

:nxtchar     jsr   inp           ; get next character
             bcc   :nxtchar      ; it MUST be there

             and   #$7f
             cmp   #cr
             bne   :valid
             cpy   #5
             bne   :nxtchar
             bra   :next

:valid       sta   code1,y
             iny
             cpy   #6
             bne   :nxtchar

:next        ldy   #32           ;def = 9600 baud carrier
             ldx   #4

             lda   code1         ;get the first code char
             cmp   #'5'          ;is it a '50'?
             bne   :not9600      ;if not, then check for other carrier speeds

             lda   code1+1
             cmp   #'0'
             beq   :setcspd

:not9600     ldy   #1
             ldx   #0
             lda   code1+1       ;is it a 300 baud carrier?
             cmp   #'0'
             beq   :setcspd      ;yes

             ldy   #4
             inx
             cmp   #'6'          ;is it a 1200 baud carrier?
             beq   :setcspd      ;yes

             ldy   #8
             inx
             cmp   #'7'          ;is it a 2400 baud carrier?
             beq   :setcspd

             ldy   #16
             inx
             cmp   #'8'          ;is it a 4800 baud carrier?
             beq   :setcspd
             jmp   noRing

:setcspd     sty   carrspd
             stx   portspd

* check for protocol connections
             lda   code2         ; get first char of protocol
             cmp   #'7'          ; is it '70'?
             bne   :ring3

             lda   code2+1       ; get last character of protocol
             cmp   #'0'          ; is it '70'?
             beq   :ring3

             lda   #$80
             sta   protocol      ; save indicator of a protocol connection
             ldx   #5
             stx   portspd

********************************
:ring3       ldy   portspd       ;get the speed to open port at
             jsr   setspeed      ;set the correct speed

             ldy   #5
ring4        lda   #0            ;let carrier's settle
             jsr   wait
             dey
             bne   ring4

             jsr   clearBuffer   ;remove any garbage
             sec                 ;we have a connection!
             rts

*-------------------------------
* clear the input buffer

clearBuffer
             lda   #Flush_List
             ldx   #>Flush_List
             ldy   #0
             jmp   doext

* set DTR on GS Serial Port, and hangup if needed
*-------------------------------

hangup       lda   #$80          ;blow 'em off (hangup)
gsdtr        sta   DTRstate

             lda   #DTR_List
             ldx   #>DTR_List
             ldy   #0
             jmp   doext

* wait routine
*-------------------------------

wait         sec                 ;from apple ][+ ref man - pg 147
wait2        pha
wait3        sbc   #1
             bne   wait3
             pla
             sbc   #1
             bne   wait2
             rts

* Check for carrier using Get_Port_Stat routine
*-------------------------------

getcarr      phx
             phy

             lda   #carrlist
             ldx   #>carrlist
             ldy   #0
             jsr   doext

             lda   carrbits
             and   cdbyte
             beq   nocarr
             sec
             ply
             plx
             rts

nocarr       clc
             ply
             plx
             rts

* send ata to phone
*-------------------------------

answer       lda   #$80
             jsr   wait

             ldx   #$ff
answer2      inx
             lda   ansstr,x      ;get text
             beq   answer3       ;we are done

             jsr   out           ;send it
             bra   answer2

answer3      rts

* set the rs-232 speed [speed offset in Y]
*
* 0 =   300 baud
* 1 =  1200 baud
* 2 =  2400 baud
* 3 =  4800 baud
* 4 =  9600 baud
* 5 = 19200 baud
*-------------------------------

setspeed     phx

             ldx   carrspd       ;find caller speed (x300)
             stx   callspd

             tya                 ;get y-reg into a-reg
             bne   Try1200
             lda   #<Baud300
             sta   Baudread+1
             lda   #>Baud300
             sta   Baudread+2
             bra   SetBaud

Try1200      cmp   #1
             bne   Try2400
             lda   #<Baud1200
             sta   Baudread+1
             lda   #>Baud1200
             sta   Baudread+2
             bra   SetBaud

Try2400      cmp   #2
             bne   Try4800
             lda   #<Baud2400
             sta   Baudread+1
             lda   #>Baud2400
             sta   Baudread+2
             bra   SetBaud

Try4800      cmp   #3
             bne   Try9600
             lda   #<Baud4800
             sta   Baudread+1
             lda   #>Baud4800
             sta   Baudread+2
             bra   SetBaud

Try9600      cmp   #4
             bne   Try19200
             lda   #<Baud9600
             sta   Baudread+1
             lda   #>Baud9600
             sta   Baudread+2
             bra   SetBaud

Try19200     lda   #<Baud19200
             sta   Baudread+1
             lda   #>Baud19200
             sta   Baudread+2

SetBaud      ldx   #$c2
             ldy   #$20
             jsr   doinit

             ldx   #0
Baudread     lda   $ffff,x
             beq   Fin_Init
             jsr   out
             inx
             bra   Baudread

Fin_Init     ldx   #0
Init_Loop    lda   Port_Init,x
             beq   donebaud
             jsr   out
             inx
             bra   Init_Loop

donebaud     lda   #Out_Buf
             ldx   #>Out_Buf
             ldy   #0
             jsr   doext

             plx
             rts

*-------------------------------
* setup interupt routine

setirq       rts

*-------------------------------
* raise dtr

raisedtr     lda   #0
             phx
             phy

             jsr   gsdtr

             ply
             plx
             rts

* globals
*-------------------------------

counthi      db    0
countlo      db    0

Baud300      hex   01
             asc   '6B'
             hex   00            ;accept 300 Baud
Baud1200     hex   01
             asc   '8B'
             hex   00            ;accept 1200 Baud
Baud2400     hex   01
             asc   '10B'
             hex   00            ;accept 2400 Baud
Baud4800     hex   01
             asc   '12B'
             hex   00            ;accept 4800 Baud
Baud9600     hex   01
             asc   '14B'
             hex   00            ;accept 9600 Baud
Baud19200    hex   01
             asc   '15B'
             hex   00            ;accept 19200 baud

Port_Init
             hex   01
             asc   '0D'          ;8 bits
             hex   01
             asc   '2P'          ;no parity
             hex   01
             asc   'AD'          ;auto-tabbing
             hex   01
             asc   'XD'          ;no xoff recognition
             hex   01
             asc   'FD'          ;no find keyboard
             hex   01
             asc   'CD'          ;no column overflow
             hex   01
             asc   'ED'          ;echo disabled
             hex   01
             asc   'MD'          ;no lf masking
             hex   01
             asc   'BE'          ;buffering enabled
             hex   01
             asc   'Z'
             hex   00            ;no more control characters

*-------------------------------

Out_Buf      hex   04            ;Parameters to set the
             hex   13            ;Output buffer
             da    0
             adrl  Buffer        ;Buffer it where
             da    2             buffer

*-------------------------------

carrlist     hex   03            ;Parameter list for
             hex   06            ;detecting carrier drop
             da    0
carrbits     da    0             ;Carrier status here

*-------------------------------

DTR_List     hex   03            ;Parameter list for
             hex   0b            ;setting DTR
             da    0
DTRstate     da    0             ;bit 7 effects DTR

*-------------------------------

Flush_List   hex   02            ;parameter list for flushing input queue
             hex   14
             da    0

*-------------------------------

code1        ds    2             ;2 byte carrier speed
code2        ds    2             ;2 byte protocol format
code3        ds    2             ;2 byte connect speed
portspd      ds    1
carrspd      ds    1

Buffer       ds    $15
cdbyte       db    #$20
ansstr       asc   'ATA',0d00
initstr      asc   'ATZ',0d00

*initstr asc 'ATX1S0=0S2=128&C1&D2&S1&K5E0V0W1M0'0d00

