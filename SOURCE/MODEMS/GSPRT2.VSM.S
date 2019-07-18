            LST   RTN
            TTL   'LLUCE - VSM GS Port 2 Driver'
            PAG
*-------------------------------
* GS Port Driver Bios
* Written By Andy Nicholas On July 26, 1987
*-------------------------------
* Jump Table
*-------------------------------

MODEMDVR    =     *
SLOT        DB    MSLOT*16                        ; Serial Card Slot
MDMSPEED    =     *
INITSPD     DB    0                               ; Initialize Speed
CALLSPD     DB    0                               ; Speed Of Call

BYTCNT      DB    0,0,0

MDMINIT     BRL   INIT
MDMRSET     BRL   RINGSET
MDMRING     BRL   RING
MDMANS      BRL   ANSRING
MDMHANG     BRL   HANGUP
MDMIN       BRL   INP
MDMOUT      BRL   OUT
MDMDCD      BRL   M_CHKDCD
MDMSSPD     BRL   SETSPD
MDMINT      BRL   M_IRQ
MDMDTR      BRL   RAISEDTR                        ; Raise Dtr
MDMCBUF     BRL   M_IRQ
MDMQUIT     BRL   M_IRQ

DOINIT      JMP   MSLOT*256+$C000
DOREAD      JMP   MSLOT*256+$C000
DOWRITE     JMP   MSLOT*256+$C000
DOSTATUS    JMP   MSLOT*256+$C000
DOEXT       JMP   MSLOT*256+$C000

* Init The Serial Port Pascal Locations
*-------------------------------

INIT        LDA   MSLOT*256+$C00D                 ; Get Init Address
            STA   DOINIT+1
            LDA   MSLOT*256+$C00E                 ; Get Read Address
            STA   DOREAD+1
            LDA   MSLOT*256+$C00F                 ; Get Write Address
            STA   DOWRITE+1
            LDA   MSLOT*256+$C010                 ; Get Status Address
            STA   DOSTATUS+1
            LDA   MSLOT*256+$C012
            STA   DOEXT+1
M_IRQ       CLC
            RTS

* Input Data
*-------------------------------

INP         PHX                                   ; Save X
            PHY
            LDX   #MSLOT+$C0                      ; Are We Ready?
            LDY   #MSLOT*16
            LDA   #RXREADY
            JSR   DOSTATUS
            BCC   :INP2                           ; Nope, Exit

            LDX   #MSLOT+$C0                      ; Yes, Read
            LDY   #MSLOT*16
            JSR   DOREAD
            SEC
:INP1       PLY
            PLX                                   ; Restore & Return
            RTS

:INP2       LDA   #0
            BEQ   :INP1

* Output Data
*-------------------------------

OUT         PHX                                   ; Save X
            PHY                                   ; Save Y
            PHA                                   ; Save A
:OUT2       LDX   #MSLOT+$C0                      ; Ready For Send?
            LDY   #MSLOT*16
            LDA   #TXREADY
            JSR   DOSTATUS
            BCC   :OUT2                           ; Nope

            PLA                                   ; Get A
            LDX   #MSLOT+$C0
            LDY   #MSLOT*16
            JSR   DOWRITE                         ; Send It
            PLY                                   ; Get Y
            PLX                                   ; Get X
            RTS

* Setup For Call
*-------------------------------

RINGSET     JSR   HANGUP
            LDA   #0                              ; Let Modem Reset
            JSR   M_WAIT
            JSR   M_WAIT
            LDA   #0
            JSR   GSDTR
            LDY   INITSPD                         ; Set Init Speed
            JSR   SETSPD
            LDA   #0                              ; Slight Delay (Let Modem Do Init)
            JSR   M_WAIT
            LDX   #-1
:RSET2      INX                                   ; Do Pre-Inc
            LDA   INITSTR,X                       ; Get Modem Init String
            BEQ   :RSET3                          ; We Are Done

            JSR   OUT                             ; Output
            BRA   :RSET2                          ; Loop (Z-Bit Set After Wait)

:RSET3      LDA   #6
            STA   COUNTLO
            STA   COUNTHI
:RSET4      LDY   #-1
:RSET5      DEY
            BEQ   :DECOUNT

            JSR   INP
            BCC   :RSET5

            AND   #Clrhi
            CMP   #'0'                            ; Check For "0" Result
            BEQ   :LEAVE
            BNE   :RSET5

:DECOUNT    DEC   COUNTLO
            BNE   :RSET4

            DEC   COUNTHI
            BNE   :RSET4
            BEQ   RINGSET

:LEAVE      JSR   INP                             ; Grab The <Cr> Off The Tail End Of The "0"
            BCC   :LEAVE

            JSR   CLRBUFR
            LDA   #0
            STZ   BYTCNT                          ; Reset Byte Counter
            STZ   BYTCNT+1
            STZ   BYTCNT+2
NORING      CLC
            RTS                                   ; Return

* Test For A Ring And Handle It
*-------------------------------

