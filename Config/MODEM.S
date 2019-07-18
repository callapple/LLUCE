            LST   OFF
            TR
            TR    ADR
*-------------------------------
* Reconfigure modem
*-------------------------------

            REL
cr          =     $D
point0      =     $11
point1      =     $14
point3      =     $FD
lnbuf       =     $200
mdmdrv      =     $B00
initbuf     =     $1800
ansbuf      =     $1830
cdbyte      =     $10BF       ; carrier detect byte
ansstr      =     $10C0       ; modem answer string
initstr     =     $10D0       ; modem init string

            DSK   REL/MODEM

TopBox      EXT               ; routines external to this file
print       EXT
cls         EXT
start       EXT
escape      EXT
inpnum      EXT
chinit      EXT
wrtchg      EXT
init        EXT
do_init     EXT
maxlen      EXT
inpmode     EXT
cout        EXT
inpln       EXT


nullmdm     EXT               ;null modem driver
cat103      EXT               ;300 baud cat driver
cat212      EXT               ;1200 baud cat driver
mm2         EXT               ;micromodem II driver
ssc         EXT               ;super serial driver
gsport1     EXT               ;location for gs port driver
gsport2     EXT               ;loc for gs port slot #2
singlespd   EXT               ;single speed driver
multispd    EXT               ;multi-speed <return> driver
nocar       EXT               ;no carrier driver

*-------------------------------
* init strings

usr2400     EXT               ;init string for usr 2400
usr9600     EXT               ;init string for usr 9600
cts         EXT               ;init string for cts 2424
apl1200     EXT
hayes1200   EXT
hayes2400   EXT
pro2400     EXT
generic     EXT
epic        EXT

re_mdm      ENT
            BIT   init
            BMI   :re_mdmx

            LDX   #<start     ; setup esc handler
            LDA   #>start
            JSR   escape
            JMP   :re_mdm0

:re_mdmx    LDX   #<do_init
            LDA   #>do_init   ; setup aux esc handler
            JSR   escape

:re_mdm0    LDA   #1          ; set input length at 1
            STA   maxlen
            LDA   #%10010000
            STA   inpmode

:re_mdm3    JSR   TopBox
            JSR   print
            DB    1,2,26
            ASC   '- Reconfigure Modem Driver -'
            DB    1,4,5
            ASC   'Please refer to Appendix A of your user'
            ASC   ' manual for more information.'00

            JSR   cls
            JSR   print
            DB    1,7,0
            ASC   ' 1 - No Modem/Local mode                '
            ASC   ' External Modem Drivers'0D0D
            ASC   ' Internal Modem Drivers                 '
            ASC   ' 8 - Super Serial Card driver'0D
            ASC   '                                        '
            ASC   ' 9 - Apple IIgs Serial Port driver'0D
            ASC   ' 2 - Apple-Cat 103 - 300 baud           '
            ASC   '10 - Single Speed SSC driver'0D
            ASC   ' 3 - Apple-Cat 212 - 300/1200 baud      '
            ASC   '11 - Multiple Speed SSC driver'0D
            ASC   ' 4 - DC Hayes Micromodem II             '
            ASC   '12 - No Carrier SSC driver'0D
            ASC   ' 5 - SSM Modemcard 300'0D
            ASC   ' 6 - Zoom Modem IIe'0D
            ASC   ' 7 - Epic 2400 Classic II'0D0D
            ASC   'Which? [1-12] '00

            LDX   #12         ; get serial device
            JSR   inpnum
            STA   serialtype  ;save the device type

            ASL               ;point0 points to the
            TAX               ;serial device driver
            LDA   devtable,X
            STA   point0
            INX
            LDA   devtable,X
            STA   point0+1

            LDA   #<mdmdrv    ;tell it to move the modem
            STA   point1      ;driver
            LDA   #>mdmdrv
            STA   point1+1

            LDA   #12         ;default is generic
            ASL               ;point init string to the
            TAX               ;right place
            LDA   strtable,X
            STA   point3
            INX
            LDA   strtable,X
            STA   point3+1

            LDA   serialtype  ;is it internal?
            CMP   #8
            BCS   getinit     ;nope, get an init string
            CMP   #7          ;was it the Epic internal?
            BEQ   :epic24     ;yes, set for epic string
            CMP   #1          ;nullmodem?
            BNE   :internal   ;nope, just internal
            PHA               ;push garbage data
            PHA
            JMP   movepage    ;move & fix into place

