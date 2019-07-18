            LST   RTN
            TTL   'LLUCE - MicroModem ]['
            PAG
*-------------------------------
*Internal Micromodem ][ //E
*-------------------------------
* Date 12/09/86
*-------------------------------
* Jump Table
*-------------------------------

MODEMDVR    =     *
SLOT        DB    MSLOT*16                 ; Serial Card Slot
MDMSPEED    =     *
INITSPD     DB    0                        ; Initialize Speed
CALLSPD     DB    0                        ; Speed Of Call

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
MDMDTR      JMP   M_IRQ
MDMCBUF     JMP   M_IRQ
MDMQUIT     JMP   M_IRQ

* Init The Modem Card
*-------------------------------

INIT        PHP
            SEI
            LDX   SLOT                     ; Get Slot Offset
            LDA   %00000000                ; Reset Tone/Speaker
            STA   CR3,X
            PLP
            RTS

* Setup For Call
*-------------------------------

RINGSET     LDA   #0                       ; Reset Time-On
            STZ   BYTCNT
            STZ   BYTCNT+1
            STZ   BYTCNT+2
            STZ   CARWAIT                  ; Reset Wait Flag
            TAY                            ; Set 300 Baud
            JMP   SETSPD

* Scan For Ring And Handle It
*-------------------------------

RING        LDX   SLOT                     ; Get Offset
            BIT   CARWAIT                  ; Do They Want Manual-Answer?
            BMI   :RING2A                  ; Yep

            LDA   RINGIN,X                 ; Check For Ring
            AND   %10000000
            BNE   :RING4                   ; Nothing

:RING2      LDA   RINGIN,X                 ; Wait For Ring To Clear
            AND   %10000000
            BEQ   :RING2

:RING2A     LDA   %00000011                ; Reset Uart
            STA   CR1,X
            LDA   %00010101                ; Set For 8N1
            STA   CR1,X

            LDA   %00000000                ; Reset Modem
            STA   CR2,X
            LDA   %10001011                ; Pick Up Phone [Enable Carrier]
            STA   CR2,X
            LDA   #$50                     ; Setup Carrier Wait Time
            STA   CARWAIT
            LDA   #60                      ; Wait For Things To Settle
            JSR   M_WAIT
:RING3      LDA   #0                       ; Do Big Wait...
            JSR   M_WAIT
            LDA   MMDATA,X
            LDA   MMSTATUS,X               ; Reset Carrier Flag
            LDA   MMSTATUS,X               ; Do We Have Carrier?
            AND   %00000100
            BEQ   :RING5                   ; Yep

            DEC   CARWAIT                  ; Loop Until Count Is Done
            BNE   :RING3

            JSR   HANGUP
:RING4      CLC                            ; Nothing Happened
            RTS

:RING5      SEC                            ; Reset Carrier Timing
ANSRING     LDA   #-1                      ; Signal We Want Manual-Answer
            STA   CARWAIT
            RTS

* Hangup Phone
*-------------------------------

HANGUP      LDX   SLOT                     ; Get Offset
            LDA   %00000001
            STA   CR2,X                    ; Hang Up Phone
            RTS

* Input Data
*-------------------------------

INP         STX   SAVE_X                   ; Save X
            LDX   SLOT                     ; Get Offset
            LDA   MMSTATUS,X               ; Get Status
            AND   %00000001
            CLC
            BEQ   :INP2                    ; No Data

            LDA   MMDATA,X                 ; Get Data
            SEC
:INP2       LDX   SAVE_X                   ; Restore & Return
            RTS

* Output Data
*-------------------------------

OUT         STX   SAVE_X                   ; Save X
            DEC   TIMECNT                  ; Count Down Bytes Per Second
            BNE   :OUT1                    ; Not A Seconds Worth Yet

            PHA
            LDA   CALLSPD                  ; Reset Counter
            ASL
            ASL
            ASL                            ; Time Count = Base.Rate * 32
            ASL
            ASL
            STA   TIMECNT
            PLA
            INC   BYTCNT                   ; Seconds - At 64 Yet?
            BIT   BYTCNT
            BVC   :OUT1                    ; Nope

            STZ   BYTCNT                   ; Reset Seconds
            INC   BYTCNT+1                 ; Minutes - At 64 Yet?
            BIT   BYTCNT+1
            BVC   :OUT1                    ; Nope

            STZ   BYTCNT+1                 ; Reset Minutes
            INC   BYTCNT+2                 ; Inc Hours
:OUT1       LDX   SLOT
            PHA
:OUT2       LDA   MMSTATUS,X               ; Check Status
            AND   %00000110
            BEQ   :OUT2                    ; Loop Until Ready

            PLA
            STA   MMDATA,X                 ; Output Byte
            LDX   SAVE_X
            RTS

* Check For Carrier
*-------------------------------

M_CHKDCD    STX   SAVE_X                   ; Don't Kill Any Reg's
            PHA
            LDX   SLOT
            LDA   MMSTATUS,X               ; Reset Carrier Flag
            LDA   MMSTATUS,X               ; Check Carrier
            AND   %00000100
            CLC
            BNE   :CHKDCD2                 ; Opps, No Carrier

            SEC                            ; Sec = We Have Carrier
:CHKDCD2    PLA                            ; Restore & Return
            LDX   SAVE_X
            RTS

* Set The Rs-232 Speed [Speed Offset In Y]
*-------------------------------

SETSPD      LDA   #1                       ; Find Caller Speed (X300)
            STA   CALLSPD
            RTS

* Handle Interrupts
*-------------------------------

M_IRQ       CLC
            RTS

* Wait Routine
*-------------------------------

M_WAIT      SEC                            ; From Apple ][+ Ref Man - Pg 147
:WAIT2      PHA
:WAIT3      SBC   #1
            BNE   :WAIT3

            PLA
            SBC   #1
            BNE   :WAIT2

            RTS

* Available Speeds
*-------------------------------

SAVE_X      DB    0

TIMECNT     DB    0
CARWAIT     DB    0

            ASC   'MM2'

            DS    $400-*+MODEM
            LST   OFF

