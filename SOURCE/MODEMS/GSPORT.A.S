            LST   RTN
            TTL   'LLUCE - GS Port Driver'
            PAG
*-------------------------------
* GS Port Driver Bios
* Written By Andy Nicholas On July 26, 1987
*-------------------------------
* Jump Table
*-------------------------------
            XC                              ; Uses 65816 Code

            ORG   $B00

MODEMDVR    =     *
SLOT        DB    MSLOT*16                  ; Serial Card Slot
MDMSPEED    =     *
INITSPD     DB    0                         ; Initialize Speed
CALLSPD     DB    0                         ; Speed Of Call

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
MDMDTR      BRL   RAISEDTR                  ; Raise Dtr
MDMCBUF     BRL   M_IRQ
MDMQUIT     BRL   M_IRQ

DOINIT      JMP   MSLOT*256+$C000
DOREAD      JMP   MSLOT*256+$C000
DOWRITE     JMP   MSLOT*256+$C000
DOSTATUS    JMP   MSLOT*256+$C000
DOEXT       JMP   MSLOT*256+$C000

* Init The Serial Port Pascal Locations
*-------------------------------

INIT        LDA   oINIT                     ; Get Init Address
            STA   DOINIT+1
            LDA   oREAD                     ; Get Read Address
            STA   DOREAD+1
            LDA   oWRITE                    ; Get Write Address
            STA   DOWRITE+1
            LDA   oSTATUS                   ; Get Status Address
            STA   DOSTATUS+1
            LDA   oCONTROL
            STA   DOEXT+1
M_IRQ       CLC
            RTS

* Input Data
*-------------------------------

INP         PHX                             ; Save X
            PHY
            LDX   #MSLOT+$C0                ; Are We Ready?
            LDY   #MSLOT*16
            LDA   #RXREADY
            JSR   DOSTATUS
            BCC   :INP2                     ; Nope, Exit

            LDX   #MSLOT+$C0                ; Yes, Read
            LDY   #MSLOT*16
            JSR   DOREAD
            SEC
:INP1       PLY
            PLX                             ; Restore & Return
            RTS

:INP2       LDA   #0
            BEQ   :INP1

* Output Data
*-------------------------------

OUT         PHX                             ; Save X
            PHY                             ; Save Y
            PHA                             ; Save A
:OUT2       LDX   #MSLOT+$C0                ; Ready For Send?
            LDY   #MSLOT*16
            LDA   #TXREADY
            JSR   DOSTATUS
            BCC   :OUT2                     ; Nope

            PLA                             ; Get A
            LDX   #MSLOT+$C0
            LDY   #MSLOT*16
            JSR   DOWRITE                   ; Send It
            PLY                             ; Get Y
            PLX                             ; Get X
            RTS

* Init Modem For Ring
*-------------------------------

RINGSET     JSR   HANGUP
            LDA   #0                        ; Let Modem Reset
            JSR   M_WAIT
            JSR   M_WAIT
            LDA   #0
            JSR   GSDTR
            LDY   INITSPD                   ; Set Init Speed
            JSR   SETSPD
            LDA   #0                        ; Slight Delay (Let Modem Do Init)
            JSR   M_WAIT
            LDX   #-1
:RSET2      INX                             ; Do Pre-Inc
            LDA   INITSTR,X                 ; Get Modem Init String
            BEQ   :RSET3                    ; We Are Done

            JSR   OUT                       ; Output
            BRA   :RSET2                    ; Loop (Z-Bit Set After Wait)

:RSET3      LDA   #6
            STA   COUNTLO
            STA   COUNTHI
:RSET4      LDY   #-1
:RSET5      DEY
            BEQ   :DECOUNT

            JSR   INP
            BCC   :RSET5

            AND   #Clrhi
            CMP   #'0'                      ; Check For "0" (Numeric)
            BEQ   :LEAVE
            BNE   :RSET5

:DECOUNT    DEC   COUNTLO
            BNE   :RSET4

            DEC   COUNTHI
            BNE   :RSET4
            BEQ   RINGSET

