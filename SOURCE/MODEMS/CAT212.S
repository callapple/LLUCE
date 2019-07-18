            LST   RTN
            TTL   'LLUCE - AppleCat 212 Driver'
            PAG
*-------------------------------
* Internal - Apple Cat 212
*-------------------------------
* Date 12/09/86
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
            STA   DACBYT,X
            INX
            INY
            CPY   #$10
            BNE   :INIT

            PLP
            RTS

* Setup For Call
*-------------------------------

RINGSET     LDA   #0                             ; Reset Time-On
            STZ   BYTCNT
            STZ   BYTCNT+1
            STZ   BYTCNT+2
            STZ   CARWAIT                        ; Reset Wait Flag
            TAY                                  ; Set 300 Baud
            JMP   SETSPD

* Scan For Ring And Handle It
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
            LDA   #DIS212+MSQ                    ; Disable 212 Mode
            STA   SQUBYT,X
            LDA   #128                           ; Wait
            JSR   WAIT
            LDA   #EN212+MSQ                     ; Enable 212 Mode
            STA   SQUBYT,X
            LDA   #60                            ; Wait For Things To Settle
            JSR   WAIT
:RING3      LDA   #0                             ; Do Big Wait...
            JSR   WAIT
            LDA   SWBYT,X                        ; Do We Have Carrier?
            AND   #CD103
            BNE   :RING5                         ; Yep

            LDA   ACBYTE,X                       ; Do We Have 212 Carrier
            AND   #CD212
            BNE   :RING6                         ; Yep

            DEC   CARWAIT                        ; Loop Until Count Is Done
            BNE   :RING3

            JSR   HANGUP
:RING4      CLC                                  ; Nothing Happened
            RTS

:RING5      LDA   #RNGIRQEN+TA103                ; Reset Xmtbyt
            STA   XMTBYT,X
            STA   XMTDATA
            LDA   #DIS212+MSQ                    ; Disable 212 Card
            STA   SQUBYT,X
            LDA   #TXMDM+RXMDM                   ; Send Uart To 103 Board
            STA   DEVBYT,X
            BEQ   :RING7                         ; Finish Connect

:RING6      LDA   #B212_10+RESET212              ; Reset 212 Card
            STA   BYT212,X
            LDA   #EN212+MSQ                     ; Re-Enable 212 Card
            STA   SQUBYT,X
            LDA   #TX212+RX212                   ; Send Uart To 212 Card
            STA   DEVBYT,X
            LDA   #RNGIRQEN+TXDISABLE+REVCHAN    ; Reset Xmtbyt
            STA   XMTBYT,X
            STA   XMTDATA
            LDY   #1                             ; Set Speed To 1200
            JSR   SETSPD
:RING7      LDA   #-1                            ; Reset Carrier Timing
            STA   CARWAIT
            SEC
            LDA   #0                             ; Do Delay Last
            JMP   WAIT

* Send Ata
*-------------------------------

ANSWER      LDA   #-1                            ; Signal We Want Manual-Answer
            STA   CARWAIT
            RTS

* Hangup Phone
*-------------------------------

HANGUP      LDX   SLOT                           ; Get Offset
            LDA   #RNGIRQEN+TXDISABLE+REVCHAN
            STA   XMTBYT,X                       ; Turn Off 103 Carrier
            LDA   #DIS212+MSQ
            STA   SQUBYT,X                       ; Turn Off 212 Carrier
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

            LDA   XMTDATA                        ; Reset Char Ready Byte
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
            ASL
            ASL
            ASL                                  ; Time Count = Base.Rate * 32
            ASL
            ASL
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
            LDA   CALLSPD                        ; Check Calling Speed
            CMP   #4                             ; At 1200 Baud?
            BEQ   :DCD212                        ; Yep

            LDA   SWBYT,X                        ; Check Carrier
            AND   #CD103
            BEQ   :CHKDCD2                       ; No Carrier

:CHKDCD1    LDA   #-1                            ; Buffer Carrier Detect
            STA   CARWAIT
            SEC
            BCS   :CHKDCD4                       ; Use Return Routine

:DCD212     LDA   ACBYTE,X                       ; Check 212 Carrier
            AND   #CD212
            BNE   :CHKDCD1                       ; All Is Well

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

WAIT        SEC                                  ; From Apple ][+ Ref Man - Pg 147
:WAIT2      PHA
:WAIT3      SBC   #1
            BNE   :WAIT3

            PLA
            SBC   #1
            BNE   :WAIT2

            RTS

*-------------------------------

SPEED       DB    TXBR300+RXBR300                ; Handle 300
            DB    TXBR1200+RXBR1200              ; Handle 1200

TIMECNT     DB    0
CARWAIT     DB    0
XMTDATA     DB    0

INITBYT     DB    $04
            DB    DIS212+MSQ
            DB    $00
            DB    IRQ29DIS+BSR120DIS
            DB    $04
            DB    $80
            DB    $00
            DB    $06
            DB    $00
            DB    RA103
            DB    STOP1_5+DATBITS8
            DB    TXBR300+RXBR300
            DB    TXON+RXON
            DB    RNGIRQEN+REVCHAN+TXDISABLE
            DB    $00
            DB    TXMDM+RXMDM

            ASC   'Cat212'
            DS    $400-*+MODEMDVR
            LST   OFF

