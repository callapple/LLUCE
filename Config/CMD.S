            LST   OFF
            TR
            TR    ADR
*-------------------------------
* Date: 3/11/88
*-------------------------------

            REL
            DSK   REL/CMD

cls         EXT
sv_drvs     EXT
start       EXT
init        EXT

*-------------------------------
* write the changes back into the drivers file
*-------------------------------

wrtchg      ENT
            JSR   cls
            JSR   sv_drvs     ; write configuration back to disk
            JMP   start

*-------------------------------
* check to see if in init mode
*-------------------------------

chinit      ENT
            BIT   init        ; in init mode?
            BPL   :chinit2    ; nope

            PLA               ; return to init routine
            PLA
:chinit2    RTS               ; return to caller

