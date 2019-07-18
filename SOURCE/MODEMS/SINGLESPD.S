                          LST   RTN
                          TTL   'LLUCE - Single Speed SSC Driver'
                          PAG
*-------------------------------
* Single Speed External
*-------------------------------
* 3/19/88 Andrew E. Nicholas
*-------------------------------
* Jump Table
*-------------------------------

MODEMSPD                  =     *
SLOT                      DB    MSLOT*16                           ; Serial Card Slot
MDMSPEED                  =     *
INITSPD                   DB    0                                  ; Initialize Speed
CALLSPD                   DB    0                                  ; Speed Of Call

BYTCNT                    DB    0,0,0

MDMINIT                   JMP   INIT
MDMRSET                   JMP   RINGSET
MDMRING                   JMP   RING
MDMANS                    JMP   ANSRING
MDMHANG                   JMP   HANGUP
MDMIN                     JMP   INP
MDMOUT                    JMP   OUT
MDMDCD                    JMP   M_CHKDCD
MDMSSPD                   JMP   SETSPD
MDMINT                    JMP   M_IRQ
MDMDTR                    JMP   RAISEDTR
MDMCBUF                   JMP   M_IRQ
MDMQUIT                   JMP   M_IRQ

* Init The Serial Card
*-------------------------------

INIT                      JSR   HANGUP
                          CLC
                          TXA
                          ADC   #<DATA
                          STA   DATALOC+1                          ; Make Into Absolute Save
                          PLP
                          RTS

* Setup For Call
*-------------------------------

RINGSET                   JSR   HANGUP
                          LDA   #0
                          JSR   M_WAIT
                          JSR   M_WAIT
                          JSR   RAISEDTR
                          LDY   INITSPD                            ; Set Init Speed
                          JSR   SETSPD
                          LDA   DATA,X                             ; Clear Data Strobe
                          LDA   #0                                 ; Long Delay
                          JSR   M_WAIT
                          JSR   M_WAIT
                          LDX   #-1


------------------------

RING                      LDX   SLOT                               ; Get Offset
                          LDA   STATUS,X
                          AND   CDBYTE                             ; Strip Out CD Byte
                          CLC
                          BNE   :RING3                             ; Nothing

                          SEC                                      ; We Have A Connection
                          LDX   #5
:RING2                    LDA   #0                                 ; Delay Before Going Online
                          JSR   M_WAIT
                          DEX
                          BNE   :RING2

                          JSR   INP                                ; Gobble Extra
                          SEC
:RING3                    RTS

* Send Ata To Phone
*-------------------------------

ANSRING                   LDX   #0
:ANSWER2                  LDA   ANSSTR,X                           ; Get Text
                          BEQ   :ANSWER3                           ; We Are Done

                          JSR   OUT                                ; Send It
                          LDA   #$80                               ; Delay A Little
                          JSR   M_WAIT
                          INX
                          BNE   :ANSWER2                           ; Loop

:ANSWER3                  RTS

* Input Data
*-------------------------------

INP                       STX   SAVE_X                             ; Save X
                          LDX   SLOT                               ; Get Offset
                          LDA   STATUS,X                           ; Get Status
                          AND   #SSCRXF
                          CLC
                          BEQ   :INP2                              ; No Data

                          LDA   DATA,X
                          SEC
:INP2                     LDX   SAVE_X                             ; Restore & Return
                          RTS

* Output Data
*-------------------------------

OUT                       STX   SAVE_X                             ; Save X
                          DEC   TIMECNT                            ; Count Down Bytes Per Second
                          BNE   :OUT1                              ; Not A Seconds Worth Yet

                          PHA
                          LDA   CALLSPD                            ; Reset Counter
                          ASL   A
                          ASL   A
                          ASL   A                                  ; Time Count = Base.Rate * 32
                          ASL   A
                          ASL   A
                          STA   TIMECNT
                          PLA
                          INC   BYTCNT                             ; Seconds - At 64 Yet?
                          BIT   BYTCNT
                          BVC   :OUT1                              ; Nope

                          LDX   #0                                 ; Reset Seconds
                          STX   BYTCNT
                          INC   BYTCNT+1                           ; Minutes - At 64 Yet?
                          BIT   BYTCNT+1
                          BVC   :OUT1                              ; Nope

                          LDX   #0                                 ; Reset Minutes
                          STX   BYTCNT+1
                          INC   BYTCNT+2                           ; Inc Hours
:OUT1                     LDX   SLOT
                          PHA
:OUT2                     LDA   STATUS,X                           ; Check Status
                          AND   #SSCTXE
                          BEQ   :OUT2                              ; Loop Until Ready

                          PLA
DATALOC                   STA   DATA                               ; Self-Modified
                          LDX   SAVE_X
                          RTS

* Check For Carrier Sec = We Have Carrier
*-------------------------------

M_CHKDCD                  PHX                                      ; Don't Kill Any Reg's
                          PHA
                          LDX   SLOT                               ; Get Offset
                          LDA   STATUS,X
                          AND   CDBYTE                             ; Check Carrier
                          CLC
                          BNE   :CHKDCD2

                          SEC
:CHKDCD2                  PLA                                      ; Restore All & Return
                          PLX
                          RTS

* Set The Rs-232 Speed [Speed Offset In Y]
*-------------------------------

SETSPD                    PHX
                          LDX   SLOT                               ; Get Offset
                          LDA   SPEED,Y                            ; Get Speed
                          STA   CONTROL,X                          ; Set Speed
                          LDA   #1                                 ; Find Caller Speed (X300)
                          STA   CALLSPD
                          CPY   #0                                 ; At 300?
                          BEQ   :SETSPD3                           ; Yep

                          ASL   CALLSPD                            ; Speed = Speed * 2
:SETSPD2                  ASL   CALLSPD                            ; Speed = Speed * 2
                          DEY
                          BNE   :SETSPD2                           ; Loop Until Correct Speed Found

:SETSPD3                  PLX                                      ; Restore & Return
                          RTS

* Handle Interrupts
*-------------------------------

M_IRQ                     CLC
                          RTS

* Turn On Dtr/Rts
*-------------------------------

HANGUP                    LDA   #SSCNOP+SSCTXOFF+SSCRXIRQX         ; Kill DTR, RTS
                          HEX   2C
RAISEDTR                  LDA   #SSCNOP+SSCTXON+SSCTXIRQX+SSCRXON  ; Turn On DTR, RTS
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

M_WAIT                    SEC                                      ; From Apple ][+ Ref Man - Pg 147
:WAIT2                    PHA
:WAIT3                    SBC   #1
                          BNE   :WAIT3

                          PLA
                          SBC   #1
                          BNE   :WAIT2

                          RTS

* Available Speeds
*-------------------------------

SPEED                     DB    SSCCLK+SSC300
                          DB    SSCCLK+SSC1200
                          DB    SSCCLK+SSC2400
                          DB    SSCCLK+SSC4800
                          DB    SSCCLK+SSC9600
                          DB    SSCCLK+SSC19200

COUNTLO                   DB    0
COUNTHI                   DB    0
SAVE_X                    DB    0
TIMECNT                   DB    0

                          ASC   'SingleSpd'

                          DS    $3B0-*+MODEMDVR

BUFFER                    DS    15

CDBYTE                    DB    SSCDCD                             ; Mask DCD Only (0=Connected)

ANSSTR                    ASC   'ATA'0D00
                          DS    $10-*+ANSSTR                       ; DON'T TOUCH

INITSTR                   ASC   'ATS0=1S2=128&S1&D2V'0D00
                          DS    $30-*+INITSTR                      ; DON'T TOUCH
                          LST   OFF

