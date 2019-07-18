            LST   RTN
            TTL   'LLUCE - VSM GS Port Driver'
            PAG
*-------------------------------
* GS Port Driver Bios
* Written By Andy Nicholas On July 26, 1987
*-------------------------------
* Jump Table
*-------------------------------
            XC                                  ; Uses 65816 Codes

MODEMDVR    =     *
PROTOCOL    =     *
SLOT        DB    MSLOT*16                      ; Serial Card Slot
MDMSPEED    =     *
INITSPD     DB    3                             ; Initialize Speed
CALLSPD     DB    0                             ; Speed Of Call

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
MDMDTR      BRL   RAISEDTR                      ; Raise Dtr
MDMCBUF     BRL   M_IRQ
MDMQUIT     BRL   M_IRQ

DOINIT      JMP   MSLOT*256+$C000
DOREAD      JMP   MSLOT*256+$C000
DOWRITE     JMP   MSLOT*256+$C000
DOSTATUS    JMP   MSLOT*256+$C000
DOEXT       JMP   MSLOT*256+$C000

* Clear The Input Buffer
*-------------------------------

CLRBUFF     LDA   #<FLUSHLST
            LDX   #>FLUSHLST
            LDY   #0
            BEQ   DOEXT

* Set DTR On GS Serial Port, And Hangup If Needed
*-------------------------------

HANGUP      LDA   #$80                          ; Blow 'em Off (Hangup)
GSDTR       STA   DTRFLAG
            LDA   #<DTRLST
            LDX   #>DTRLST
            LDY   #0
            BEQ   DOEXT

* Init The Serial Port Pascal Locations
*-------------------------------

INIT        LDA   MSLOT*256+$C00D               ; Get Init Address
            STA   DOINIT+1
            LDA   MSLOT*256+$C00E               ; Get Read Address
            STA   DOREAD+1
            LDA   MSLOT*256+$C00F               ; Get Write Address
            STA   DOWRITE+1
            LDA   MSLOT*256+$C010               ; Get Status Address
            STA   DOSTATUS+1
            LDA   MSLOT*256+$C012
            STA   DOEXT+1
            CLC
            RTS

M_IRQ       SEC
            RTS

* Input Data
*-------------------------------

INP         PHX                                 ; Save X
            PHY
            LDX   #MSLOT+$C0                    ; Is There Input Ready?
            LDY   #MSLOT*16
            LDA   #RXREADY
            JSR   DOSTATUS
            BCC   M_INP2                        ; Yes, Read Character

            LDX   #MSLOT+$C0                    ; Yes, Read
            LDY   #MSLOT*16
            JSR   DOREAD
            SEC
M_INP3      PLY
            PLX                                 ; Restore & Return
            RTS

M_INP2      LDA   #0
            BCC   M_INP3

* Output Data
*-------------------------------

OUT         PHX                                 ; Save X
            PHY                                 ; Save Y
            PHA                                 ; Save A
M_OUT2      LDX   #MSLOT+$C0                    ; Ready For Send?
            LDY   #MSLOT*16
            LDA   #TXREADY
            JSR   DOSTATUS
            BCC   M_OUT2                        ; Nope

            PLA                                 ; Get A
            LDX   #MSLOT+$C0
            LDY   #MSLOT*16
            JSR   DOWRITE                       ; Send It
            PLY                                 ; Get Y
            PLX                                 ; Get X
            RTS

* Setup For Call
*-------------------------------

RINGSET     JSR   HANGUP
            LDA   #0                            ; Let Modem Reset
            JSR   MDMWAIT
            JSR   MDMWAIT
            LDA   #0
            JSR   GSDTR
            LDY   INITSPD                       ; Set Init Speed
            JSR   SETSPD
            LDA   #0                            ; Slight Delay (Let Modem Do Init)
            JSR   MDMWAIT
            LDX   #-1
M_RSET2     INX                                 ; Do Pre-Inc
            LDA   INITSTR,X                     ; Get Modem Init String
            BEQ   M_RSET3                       ; We Are Done

            JSR   OUT                           ; Output
            BRA   M_RSET2                       ; Loop (Z-Bit Set After Wait)

M_RSET3     LDA   #6
            STA   COUNTLO
            STA   COUNTHI
M_RSET4     LDY   #-1
M_RSET5     DEY
            BEQ   DECOUNT

            JSR   INP
            BCC   M_RSET5

            AND   #Clrhi
            CMP   #'0'                          ; Check For "0" Result
            BEQ   M_LEAVE
            BNE   M_RSET5

DECOUNT     DEC   COUNTLO
            BNE   M_RSET4

            DEC   COUNTHI
            BNE   M_RSET4
            BEQ   RINGSET

