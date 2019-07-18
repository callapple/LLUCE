            LST    RTN
            TTL    'LLUCE - Initialize'
            PAG
*===============================
* Do Memory Move And Setup
*===============================
* Standard 128k Test Routine
*-------------------------------

TST128LC    ORG    $80

TST128      MOV    #$EE;AUXWRT                ;Testing For 128k
            STA    AUXREAD
            STA    $C00
            STA    $800
            IFNE   $C00;#$EE;T128_1

            ASL    $C00
            ASL    A
            CPNE   $C00;T128_1
            CPNE   $800;T128_2

T128_1      SEC
            BCS    T128_3                     ; CHANGE TO SKIPCC

T128_2      CLC
T128_3      STA    MAINWRT                    ; REMOVE LABEL LATER
            STA    MAINREAD
            RTS
E128
            ORG

*-------------------------------
* Begin Initialization
* Initialize Monitor
*-------------------------------

STARTUP     STA    DISP40                     ; Clear //E 80 Column
            STA    CLR80STO                   ; Clear 80 Column Store
            JSR    MONSNORM                   ; Init Monitor In Std ZP
            JSR    MONINIT
            JSR    MONSKBD
            JSR    MONSVID
            JSR    MONCLS
            JSR    IPRINT
            DO     DEMOPGM
            ASC    'DEMO '
            FIN
            ASC    'LOADING...'
            DB     cr,cr
            DCI    'CHECKING SYSTEM: '

*-------------------------------
* Check Machine Type
*-------------------------------

            LDA    MONID1                     ; Is This A //E Or Better?
            CMP    #6
            SEC
            BNE    BADMACH                    ; Nope

            LDA    MONID2                     ; Unenhanced?
            EOR    #$EA
            BEQ    BADMACH                    ; Yes, Won't Run

            LDX    #E128-TST128               ; Move 128K Tester Down
I_MV128     MOV    TST128LC,X;TST128,X
            DBPL   X;I_MV128

            JSR    TST128                     ; Test For 128K
BADMACH     BCC    I_DO_CRC                   ; Not There

            JSR    IPRINT
            DB     cr,cr
            DCI    'REQUIRES 65C02 AND 128K'
            JMP    IQUIT

I_DO_CRC    JSR    IPRINT
            ASC    'Ok'
            DB     cr
            DCI    'CRC Check: '
            LDA    SETRAM1
            MOV    SETRAM1;SETALTZP
            LDX    #0                         ; Zero Crc Pages
I_ZCRCTB    STZ    CRCLO,X
            STZ    CRCHI,X
            IBNE   X;I_ZCRCTB

I_FETCH     TXA                               ; Set Up CRC Table
            EOR    CRCHI,X
            STA    CRCHI,X
            LDY    #8
I_MKCRCT    ASL    CRCLO,X
            ROL    CRCHI,X
            BCC    I_MCRCL1

            LDA    CRCHI,X
            EOR    #>$1021
            STA    CRCHI,X
            LDA    CRCLO,X
            EOR    #<$1021
            STA    CRCLO,X
I_MCRCL1    DBNE   Y;I_MKCRCT

            IBNE   X;I_FETCH

            MOVD   #MOV_F00;TEMP
I_CALCRC    LDA    (TEMP)
            EOR    CRC1+1                     ; Add It To Crc
            TAX
            LDA    CRC1
            EOR    CRCHI,X
            STA    CRC1+1
            MOV    CRCLO,X;CRC1
            INCD   TEMP
            IFNE   TEMP;#<CRC1;I_CALCRC
            IFNE   TEMP+1;#>CRC1;I_CALCRC

*-------------------------------
* Check CRC Found, Error If Wrong
*-------------------------------

            MOV    SETROM;SETSTDZP
            IFNE   CRC1;CRC2;I_G_XCRC         ; check CRC
            IFEQ   CRC1+1;CRC2+1;BITSET

I_G_XCRC    JSR    IPRINT
            DB     cr,cr
            DO     DEMOPGM
            DCI    'This program cannot be altered'
            ELSE
            DCI    'Bad CRC - Check For Virus:'
            FIN
            JMP    IQUIT

*-------------------------------
* Set Up Bitmap
*-------------------------------

BITSET      JSR    IPRINT
            ASC    'Ok'
            DB     cr
            DCI    'Loading Drivers: '
            LDX    #23
I_ZBIT      STZ    BITMAP,X                   ; Move 1 - 000 Pattern
            DBNE   X;I_ZBIT

            MOV    #%11001111;BITMAP          ; Protect Bottom Pages
            INC    BITMAP+23

