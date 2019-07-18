            LST   RTN
            TTL   'LLUCE - AppleCat 103 Driver'
            PAG
*-------------------------------
* Internal - Apple Cat 103
*-------------------------------
* Date 3/18/88 - AEN
*-------------------------------
* Jump Table
*-------------------------------

MODEMDVR    =     *
SLOT        DB    MSLOT*16                       ; Serial Card Slot
MDMSPEED    =     *
INITSPD     DB    0                              ; Initialize Speed
CALLSPD     DB    0                              ; Speed Of Call

BYTCNT      DB    0,0,0

MDMINIT     JMP   INIT
MDMRSET     JMP   RINGSET
MDMRING     JMP   RING
MDMANS      JMP   ANSWER
MDMHANG     JMP   HANGUP
MDMIN       JMP   INP
MDMOUT      JMP   OUT
MDMDCD      JMP   M_CHKDCD
MDMSSPD     JMP   SETSPD
MDMINT      JMP   M_IRQ
MDMDTR      JMP   M_IRQ                          ; Raise Dtr
MDMCBUF     JMP   M_IRQ
MDMQUIT     JMP   M_IRQ

* Init The Modem Card
*-------------------------------

INIT        PHP
            SEI
            LDX   SLOT                           ; Get Slot Offset
            LDY   #0
:INIT       LDA   INITBYT,Y                      ; Init All 16 Bytes
            STA   SWBYT,X
            INX
            INY
            CPY   #$10
            BNE   :INIT

            PLP
            RTS

* Setup For The Call
*-------------------------------

RINGSET     LDA   #0                             ; Reset Time-On
            STZ   BYTCNT
            STZ   BYTCNT+1
            STZ   BYTCNT+2
            STZ   CARWAIT                        ; Reset Wait Flag
            TAY                                  ; Set 300 Baud
            JMP   SETSPD

* Scan For The Ring And Handle It
*-------------------------------

RING        LDX   SLOT                           ; Get Offset
            BIT   CARWAIT                        ; Do They Want Manual-Answer?
            BMI   :RING2A                        ; Yep

            LDA   ACBYTE,X
            AND   #CATRING
            BEQ   :RING4                         ; Nothing

:RING2      LDA   ACBYTE,X                       ; Wait For Ring To Clear
            AND   #CATRING
            BNE   :RING2

:RING2A     LDA   #SH                            ; Pick Up Phone
            STA   SHBYT,X
            LDA   #80                            ; Setup Carrier Wait Time
            STA   CARWAIT
            LDA   #60                            ; Wait For Things To Settle
            JSR   WAIT
:RING3      LDA   #0                             ; Do Big Wait...
            JSR   WAIT
            LDA   SWBYT,X                        ; Do We Have Carrier?
            AND   #CD103
            BNE   :RING5                         ; Yep

            DEC   CARWAIT                        ; Loop Until Count Is Done
            BNE   :RING3

            JSR   HANGUP
:RING4      CLC                                  ; Nothing Happened
            RTS

:RING5      SEC                                  ; Reset Carrier Timing
ANSWER      LDA   #-1                            ; Signal We Want Manual-Answer
            STA   CARWAIT
            RTS

* Hangup Phone
*-------------------------------

HANGUP      LDX   SLOT                           ; Get Offset
            STZ   SHBYT,X                        ; Hang Up Phone
            RTS

* Input Data
*-------------------------------

INP         PHX                                  ; Save X
            LDX   SLOT                           ; Get Offset
            LDA   STATUS1,X                      ; Get Status
            AND   #CAT_RXF
            CLC
            BEQ   :INP2                          ; No Data

            LDA   #RNGIRQEN                      ; Reset Char Ready Byte
            STA   XMTBYT,X
            LDA   INDATA,X                       ; Get Data
            SEC
:INP2       PLX                                  ; Restore & Return
            RTS

* Output Data
*-------------------------------

