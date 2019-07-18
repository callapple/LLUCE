            LST   OFF
            TR
            TR    ADR
*-------------------------------
* reconfigure clocks
*-------------------------------

            REL
point0      =     $11
point1      =     $14
clkdrv      =     $a00

            DSK   REL/CLOCK

TopBox      EXT               ; routines external to this file
print       EXT
cls         EXT
start       EXT
escape      EXT
inpnum      EXT
chinit      EXT
wrtchg      EXT

gsclock     EXT               ;gs clock driver
serialpro   EXT               ;serialpro driver
thunder     EXT               ;thunderclock/timemaster driver
iicsys      EXT               ;iic system clock
mountain    EXT               ;mountain clock
prodos      EXT               ;standard prodos stuff
nullclk     EXT               ;no clock
noslot      EXT               ;no slot clock
versa       EXT               ;prometheus versacard
ultra       EXT               ;ultra clock driver

re_clk      ENT
            JSR   TopBox
            JSR   print
            DB    1,2,30
            ASC   '- Reconfigure Clock -'
            DB    1,4,5
            ASC   'Please refer to Appendix C of your user'
            ASC   ' manual for more information.'00

            JSR   cls
            LDX   #<start     ; setup esc handler
            LDA   #>start
            JSR   escape

            LDA   #<clkdrv    ;tell it to move the modem
            STA   point1      ;driver
            LDA   #>clkdrv
            STA   point1+1

IIeClk      JSR   print
            DB    1,7,0

            ASC   ' 1 - Thunderclock Compatible               '
            ASC   ' 7 - ProDOS Compatible Clock'0D
            ASC   ' 2 - A.E. Timemaster II H.O.               '
            ASC   ' 8 - Mountain Hardware Clock'0D
            ASC   ' 3 - A.E. Serial Pro                       '
            ASC   ' 9 - Prometheus Versacard'0D
            ASC   ' 4 - A.E. //c Ultra Clock                  '
            ASC   '10 - Apple IIgs System Clock'0D
            ASC   ' 5 - A.E. //c System Clock                 '
            ASC   '11 - No Clock in System'0D
            ASC   ' 6 - SMT No-Slot Clock'0D0D

            ASC   'Which? [1-11] '00

            LDX   #11
            JSR   inpnum

            PHA
            ASL
            TAX
            LDA   :clktbl,X
            STA   point0
            INX
            LDA   :clktbl,X
            STA   point0+1

            PLA
            CMP   #4          ;no slot clock
            BEQ   :noslot
            CMP   #5          ;no slot clock
            BEQ   :noslot
            CMP   #6          ;no clock in system
            BEQ   :noslot
            CMP   #10
            BEQ   :noslot
            CMP   #11
            BNE   :slot
            PHA               ; save fake slot
            PHA               ; save fake mode
            JMP   :done

:slot       JSR   print
            DB    1,16,0
            ASC   'Which slot/port does the clock use? [1-7] ',00

            LDX   #7          ; get slot
            JSR   inpnum
            ASL
            ASL
            ASL
            ASL
:noslot     PHA               ;save slot

:done       LDY   #0          ;move the single page
:loop       LDA   (point0),Y  ;source
            STA   (point1),Y  ;destination
            INY
            BNE   :loop

            LDY   #0
            PLA               ;get the slot back
            STA   (point1),Y

            JSR   chinit      ; check for init
            JMP   wrtchg      ; write the changes

:clktbl     DA    0
            DA    thunder
            DA    thunder
            DA    serialpro
            DA    ultra
            DA    noslot
            DA    iicsys
            DA    prodos
            DA    mountain
            DA    versa
            DA    gsclock
            DA    nullclk