M_LEAVE     JSR   INP                           ; Grab The <Cr> Off The Tail End Of The "0"
            BCC   M_LEAVE

            JSR   CLRBUFF
            LDA   #0
            STZ   BYTCNT                        ; Reset Byte Counter
            STZ   BYTCNT+1
            STZ   BYTCNT+2
            CLC
            RTS                                 ; Return

* Test For A Ring And Handle It
*-------------------------------

RING        JSR   INP                           ; Check For A Char
            BCC   GNORING                       ; Nope...

            AND   #Clrhi                        ; Strip High
            CMP   #'2'                          ; Is It A 'ring'? (Numeric)
            BNE   NOTRING                       ; Nope, Check For Connect Messages

*-------------------------------

M_GRABCR    JSR   INP                           ; Grab The <Cr> Off The Tail End Of The "2"
            BCC   M_GRABCR
            BRL   ANSRING

*-------------------------------

NOTRING     CMP   #'4'                          ; Is It A '40','46','47' Or '48'?
            BEQ   GOTCODE

            CMP   #'5'                          ; Is It A '50'?
            BEQ   GOTCODE                       ; Yes, Check For Carrier Speed
            BNE   GNORING

GOTCODE     STA   CODE1
            LDY   #1
M_2NDCHR    JSR   INP                           ; Get Next Character
            BCC   M_2NDCHR                      ; It MUST Be There

            AND   #Clrhi
            CMP   #cr
            BNE   M_VALID

            CPY   #5
            BNE   M_2NDCHR
            BRA   M_NEXT

M_VALID     STA   CODE1,Y
            INY
            CPY   #6
            BNE   M_2NDCHR

M_NEXT      LDY   #32                           ; Def = 9600 Baud Carrier
            LDX   #4
            LDA   CODE1                         ; Get The First Code Char
            CMP   #'5'                          ; Is It A '50'?
            BNE   NOT9600                       ; If Not, Then Check For Other Carrier Speeds

            LDA   CODE1+1
            CMP   #'0'
            BEQ   SETCSPD

NOT9600     LDY   #1
            LDX   #0
            LDA   CODE1+1                       ; Is It A 300 Baud Carrier?
            CMP   #'0'
            BEQ   SETCSPD                       ; Yes

            LDY   #4
            INX
            CMP   #'6'                          ; Is It A 1200 Baud Carrier?
            BEQ   SETCSPD                       ; Yes

            LDY   #8
            INX
            CMP   #'7'                          ; Is It A 2400 Baud Carrier?
            BEQ   SETCSPD

            LDY   #16
            INX
            CMP   #'8'                          ; Is It A 4800 Baud Carrier?
            BEQ   SETCSPD
GNORING     BRA   NORING

SETCSPD     STY   CARRSPD
            STX   PORTSPD

* Check For Protocol Connections

            LDA   CODE2                         ; Get First Char Of Protocol
            CMP   #'7'                          ; Is It '70'?
            BNE   M_RING3

            LDA   CODE2+1                       ; Get Last Character Of Protocol
            CMP   #'0'                          ; Is It '70'?
            BEQ   M_RING3

            LDA   #$80
            STA   PROTOCOL                      ; Save Indicator Of A Protocol Connection
            LDX   #5
            STX   PORTSPD

*-------------------------------

M_RING3     LDY   PORTSPD                       ; Get The Speed To Open Port At
            JSR   SETSPD                        ; Set The Correct Speed
            LDY   #5
M_RING4     LDA   #0                            ; Let Carrier's Settle
            JSR   MDMWAIT
            DEY
            BNE   M_RING4

            JSR   CLRBUFF                       ; Remove Any Garbage
            SEC                                 ; We Have A Connection!
            RTS

NORING      CLC
            RTS

ANSRING     JSR   ANSWER                        ; The Phone Rang, So Send 'ATA'
            CLC
            RTS

* Wait Routine
*-------------------------------