:internal   JMP   getslot     ;must have been internal, skip next

:epic24     LDA   #1          ;default for epic is &s1&d2
            ASL               ;point init string to the
            TAX               ;right place
            LDA   strtable,X
            STA   point3
            INX
            LDA   strtable,X
            STA   point3+1
            JMP   setinit

*-------------------------------
* get the init string for the modem

getinit     JSR   cls
            JSR   print
            DB    1,7,0
            ASC   'Choose Modem:'0D0D
            ASC   ' 1 - Epic 2400 Plus'0D
            ASC   ' 2 - USRobotics Courier 2400'0D
            ASC   ' 3 - USRobotics Courier HST'0D
            ASC   ' 4 - CTS 2424'0D
            ASC   ' 5 - Apple Modem 1200'0D
            ASC   ' 6 - Prometheus Promodem 1200'0D
            ASC   ' 7 - Prometheus Promodem 2400'0D
            ASC   ' 8 - Novation SmartCat'0D
            ASC   ' 9 - Novation Professional 2400'0D
            ASC   '10 - Hayes 1200'0D
            ASC   '11 - Hayes 2400'0D
            ASC   !12         -
            ASC   'Which? [1-12] '00

            LDX   #12
            JSR   inpnum
            STA   modemtype

            ASL               ;point init string to the
            TAX               ;right place
            LDA   strtable,X
            STA   point3
            INX
            LDA   strtable,X
            STA   point3+1

*-------------------------------

setinit     JSR   cls
            JSR   print
            DB    1,7,0
            ASC   'The initialization string for this modem is: '0D0D00

            LDY   #0
:loop       LDA   (point3),Y
            STA   initbuf,Y
            BEQ   :done
            JSR   cout
            INY
            BNE   :loop

:done       JSR   print
            HEX   0D
            ASC   'Press [RETURN] to accept this as'
            ASC   ' default, or enter a new init string.'0D
            ASC   ':'00

            LDA   #39         ; only allow 39 chars
            STA   maxlen
            LDA   #%10100000
            STA   inpmode     ;ascii
            JSR   inpln       ; get the input
            LDY   lnbuf
            CPY   #cr
            BEQ   getans      ; use default

            LDY   #-1
:loop2      INY               ;move the typed init string
            LDA   lnbuf,Y
            STA   initbuf,Y
            CMP   #cr
            BNE   :loop2

            INY
            LDA   #0
            STA   initbuf,Y

*-------------------------------
* get the answer string

getans      JSR   cls
            JSR   print
            DB    1,7,0
            ASC   'The default answer string for this modem is: '0D0D00

            LDY   #0
:loop       LDA   atastr,Y
            STA   ansbuf,Y
            BEQ   :done
            JSR   cout
            INY
            BNE   :loop

:done       JSR   print
            HEX   0D
            ASC   'Press [RETURN] to accept this,'
            ASC   ' or enter a new answer string.'0D
            ASC   ':'00

            LDA   #15         ; only allow 15 chars
            STA   maxlen
            JSR   inpln       ; get the input
            LDY   lnbuf
            CPY   #cr
            BEQ   getdcd      ; use default

            LDY   #-1
:loop2      INY               ;move the typed answer string
            LDA   lnbuf,Y
            STA   ansbuf,Y
            CMP   #cr
            BNE   :loop2

            INY
            LDA   #0
            STA   ansbuf,Y

*-------------------------------
* get the dcd drop type

getdcd      JSR   print
            HEX   0D0D
            ASC   'What type of carrier detect should the'
            ASC   ' driver use?'0D0D
            ASC   ' 1 - DSR Carrier Detect [Normal]'0D
            ASC   ' 2 - DCD Carrier Detect'0D0D
            ASC   'Which? [1-2] '00

            LDX   #2
            JSR   inpnum
            STA   cdtype

*-------------------------------
* get the proper slot

getslot     JSR   cls
            LDA   serialtype
            CMP   #9
            BEQ   :gsport

            JSR   print
            DB    1,7,0
            ASC   'Which slot should the modem driver use? [1-7] '00
            LDX   #7
            JMP   :over

:gsport     JSR   print
            DB    1,7,0
            ASC   'Which Serial Port? [1-2] '00

            LDX   #2
