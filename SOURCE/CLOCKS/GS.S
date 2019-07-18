             LST   RTN
             TTL   'LLUCE - Apple //Gs Clock'
             PAG
             XC                                ; Uses 65816 Codes

ReadTimeHex  =     $D03
Tool_Entry   =     $E10000

CLOCKDVR     DB    0
CLKMODE      DB    0

GETDATE      JMP   G_DATE
GETTIME      JMP   G_TIME
SETDATE      JMP   S_DATE

*-------------------------------
* Get The Date In Prodos Format
*-------------------------------

G_DATE       JSR   MLI
             DB    Gettime
             DA    0
             LDX   DATE
             LDA   DATE+1
S_DATE       RTS

*-------------------------------
* Get The Current Time
*-------------------------------

G_TIME       CLC
             XCE
             REP   %00110000
             PHA
             PHA
             PHA
             PHA
             LDX   #ReadTimeHex
             JSL   Tool_Entry
             SEC
             XCE
             LDA   #' '                        ; Clear AM/PM
             STA   :TIMESTR+9
             STA   :TIMESTR+10
             PLA                               ; Seconds
             JSR   :BINDEC8
             STA   :TIMESTR+6
             STX   :TIMESTR+7
             PLA                               ; Minutes
             JSR   :BINDEC8
             STA   :TIMESTR+3
             STX   :TIMESTR+4
             LDA   #<:TIMESTR
             STA   :TIMELOC+1
             PLA                               ; Hours
             LDY   #8
             BIT   CLKMODE
             BPL   :RTNTIME

             LDY   #11
             LDX   #'A'                        ; Default To Am
             CMP   #12+1                       ; Is It After Noon?
             BLT   :AM                         ; Nope
             SBC   #12                         ; Subtract For PM
             LDX   #'P'
:AM          STX   :TIMESTR+9
             LDX   #'M'
             STX   :TIMESTR+10
             CMP   #0                          ; If 0, Actually 12
             BNE   :RTNTIME

             LDA   #12
:RTNTIME     JSR   :BINDEC8
             CMP   #'0'                        ; Hour Less Than 10?
             BNE   :DOIT                       ; Nope

             LDA   #' '                        ; Make It A Space
             DEY                               ; String Length Is 1 Less
             INC   :TIMELOC+1                  ; String Start Is 1 More
:DOIT        STA   :TIMESTR
             STX   :TIMESTR+1
             PLA                               ; Year
             PLA                               ; Date
             PLA                               ; Month
             PLA                               ; Reserved
             PLA                               ; Dayofweek
             STA   CLOCKDVR
:TIMELOC     LDX   #<:TIMESTR
             LDA   #>:TIMESTR
             RTS

*-------------------------------
* Translate A Binary To Text [0-99]
*-------------------------------

:BINDEC8     CMP   #60
             BLT   :INRNG
             LDA   #59
:INRNG       LDX   #0
:CNTDN       CMP   #10
             BLT   :MKASC
             SBC   #10
             INX
             BNE   :CNTDN

:MKASC       ADC   #'0'
             PHA
             TXA
             ADC   #'0'
             PLX
             RTS

*-------------------------------
*              '01234567890
:TIMESTR     ASC   '12:00:00   '
             DS    \
             LST   OFF

