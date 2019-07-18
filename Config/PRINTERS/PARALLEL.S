            LST   OFF
            TR
            TR    ADR
********************************
*                              *
*   Parallel Printer Driver    *
*                              *
********************************

*-------------------------------
* Date: 12/07/86
*-------------------------------

            REL
            DSK   PRINTERS/REL/PARALLEL

cr          =     $D
lf          =     $A

parallel    ENT

*-------------------------------

            ORG   $900

slot        DB    $10

            JMP   init
            JMP   print
            JMP   clear

*-------------------------------

init        LDA   slot
            LUP   4
            LSR
            --^
            CLC
            ADC   #$C0        ; get $Cx value
            STA   print2+2
            RTS

*-------------------------------
* print character: A = character

print       PHA
            STX   save_x
print2      LDA   $C1C1       ; is printer ready?
            BMI   print2      ; nope

            PLA
            PHA
            LDX   slot        ; get offset
            AND   #$7F
            STA   $C080,x     ; print data
            CMP   #cr
            BNE   print3

            LDA   #lf         ; add lf to cr
            LDX   save_x
            JSR   print

print3      LDX   save_x      ; finish up
            PLA
            RTS

*-------------------------------

clear       RTS

save_x      DB    0