:over       JSR   inpnum
            PHA

            LDX   serialtype
            cpx   #9          ;was it the IIgs serial port?
            BNE   :notgsport  ;nope

            CMP   #1          ;was it port #1?
            BNE   :port2      ;nope, must be port 2

            LDA   #<gsport1   ;move gs port, slot 1
            STA   point0
            LDA   #>gsport1
            STA   point0+1
            JMP   :notgsport

:port2      LDA   #<gsport2   ;move gs port slot 2
            STA   point0
            LDA   #>gsport2
            STA   point0+1

:notgsport  LDA   serialtype  ;was it an internal?
            CMP   #7
            BCS   :external   ;no, init baud needed
            JMP   :internal   ;yes, init spd not needed

:external   JSR   print
            DB    1,10,0
            ASC   'At what baud rate should the port/card be initialized?'0D
            ASC   '(Choose the maximum baud rate of your modem)'0D0D
            ASC   ' 1 -   300 baud'0D
            ASC   ' 2 -  1200 baud'0D
            ASC   ' 3 -  2400 baud'0D
            ASC   ' 4 -  4800 baud'0D
            ASC   ' 5 -  9600 baud'0D
            ASC   ' 6 - 19200 baud'0D0D
            ASC   'Which? [1-6] '00

            LDX   #6
            JSR   inpnum
:internal   PHA

movepage    LDX   #3          ;move 3 illustrious pages
:loop2      LDY   #0
:loop       LDA   (point0),Y  ;source
            STA   (point1),Y  ;destination
            INY
            BNE   :loop
            INC   point0+1
            INC   point1+1
            DEX
            BNE   :loop2

            LDA   mdmdrv
            STA   point1+1
            LDY   #1
            PLX               ;get init speed
            DEX               ;one less
            TXA
            STA   (point1),Y  ;save it

            dey
            PLA               ;get the slot
            ASL
            ASL
            ASL
            ASL               ;a := a*16
            STA   (point1)    ;store the slot

            DEC   cdtype
            LDA   serialtype
            CMP   #9          ;was it the gs?
            BNE   :notgs      ;nope, go there, SSC

            LDA   cdtype      ;get drop type
            BNE   :notgsdsr   ;dcd wanted, so stick it
            LDA   #$20        ;else use dsr drop
            STA   cdbyte
            BNE   copyans

:notgsdsr   LDA   #$08        ;setup for dcd drop
            STA   cdbyte
            BNE   copyans

:notgs      LDA   cdtype      ;ssc
            BNE   :notdsr     ;dcd drop wanted, go there
            LDA   #%01000000  ;check only dsr (normal)
            STA   cdbyte
            BNE   copyans

:notdsr     LDA   #%00100000  ;otherwise check DCD
            STA   cdbyte

*-------------------------------

copyans     LDY   #0
:loop       LDA   ansbuf,Y    ;copy the answer string
            STA   ansstr,Y
            BEQ   copyinit
            INY
            BNE   :loop

copyinit    LDY   #0          ;copy the init string
:loop       LDA   initbuf,Y
            STA   initstr,Y
            BEQ   :writeit
            INY
            BNE   :loop

:writeit    JSR   chinit      ; check for init
            JMP   wrtchg      ; write the changes

cdtype      DB    0
modemtype   DB    0
serialtype  DB    0

*-------------------------------
* modem drivers

devtable    DA    0           ;extra for offset 0
            DA    nullmdm     ;null modem driver
            DA    cat103      ;300 baud cat driver
            DA    cat212      ;1200 baud cat driver
            DA    mm2         ;micromodem II driver
            DA    mm2         ;SSM modemcard
            DA    mm2         ;networker
            DA    ssc         ;epic 2400 classic
            DA    ssc         ;super serial driver
            DA    gsport2     ;location for gs port driver
            DA    singlespd   ;single speed driver
            DA    multispd    ;multi-speed <return> driver
            DA    nocar       ;no carrier 300 baud driver

strtable    DA    0
            DA    epic
            DA    usr2400
            DA    usr9600
            DA    cts
            DA    apl1200
            DA    usr2400
            DA    usr2400
            DA    usr2400
            DA    pro2400
            DA    hayes1200
            DA    hayes2400
            DA    generic

atastr      ASC   'ATA'0D00

