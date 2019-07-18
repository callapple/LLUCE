            TR
            TR    ADR
*-------------------------------
* GS Port Driver Bios - Slot #1
* written by Andy Nicholas on July 26, 1987
*-------------------------------

            rel
            dsk   rel/gsport1

cr          equ   $0d
lf          equ   $0a

initstr     equ   $10d0
ansstr      equ   $10c0
cdbyte      equ   $10bf

* setup for call
*-------------------------------

gsport1     ent

* Jump Table
*-------------------------------

            org   $b00

            hex   10           ;serial card slot * 16
initspd     hex   00           ;init speed for modem

callspd     dfb   0            speed

bytcnt      dfb   0,0,0

            jmp   init
            jmp   ringset
            jmp   ring
            jmp   answer
            jmp   hangup
            jmp   inp          ;get a byte
            jmp   out          ;send a byte
            jmp   getcarr      ;caller there?
            jmp   setspeed     ;speed of port
            jmp   raisedtr     ;raise dtr

doinit      jmp   $c100
doread      jmp   $c100
dowrite     jmp   $c100
dostatus    jmp   $c100
doext       jmp   $c100

* init the serial port pascal locations
*-------------------------------

init        lda   $c10d        ;get init address
            sta   doinit+1
            lda   $c10e        ;get read address
            sta   doread+1
            lda   $c10f        ;get write address
            sta   dowrite+1
            lda   $c110        ;get status address
            sta   dostatus+1
            lda   $c112
            sta   doext+1

            rts

* input data
*-------------------------------

inp         phx   save         ;x
            phy
            ldx   #$c1         ;are we ready?
            ldy   #$10
            lda   #1
            jsr   dostatus
            bcc   inp2         ;nope, exit

            ldx   #$c1         ;yes, read
            ldy   #$10
            jsr   doread

            sec
            ply
            plx   restore      ;& return
            rts

inp2        lda   #0
            clc
            ply
            plx
            rts

* output data
*-------------------------------

out         phx   save         ;x
            phy   save         ;y
            pha   save         ;a

out1        ldx   #$c1         ;ready for send?
            ldy   #$10
            lda   #$00
            jsr   dostatus
            bcc   out1         ;nope

            pla   get          ;a
            ldx   #$c1
            ldy   #$10
            jsr   dowrite      ;send it

            ply   get          ;y
            plx   get          ;x
            rts

* init modem for ring
*-------------------------------

ringset     jsr   hangup

            lda   #0           ;let modem reset
            jsr   wait
            jsr   wait

            lda   #$00
            jsr   gsdtr

            ldy   initspd      ;set init speed
            jsr   setspeed

            lda   #0           ;slight delay (let modem do init)
            jsr   wait

            ldx   #$FF
rset2       inx   do           ;pre-inc
            lda   initstr,x    ;get modem init string
            beq   rset3        ;we are done

            jsr   out          ;output
            bra   rset2        ;loop (Z-bit set after wait)

rset3       lda   #6
            sta   countlo
            sta   counthi

rset4       ldy   #$FF
rset5       dey
            beq   decount

            jsr   inp
            bcc   rset5
            and   #$7f
            cmp   #'K'         ;check for "OK"
            beq   leave
            jmp   rset5

decount     dec   countlo
            bne   rset4
            dec   counthi
            bne   rset4
            jmp   ringset

leave       lda   #0
            sta   bytcnt       ;reset byte counter
            sta   bytcnt+1
            sta   bytcnt+2
            clc
            rts                ;return

* scan for ring and handle it
*-------------------------------

ring        jsr   inp          ;check for a char
            bcc   ring5        ;nope...

            and   #$7f         ;strip high
            cmp   #'E'
            clc
            bne   ring5        ;keep checking

ring2       jsr   inp          ;check for char
            bcc   ring2

            ldy   #0           ;def = 300 baud
            and   #$7f         ;strip high

            cmp   #'R'         ;oops, "No Carrier" message
            beq   ringset

            cmp   #cr          ;connect 300
            beq   ring3

            cmp   #'3'         ;connect 300
            beq   ring3

            iny
            cmp   #'1'         ;connect 1200
            beq   ring3

            iny
            cmp   #'2'         ;connect 2400
            beq   ring3

            iny
            cmp   #'4'         ;connect 4800
            beq   ring3

            iny
            cmp   #'9'         ;connect 9600
            bne   ring2

ring3       jsr   setspeed     ;set the correct speed

            ldy   #5
ring4       lda   #0           ;let carrier's settle
            jsr   wait
            dey
            bne   ring4

            sec   we           ;have a connection!
ring5       rts

