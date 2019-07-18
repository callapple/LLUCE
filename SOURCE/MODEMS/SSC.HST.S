            LST   RTN
            TTL   'LLUCE - SSC HST Driver'
            PAG
*-------------------------------
* USRobotics HST 19200 Super Serial Driver For LLUCE
* Written By Andy Nicholas On One Cold January Night
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
            LDA   #0                                 ; Slight Delay (Let Modem Do Init)
            JSR   M_WAIT
            LDX   #0
:RSET2      LDA   INITSTR,X                          ; Get Modem Init String
            BEQ   :RSET3

            JSR   OUT                                ; Output
            INX
            BNE   :RSET2

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
            BEQ   RINGSET

:LEAVE      LDA   #0
            STZ   BYTCNT                             ; Reset Byte Counter
            STZ   BYTCNT+1
            STZ   BYTCNT+2
            CLC
            RTS                                      ; Return

JRING       JMP   RINGSET                            ; Extend Branch To Ringset

* Scan For Ring And Handle It
*-------------------------------

RING        JSR   INP                                ; Check For A Char
            BCC   :RING5                             ; Nope...

            AND   #Clrhi                             ; Strip High
            CMP   #'E'
            CLC
            BNE   :RING5                             ; Keep Checking

:RING2      JSR   INP                                ; Check For Char
            BCC   :RING2

            LDY   #0                                 ; Def = 300 Baud
            AND   #Clrhi                             ; Strip High

            CMP   #'R'                               ; Oops, "No Carrier" Message
            BEQ   JRING

            CMP   #Cr                                ; Connect 300
            BEQ   :RING3

            CMP   #'3'                               ; Connect 300
            BEQ   :RING3

            INY
            CMP   #'1'                               ; Connect 1200
            BEQ   :RING3

            INY
            CMP   #'2'                               ; Connect 2400
            BEQ   :RING3

            INY
            CMP   #'4'                               ; Connect 4800
            BEQ   :RING3

            INY
            CMP   #'9'                               ; Connect 9600
            BNE   :RING2

:RING3      JSR   SETSPD                             ; Set The Correct Speed
            LDY   #5
:RING4      LDA   #0                                 ; Let Carrier's Settle
            JSR   M_WAIT
            DEY
            BNE   :RING4

            SEC                                      ; We Have A Connection!
:RING5      RTS

* Send Ata To Phone
*-------------------------------

ANSRING     LDX   #0
:ANSWER2    LDA   ANSSTR,X                           ; Get Text
            BEQ   :ANSWER3                           ; We Are Done

            JSR   OUT                                ; Send It
            INX
            BNE   :ANSWER2                           ; Loop

:ANSWER3    RTS

* Input Data
*-------------------------------

INP         PHX                                      ; Save X
            LDX   SLOT                               ; Get Offset
            LDA   STATUS,X                           ; Get Status
            AND   #SSCRXF
            CLC
            BEQ   :INP2                              ; No Data

            LDA   DATA,X
            SEC
:INP2       PLX                                      ; Restore & Return
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
DATALOC     STA   DATA                               ; Self Modified
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

* Set The Rs232 Speed/19200 Always
*-------------------------------

SETSPD      PHX
            LDX   SLOT                               ; Get Offset
            LDA   SPEED                              ; Get Speed
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

* Handle Interrupts
*-------------------------------

M_IRQ       CLC
            RTS

* Turn On Dtr/Rts
*-------------------------------

HANGUP      LDA   #SSCNOP+SSCTXOFF+SSCRXIRQX         ; Kill DTR, RTS
            HEX   2C
RAISEDTR    LDA   #SSCNOP+SSCTXON+SSCTXIRQX+SSCRXON  ; Turn On DTR, RTS
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

* Global Data Area
*-------------------------------

SPEED       DB    SSCCLK+SSC19200                    ; 19200B All We Have To Worry About

TIMECNT     DB    0                                  ; 1-Second Counter
SAVE_X      DB    0
COUNTLO     DB    -1
COUNTHI     DB    -1

            ASC   'SSC/HST'

            DS    $3B0-*+MODEMDVR

BUFFER      DS    15

CDBYTE      DB    SSCDCD                             ; Mask DCD Only (0=Connected)

ANSSTR      ASC   'ATA'0D00
            DS    $10-*+ANSSTR                       ; DON'T TOUCH

INITSTR     ASC   'ATS0=1S2=128&S1&D2V1'0D00
            DS    $30-*+INITSTR                      ; DON'T TOUCH
            LST   OFF

