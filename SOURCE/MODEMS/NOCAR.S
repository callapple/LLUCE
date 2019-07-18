            LST   RTN
            TTL   'LLUCE - No Carrier SSC Driver'
            PAG
*-------------------------------
* No Carrier Driver
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
            LDA   #0
            JSR   M_WAIT
            JSR   M_WAIT
            JSR   RAISEDTR
            LDY   INITSPD                            ; Set Init Speed
            JSR   SETSPD
            LDA   DATA,X                             ; Clear Data Strobe
:RSET1      LDA   #0                                 ; Slight Delay (Let Modem Do Init)
            JSR   M_WAIT
            JSR   M_WAIT
            JSR   CHKOK                              ; Is Modem Out There And Ready?
            BCS   :RSET2                             ; Yep

            LDX   #INITSTR-ANSSTR                    ; Print Modem Init String
            JSR   PRSTR
            BRA   :RSET1

:RSET2      LDA   #0
            STA   BYTCNT                             ; Reset Byte Counter
            STA   BYTCNT+1
            STA   BYTCNT+2
            CLC
            RTS                                      ; Return

RSET5       JMP   RINGSET                            ; Extend A Branch

* Scan For Ring And Handle It
*-------------------------------

RING        LDA   #5                                 ; Make Sure Timer Never Triggers
            STA   CDCOUNT+2
            JSR   INP                                ; Check For A Char
            BCC   :RING5                             ; Nope...

            AND   #Clrhi                             ; Strip High
            CMP   #'3'
            BEQ   RSET5                              ; No Carrier

            LDY   #0
            CMP   #'1'                               ; Connect 300
            BEQ   :RING3

            INY
            CMP   #'5'                               ; Connect 1200
            BEQ   :RING3

            INY
            CMP   #'6'                               ; Connect 2400
            BEQ   :RING3

            CMP   #'2'                               ; Check For Ring
            CLC
            BNE   :RING5                             ; Nope, Nothing

            LDA   #0
            JSR   M_WAIT                             ; Slight Delay
            JSR   M_WAIT
            BEQ   ANSRING

:RING3      JSR   SETSPD                             ; Set The Correct Speed
            LDY   #5
:RING4      LDA   #0                                 ; Let Carrier's Settle
            JSR   M_WAIT
            DEY
            BNE   :RING4

            JSR   INP                                ; Gobble Extra Stuff Coming In
            JSR   INP
            LDA   #-1                                ; Set Cd Status To Connected
            STA   CDSTAT
            SEC                                      ; We Have A Connection!
:RING5      RTS

ANSRING     LDX   #0
            JSR   PRSTR                              ; Answer The Phone
            CLC
            RTS

* Input Data
*-------------------------------

INP         PHX                                      ; Save X
            INC   CDCOUNT
            BNE   :INP2

            INC   CDCOUNT+1                          ; Count Up Tries
            BNE   :INP2                              ; All Is Still Ok

            DEC   CDCOUNT+2                          ; Count Big Stuff
            BNE   :INP2

            LDA   #5                                 ; Reset Counter
            STA   CDCOUNT+2
            JSR   CHKOK                              ; Is Modem Out There?
            BCC   :INP2                              ; Nope, It Isn't, Must Be User

            STZ   CDSTAT                             ; We Have Lost CD
:INP2       LDX   SLOT                               ; Get Offset
            LDA   STATUS,X                           ; Get Status
            AND   #SSCRXF
            CLC
            BEQ   :INP3                              ; No Data

            LDA   #-1
            STA   CDSTAT                             ; Reset Status & Counter
            STZ   CDCOUNT
            STZ   CDCOUNT+1
            LDA   #5
            STA   CDCOUNT+2
            LDA   DATA,X                             ; Get Data
            CMP   #28                                ; Kill Connection?
            SEC
            BNE   :INP3                              ; Nope

            LDX   #1
            STX   CDCOUNT+2                          ; Reset Counter
:INP3       PLX                                      ; Restore & Return
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
            PHA
            AND   #SSCOE
            BEQ   :OUT3                              ; No Error, All Is Well

            LDA   DATA,X
            CMP   #28                                ; Was Is Loss Of Carrier?
            BNE   :OUT3                              ; Nope

            LDA   #1                                 ; Set Count Down For CD Loss
            STA   CDCOUNT+2
:OUT3       PLA
            AND   #SSCTXE
            BEQ   :OUT2                              ; Loop Until Ready

            PLA
DATALOC     STA   DATA                               ; Output Byte
            PLX
            RTS

* Check For Carrier
*-------------------------------

M_CHKDCD    LDA   CDSTAT
            PHA
            ASL   A
            PLA
            EOR   #-1
PRSTR2      RTS

* Print Control String To Modem
*-------------------------------

PRSTR       LDA   ANSSTR,X                           ; Get Data Byte
            BEQ   PRSTR2                             ; Did It Work?

            INX
            JSR   OUT                                ; Output Byte
            CMP   #Cr
            BNE   PRSTR

            LDA   #0                                 ; Slight Pause
            JSR   M_WAIT
            BEQ   PRSTR                              ; Loop (Z-Bit Always Set)

* Check For OK From Question
*-------------------------------

CHKOK       LDX   #INITSTR-ANSSTR                    ; Send An AT
            JSR   PRSTR
            LDY   #250                               ; Check 250 Times
:CHKOK2     DEY                                      ; Count Down
            CLC
            BEQ   :CHKOK3                            ; No OK Gotten

            LDA   #40                                ; Delay Slightly
            JSR   M_WAIT
            JSR   INP
            BCC   :CHKOK2

            CMP   #'0'                               ; Check For "0" For OK
            BNE   :CHKOK2

            LDA   #80
            JSR   M_WAIT
            JSR   INP                                ; Gobble EOL Char
            SEC                                      ; We Have Confirmation
:CHKOK3     RTS

* Set The Rs-232 Speed [Speed Offset In Y]
*-------------------------------

SETSPD      PHX
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

* Handle Interrupts
*-------------------------------

M_IRQ       CLC
            RTS

* Turn On Dtr/Rts
*-------------------------------

HANGUP      LDA   #SSCNOP+SSCTXOFF+SSCRXIRQX         ; Kill DTR, RTS
            STZ   CDSTAT
            HEX   2C
RAISEDTR    LDA   #SSCNOP+SSCTXON+SSXRXIRQX+SSCRXON  ; Turn On DTR, RTS
            PHP
            SEI
            LDX   SLOT
            STA   COMMAND,X
            LDA   DATA,X                             ; Clear Data Strobe
            LDA   STATUS,X
            PLP
            CLC
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

ATSTR       ASC   'AT'0808
            ASC   '  '08082800

TIMECNT     DB    0                                  ; 1-Second Counter
CDSTAT      DB    0                                  ; Carrier Status
CDCOUNT     DB    0,0,0                              ; Loss Of Cd Counter
SAVE_X      DB    0
SAVE_Y      DB    0

            ASC   'Nocarrier'

            DS    $3B0-*+MODEMDVR

BUFFER      DS    15

CDBYTE      DB    SSCDCD                             ; Mask DCD Only (0=Connected)

ANSSTR      ASC   'ATA'0D00
            DS    $10-*+ANSSTR                       ; DON'T TOUCH

INITSTR     ASC   'ATS0=1S2=128&S1&D2V'0D00
            DS    $30-*+INITSTR                      ; DON'T TOUCH
            LST   OFF

