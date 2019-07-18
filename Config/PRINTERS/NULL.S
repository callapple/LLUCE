            LST   OFF
            TR
            TR    ADR
********************************
*                              *
*      No Printer Driver       *
*                              *
********************************

*-------------------------------
* Date: 01/03/86
*-------------------------------

            REL
            DSK   PRINTERS/REL/NULL

nullprnt    ENT

            ORG   $900
; jump table
slot        DB    $10

            JMP   init
            JMP   print
            JMP   clear

; init printer
init        RTS

; print character: A = character
print       RTS

; clear print buffer (not available)
clear       RTS