*-------------------------------
* Setup Starting Prefix
*-------------------------------

            PDOS   Getpfx;INITGPFX            ; Get The Current Prefix
            MOVX   DEVNUM;I_ATUNIT            ; Any Unit Used?
            LDNE   LNBUF+$80;I_DRVOK          ; Any Prefix?

            TXA
            BNE    I_DEVOK                    ; Yes, All Ok

            LDX    DEVCNT                     ; Use Last Unit On List
            MOV    DEVLST,X;DEVNUM
I_DEVOK     STA    I_UNIT                     ; Save Unit Number
            PDOS   Online;I_ONLINE            ; Get Last Drive's Name
            LDA    LNBUF+$81                  ; Get Length Of Volume Name
            AND    #LoNibble                  ; Trim Off Slot Number
            INC    A                          ; Add 1 For Leading '/'
            STA    LNBUF+$80                  ; Save For Set Prefix
            MOV    #'/';LNBUF+$81             ; Put In Laading '/'
            PDOS   Setpfx;INITGPFX            ; Set The Prefix

*-------------------------------
* Check If AppleShare Active
*-------------------------------

I_DRVOK     PDOS   Ashare;I_ATALST            ; Is AppleShare Available?
            STZ    ATAVAIL
            STZ    ATLAUNCH                   ; Flag None
            BCS    I_LD_DVR                   ; Nope

            DEC    ATAVAIL
            PDOS   Rd_Block;I_ATLLST          ; Check If Launched From
            CPNE   #networkError;I_LD_DVR

            DEC    ATLAUNCH                   ; It's There

*-------------------------------
* Load In LLUCE Drivers
*-------------------------------

I_LD_DVR    MOV    #3;I_DVROPN                ; Standard Open List Length
            STA    I_TXTOPN
            PUSHX  ATAVAIL                    ; save AT stuff for later
            PUSHX  ATLAUNCH                   ; Launched From AppleTalk?
            PHP
            BPL    REGTOPEN                   ; Nope

            INC    I_TXTOPN                   ; Special Open List Length
            PDOS   SpclOpen;I_TXTOPN          ; Open File As Read Only
            BRA    TXTCONT

REGTOPEN    PDOS   Open;I_TXTOPN              ; Open The Driver File
TXTCONT     BCS    BADTXT                     ; Doesn't Exist?

            MOV    TXTOREF;TXTRDRF            ; Move Reference Numbers
            STA    TXTCLSRF
            PDOS   Read;TXTREAD               ; Read In First Chunk
BADTXT      PHA
            PDOS   Close;TXTCLS               ; Close It
            PLA
            BEQ    MOV_TXT

            PLP

            JSR    IPRINT
            DB     cr,cr
            DCI    'LLUCE.TEXT missing or damaged'
            JMP    IQUIT

MOV_TXT     LDY    #0                         ; Move The Code
            LDX    #11
            LDA    SETRAM1
            LDA    SETRAM1
            MOVD   #NODENUM;TEMP
            MOVD   #ERRMSGS;TEMP2
I_MOVET     MOV    (TEMP),Y;(TEMP2),Y
            IBNE   Y;I_MOVET

            INC    TEMP+1
            INC    TEMP2+1
            DBNE   X;I_MOVET

            LDA    SETROM

            PLP
            BPL    REGOPEN                    ; Nope

            INC    I_DVROPN                   ; Special Open List Length
            PDOS   SpclOpen;I_DVROPN          ; Open File As Read Only
            BRA    DVRCONT

REGOPEN     PDOS   Open;I_DVROPN              ; Open The Driver File
DVRCONT     BCS    BADDRVR                    ; Doesn't Exist?

            MOV    DVROREF;DVRRDRF            ; Move Reference Numbers
            STA    DVCLSRF
            PDOS   Read;DVRREAD               ; Read In First Chunk
BADDRVR     PHA
            PDOS   Close;DVRCLS               ; Close It
            PLA
            BEQ    INIT_BGN

            JSR    IPRINT
            DB     cr,cr
            DCI    'Driver Missing Or Damaged:'
            JMP    IQUIT

I_DVROPN    DB     3
            DA     DVRNAME                    ; Open Driver File
            DA     FBUF1                      ; First I/O Buffer
DVROREF     DB     0
            DB     %00100001                  ; Deny Write/Request Read

DVRREAD     DB     4
DVRRDRF     DB     0
            DA     NODENUM                    ; Read In At Bottom
            DA     $800                       ; $800 Bytes
            DA     0

I_ATALST    DB     0                          ; Async Flag
            DB     2                          ; GetInfo Command
            DW     0                          ; Result Code
            ADRL   0                          ; Completion Routine Return
            DDB    0                          ; This-Net
            DB     0                          ; A-Bridge
            DB     0                          ; Hardware ID
            DW     0                          ; ROM Version
