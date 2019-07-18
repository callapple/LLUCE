            TR
            TR    ADR
*-------------------------------
* USRobotics HST 19200 Super Serial driver for acos
* written by Andy Nicholas on one cold january night
*-------------------------------

            rel
            dsk   rel/ssc.hst
            org   $0b00

cr          equ   $0d
lf          equ   $0a

data        equ   $c088
status      equ   $c089
command     equ   $c08a
control     equ   $c08b

initstr     equ   $10d0
ansstr      equ   $10c0
cdbyte      equ   $10bf

*-------------------------------

ssc_hst     ent

* jumptable
*-------------------------------

slot        db    $20         ;serial card slot*16
initspd     db    00

callspd     dfb   0           ;speed of call

bytcnt      dfb   0,0,0

            jmp   init
            jmp   ringset
            jmp   ring
            jmp   answer
            jmp   hangup
            jmp   inp
            jmp   out
            jmp   chkdcd
            jmp   setspd
            jmp   setirq
            jmp   raisedtr

* init the serial card
*-------------------------------

init        lda   #0          ;reset bytes
            ldx   slot
            sta   status,x    ;reset uart
            sta   command,x   ;reset command

            clc
            txa
            adc   #<data
            sta   dataloc+1   ;make into absolute save
            rts

* setup for call
*-------------------------------

ringset     ldx   slot        ;get offset

            lda   #%00000000  ;kill DTR, RTS
            sta   command,x

            lda   #0          ;let modem reset
            jsr   wait
            jsr   wait

            lda   #%00001011  ;turn on DTR, RTS
            sta   command,x

            sei

            ldy   initspd     ;set init speed
            jsr   setspd

            lda   data,x      ;clear data strobe

            lda   #0          ;slight delay (let modem do init)
            jsr   wait

            ldx   #0
loop        lda   initstr,x   ;get modem init string
            beq   rset3
            jsr   out         ;output
            inx
            bne   loop

rset3       lda   #6
            sta   countlo
            sta   counthi

rset4       ldy   #$FF
rset5       dey
            beq   decount

            jsr   inp
            bcc   rset5
            and   #$7f
            cmp   #'K'        ;check for "OK"
            beq   leave
            jmp   rset5

decount     dec   countlo
            bne   rset4
            dec   counthi
            bne   rset4
            jmp   ringset

leave       lda   #0
            sta   bytcnt      ;reset byte counter
            sta   bytcnt+1
            sta   bytcnt+2
            clc
            rts   return

jring       jmp   ringset     ;extend branch to ringset

* scan for ring and handle it
*-------------------------------

ring        jsr   inp         ;check for a char
            bcc   ring5       ;nope...

            and   #$7f        ;strip high
            cmp   #'E'
            clc
            bne   ring5       ;keep checking

ring2       jsr   inp         ;check for char
            bcc   ring2

            ldy   #0          ;def = 300 baud
            and   #$7f        ;strip high

            cmp   #'R'        ;oops, "No Carrier" message
            beq   jring

            cmp   #cr         ;connect 300
            beq   ring3

            cmp   #'3'        ;connect 300
            beq   ring3

            iny
            cmp   #'1'        ;connect 1200
            beq   ring3

            iny
            cmp   #'2'        ;connect 2400
            beq   ring3

            iny
            cmp   #'4'        ;connect 4800
            beq   ring3

            iny
            cmp   #'9'        ;connect 9600
            bne   ring2

ring3       jsr   setspd      ;set the correct speed

            ldy   #5
ring4       lda   #0          ;let carrier's settle
            jsr   wait
            dey
            bne   ring4

            sec   we          ;have a connection!
ring5       rts

* send ata to phone
*-------------------------------

answer      ldx   #0
answer2     lda   ansstr,x    ;get text
            beq   answer3     ;we are done

            jsr   out         ;send it
            inx
            bne   answer2     ;loop

answer3     rts

* hangup phone
*-------------------------------

hangup      ldx   slot        ;get offset
            lda   #0
            sta   command,x   ;hang up phone
            rts

* input data
*-------------------------------

inp         stx   save_x      ;save X
            ldx   slot        ;get offset
            lda   status,x    ;get status
            and   #%00001000
            clc
            beq   inp2        ;no data

            lda   data,x
            sec
inp2        ldx   save_x      ;restore & return
            rts

* output data
*-------------------------------

out         stx   save_x      ;save x
            dec   timecnt     ;count down 1 section
            bne   out1

            inc   bytcnt      ;1 second gone by
            bit   bytcnt
            bvc   out1

            ldx   #0          ;reset seconds
            stx   bytcnt

            inc   bytcnt+1    ;1 minute gone by
            bit   bytcnt+1
            bvc   out1

            ldx   #0          ;reset minutes
            stx   bytcnt+1

            inc   bytcnt+2    ;1 hour gone by

out1        ldx   slot

            pha
out2        lda   status,x    ;check status
            and   #%00010000
            beq   out2        ;loop until ready
            pla

dataloc     sta   data        ;self modified
            ldx   save_x
            rts

* check for carrier
*-------------------------------

chkdcd      stx   save_x      ;dont kill any reg's
            pha

            ldx   slot        ;get offset
            lda   status,x
            and   cdbyte      ;check carrier
            clc
            bne   chkdcd2

            sec
chkdcd2     pla   restore     ;all & return
            ldx   save_x
            rts

* set the rs232 speed/19200 always
*-------------------------------

setspd      stx   save_x
            ldx   slot        ;get offset
            lda   speed       ;get speed
            sta   control,x   ;set speed

            lda   #1          ;find caller speed (x300)
            sta   callspd
            cpy   #0          ;at 300?
            beq   setspd3     ;yep

            asl   callspd     ;speed = speed * 2
setspd2     asl   callspd     ;speed = speed * 2
            dey
            bne   setspd2     ;loop until correct speed found

setspd3     ldx   save_x      ;restore & return
            rts

*-------------------------------
* setup interupt routine

setirq      rts

*-------------------------------
* turn on dtr/rts

raisedtr    stx   save_x
            ldx   slot

            lda   #%00001011  ;turn on DTR, RTS
            sta   command,x
            sei               ;re-disable interrupts

            ldx   save_x
            rts

* wait routine
*-------------------------------

wait        sec               ;from apple ][+ ref man - pg 147
wait2       pha
wait3       sbc   #1
            bne   wait3
            pla
            sbc   #1
            bne   wait2
            rts

* global data area
*-------------------------------

speed       hex   1F          ;19200b all we have to worry about

timecnt     dfb   0           ;1-second counter
save_x      dfb   0
countlo     dfb   $FF
counthi     dfb   $FF

            asc   'SSC/HST'

