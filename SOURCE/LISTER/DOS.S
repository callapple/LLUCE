            JMP   BEGIN

            HEX   EEEE
            DB    65
FLNAME      DS    65
REFNUM      DB    0

BEGIN       STA   DISP40      ; Clear //E 80 Column
            STA   CLR80STO    ; Clear 80 Column Store
            JSR   MONSNORM    ; Init Monitor
            JSR   MONINIT
            JSR   MONSKBD
            JSR   MONSVID
            LDA   #<:QUIT
            STA   $3F2
            LDA   #>:QUIT
            STA   $3F2+1
            EOR   #$A5
            STA   $3F4
            LDA   #<SLOT3     ; Set Up For Slot 3
            STA   CSW
            LDA   #>SLOT3
            STA   CSW+1
            LDA   #Cls        ; Clear The Screen
            JSR   COUT
            LDA   #0
            STA   INTOUT
            JSR   LISTER
            JSR   SHOWSTR
            DB    Cr
            DCI   'Press A Key'
:WAIT       LDA   KYBD
            BPL   :WAIT
            BIT   KBDSTRB
:QUIT       JSR   MLI
            DB    $65
            DA    :QLIST
            BRK

:QLIST      DB    4
            DS    6

COUT        PHA
            ORA   #$80
            JSR   MONCOUT
            LDA   KYBD
            BPL   :DONE

            CMP   #$93
            BNE   :INT

            BIT   KBDSTRB
:LOOP       LDA   KYBD
            BPL   :LOOP
            BMI   :EXIT

:INT        LDA   KYBD
            STA   INTOUT
:EXIT       BIT   KBDSTRB
:DONE       PLA
            RTS

INTOUT      DB    0

GOBCOM
MOVNAME
DO_SED      RTS

OPEN        JSR   MLI
            DB    Open
            DW    :OPENLST
            BCS   :OPEN2

            LDA   :OPENREF    ; Save Refnum
            HEX   2C
:OPEN2      LDA   #-1         ; Make A Bad Refnum
            STA   REFNUM
            RTS

:OPENLST    DB    3
            DW    FLNAME
            DW    FBUF1
:OPENREF    DB    0

CLOSE       LDA   REFNUM
            STA   :CLFLREF
            JSR   MLI
            DB    Close       ; *** Modified ***
            DW    :CLFLLST
            RTS

:CLFLLST    DB    1
:CLFLREF    DB    0

SET_POS     STX   MARK
            STA   MARK+1      ; Point To New Location
            STY   MARK+2
            LDA   REFNUM
            STA   MARKREF     ; Save Refnum
            JSR   MLI
            DB    Setmark
            DW    MARKLST
            RTS

MARKLST     DB    2
MARKREF     DB    0
MARK        DB    0,0,0

GET_MARK    LDA   REFNUM      ; $CF Save Refnum
            STA   MARKREF
            JSR   MLI
            DB    Getmark
            DW    MARKLST
            LDX   #0
            TXA
            TAY
            BCS   :GETMRK2    ; Opps, Error

            LDX   MARK        ; All Is Well
            LDA   MARK+1
            LDY   MARK+2
:GETMRK2    RTS

            DS    \

