            TR
            TR    ADR
*-------------------------------
* GS Port Driver Bios - Slot #2
* written by Andy Nicholas on July 26, 1987
*
* Special version for the USR HST & 19200 Baud
*-------------------------------

            rel
            dsk   rel/gsport.hst
            org   $b00

cr          equ   $0d
lf          equ   $0a

Buffer      equ   $10b0
initstr     equ   $10d0
ansstr      equ   $10c0
cdbyte      equ   $10bf

*-------------------------------

gsport_hst  ent

* Jump Table
*-------------------------------

            hex   20           ;serial card slot * 16
initspd     db    00

callspd     dfb   0            speed

bytcnt      dfb   0,0,0

            jmp   init
            jmp   ringset
            jmp   ring
            jmp   answer
            jmp   hangup
            jmp   inp
            jmp   out
            jmp   getcarr
            jmp   initport
            jmp   setirq
            jmp   raisedtr

doinit      jmp   $c200
doread      jmp   $c200
dowrite     jmp   $c200
dostatus    jmp   $c200
doext       jmp   $c200

* init the serial port pascal locations
*-------------------------------

init        lda   $c20d        ;get init address
            sta   doinit+1
            lda   $c20e        ;get read address
            sta   doread+1
            lda   $c20f        ;get write address
            sta   dowrite+1
            lda   $c210        ;get status address
            sta   dostatus+1
            lda   $c212
            sta   doext+1

            rts

* setup for call
*-------------------------------

ringset     jsr   hangup

            lda   #0           ;let modem reset
            jsr   wait
            jsr   wait

            lda   #$00
            jsr   gsdtr

            jsr   initport

            lda   #0           ;slight delay (let modem do init)
            jsr   wait

            ldx   #$FF
rset2       inx   do           ;pre-inc
            lda   initstr,x    ;get modem init string
            beq   rset3        ;we are done

            jsr   out          ;output
            bra   rset2        ;loop (Z-bit set after wait)

rset3       ldy   #250         ;check 50 times
rset4       dey   count        ;down
            beq   ringset

            lda   #30          ;delay slightly
            jsr   wait
            jsr   inp
            bcc   rset4

            and   #$7f
            cmp   #'K'         ;check for "OK"
            bne   rset4

            clc
            rts   return

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

ring3       jsr   setbyte      ;set the correct speed byte

            ldy   #5
ring4       lda   #0           ;let carrier's settle
            jsr   wait
            dey
            bne   ring4

            sec   we           ;have a connection!
ring5       rts

* input data
*-------------------------------

inp         phx   save         ;x
            phy
            ldx   #$c2         ;are we ready?
            ldy   #$20
            lda   #1
            jsr   dostatus
            bcc   inp2         ;nope, exit

            ldx   #$c2         ;yes, read
            ldy   #$20
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

out1        ldx   #$c2         ;ready for send?
            ldy   #$20
            lda   #$00
            jsr   dostatus
            bcc   out1         ;nope

            pla   get          ;a
            ldx   #$c2
            ldy   #$20
            jsr   dowrite      ;send it

            ply   get          ;y
            plx   get          ;x
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

* set the rs-232 speed [speed offset in Y]
*
* 0 = 300  baud
* 1 = 1200 baud
* 2 = 2400 baud
* 3 = 4800 baud
* 4 = 9600 baud
*-------------------------------

setbyte     lda   #1           ;find caller speed (x300)
            sta   callspd
            cpy   #0           ;at 300?
            beq   done         ;yep

            asl   callspd      ;speed = speed * 2
setspeed2   asl   callspd      ;speed = speed * 2
            dey
            bne   setspeed2    ;loop until correct speed found
done        rts

* reinit the port for 19200 baud
*-------------------------------

initport    phx
            phy

            ldx   #$c2
            ldy   #$20
            jsr   doinit

            ldx   #0
Baudread    lda   Baud19200,x
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

            ply
            plx
            rts

*-------------------------------
* setup interupt vector

setirq      rts

*-------------------------------
* raise dtr

raisedtr    lda   #0
            phx
            phy

            jsr   gsdtr

            ply
            plx
            rts

* global data area
*-------------------------------

Baud19200   hex   01
            asc   '15B'
            hex   00           ;accept 19200 Baud

Port_Init
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

            asc   'GSPort/HST'

