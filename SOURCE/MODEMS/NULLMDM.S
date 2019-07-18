            LST   RTN
            TTL   'LLUCE - Null Modem Driver'
            PAG
*-------------------------------
* Date 01/06/87
*-------------------------------
* Jump Table
*-------------------------------

MODEMDVR    =     *
SLOT        DB    MSLOT*16                     ; Serial Card Slot
MDMSPEED    =     *
INITSPD     DB    0                            ; Initialize Speed
CALLSPD     DB    0                            ; Speed Of Call

BYTCNT      DB    0,0,0

MDMINIT     JMP   MDMDTR
MDMRSET     JMP   MDMDTR
MDMRING     JMP   RING
MDMANS      JMP   MDMDTR
MDMHANG     JMP   MDMDTR
MDMIN       JMP   INP
MDMOUT      JMP   OUT
MDMDCD      JMP   M_CHKDCD
MDMSSPD     JMP   MDMDTR
MDMINT      JMP   RING
MDMDTR      JMP   RING
MDMCBUF     JMP   RING
MDMQUIT     JMP   RING

* Init The Serial Card
*-------------------------------

RING        CLC                                ; Scan For Ring And Handle It
            RTS

INP         LDA   #0                           ; Input Data
            CLC
            RTS

OUT         INC   BYTCNT                       ; Output Data
            BNE   :OUT1                        ; Do Byte-Counting

            INC   BYTCNT+1
            BNE   :OUT1

            INC   BYTCNT+2
:OUT1       RTS

M_CHKDCD    CLC                                ; Check For Carrier
            RTS

            ASC   'NullModem'
            DS    $400-*+MODEMDVR
            LST   OFF

