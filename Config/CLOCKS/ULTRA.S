            LST   OFF
            TR
            TR    ADR
*-------------------------------
* Z-RAM Ultra 2-3 - 12 hour
*-------------------------------
* Date Revised: 05/05/87
*-------------------------------

            rel
            dsk   CLOCKS/rel/ultra

ultra       ent

            org   $A00

*-------------------------------

get_time    equ   $82
mli         equ   $bf00
date        equ   $bf90

            hex   00
mode        db    0
            jmp   getdate
            jmp   gettime
            jmp   setdate

* get the date in prodos gbbs format
*-------------------------------

getdate     jsr   mli         ; mli call
            db    get_time
            hex   0000        ; no pramater table

            ldx   date
            lda   date+1
setdate     rts

* get the current time
*-------------------------------

gettime     jsr   rdtime
            lda   mode
            bpl   gtime1
            jsr   convert

gtime1      ldx   #<timestr   ; point to string
            lda   #>timestr
            rts

* read the current time from clock
*-------------------------------

rdtime      lda   #$C060
holdclk     lda   #%00000101
            sta   $C06D
            sta   $C06D
            sta   $C06D
            ldy   #30
loop        lda   $C06D
            and   #%00000010
            beq   readtime
            dey
            bne   loop
            lda   #%00000100
            sta   $C06D
            sta   $C06D
            sta   $C06D
            bne   holdclk

readtime    lda   $C065       ; 10's of hour
            and   #$F
            ora   #'0'
            sta   timestr
            lda   $C064       ; 1's of hour
            and   #$F
            ora   #'0'
            sta   timestr+1
            lda   $C063       ; 10's of minute
            and   #$F
            ora   #'0'
            sta   timestr+3
            lda   $C062       ; 1's of minute
            and   #$F
            ora   #'0'
            sta   timestr+4
            lda   $C061       ; 10's of seconds
            and   #$F
            ora   #'0'
            sta   timestr+6
            lda   $C060       ; 1's of seconds
            and   #$F
            ora   #'0'
            sta   timestr+7
            rts

* convert time to 12hr format
*----------------------------

convert     lda   timestr     ;convert to 12 hour
            ldx   timestr+1

            and   #$F
            tay
            txa
            and   #$F

            dey
            bmi   conv2
            clc
            adc   #10
            dey
            bmi   conv2
            adc   #10

conv2       cmp   #12
            bne   conv2a
            lda   #24
conv2a      tay
            bne   conv3
            lda   #12

conv3       ldx   #'A'
            cmp   #13
            bcc   conv4

            sbc   #12
            ldx   #'P'

conv4       ldy   #'0'
conv5       cmp   #10
            bcc   conv6

            sbc   #10
            iny
            bne   conv5

conv6       ora   #'0'
            sta   timestr+1
            sty   timestr
            stx   timestr+9
            ldx   #'M'
            stx   timestr+10
            rts

* variables
*-------------------------------

timestr     asc   '00:00:00   '00

            ds    \