:LEAVE      JSR   INP                       ; Grab The <Cr> Off The Tail End Of The "0"
            BCC   :LEAVE

            JSR   CLRBUFF
            LDA   #0
            STZ   BYTCNT                    ; Reset Byte Counter
            STZ   BYTCNT+1
            STZ   BYTCNT+2
            CLC
            RTS                             ; Return

* Test For A Ring And Handle It
*-------------------------------

RING        JSR   INP                       ; Check For A Char
            BCC   :NORING                   ; Nope...

            AND   #Clrhi                    ; Strip High
            CMP   #'2'                      ; Is It A 'ring'? (Numeric)
            BNE   :NOTRING                  ; Nope, Check For Connect Messages

*-------------------------------

:GRABCR     JSR   INP                       ; Grab The <Cr> Off The Tail End Of The "2"
            BCC   :GRABCR
            BCS   ANSRING

*-------------------------------

:NOTRING    CMP   #'1'                      ; Is It A '1' Or '10' Or '11' Or '12' Or '14'?
            BEQ   :GOTCODE                  ; Yes, Save It

            CMP   #'5'                      ; Is It Connect 1200?
            BNE   :NORING                   ; Nope

:GOTCODE    STA   CODE
:2NDCHAR    JSR   INP                       ; Second Character Will ALWAYS Be There
            BCC   :2NDCHAR

            AND   #Clrhi                    ; Strip High
            CMP   #Cr                       ; But Might Be A <Cr>
            BNE   :MULTCOD

*-------------------------------

            LDY   #0                        ; Connect 300?
            LDA   CODE
            CMP   #'1'
            BEQ   :RING3

            INY
            CMP   #'5'                      ; Connect 1200?
            BEQ   :RING3                    ; Nope, Unknown Code, Keep Checking
            BNE   :NORING

*-------------------------------

:MULTCOD    STA   CODE+1
            LDY   #2                        ; Def = 2400 Baud
            LDA   CODE                      ; Get The First Code Char
            CMP   #'1'                      ; Must Be A One
            BNE   :NORING                   ; If Not, Then Keep Trying

            LDA   CODE+1                    ; Is It 2400?
            CMP   #'0'
            BEQ   :RING3

            INY
            CMP   #'1'                      ; Is It 4800?
            BEQ   :RING3

            INY
            CMP   #'2'                      ; Is It 9600
            BEQ   :RING3

            INY
            CMP   #'4'                      ; Is It 19200?
            BEQ   :RING3

            DEY
            CMP   #'7'                      ; Is It 9600/ARQ?
            BEQ   :RING3

            DEY                             ; No 4800/Arq
            DEY
            CMP   #'6'
            BEQ   :RING3                    ; 2400/ARQ

            DEY
            CMP   #'5'                      ; 1200/ARQ
            BEQ   :RING3
            BNE   :NORING

*-------------------------------

:RING3      JSR   SETSPD                    ; Set The Correct Speed
            LDY   #5
:RING4      LDA   #0                        ; Let Carrier's Settle
            JSR   M_WAIT
            DEY
            BNE   :RING4

            JSR   CLRBUFF
            SEC                             ; We Have A Connection!
            RTS

:NORING     CLC
            RTS

ANSRING     JSR   ANSWER                    ; The Phone Rang, So Send 'ATA'
            CLC
            RTS

* Clear The Input Buffer
*-------------------------------

CLRBUFF     LDA   #<FLUSHLST
            LDX   #>FLUSHLST
            LDY   #0
            JMP   DOEXT

* Set DTR On GS Serial Port, And Hangup If Needed
*-------------------------------

HANGUP      LDA   #Hibit                    ; Blow 'em Off (Hangup)
GSDTR       STA   DTRFLAG
            LDA   #<DTRLST
            LDX   #>DTRLST
            LDY   #0
            JMP   DOEXT

* Wait Routine
*-------------------------------

