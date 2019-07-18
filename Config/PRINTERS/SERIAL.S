            LST   OFF
            TR
            TR    ADR
********************************
*                              *
*    Serial Printer Driver     *
*                              *
********************************

*-------------------------------
* Date: 12/07/86
*-------------------------------

            REL
            DSK   PRINTERS/REL/SERIAL

cr          =     $D
lf          =     $A

serial      ENT

            ORG   $900

*-------------------------------
; jump table
slot        DB    $10

            JMP   init
            JMP   print
            JMP   clear

*-------------------------------
* flag init status for output

init        PHA
            LDA   #0          ; signal that printer not init'ed
            STA   initflg
            PLA
            RTS

*-------------------------------
* print character: A = character

print       PHP               ; disable int's
            SEI
            PHA               ; save all reg's
            STX   save_x
            STY   save_y
            LDA   $C082       ; enable roms

            LDX   #$13
print1      LDA   $24,X       ; save zero page stuff
            STA   zero,X
            DEX
            BPL   print1

            BIT   initflg     ; has printer been used?
            BMI   print3      ; yep

            LDA   slot
            STA   $26         ; save slot for card
            LUP   4
            LSR               ; move down slot
            --^
            CLC
            ADC   #$C0
            STA   print2+2
            STA   $36+1       ; point ($0036) at $c100

            LDA   #0          ; init printer card
            TAX
            TAY
            STA   $24         ; zero horiz offset
            STA   $27         ; zero character buffer
            STA   $36
print2      JSR   $C100
            LDA   $36         ; point to output routine
            STA   jprint+1
            LDA   $36+1
            STA   jprint+2
            DEC   initflg     ; show we have done init

            LDA   #'I'-$40    ; send ctrl-I 80 n
            JSR   doprint
            LDA   #'8'
            JSR   doprint
            LDA   #'0'
            JSR   doprint
            LDA   #'N'
            JSR   doprint
            LDA   #cr
            JSR   doprint

print3      LDA   #0          ; set ch over to border
            STA   $24
            PLA               ; get byte to print
            PHA
            JSR   doprint

            LDX   #$13
print4      LDA   zero,X      ; restore zero page
            STA   $24,X
            DEX
            BPL   print4

            LDA   $C083       ; enable ram card
            LDA   $C083
            LDX   save_x      ; restore reg's
            LDY   save_y
            PLA
            PLP               ; restore int status
            RTS

doprint     ORA   #$80        ; print with high-bit set
jprint      JMP   $C000       ; do output routine

; clear print buffer (not available)
clear       RTS

save_x      DB    0
save_y      DB    0
initflg     DB    0

zero        DS    $14

