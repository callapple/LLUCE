            LST   RTN
            TTL   'LLUCE - Multispeed SSC Driver'
            PAG
*-------------------------------
* Multiple Speed Modem Driver
*-------------------------------
* 3/18/88 AEN
*-------------------------------
* Jump Table
*-------------------------------

MODEMDVR    =     *
SLOT        DB    MSLOT*16                           ; Serial Card Slot
MDMSPEED    =     *
INITSPD     DB    0                                  ; Initialize Speed
CALLSPD     DB    0                                  ; Speed Of Call

BYTCNT      DB    0,0,0

MDMINIT     JMP   INIT
MDMRSET     JMP   RINGSET
MDMRING     JMP   RING
MDMANS      JMP   ANSRING
MDMHANG     JMP   HANGUP
MDMIN       JMP   INP
MDMOUT      JMP   OUT
MDMDCD      JMP   M_CHKDCD
MDMSSPD     JMP   SETSPD
MDMINT      JMP   M_IRQ
MDMDTR      JMP   RAISEDTR                           ; Raise Dtr
MDMCBUF     JMP   M_IRQ
MDMQUIT     JMP   M_IRQ

* Init The Serial Card
*-------------------------------

INIT        JSR   HANGUP
            CLC
            TXA
            ADC   #<DATA
            STA   DATALOC+1                          ; Make Into Absolute Save
            PLP
            RTS

* Setup For Call
*-------------------------------

RINGSET     JSR   HANGUP
            LDA   #0                                 ; Let Modem Reset
            JSR   M_WAIT
            JSR   M_WAIT
            JSR   RAISEDTR
            LDY   INITSPD                            ; Set Init Speed
            JSR   SETSPD
            LDA   DATA,X                             ; Clear Data Strobe
            LDA   #0                                 ; Long Delay
            JSR   M_WAIT
            JSR   M_WAIT
            LDX   #-1                                ; Start At -1
:RSET2      INX                                      ; Do Pre-Inc
            LDA   INITSTR,X                          ; Get Modem Init String
            BEQ   :RSET3                             ; We Are Done

            JSR   OUT                                ; Output
            LDA   #$80
            JSR   M_WAIT
            BRA   :RSET2                             ; Loop

:RSET3      LDA   #6
            STA   COUNTLO
            STA   COUNTHI
:RSET4      LDY   #-1
:RSET5      DEY
            BEQ   :DECOUNT

            JSR   INP
            BCC   :RSET5

            AND   #Clrhi
            CMP   #'K'                               ; Check For "OK"
            BEQ   :LEAVE
            BNE   :RSET5

:DECOUNT    DEC   COUNTLO
            BNE   :RSET4

            DEC   COUNTHI
            BNE   :RSET4

            JMP   RINGSET

:LEAVE      LDA   #0
            STZ   BYTCNT                             ; Reset Byte Counter
            STZ   BYTCNT+1
            STZ   BYTCNT+2
            CLC
            RTS                                      ; Return

JRING       JMP   RINGSET                            ; 128 Byte Branches!!

* Scan For Ring And Handle It
*-------------------------------

RING        LDX   SLOT
            LDA   STATUS,X                           ; Do We Have Carrier?
            AND   CDBYTE
            CLC
            BNE   :RING3                             ; Nope

            LDA   DATA,X                             ; Gobble Byte(S)
            LDA   DATA,X
            LDA   #0                                 ; Reset Speed Byte
            STA   SPDATA
            LDY   #0                                 ; Set Default To 300
:RING1      JSR   SETSPD
:RING2      LDA   STATUS,X                           ; We Still Get Carrier
            AND   CDBYTE
            BNE   JRING                              ; Nope

            LDA   STATUS,X                           ; Have A Char Waiting?
            AND   #SSCRXF
            BEQ   :RING2                             ; Nope, Check Carrier

            LDA   STATUS,X                           ; Check Framing
            AND   #SSCFE
            BNE   :RING4                             ; Oops, Framing Error

            LDA   DATA,X                             ; Get Byte (No Framing Error)
            STA   SPDATA                             ; Save Speed Data
            AND   #Clrhi
            CMP   #Cr                                ; Is It A Return?
            BEQ   :RING2A                            ; Yep, We Have The Speed

            AND   #%01110000                         ; Check For Higher Speed
            CMP   #%01110000
            BEQ   :RING5                             ; Go To Up A Notch
            BNE   :RING2                             ; Loop Back

:RING2A     SEC                                      ; All Is Well, Connect
:RING3      RTS

:RING4      LDA   DATA,X                             ; Empty Uart
            LDA   DATA,X
            LDA   SPDATA                             ; Get Last "Legal" Byte
            AND   #%11100000                         ; Check For 300 Baud Overrun
            CMP   #%11100000
            BEQ   :RING5                             ; Looks Like A Higher Speed

            LDY   CURSPD                             ; What Speed
            BEQ   :RING2                             ; Hmm, Cant Go Below 300

            DEY
            BRA   :RING1                             ; Set New Speed, Check Again

