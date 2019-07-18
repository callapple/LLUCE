            LST   OFF
            TR
            TR    ADR
********************************
*                              *
*   Grappler Printer Driver    *
*                              *
********************************

*-------------------------------
* Date: 12/07/86
*-------------------------------

            REL
            DSK   PRINTERS/REL/GRAPPLER

cr          =     $D
lf          =     $A

grappler    ENT

*-------------------------------

            ORG   $900
; jump table
slot        DB    $10

            JMP   init
            JMP   print
            JMP   clear

*-------------------------------
* init printer

init        RTS               ; no init code needed

*-------------------------------
* print character: A = character

print       PHA
            STX   save_x

            LDX   slot
print2      LDA   $C080,X     ; check printer status
            AND   #%00000111  ; check busy/wait bits
            EOR   #%00000011  ; turn all bits off
            BNE   print2      ; wait to come ready

            PLA
            PHA
            AND   #$7F
            STA   $C080,X     ; print data
            CMP   #cr
            BNE   print3

            LDA   #lf         ; add lf to cr
            LDX   save_x
            JSR   print

print3      LDX   save_x      ; finish up
            PLA
            RTS

*-------------------------------
* clear print buffer (not available)

clear       RTS

save_x      DB    0