OUT         PHX                                  ; Save X
            PHA
            DEC   TIMECNT                        ; Count Down Bytes Per Second
            BNE   :OUT1                          ; Not A Seconds Worth Yet

            LDA   CALLSPD                        ; Reset Counter
            ASL   A
            ASL   A
            ASL   A                              ; Time Count = Base.Rate * 32
            ASL   A
            ASL   A
            STA   TIMECNT
            INC   BYTCNT                         ; Seconds - At 64 Yet?
            BIT   BYTCNT
            BVC   :OUT1                          ; Nope

            LDX   #0                             ; Reset Seconds
            STX   BYTCNT
            INC   BYTCNT+1                       ; Minutes - At 64 Yet?
            BIT   BYTCNT+1
            BVC   :OUT1                          ; Nope

            LDX   #0                             ; Reset Minutes
            STX   BYTCNT+1
            INC   BYTCNT+2                       ; Inc Hours
:OUT1       LDX   SLOT
:OUT2       LDA   STATUS1,X                      ; Check Status
            AND   #CAT_TXE
            BEQ   :OUT2                          ; Loop Until Ready

            PLA
            STA   OUTDAT,X                       ; Output Byte
            PLX
            RTS

* Check For Carrier
*-------------------------------

M_CHKDCD    PHX                                  ; Don't Kill Any Reg's
            PHA
            LDA   CARWAIT                        ; Do We Have Carrier?
            BEQ   :CHKDCD3                       ; Nope

            LDX   SLOT
            LDA   SWBYT,X                        ; Check Carrier
            AND   #CD103
            BEQ   :CHKDCD2                       ; No Carrier

            LDA   #-1                            ; Buffer Carrier Detect
            STA   CARWAIT
            SEC
            BCS   :CHKDCD4                       ; Use Return Routine

:CHKDCD2    DEC   CARWAIT                        ; Count Down
:CHKDCD3    CLC
:CHKDCD4    PLA                                  ; Restore All & Return
            PLX
            RTS

* Set The Rs232 Speed
*-------------------------------

SETSPD      PHX
            LDX   SLOT                           ; Get Offset
            LDA   SPEED,Y                        ; Get Speed
            STA   SPDBYT,X                       ; Set Speed
            LDA   #1                             ; Find Caller Speed (X300)
            STA   CALLSPD
            CPY   #0                             ; At 300?
            BEQ   :SETSPD3                       ; Yep

            ASL   CALLSPD                        ; Speed = Speed * 2
:SETSPD2    ASL   CALLSPD                        ; Speed = Speed * 2
            DEY
            BNE   :SETSPD2                       ; Loop Until Correct Speed Found

:SETSPD3    PLX                                  ; Restore & Return
            RTS

* Handle Interrupt
*-------------------------------

M_IRQ       CLC
            RTS

* Wait Routine
*-------------------------------

WAIT        SEC                                  ; From Apple [+ Ref Man - Pg 147]
:WAIT2      PHA
:WAIT3      SBC   #1
            BNE   :WAIT3

            PLA
            SBC   #1
            BNE   :WAIT2

            RTS

* Variables
*-------------------------------

SPEED       DB    TXBR300+RXBR300                ; Handle 300
            DB    TXBR1200+RXBR1200              ; Handle 1200

TIMECNT     DB    0
CARWAIT     DB    0

INITBYT     DB    $00                            ; DACBYT
            DB    DIS212+MSQ                     ; SQUBYT
            DB    $00                            ; SHBYT
            DB    IRQ29DIS+BSR120DIS             ; BSRBYT
            DB    $00
            DB    $80
            DB    $00
            DB    $06
            DB    $00
            DB    RA103                          ; 103 answer
            DB    STOP1_5+DATBITS8
            DB    TXBR300+RXBR300
            DB    TXON+RXON
            DB    RNGIRQEN+TA103
            DB    $00
            DB    TXMDM+RXMDM

            ASC   'Cat103'
            DS    $400-*+MODEMDVR
            LST   OFF

