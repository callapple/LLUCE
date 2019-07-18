            LST   RTN
            TTL   'LLUCE - Copyright Encoder'
            PAG
]COPYR      =     COPNOT-VIDRDKY+MOV_F00
]SERIAL     =     SERNUM-VIDRDKY+MOV_F00

ENCODE      BRA   ENC_DOIT                     ; Jump Around

            HEX   EEEE                         ; Tell Em We're Here
            DO    DEMOPGM
            DW    0
            ELSE
            DW    ]SERIAL
            FIN

ENC_DOIT    IFNE  TEMP;#1;ARRGH
            IFEQ  TEMP+1;#2;ENCODEIT

ARRGH       LDY   #0                           ; Print Message
EN_PRMSG    LDEQ  ARGMSG,Y;ENC_DONE

            ORA   #Hibit
            JSR   MONCOUT
            IBRA  Y;EN_PRMSG

ENC_DONE    LDA   KBDSTRB
ENC_WAIT    LDPL  KYBD;ENC_WAIT                ; Wait For Keypress

            LDA   KBDSTRB
            PDOS  Quit;ENC_QLST
            INC   SOFTEV
            JMP   ($FFFC)

ENC_QLST    DB    4
            DS    7

ARGMSG      DB    cr,cr
            ASC   'System Not Set Up'00
ENCODEIT    MOVD  #]COPYR;TEMP
            LDY   #COPLEN
            DEY
ENC_COPY    LDA   (TEMP),Y
            ROL   A
            EOR   #COPLEN
            STA   (TEMP),Y
            DBPL  Y;ENC_COPY

            MOVD  #]SERIAL;TEMP
            LDY   #SERLEN
            DEY
ENC_SN      LDA   (TEMP),Y
            ROL   A
            EOR   #SERLEN
            STA   (TEMP),Y
            DBPL  Y;ENC_SN

            LDA   SETRAM1
            LDA   SETRAM1
            LDX   #0                           ; Zero CRC Pages
ENC_ZCRC    STZ   CRCLO,X
            STZ   CRCHI,X
            IBNE  X;ENC_ZCRC

EN_FETCH    TXA                                ; Set Up CRC Table
            EOR   CRCHI,X
            STA   CRCHI,X
            LDY   #8
ENC_MCTB    ASL   CRCLO,X
            ROL   CRCHI,X
            BCC   ENC_LUP1

            LDA   CRCHI,X
            EOR   #>$1021
            STA   CRCHI,X
            LDA   CRCLO,X
            EOR   #<$1021
            STA   CRCLO,X
ENC_LUP1    DBNE  Y;ENC_MCTB
            IBNE  X;EN_FETCH

            MOVD  #MOV_F00;TEMP
ENCALCRC    LDA   (TEMP)
            EOR   CRC2+1                       ; Add It To CRC
            TAX
            LDA   CRC2
            EOR   CRCHI,X
            STA   CRC2+1
            MOV   CRCLO,X;CRC2
            INCD  TEMP
            IFNE  TEMP;#<CRC1;ENCALCRC
            IFNE  TEMP+1;#>CRC1;ENCALCRC

            LDA   SETROM
            MOVD  #STARTUP;HEADER+1
            LDY   CRC2
            LDA   CRC2+1
ZAPENCOD    LDX   #ZAPENCOD-ENCODE
ENC_ZERO    STZ   ENCODE,X
            DBNE  X;ENC_ZERO

            RTS
            LST   OFF

