            LST   OFF
            TR
            TR    ADR
*-------------------------------
* No Slot Clock - 24 hr
*-------------------------------
* Revised Date: 08/02/87
*-------------------------------

            rel
            dsk   CLOCKS/rel/noslot

ZBUF        EQU   $41
PTR         EQU   $42

YEAR        EQU   $44
HOURS       EQU   $48
TEMP        EQU   $2F0

date        equ   $bf90
get_time    equ   $82


noslot      ent

            org   $0a00

*-------------------------------

            db    $00
MODE        dfb   $00
            JMP   getdate
            JMP   getime
            JMP   setdate

*
* TIME OUTPUT BUFFER
*

TIME        ASC   '00:00:00   '
*
* DEFINE RECOGNITION SEQUENCE FOR NO-SLOT CLOCK
*

RECSEQ      db    $5C,$A3,$3A,$C5,$5C,$A3,$3A,$C5

*
* FORMAT NO-SLOT CLOCK DATE
*

* get the date in prodos gbbs format
*-------------------------------

getdate     jsr   $bf00       ; mli call
            db    get_time
            hex   0000        ; no pramater table

            ldx   date
            lda   date+1
setdate     rts

*
* FORMAT NO-SLOT CLOCK TIME
*

getime      JSR   RDCLOCK
            LDY   HOURS
            LDA   MODE
            BEQ   FMT24
            LDA   #'M'
            STA   TIME+10
            LDX   #'A'
            SED
            SEC
            TYA
            SBC   #$12
            CLD
            BCC   SETHOUR
            TAY
            BNE   NOTNOON
            LDY   #$12
NOTNOON     LDX   #'P'
SETHOUR     STX   TIME+9
            TYA
            BNE   FMT24
            LDY   #$12
FMT24       TYA
            LDY   #0
            LDX   #0
FMT         PHA
            AND   #$F0
            LSR
            LSR
            LSR
            LSR
            CLC
            ADC   #'0'
            STA   TIME,Y
            INY
            PLA
            AND   #$F
            ADC   #'0'
            STA   TIME,Y
            INY
            INY
            INX
            LDA   HOURS,X
            CPX   #3
            BNE   FMT
            JSR   ZRECALL
*
            LDX   #<TIME
            LDA   #>TIME
            RTS
*
* RECALL PG ZERO BUFFER (ACCESS VIA JMP)
*
ZRECALL     LDY   #$A
ZRECALL1    LDA   TEMP,Y
            STA   PTR,Y
            DEY
            BNE   ZRECALL1
            RTS
*
* READ THE NO-SLOT CLOCK AND RETRIEVE DATE/TIME
*
RDCLOCK     LDY   #$A
STORBUF     LDA   ZBUF,Y
            STA   TEMP,Y
            DEY
            BNE   STORBUF
            SEI
            LDA   $C015
            PHA
            STA   $C007
            LDA   $C804
            LDA   #<RECSEQ
            STA   PTR
            LDA   #>RECSEQ
            STA   PTR+1
            LDY   #7
RECOG1      LDA   (PTR),Y
            SEC
            ROR
RECOG2      PHA
            LDA   #0
            ROL
            TAX
            LDA   $C800,X
            PLA
            LSR
            BNE   RECOG2
            DEY
            BPL   RECOG1
            LDX   #7
NEXTREAD    LDY   #7
READBIT     LDA   $C804
            ROR
            ROR   YEAR,X
            DEY
            BPL   READBIT
            CPX   #3
            BPL   STORDATE
            LDA   YEAR,X
            PHA
            AND   #$F
            STA   YEAR,X
            PLA
            AND   #$F0
            LSR
            LSR
            LSR
            LSR
            TAY
            BEQ   STORDATE
            LDA   #0
ADDTENS     ADC   #10
            DEY
            BNE   ADDTENS
            ADC   YEAR,X
            STA   YEAR,X
STORDATE    DEX
            BPL   NEXTREAD
            PLA
            ROL
            BCS   RDEND
            STA   $C006
RDEND       RTS

            ds    \