:RING5      LDY   CURSPD                             ; We At 2400?
            CPY   INITSPD                            ; As High As We Can Go?
            BEQ   :RING2                             ; Yep, Cant Go Any Higher

            INY
            BRA   :RING1                             ; Set New Speed, Up 1 Notch

* Send Ata To Phone
*-------------------------------

ANSRING     LDX   #0
:ANSWER2    LDA   ANSSTR,X                           ; Get Text
            BEQ   :ANSWER3                           ; We Are Done

            JSR   OUT                                ; Send It
            LDA   #$80
            JSR   M_WAIT
            INX
            BNE   :ANSWER2                           ; Loop

:ANSWER3    RTS

* Input Data
*-------------------------------

INP         STX   SAVE_X                             ; Save X
            LDX   SLOT                               ; Get Offset
            LDA   STATUS,X                           ; Get Status
            AND   #SSCRXF
            CLC
            BEQ   :INP2                              ; No Data

            LDA   DATA,X
            SEC
:INP2       LDX   SAVE_X                             ; Restore & Return
            RTS

* Output Data
*-------------------------------

OUT         PHX                                      ; Save X
            DEC   TIMECNT                            ; Count Down 1 Section
            BNE   :OUT1

            INC   BYTCNT                             ; 1 Second Gone By
            BIT   BYTCNT
            BVC   :OUT1

            STZ   BYTCNT                             ; Reset Seconds
            INC   BYTCNT+1                           ; 1 Minute Gone By
            BIT   BYTCNT+1
            BVC   :OUT1

            STZ   BYTCNT+1                           ; Reset Minutes
            INC   BYTCNT+2                           ; 1 Hour Gone By
:OUT1       LDX   SLOT
            PHA
:OUT2       LDA   STATUS,X                           ; Check Status
            AND   #SSCTXE
            BEQ   :OUT2                              ; Loop Until Ready

            PLA
DATALOC     STA   DATA                               ; Output Byte
            PLX
            RTS

* Check For Carrier
*-------------------------------

M_CHKDCD    PHX                                      ; Don't Kill Any Reg's
            PHA
            LDX   SLOT                               ; Get Offset
            LDA   STATUS,X
            AND   CDBYTE                             ; Check Carrier
            CLC
            BNE   :CHKDCD2

            SEC
:CHKDCD2    PLA                                      ; Restore All & Return
            PLX
            RTS

* Set The Rs-232 Speed [Speed Offset In Y]
*-------------------------------

SETSPD      STY   CURSPD                             ; Save Current Speed
            PHX
            LDX   SLOT                               ; Get Offset
            LDA   SPEED,Y                            ; Get Speed
            STA   CONTROL,X                          ; Set Speed
            LDA   #1                                 ; Find Caller Speed (X300)
            STA   CALLSPD
            CPY   #0                                 ; At 300?
            BEQ   :SETSPD3                           ; Yep

            ASL   CALLSPD                            ; Speed = Speed * 2
:SETSPD2    ASL   CALLSPD                            ; Speed = Speed * 2
            DEY
            BNE   :SETSPD2                           ; Loop Until Correct Speed Found

:SETSPD3    PLX                                      ; Restore & Return
            RTS

* Setup Interrupt Routine
*-------------------------------

M_IRQ       CLC
            RTS

* Turn On Dtr/Rts
*-------------------------------

HANGUP      LDA   #SSCNOP+SSCTXOFF+SSCRXIRQX         ; Kill DTR, RTS
            HEX   2C
RAISEDTR    LDA   #SSCNOP+SSCTXON+SSCRXIRQX+SSCRXON  ; Turn On DTR, RTS
            PHP
            SEI
            LDX   SLOT
            STA   COMMAND,X
            LDA   DATA,X                             ; Clear Data Strobe
            LDA   STATUS,X
            PLP
            RTS

* Wait Routine
*-------------------------------

M_WAIT      SEC                                      ; From Apple ][+ Ref Man - Pg 147
:WAIT2      PHA
:WAIT3      SBC   #1
            BNE   :WAIT3

            PLA
            SBC   #1
            BNE   :WAIT2

            RTS

* Available Speeds
*-------------------------------

SPEED       DB    SSCCLK+SSC300
            DB    SSCCLK+SSC1200
            DB    SSCCLK+SSC2400
            DB    SSCCLK+SSC4800
            DB    SSCCLK+SSC9600
            DB    SSCCLK+SSC19200

COUNTLO     DB    0
COUNTHI     DB    0
CURSPD      DB    0                                  ; Current Speed

TIMECNT     DB    0                                  ; 1-Second Counter
SPDATA      DB    0                                  ; Speed Data
SAVE_X      DB    0

            ASC   'MultiSpd'

            DS    $3B0-*+MODEMDVR

BUFFER      DS    15

CDBYTE      DB    SSCDCD                             ; Mask DCD Only (0=Connected)

ANSSTR      ASC   'ATA'0D00
            DS    $10-*+ANSSTR                       ; DON'T TOUCH

INITSTR     ASC   'ATS0=1S2=128&S1&D2V1'0D00
            DS    $30-*+INITSTR                      ; DON'T TOUCH
            LST   OFF