ASNODE      DB     0                          ; Node Number

DVRCLS      DB     1
DVCLSRF     DB     0

DVRNAME     STR    'LLUCE.DRIVERS'

I_TXTOPN    DB     3
            DA     TXTNAME                    ; Open Driver File
            DA     FBUF1                      ; First I/O Buffer
TXTOREF     DB     0
            DB     %00100001                  ; Deny Write/Request Read

TXTREAD     DB     4
TXTRDRF     DB     0
            DA     NODENUM                    ; Read In At Bottom
            DA     $B00                       ; $B00 Bytes
            DA     0

TXTCLS      DB     1
TXTCLSRF    DB     0

TXTNAME     STR    'LLUCE.TEXT'

*-------------------------------
* Set Up Stack And Pointers
*-------------------------------

INIT_BGN    PULL   ATLAUNCH                   ; Get AppleTalk Stuff Back
            PULL   ATAVAIL
            TSTPL  ATLAUNCH;INITBGN2          ; Launched From AppleTalk

            MOV    ASNODE;NODENUM             ; Move AppleShare Node Num
INITBGN2    JSR    IPRINT
            ASC    'Ok'
            DB     cr
            DCI    'Initializing System'
            STZ    GSFLAG
            SEC
            JSR    IDROUTINE
            ROR    GSFLAG

*-------------------------------
* Clear Out Zero Page
*-------------------------------

            STZ    SETALTZP                   ; in alt zp

            LDX    #0                         ; Clear Zero Page
I_ZRO_ZP    STZ    0,X
            IBNE   X;I_ZRO_ZP

            STZ    SETSTDZP

            IFNE   DEV1ADR;DEV2ADR+6;KILLRAM  ; /RAM
            IFEQ   DEV1ADR+1;DEV2ADR+7;NORAM  ; installed?

KILLRAM     LDX    DEVCNT                     ; Find Any Ramdisk
FNDRAM      LDA    DEVLST,X                   ; Get Device Id Byte
            TAY
            AND    #$B3                       ; Low Nibble Is Type
            CPEQ   #$B3;MVDEV                 ; Is It A RAM Disk?

            DBPL   X;FNDRAM                   ; Go To Next Device
            BRA    NORAM

MVDEV       MOV    DEVLST+1,X;DEVLST,X        ; Copy Bytes Down
            INX
            CPLTX  #13;MVDEV                  ; Finished With List?
            STZ    DEVLST+13                  ; zap last byte

            DEC    DEVCNT                     ; 1 Less Device

            LD16   DEV2ADR+6                  ; save driver info
            STZ    SETALTZP                   ; in alt zp
            ST16   RAMDRVR
            STY    RAMDEV
            STZ    SETSTDZP

            MOVD   DEV1ADR;DEV2ADR+6          ; set no device

            TYA
            AND    #HiNibble
            STA    I_UNIT                     ; Save Unit Number
            PDOS   Online;I_ONLINE            ; This Clears Device

NORAM       MOVX   #-1;$100                   ; Set To Top Of Stack
            STX    $101
            STX    SETALTZP
            STX    $100
            STX    $101
            TXS                               ; Set Top Of Stack

*-------------------------------
* Copy Interrupt Vectors To Ram
*-------------------------------

            LDA    $C081                      ; Read ROM/Write RAM
            LDA    $C081
            LDX    #5                         ; Save Vectors
CPYINT      MOV    INTVEC,X;INTVEC,X
            DBPL   X;CPYINT

*-------------------------------
* Initialize Monitor Here
*-------------------------------

            JSR    MONSNORM                   ; Init Monitor In Alt ZP
            JSR    MONINIT
            JSR    MONSKBD
            JSR    MONSVID
            LDA    SETRAM2                    ; Switch RAM Back In
            LDA    SETRAM2

*-------------------------------
* Move Supplied Filename
*-------------------------------

            LDX    ST_NAME                    ; Move Startup Name
I_MVNAME    MOV    ST_NAME,X;SEG_NAME,X
            DBPL   X;I_MVNAME

*-------------------------------
* Move Profanity Filter Into Place
*-------------------------------

            LDX    #0
I_MVFILT    MOV    $F00,X;FILTER,X
            IBNE   X;I_MVFILT

*-------------------------------
* Point To Code Start
*-------------------------------

            MOVD   #CODEND;MODULE             ; Set ptr to segment space
            MOVD   #Version;VERSION           ; put in version number

*-------------------------------
* Move Main Program Into Place
*-------------------------------

            LDX    #0                         ; Start It Up
