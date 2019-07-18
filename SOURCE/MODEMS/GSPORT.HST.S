            LST   RTN
            TTL   'LLUCE - HST GS Port Driver'
            PAG
*-------------------------------
* GS Port Driver Bios
* Written By Andy Nicholas On July 26, 1987
*
* Special Version For The USR HST & 19200 Baud
*-------------------------------
* Jump Table
*-------------------------------

MODEMDVR    =     *
SLOT        DB    MSLOT*16                      ; Serial Card Slot
MDMSPEED    =     *
INITSPD     DB    0                             ; Initialize Speed
CALLSPD     DB    0                             ; Speed Of Call

BYTCNT      DB    0,0,0

MDMINIT     BRL   INIT
MDMRSET     BRL   RINGSET
MDMRING     BRL   RING
MDMANS      BRL   ANSWER
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
M_IRQ       CLC
            RTS

* Setup For Call
*-------------------------------

RINGSET     JSR   HANGUP
            LDA   #0                            ; Let Modem Reset
            JSR   M_WAIT
            JSR   M_WAIT
            LDA   #0
            JSR   GSDTR
            JSR   SETSPD
            LDA   #0                            ; Slight Delay (Let Modem Do Init)
            JSR   M_WAIT
            LDX   #-1
:RSET2      INX                                 ; Do Pre-Inc
            LDA   INITSTR,X                     ; Get Modem Init String
            BEQ   :RSET3                        ; We Are Done

            JSR   OUT                           ; Output
            BRA   :RSET2                        ; Loop (Z-Bit Set After Wait)

:RSET3      LDY   #250                          ; Check 50 Times
:RSET4      DEY   COUNT                         ; Down
            BEQ   RINGSET

            LDA   #30                           ; Delay Slightly
            JSR   M_WAIT
            JSR   INP
            BCC   :RSET4

            AND   #Clrhi
            CMP   #'K'                          ; Check For "OK"
            BNE   :RSET4

            CLC
            RTS                                 ; Return

* Scan For Ring And Handle It
*-------------------------------

RING        JSR   INP                           ; Check For A Char
            BCC   :RING5                        ; Nope...

            AND   #Clrhi                        ; Strip High
            CMP   #'E'
            CLC
            BNE   :RING5                        ; Keep Checking

:RING2      JSR   INP                           ; Check For Char
            BCC   :RING2

            LDY   #0                            ; Def = 300 Baud
            AND   #Clrhi                        ; Strip High
            CMP   #'R'                          ; Oops, "No Carrier" Message
            BEQ   RINGSET

            CMP   #Cr                           ; Connect 300
            BEQ   :RING3

            CMP   #'3'                          ; Connect 300
            BEQ   :RING3

            INY
            CMP   #'1'                          ; Connect 1200
            BEQ   :RING3

            INY
            CMP   #'2'                          ; Connect 2400
            BEQ   :RING3

            INY
            CMP   #'4'                          ; Connect 4800
            BEQ   :RING3

            INY
            CMP   #'9'                          ; Connect 9600
            BNE   :RING2

:RING3      JSR   SETBYTE                       ; Set The Correct Speed Byte
            LDY   #5
:RING4      LDA   #0                            ; Let Carrier's Settle
            JSR   M_WAIT
            DEY
            BNE   :RING4

            SEC                                 ; We Have A Connection!
:RING5      RTS

* Input Data
*-------------------------------

INP         PHX                                 ; Save X
            PHY
            LDX   #MSLOT+$C0                    ; Are We Ready?
            LDY   #MSLOT*16
            LDA   #RXREADY
            JSR   DOSTATUS
            BCC   :INP2                         ; Nope, Exit

            LDX   #MSLOT+$C0                    ; Yes, Read
            LDY   #MSLOT*16
            JSR   DOREAD
            SEC
:INP1       PLY
            PLX                                 ; Restore & Return
            RTS

:INP2       LDA   #0
            BEQ   :INP1

* Output Data
*-------------------------------

OUT         PHX                                 ; Save X
            PHY                                 ; Save Y
            PHA                                 ; Save A
:OUT2       LDX   #MSLOT+$C0                    ; Ready For Send?
            LDY   #MSLOT*16
            LDA   #TXREADY
            JSR   DOSTATUS
            BCC   :OUT2                         ; Nope

            PLA                                 ; Get A
            LDX   #MSLOT+$C0
            LDY   #MSLOT*16
            JSR   DOWRITE                       ; Send It
            PLY                                 ; Get Y
            PLX                                 ; Get X
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

ANSWER      LDX   #-1
:ANSWER2    INX
            LDA   ANSSTR,X                      ; Get Text
            BEQ   :ANSWER3                      ; We Are Done

            JSR   OUT                           ; Send It
            BRA   :ANSWER2

:ANSWER3    RTS

* Set DTR On GS Serial Port, And Hangup If Needed
*-------------------------------

HANGUP      LDA   #$80                          ; Blow 'em Off (Hangup)
GSDTR       STA   DTRFLAG
            LDA   #<DTRLST
            LDX   #>DTRLST
            LDY   #0
            BRL   DOEXT

* Wait Routine
*-------------------------------

M_WAIT      SEC                                 ; From Apple ][+ Ref Man - Pg 147
:WAIT2      PHA
:WAIT3      SBC   #1
            BNE   :WAIT3

            PLA
            SBC   #1
            BNE   :WAIT2

            RTS

* Set The Rs-232 Speed [Speed Offset In Y]
*
* 0 =  300 Baud
* 1 = 1200 Baud
* 2 = 2400 Baud
* 3 = 4800 Baud
* 4 = 9600 Baud
*-------------------------------

SETBYTE     LDA   #1                            ; Find Caller Speed (X300)
            STA   CALLSPD
            CPY   #0                            ; At 300?
            BEQ   :DONE                         ; Yep

            ASL   CALLSPD                       ; Speed = Speed * 2
:SETSPD2    ASL   CALLSPD                       ; Speed = Speed * 2
            DEY
            BNE   :SETSPD2                      ; Loop Until Correct Speed Found

:DONE       RTS

* Reinit The Port For 19200 Baud
*-------------------------------

SETSPD      PHX
            PHY
            LDX   #MSLOT+$C0
            LDY   #MSLOT*16
            JSR   DOINIT
            LDX   #0
:SPD2       LDA   B19200,X
            BEQ   :FINISH

            JSR   OUT
            INX
            BRA   :SPD2

:FINISH     LDX   #0
:SPD3       LDA   PORTINIT,X
            BEQ   :DONE

            JSR   OUT
            INX
            BRA   :SPD3

:DONE       LDA   #<OUTBUF
            LDX   #>OUTBUF
            LDY   #0
            JSR   DOEXT
            PLY
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

* Global Data Area
*-------------------------------

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

            ASC   'GSPort/HST'

            DS    $3B0-*+MODEMDVR

BUFFER      DS    15

CDBYTE      DB    DSRSTATE                      ; Mask Dsr Only (0=Connected)

ANSSTR      ASC   'ATA'0D00
            DS    $10-*+ANSSTR                  ; DON'T TOUCH

INITSTR     ASC   'ATS0=1S2=128&S1&D2V1'0D00
            DS    $30-*+INITSTR                 ; DON'T TOUCH
            LST   OFF