M_WAIT      SEC                             ; From Apple ][+ Ref Man - Pg 147
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
            LDA   #<CARRLST
            LDX   #>CARRLST
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
            LDA   ANSSTR,X                  ; Get Text
            BEQ   :ANSWER3                  ; We Are Done

            JSR   OUT                       ; Send It
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
            PHY
            LDA   #1                        ; Find Caller Speed (X300)
            STA   CALLSPD
            CPY   #0                        ; At 300?
            BEQ   :DO_BAUD                  ; Yep

            ASL   CALLSPD                   ; Speed = Speed * 2
:SETSPD2    ASL   CALLSPD                   ; Speed = Speed * 2
            DEY
            BNE   :SETSPD2                  ; Loop Until Correct Speed Found

:DO_BAUD    PLA                             ; Get Y-Reg
            ASL   A
            TAY
            LDA   BAUDS,Y
            STA   :BAUDRD+1
            LDA   BAUDS+1,Y
            STA   :BAUDRD+2
            LDX   #MSLOT+$C0
            LDY   #MSLOT*16
            JSR   DOINIT
            LDX   #0
:BAUDRD     LDA   -1,X
            BEQ   :FINISH

            JSR   OUT
            INX
            BRA   :BAUDRD

:FINISH     LDX   #0
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

*-------------------------------

BAUDS       DA    B300
            DA    B1200
            DA    B2400
            DA    B4800
            DA    B9600
            DA    B19200

*-------------------------------
* Raise Dtr

RAISEDTR    PHX
            PHY
            LDA   #0
            JSR   GSDTR
            PLY
            PLX
            RTS

* Table Of Speeds And Other Important Stuff
*-------------------------------

COUNTHI     DB    0
COUNTLO     DB    0

B300        DB    1
            ASC   '6B'00                    ; Accept 300 Baud
B1200       DB    1
            ASC   '8B'00                    ; Accept 1200 Baud
B2400       DB    1
            ASC   '10B'00                   ; Accept 2400 Baud
B4800       DB    1
            ASC   '12B'00                   ; Accept 4800 Baud
B9600       DB    1
            ASC   '14B'00                   ; Accept 9600 Baud
B19200      DB    1
            ASC   '15B'00                   ; Accept 19200 Baud

PORTINIT    DB    1
            ASC   '0D'                      ; 8 Bits
            DB    1
            ASC   '2P'                      ; No Parity
            DB    1
            ASC   'AD'                      ; Auto-Tabbing
            DB    1
            ASC   'XD'                      ; No Xoff Recognition
            DB    1
            ASC   'FD'                      ; No Find Keyboard
            DB    1
            ASC   'CD'                      ; No Column Overflow
            DB    1
            ASC   'ED'                      ; Echo Disabled
            DB    1
            ASC   'MD'                      ; No Lf Masking
            DB    1
            ASC   'BE'                      ; Buffering Enabled
            DB    1
            ASC   'Z'
            DB    0                         ; No More Control Characters

*-------------------------------

OUT_BUF     DB    4                         ; Parameters To Set The
            DB    SetOutBuffer              ; Output Buffer
            DA    0
            ADRL  BUFFER                    ; Buffer It Where
            DA    2                         ; Buffer 2 Bytes

*-------------------------------

CARRLST     DB    3                         ; Parameter List For
            DB    GetPortStat               ; Detecting Carrier Drop
            DA    0
CARRBITS    DA    0                         ; Carrier Status Here

*-------------------------------

DTRLST      DB    3                         ; Parameter List For
            DB    SetDTR                    ; Setting DTR
            DA    0
DTRFLAG     DA    0                         ; Bit 7 Affects DTR

*-------------------------------

FLUSHLST    DB    2                         ; Parameter List For Flushing Input Queue
            DB    FlushInQueue
            DA    0

*-------------------------------

CODE        DS    2                         ; 2 Byte Code Returned By Modem

            ASC   'GSPort'
            DB    MSLOT!$30

            DS    $3B0-*+MODEMDVR

BUFFER      DS    15

CDBYTE      DB    DSRSTATE                  ; Mask Dsr Only (0=Connected)

ANSSTR      ASC   'ATA'0D00
            DS    $10-*+ANSSTR              ; DON'T TOUCH

INITSTR     ASC   'ATS0=1S2=128&S1&D2V'0D00
            DS    $30-*+INITSTR             ; DON'T TOUCH
            LST   OFF

