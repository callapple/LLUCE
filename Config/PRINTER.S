            LST   OFF
            TR
            TR    ADR
*-------------------------------
* Printer re-configuration
*-------------------------------

            REL
prdrv       =     $900
point0      =     $11
point1      =     $14

            DSK   REL/PRINTER

TopBox      EXT
print       EXT
cls         EXT
start       EXT
escape      EXT
inpnum      EXT
chinit      EXT
wrtchg      EXT


nullprnt    EXT               ;null printer driver
serial      EXT               ;serial/cout printer driver
grappler    EXT               ;parallel grappler printer driver
parallel    EXT               ;parallel printer driver

re_pr       ENT
            JSR   TopBox
            JSR   print
            DB    1,2,29
            ASC   '- Printer Interfaces -'
            DB    1,4,5
            ASC   'Please refer to Appendix B of your user'
            ASC   ' manual for more information.'00

            JSR   cls
            LDX   #<start     ; setup esc handler
            LDA   #>start
            JSR   escape

            LDA   #<prdrv     ;tell it to move the modem
            STA   point1      ;driver
            LDA   #>prdrv
            STA   point1+1

            JSR   print
            DB    1,7,0
            ASC   ' 1 - Apple //c built-in port         '
            ASC   ' 7 - Apple Parallel interface'0D
            ASC   ' 2 - Apple Super Serial Card (SSC)   '
            ASC   ' 8 - Epson APL printer card'0D
            ASC   ' 3 - Apple IIgs built-in port        '
            ASC   ' 9 - Appricorn Parallel card'0D
            ASC   ' 4 - Generic Printer Driver          '
            ASC   '10 - Tyvec Printer Interface'0D
            ASC   ' 5 - Star Micronics Grafstar         '
            ASC   '11 - No Printer in system'0D
            ASC   ' 6 - Orange Micro Grappler card'0D0D0D
            ASC   'Which? [1-11] '00

            LDX   #11         ;get printer #
            JSR   inpnum

            CMP   #5
            BLT   :serial
            CMP   #7
            BLT   :grappler
            CMP   #11
            BLT   :parallel

:null       LDA   #<nullprnt
            STA   point0
            LDA   #>nullprnt
            STA   point0+1
            JMP   :noslot

:serial     LDA   #<serial
            LDX   #>serial
            JMP   :getslot

:grappler   LDA   #<grappler
            LDX   #>grappler
            JMP   :getslot

:parallel   LDA   #<parallel
            LDX   #>parallel

:getslot    STA   point0
            STX   point0+1

            JSR   print
            DB    1,20,0
            ASC   'What slot/port does your printer use? [1-7] '00

            LDX   #7          ; get slot
            JSR   inpnum
            ASL
            ASL
            ASL
            ASL
:noslot     PHA               ;save slot

            LDY   #0          ;move the single page
:loop       LDA   (point0),Y  ;source
            STA   (point1),Y  ;destination
            INY
            BNE   :loop

            LDY   #0
            PLA               ;get the slot back
            STA   (point1),Y

            JSR   chinit      ; check for init
            JMP   wrtchg      ; write the changes