RING        JSR   INP                             ; Check For A Char
            BCC   NORING                          ; Nope...

            AND   #Clrhi                          ; Strip High
            CMP   #'2'                            ; Is It A 'ring'? (Numeric)
            BNE   NOTRING                         ; Nope, Check For Connect Messages

*-------------------------------

:GRABCR     JSR   INP                             ; Grab The <Cr> Off The Tail End Of The "2"
            BCC   :GRABCR

ANSRING     JSR   ANSWER                          ; The Phone Rang, So Send 'ATA'
            CLC
            RTS

*-------------------------------

NOTRING     CMP   #'4'                            ; Is It A '40','46','47' Or '48'?
            BEQ   :GOTCODE

            CMP   #'5'                            ; Is It A '50'?
            BEQ   :GOTCODE                        ; Yes, Check For Carrier Speed
            BNE   NORING

:GOTCODE    STA   CODE1
:2NDCHAR    JSR   INP                             ; Get Next Character
            BCC   :2NDCHAR                        ; It MUST Be There

            AND   #Clrhi
            CMP   #Cr
            BEQ   :STARTCK

            STA   CODE1+1
            BRA   :2NDCHAR

:STARTCK    LDY   #32                             ; Def = 9600 Baud Carrier
            LDX   #5
            LDA   CODE1                           ; Get The First Code Char
            CMP   #'5'                            ; Is It A '50'?
            BNE   :NOT9600                        ; If Not, Then Check For Other Carrier Speeds

            LDA   CODE1+1
            CMP   #'0'
            BEQ   SETCSPD

:NOT9600    LDY   #1
            LDX   #0
            LDA   CODE1+1                         ; Is It A 300 Baud Carrier?
            CMP   #'0'
            BEQ   SETCSPD                         ; Yes

            LDY   #4
            INX
            CMP   #'6'                            ; Is It A 1200 Baud Carrier?
            BEQ   SETCSPD                         ; Yes

            LDY   #8
            INX
            CMP   #'7'                            ; Is It A 2400 Baud Carrier?
            BEQ   SETCSPD

            LDY   #16
            INX
            CMP   #'8'                            ; Is It A 4800 Baud Carrier?
            BEQ   SETCSPD

            BRL   NORING

SETCSPD     STY   CARRSPD
            STX   PORTSPD
            LDY   #0                              ; Check For Protocol Connections
:SETC2      JSR   INP                             ; Get Next Character
            BCC   :SETC2                          ; It MUST Be There

            AND   #Clrhi
            CMP   #Cr
            BEQ   :STARTCK

            STA   CODE2,Y                         ; Save It...
            INY
            BRA   :SETC2

:STARTCK    LDA   CODE2                           ; Get First Char Of Protocol
            CMP   #'7'                            ; Is It '70'?
            BNE   :RING3

            LDA   CODE2+1                         ; Get Last Character Of Protocol
            CMP   #'0'                            ; Is It '70'?
            BNE   :RING3

            LDX   #5
            STX   PORTSPD

*-------------------------------

:RING3      LDY   PORTSPD                         ; Get The Speed To Open Port At
            JSR   SETSPD                          ; Set The Correct Speed
            LDY   #5
:RING4      LDA   #0                              ; Let Carrier's Settle
            JSR   M_WAIT
            DEY
            BNE   :RING4

            JSR   CLRBUFR                         ; Remove Any Garbage
            SEC                                   ; We Have A Connection!
            RTS

* Clear The Input Buffer
*-------------------------------

CLRBUFR     LDA   #<FLUSH_LIST
            LDX   #>FLUSH_LIST
            LDY   #0
            BRL   DOEXT

* Set DTR On GS Serial Port, And Hangup If Needed
*-------------------------------

HANGUP      LDA   #$80                            ; Blow 'em Off (Hangup)
GSDTR       STA   DTRFLAG
            LDA   #<DTR_LIST
            LDX   #>DTR_LIST
            LDY   #0
            BRL   DOEXT

* Wait Routine
*-------------------------------