I_MV_LUP    MOV    MV_PARMS,X;TEMP            ; Get Ram Area To Move To
            INX
            MOV    MV_PARMS,X;TEMP+1
            INX
            ORA    TEMP                       ; Finished?
            BEQ    I_DONE

            LDA    (TEMP)                     ; Switch Ram In
            LDY    #0                         ; Get Source & Destination
I_MV_PRM    MOV    MV_PARMS,X;TEMP,Y
            INX
            INY
            CPNEY  #6;I_MV_PRM

            LDY    #0                         ; Move The Code
I_MOVEB     MOV    (TEMP),Y;(TEMP2),Y
            IBNE   Y;I_MOVEB

            INC    TEMP+1
            INC    TEMP2+1
            DBNE   TEMP3+1;I_MOVEB
            BRA    I_MV_LUP

*-------------------------------
* Patch ProDOS Entry Point
*-------------------------------

I_DONE      PHP                               ; No interrupts during this!
            SEI

            LDA    SETRAM2                    ; Set Ram To Proper State
            MOVD   MLI+1;PDOSVEC              ; Get MLI's JMP Address
            MOVD   #NEW_MLI;MLI+1             ; Patch In Our Routine

*-------------------------------
* Patch IRQ vector
*-------------------------------

            MOVD   IRQVEC;IRQSAVE             ; save current IRQ vector
            MOVD   #IRQ_FIX;IRQVEC            ; point to our routine

*-------------------------------
* Point Reset Vector
*-------------------------------

            MOVD   #RESET;RESETVEC            ; Setup Reset Vector
            EOR    #$A5                       ; Get Power-Up Byte
            STA    SOFTEV
            PLP

*-------------------------------
* Get And Save Boot Prefix
*-------------------------------

            JSR    PD_GPFX                    ; Get The Startup Prefix
            LDX    FLNAME                     ; Save It For Later Use
MVSYS       MOV    FLNAME,X;SYSPFX,X
            DBPL   X;MVSYS

*-------------------------------
* Initialize All Drivers
*-------------------------------

            DO     DEMOPGM
            ELSE
            JSR    MDMINIT                    ; Initialize The Modem
            JSR    PRINIT                     ; And Printer
            FIN
            JSR    CLRBUF                     ; Clear Type Ahead Buffer
            JSR    PRGINIT                    ; Do All The Program Setup
            LDA    #norm
            JSR    VIDCOUT                    ; Set Normal Mode
            LDA    #clrscn
            JSR    VIDCOUT                    ; Clear Local Screen
            LDY    #0                         ; Set I/O Vectors
            JSR    SETOVEC
            JSR    SETIVEC
            JSR    MDMINIT
            JSR    PTERM
            LDA    #3
            STA    AUTORST                    ; Allow Auto-Restart 3 Times
            JMP    LLUCE

I_ATLLST    DB     3
I_ATUNIT    DB     0
            DA     $800
            DA     0

INITGPFX    DB     1
            DA     LNBUF+$80

I_ONLINE    DB     2
I_UNIT      DB     0
            DA     LNBUF+$81

*-------------------------------
* Move Parameters
*-------------------------------

; Move main code
MV_PARMS    DA     SETRAM2
            DA     MOV_F00,VIDRDKY
            DA     MOV_D800-MOV_F00+256

; Move entry points
; and token jump table
            DA     SETRAM2
            DA     MOV_F100,ENTPOINT
            DA     MOV_D400-MOV_F100+256

; Move ramcard data
            DA     SETRAM2
            DA     MOV_F800,SEGSAVE
            DA     MOV_END-MOV_F800+256

; Move high stuff
            DA     SETRAM1
            DA     MOV_D800,XTRAPGM
            DA     MOV_F100-MOV_D800+256

; Move token text
            DA     SETRAM1
            DA     MOV_D400,SYMTXT
            DA     MOV_F800-MOV_D400+256
            DA     0

*===============================
* Standard Inline Print Message Routine
*===============================

IPRINT      PULL   PRN
            PULL   PRN+1
            LDA    SETROM
I_PR1       INCD   PRN
            LDA    (PRN)
            PHP
            ORA    #Hibit
            JSR    MONCOUT
            PLP
            BPL    I_PR1

            INCD   PRN
            JMP    (PRN)

*===============================
* Error, Quitting
*===============================

IQUIT       JSR    IPRINT
            DB     cr,cr
            DCI    '     PRESS A KEY'
            LDA    KBDSTRB                    ; Clear Keyboard
I_WAIT2     LDPL   KYBD;I_WAIT2               ; Wait For Key Press

            LDA    KBDSTRB                    ; Clear Keyboard Again
            PDOS   Quit;DVRQUIT               ; Quit Back To ProDOS

DVRQUIT     DB     4
            DS     8

CRC1        DA     0
CRC2        DA     0
            LST    OFF