* set DTR on GS Serial Port, and hangup if needed
*-------------------------------

hangup      lda   #$80         ;blow 'em off (hangup)

gsdtr       sta   DTRstate

            lda   #DTR_List
            ldx   #>DTR_List
            ldy   #0
            jmp   doext

* wait routine
*-------------------------------

wait        sec                ;from apple ][+ ref man - pg 147
wait2       pha
wait3       sbc   #1
            bne   wait3
            pla
            sbc   #1
            bne   wait2
            rts

* Check for carrier using Get_Port_Stat routine
*-------------------------------

getcarr     phx
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

nocarr      clc
            ply
            plx
            rts

* send ata to phone
*-------------------------------

answer      ldx   #$ff
answer2     inx
            lda   ansstr,x     ;get text
            beq   answer3      ;we are done

            jsr   out          ;send it
            bra   answer2

answer3     rts

* set the rs-232 speed [speed offset in Y]
*-------------------------------

setspeed    phx
            phy

            lda   #1           ;find caller speed (x300)
            sta   callspd
            cpy   #0           ;at 300?
            beq   Do_Baud      ;yep

            asl   callspd      ;speed = speed * 2
setspeed2   asl   callspd      ;speed = speed * 2
            dey
            bne   setspeed2    ;loop until correct speed found

Do_Baud     pla   get          ;y-reg
            bne   Try1200
            lda   #<Baud300
            sta   Baudread+1
            lda   #>Baud300
            sta   Baudread+2
            bra   SetBaud

Try1200     cmp   #1
            bne   Try2400
            lda   #<Baud1200
            sta   Baudread+1
            lda   #>Baud1200
            sta   Baudread+2
            bra   SetBaud

Try2400     cmp   #2
            bne   Try4800
            lda   #<Baud2400
            sta   Baudread+1
            lda   #>Baud2400
            sta   Baudread+2
            bra   SetBaud

Try4800     cmp   #3
            bne   Try9600
            lda   #<Baud4800
            sta   Baudread+1
            lda   #>Baud4800
            sta   Baudread+2
            bra   SetBaud

Try9600     lda   #<Baud9600
            sta   Baudread+1
            lda   #>Baud9600
            sta   Baudread+2

SetBaud     ldx   #$c1
            ldy   #$10
            jsr   doinit

            ldx   #0
Baudread    lda   $ffff,x
            beq   Fin_Init
            jsr   out
            inx
            bra   Baudread

Fin_Init    ldx   #0
Init_Loop   lda   Port_Init,x
            beq   donebaud
            jsr   out
            inx
            bra   Init_Loop

donebaud    lda   #Out_Buf
            ldx   #>Out_Buf
            ldy   #0
            jsr   doext

            plx
            rts

*-------------------------------
* raise dtr

raisedtr    lda   #0
            phx
            phy

            jsr   gsdtr

            ply
            plx
            rts

* Table of Speeds and other important stuff
*-------------------------------

Buffer      equ   $1080

counthi     db    0
countlo     db    0

Baud300     hex   01
            asc   '6B'
            hex   00           ;accept 300 Baud
Baud1200    hex   01
            asc   '8B'
            hex   00           ;accept 1200 Baud
Baud2400    hex   01
            asc   '10B'
            hex   00           ;accept 2400 Baud
Baud4800    hex   01
            asc   '12B'
            hex   00           ;accept 4800 Baud
Baud9600    hex   01
            asc   '14B'
            hex   00           ;accept 9600 Baud

Port_Init                      ;
            hex   01
            asc   '0D'         ;8 bits
            hex   01
            asc   '2P'         ;no parity
            hex   01
            asc   'AD'         ;auto-tabbing
            hex   01
            asc   'XD'         ;no xoff recognition
            hex   01
            asc   'FD'         ;no find keyboard
            hex   01
            asc   'CD'         ;no column overflow
            hex   01
            asc   'ED'         ;echo disabled
            hex   01
            asc   'MD'         ;no lf masking
            hex   01
            asc   'BE'         ;buffering enabled
            hex   01
            asc   'Z'
            hex   00           ;no more control characters

*-------------------------------

Out_Buf     hex   04           ;Parameters to set the
            hex   13           ;Output buffer
            da    0
            adrl  Buffer       ;Buffer it where
            da    2            buffer

*-------------------------------

carrlist    hex   03           ;Parameter list for
            hex   06           ;detecting carrier drop
            da    0
carrbits    da    0            Carrier

*-------------------------------

DTR_List    hex   03           ;Parameter list for
            hex   0b           ;setting DTR
            da    0
DTRstate    da    0            bit

            asc   'GSPort1'