M_WAIT      SEC                                   ; From Apple ][+ Ref Man - Pg 147
:WAIT2      PHA
:WAIT3      SBC   #1
            BNE   :WAIT3

            PLA
            SBC   #1
            BNE   :WAIT2

            RTS

* Check For Carrier Using Get_Port_Stat Routine
*-------------------------------

M_CHKDCD    PHX
            PHY
            LDA   #<CARRLIST
            LDX   #>CARRLIST
            LDY   #0
            JSR   DOEXT
            CLC
            LDA   CARRBITS
            AND   CDBYTE
            BEQ   :NOCARR

            SEC
:NOCARR     PLY
            PLX
            RTS

* Send Ata To Phone
*-------------------------------

ANSWER      LDA   #$80
            JSR   M_WAIT
            LDX   #-1
:ANSWER2    INX
            LDA   ANSSTR,X                        ; Get Text
            BEQ   :ANSWER3                        ; We Are Done

            JSR   OUT                             ; Send It
            BRA   :ANSWER2

:ANSWER3    RTS

* Set The Rs-232 Speed [Speed Offset In Y]
*
* 0 =   300 Baud
* 1 =  1200 Baud
* 2 =  2400 Baud
* 3 =  4800 Baud
* 4 =  9600 Baud
* 5 = 19200 Baud
*-------------------------------

SETSPD      PHX
            LDX   CARRSPD                         ; Find Caller Speed (X300)
            STX   CALLSPD
            TYA                                   ; Get Y-Reg Into A-Reg
            BNE   :TRY1200

            LDX   #<BAUD300
            LDA   #>BAUD300
            BRA   :SETBAUD

:TRY1200    CMP   #1
            BNE   :TRY2400

            LDX   #<BAUD1200
            LDA   #>BAUD1200
            BRA   :SETBAUD

:TRY2400    CMP   #2
            BNE   :TRY4800

            LDX   #<BAUD2400
            LDA   #>BAUD2400
            BRA   :SETBAUD

:TRY4800    CMP   #3
            BNE   :TRY9600

            LDX   #<BAUD4800
            LDA   #>BAUD4800
            BRA   :SETBAUD

:TRY9600    CMP   #4
            BNE   :TRY192K

            LDX   #<BAUD9600
            LDA   #>BAUD9600
            BRA   :SETBAUD

:TRY192K    LDX   #<BAUD192K
            LDA   #>BAUD192K

:SETBAUD    STX   :BAUDRD+1
            STA   :BAUDRD+2
            LDX   #MSLOT+$C0
            LDY   #MSLOT*16
            JSR   DOINIT
            LDX   #0
:BAUDRD     LDA   -1,X
            BEQ   :FININIT

            JSR   OUT
            INX
            BRA   :BAUDRD

:FININIT    LDX   #0
:LOOP       LDA   PORTINIT,X
            BEQ   :DONE

            JSR   OUT
            INX
            BRA   :LOOP

:DONE       LDA   #<OUT_BUF
            LDX   #>OUT_BUF
            LDY   #0
            JSR   DOEXT
            PLX
            RTS

* Raise Dtr
*-------------------------------

RAISEDTR    PHX
            PHY
            LDA   #0
            JSR   GSDTR
            PLY
            PLX
            RTS

* Globals
*-------------------------------

COUNTHI     DB    0
COUNTLO     DB    0

BAUD300     DB    1
            ASC   '6B'00                          ; Accept 300 Baud
BAUD1200    DB    1
            ASC   '8B'00                          ; Accept 1200 Baud
BAUD2400    DB    1
            ASC   '10B'00                         ; Accept 2400 Baud
BAUD4800    DB    1
            ASC   '12B'00                         ; Accept 4800 Baud
BAUD9600    DB    1
            ASC   '14B'00                         ; Accept 9600 Baud
BAUD192K    DB    1
            ASC   '15B'00                         ; Accept 19200 Baud

PORTINIT    DB    1
            ASC   '0D'                            ; 8 Bits
            DB    1
            ASC   '2P'                            ; No Parity
            DB    1
            ASC   'AD'                            ; Auto-Tabbing
            DB    1
            ASC   'XD'                            ; No Xoff Recognition
            DB    1
            ASC   'FD'                            ; No Find Keyboard
            DB    1
            ASC   'CD'                            ; No Column Overflow
            DB    1
            ASC   'ED'                            ; Echo Disabled
            DB    1
            ASC   'MD'                            ; No Lf Masking
            DB    1
            ASC   'BE'                            ; Buffering Enabled
            DB    1
            ASC   'Z'
            DB    0                               ; No More Control Characters

*-------------------------------

OUT_BUF     DB    4                               ; Parameters To Set The
            DB    SetOutBuffer                    ; Output Buffer
            DA    0
            ADRL  BUFFER                          ; Buffer It Where
            DA    2                               ; Buffer 2 Bytes

*-------------------------------

CARRLIST    DB    3                               ; Parameter List For
            DB    GetPortStat                     ; Detecting Carrier Drop
            DA    0
CARRBITS    DA    0                               ; Carrier Status Here

*-------------------------------

DTR_LIST    DB    3                               ; Parameter List For
            DB    SetDTR                          ; Setting DTR
            DA    0
DTRFLAG     DA    0                               ; Bit 7 Affects DTR

*-------------------------------

FLUSH_LIST  DB    2                               ; Parameter List For Flushing Input Queue
            DB    FlushInQueue
            DA    0

*-------------------------------

CODE1       DS    2                               ; 2 Byte Code Returned By Modem
CODE2       DS    2
PORTSPD     DS    1
CARRSPD     DS    1

            ASC   'GSPort2 Hayes VSM'

            DS    $3B0-*+MODEMDVR

BUFFER      DS    15

CDBYTE      DB    DSRSTATE                        ; Mask Dsr Only (0=Connected)

ANSSTR      ASC   'ATA'0D00
            DS    $10-*+ANSSTR                    ; DON'T TOUCH

INITSTR     ASC   'ATS0=1S2=128&S1&D2V'0D00
            DS    $30-*+INITSTR                   ; DON'T TOUCH
            LST   OFF