MDMWAIT     SEC                                 ; From Apple ][+ Ref Man - Pg 147
MDMWAIT2    PHA
MDMWAIT3    SBC   #1
            BNE   MDMWAIT3

            PLA
            SBC   #1
            BNE   MDMWAIT2

            RTS

* Check For Carrier Using Get_Port_Stat Routine
*-------------------------------

M_CHKDCD    PHX
            PHY
            LDA   #<CARRLST
            LDX   #>CARRLST
            LDY   #0
            JSR   DOEXT
            CLC
            LDA   CARRBITS
            AND   CDBYTE
            BEQ   M_NOCAR

            SEC
M_NOCAR     PLY
            PLX
            RTS

* Send Ata To Phone
*-------------------------------

ANSWER      LDA   #$80
            JSR   MDMWAIT
            LDX   #-1
ANSWER2     INX
            LDA   ANSSTR,X                      ; Get Text
            BEQ   ANSWER3                       ; We Are Done

            JSR   OUT                           ; Send It
            BRA   ANSWER2

ANSWER3     RTS

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
            LDX   CARRSPD                       ; Find Caller Speed (X300)
            STX   CALLSPD
            TYA                                 ; Get Y-Reg Into A-Reg
            BNE   TRY1200

            LDX   #<B300
            LDA   #>B300
            BRA   SETBAUD

TRY1200     CMP   #1
            BNE   TRY2400

            LDX   #<B1200
            LDA   #>B1200
            BRA   SETBAUD

TRY2400     CMP   #2
            BNE   TRY4800

            LDX   #<B2400
            LDA   #>B2400
            BRA   SETBAUD

TRY4800     CMP   #3
            BNE   TRY9600

            LDX   #<B4800
            LDA   #>B4800
            BRA   SETBAUD

TRY9600     CMP   #4
            BNE   TR19200

            LDX   #<B9600
            LDA   #>B9600
            BRA   SETBAUD

TR19200     LDX   #<B19200
            LDA   #>B19200
SETBAUD     STX   BAUDRD+1
            STA   BAUDRD+2
            LDX   #MSLOT+$C0
            LDY   #MSLOT*16
            JSR   DOINIT
            LDX   #0
BAUDRD      LDA   -1,X
            BEQ   M_FINISH

            JSR   OUT
            INX
            BRA   BAUDRD

M_FINISH    LDX   #0
M_PILOOP    LDA   PORTINIT,X
            BEQ   M_I_DONE

            JSR   OUT
            INX
            BRA   M_PILOOP

M_I_DONE    LDA   #<OUTBUF
            LDX   #>OUTBUF
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

B300        DB    1
            ASC   '6B'00                        ; Accept 300 Baud
B1200       DB    1
            ASC   '8B'00                        ; Accept 1200 Baud
B2400       DB    1
            ASC   '10B'00                       ; Accept 2400 Baud
B4800       DB    1
            ASC   '12B'00                       ; Accept 4800 Baud
B9600       DB    1
            ASC   '14B'00                       ; Accept 9600 Baud
B19200      DB    1
            ASC   '15B'00                       ; Accept 19200 Baud

PORTINIT    DB    1
            ASC   '0D'                          ; 8 Bits
            DB    1
            ASC   '2P'                          ; No Parity
            DB    1
            ASC   'AD'                          ; Auto-Tabbing
            DB    1
            ASC   'XD'                          ; No Xoff Recognition
            DB    1
            ASC   'FD'                          ; No Find Keyboard
            DB    1
            ASC   'CD'                          ; No Column Overflow
            DB    1
            ASC   'ED'                          ; Echo Disabled
            DB    1
            ASC   'MD'                          ; No Lf Masking
            DB    1
            ASC   'BE'                          ; Buffering Enabled
            DB    1
            ASC   'Z'
            DB    0                             ; No More Control Characters

*-------------------------------

OUTBUF      DB    4                             ; Parameters To Set The
            DB    SetOutBuffer                  ; Output Buffer
            DA    0
            ADRL  BUFFER                        ; Buffer It Where
            DA    2                             ; Buffer 2 Bytes

*-------------------------------

CARRLST     DB    3                             ; Parameter List For
            DB    GetPortStat                   ; Detecting Carrier Drop
            DA    0
CARRBITS    DA    0                             ; Carrier Status Here

*-------------------------------

DTRLST      DB    3                             ; Parameter List For
            DB    SetDTR                        ; Setting DTR
            DA    0
DTRFLAG     DA    0                             ; Bit 7 Affects DTR

*-------------------------------

FLUSHLST    DB    2                             ; Parameter List For Flushing Input Queue
            DB    FlushInQueue
            DA    0

*-------------------------------

CODE1       DS    2                             ; 2 Byte Carrier Speed
CODE2       DS    2                             ; 2 Byte Protocol Format
PORTSPD     DS    1
CARRSPD     DS    1

            DS    $3B0-*+MODEMDVR

BUFFER      DS    15

CDBYTE      DB    DSRSTATE                      ; Mask Dsr Only (0=Connected)

ANSSTR      ASC   'ATA'0D00
            DS    $10-*+ANSSTR                  ; DON'T TOUCH

*INITSTR ASC 'ATS0=1S2=128&S1&D2V1'0D00

INITSTR     ASC   'ATX1S0=0S2=128&C1&D2&S1&K5&Q5E0V0W1M0'0D00
            DS    $30-*+INITSTR                 ; DON'T TOUCH
            LST   OFF

