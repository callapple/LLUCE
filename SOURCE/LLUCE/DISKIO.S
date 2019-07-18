            LST    RTN
            TTL    'LLUCE - ProDOS I/O Routines'
            PAG
*===============================
* Contents:
*
* NEW_MLI  - Entry Point For All ProDOS Calls
*            Patched In ProDOS Global Page
* PD_APEND - Set Mark To End Of Disk File
* PD_BOPEN - Open File Channel Y
* PD_CKEOF - Check For End Of Disk File
* PD_CLOSE - Close Disk File
* PD_FLUSH - Flush Data To Disk File
* PD_GEOF  - Get Disk File EOF Pointer
* PD_GINFO - Get A Files Info
* PD_GMARK - Get Disk File Mark
* PD_GPFX  - Get Current Prefix
* PD_KILL  - Delete A File
* PD_MAKE  - Create A File
* PD_NAME  - Rename A File
* PD_NEWLN - Setup For ASCII Line Input
* PD_OPEN  - Open File Channel 0
* PD_QUIT  - Quit To ProDOS
* PD_RBLK1 - Read One Block
* PD_RBYTS - Read a bunch of bytes
* PD_RDBLK - Read Multiple Blocks
* PD_RDBYT - Read Single Byte
* PD_RDLN  - Read ASCII Line From Disk File
* PD_SINFO - Set Files Info
* PD_SMARK - Set 16 Bit Disk File Mark
* PD_SPFX  - Set New Prefix
* PD_SPOS  - Set 24 Bit Disk File Mark
* PD_TREAD - Read Data Bytes
* PD_WBYTS - Write a bunch of bytes
* PD_WRBYT - Write Byte To Disk File
* PD_WRBLK - Write Multiple Blocks
*===============================

*===============================
*   Name: PD_QUIT - Quit To ProDOS
*
*  Input: None
*
* Output: None
*===============================

PD_QUIT     PHP                                   ; No interrupts here!!
            SEI

            MOVD   PDOSVEC;MLI+1                  ; restore MLI Entry Point
            MOVD   IRQSAVE;IRQVEC                 ; restore IRQ vector

            LDEQ   RAMDEV;NODRVR                  ; /RAM removed?

            MOVD   RAMDRVR;DEV2ADR+6

            INC    DEVCNT
            LDY    DEVCNT
FIXDEV      MOV    DEVLST-1,Y;DEVLST,Y
            DBNE   Y;FIXDEV
            MOV    RAMDEV;DEVLST
            STA    SETSTDZP                       ; Standard Memory
            AND    #HiNibble
            STA    DVRUNIT
            MOV    #3;DVRCMD                      ; format command
            MOVD   #SYSTEM;DVRBUFF
            LDA    SETRAM2
            LDA    SETRAM2
            JSR    FMTDVR

NODRVR      STA    SETSTDZP                       ; Standard Memory
            BIT    SETROM
            PLP

            PDOS   Quit;QUITLST                   ; do the quit

            INC    SOFTEV                         ; Should Never Get Here
            JMP    (RESETVEC)                     ; If So, Cold Start

FMTDVR      JMP    (DEV2ADR+6)

QUITLST     DB     4
QUIT_TYP    DB     0                              ; Quit type 0=Standard, EE=extended
QUITPATH    DW     0                              ; App to quit to (Extended only)
            DB     0
            DW     0

*===============================
*   Name: PD_MAKE - Create A File
*
*  Input: Y    - File Type
*         X, A - Aux Type
*
* Output: None
*===============================

PD_MAKE     STY    CR_FTYPE                       ; Save Filetype
            ST16   CR_ATYPE                       ; save aux type
            LDA    #Seedling                      ; 1
            CPNEY  #Dir;CR1                       ; Directory?

            LDA    #Linklist
CR1         STA    CR_STYPE
            LDX    #3
CR_MOVE     STZ    CR_DATE,X
            DBPL   X;CR_MOVE

            PDOS   Create;CRLST
            RTS

CRLST       DB     7
            DW     FLNAME
            DB     %11100011
CR_FTYPE    DB     0
CR_ATYPE    DW     0
CR_STYPE    DB     1
CR_DATE     DW     0
            DW     0

*===============================
*   Name: PD_KILL - Delete A File
*
*  Input: None
*
* Output: None
*===============================

PD_KILL     PDOS   Destroy;DELLST                 ; Delete A File
            RTS

DELLST      DB     1
            DW     FLNAME

*===============================
*   Name: PD_NAME - Rename A File
*
*  Input: None
*
* Output: None
*===============================

PD_NAME     PDOS   Rename;RENLST                  ; Rename A File
            RTS

RENLST      DB     2
            DW     LNBUF
            DW     FLNAME

*===============================
*   Name: PD_SINFO - Set Files Info
*
*  Input: A - File Access
*
* Output: None
*===============================

PD_SINFO    STA    ACCESS                         ; Set File Access
            MOV    #7;INFOLST
            PDOS   Setinfo;INFOLST
            RTS

INFOLST     DB     7
            DW     FLNAME
ACCESS      DB     %11100011
FILETYPE    DB     0
AUXTYPE     DW     0
            DB     1                              ; not used in set_info
            DW     0                              ; not used in set_info
MOD_DATE    DW     0
MOD_TIME    DW     0
            DW     0                              ; not used in set_info
            DW     0                              ; not used in set_info

*===============================
*   Name: PD_GINFO - Get A Files Info
*
*  Input: None
*
* Output: A - Access
*         X - Filetype
*===============================

PD_GINFO    MOV    #10;INFOLST                    ; Get File Access/Type
            PDOS   Getinfo;INFOLST
            LDA    ACCESS
            LDX    FILETYPE
            RTS

*===============================
*   Name: PD_SPFX - Set New Prefix
*
*  Input: None
*
* Output: None
*===============================

PD_SPFX     PDOS   Setpfx;SPFXLST                 ; Set A New Prefix
            RTS

SPFXLST     DB     1
            DW     FLNAME

*===============================
*   Name: PD_GPFX - Get Current Prefix
*
*  Input: None
*
* Output: None
*===============================

PD_GPFX     PDOS   Getpfx;GPFXLST                 ; Get Current Prefix
            RTS

GPFXLST     DB     1
            DW     FLNAME

*===============================
*   Name: PD_OPEN  - Open File Channel 0
*         PD_BOPEN - Open File Channel Y
*
*  Input: Y - Channel Number
*         A - File Access
*
* Output: A - Files Ref Number
*===============================

PD_OPEN     LDY    #0                             ; Open File With Buffer 0
PD_BOPEN    STA    OPENACS                        ; Open File With Buffer Y
            MOV    BUFADR,Y;OPENBUF+1             ; Point At Buffer
OPEN0       TSTPL  ATLAUNCH;OPEN1                 ; Launched From AppleShare?
            MOV    #4;OPENLST                     ; Set For 4 Parameters
            PDOS   SpclOpen;OPENLST               ; AppleTalk Special Open
            BRA    OPEN2

OPEN1       MOV    #3;OPENLST                     ; Set For 3 Parameters
            PDOS   Open;OPENLST
OPEN2       BCC    OPEN3

            CMP    #invalidAccess                 ; Access Error?
            SEC
            BNE    OPEN4

            LDA    #$FF                           ; Wait A Bit
            JSR    WAIT
            BRA    OPEN0                          ; Try It Again

OPEN3       LDA    OPENREF                        ; Save Refnum
            SKIP2
OPEN4       MOV    #-1;REFNUM                     ; Make A Bad Refnum
            RTS

OPENLST     DB     3
            DW     FLNAME
OPENBUF     DW     FBUF1
OPENREF     DB     0
OPENACS     DB     0

*===============================
*   Name: PD_NEWLN - Setup For ASCII Line Input
*
*  Input: None
*
* Output: None
*===============================

PD_NEWLN    MOV    REFNUM;NEWLNREF                ; Enable Newline Mode
            PDOS   Newline;NEWLNLST
            RTS

NEWLNLST    DB     3
NEWLNREF    DB     0
            DB     Clrhi
            DB     cr

*===============================
*   Name: PD_RDLN - Read ASCII Line From Disk File
*
*  Input: Program Pointer
*
* Output: None
*===============================

PD_RDLN     MOV    REFNUM;RDLNREF                 ; Read Text Line From File
            PDOS   Read;RDLNLST
            BNE    RDLINE2                        ; Read Error

            LDX    XFRD                           ; CR At End Of Line?
            LDA    LNBUF-1,X
            AND    #Clrhi
            CPNE   #cr;RDLINE2                    ; No More Stuff

            CLC
            RTS

RDLINE2     MOV    #0;LNBUF                       ; No Data In Line
            SEC                                   ; EOF
            RTS

RDLNLST     DB     4
RDLNREF     DB     0
            DW     LNBUF
            DW     255
XFRD        DW     0

*===============================
*   Name: PD_TREAD - Read Data Bytes
*
*  Input: A - Number Of Bytes To Read
*
* Output: None
*===============================

PD_TREAD    STA    TREQCNT                        ; Set Characters To Read
            MOV    REFNUM;TRDREF
            PDOS   Read;TRDLST
            RTS

TRDLST      DB     4
TRDREF      DB     0
            DW     LNBUF
TREQCNT     DW     0
            DW     0

*===============================
*   Name: PD_RDBYT - Read Single Byte
*
*  Input: None
*
* Output: A - Byte Read
*===============================

PD_RDBYT    LDEQ   REFNUM;RDBYTE2                 ; Read Byte From File
            STA    BRDREF
            PDOS   Read;BRDLST
            BCS    RDBYTE2

            LDA    RWBYTE                         ; Get Byte
            SKIP2
RDBYTE2     LDA    #0                             ; Fake Data
            RTS

BRDLST      DB     4
BRDREF      DB     0
            DW     RWBYTE
            DW     1
            DW     0

RWBYTE      DB     0

*===============================
*   Name: PD_RBYTS
*         PD_WBYTS
*
*  Input: A, X - Address to read into
*         Y    - Number of bytes to read
*
* Output: C - Error flag
*         A - Error code
*===============================

PD_RBYTS    CLC                                   ; Flag for read
            SKIPCS
PD_WBYTS    SEC                                   ; Flag for write
            ST16   RWBADR                         ; Save location
            STY    RWBREQ                         ; and size
            LDA    #Read                          ; assume reading
            BCC    RWBYTS

            LDA    #Write                         ; unless writing
RWBYTS      STA    MODBYTS                        ; set command
            LDEQ   REFNUM;RWBERR                  ; set reference
            STA    RWBREF
            JSR    MLI                            ; execute
MODBYTS     DB     Read
            DA     RWBLST
            BCC    RWBNERR                        ; exit if no error

            SKIP2                                 ; skip next operation
RWBERR      LDA    #0                             ; no open file
            SEC                                   ; set error flag
RWBNERR     RTS

RWBLST      DB     4
RWBREF      DB     0
RWBADR      DW     0
RWBREQ      DW     0
            DW     0

*===============================
*   Name: PD_WRBYT - Write Byte To Disk File
*
*  Input: A - Byte To Write
*
* Output: None
*===============================

PD_WRBYT    STA    RWBYTE                         ; Save Data
            PHA
            LDEQ   REFNUM;WRBYTE2
            STA    BWRREF
            PDOS   Write;BWRLST
            PLA
            RTS

WRBYTE2     PLA
            SEC
            RTS

BWRLST      DB     4
BWRREF      DB     0
            DW     RWBYTE
            DW     1
            DW     0

*===============================
*   Name: PD_RBLK1 - Read One Block
*         PD_RDBLK - Read Multiple Blocks
*         PD_WRBLK - Write Multiple Blocks
*
*  Input: X, A - Buffer Pointer
*         Y    - Number Of Blocks
*
* Output: None
*===============================

PD_RBLK1    LDY    #1                             ; Reading 1 Block
PD_RDBLK    PHA                                   ; Read Y Blocks
            LDRA   #Read;RWBLK                    ; Use Read Call

PD_WRBLK    PHA                                   ; Write Y Blocks
            LDA    #Write
RWBLK       STA    RWTYPE                         ; --- Does Modify
            PLA
            ST16   RWADR                          ; Save Read Address
            STZ    RWREQ
            STY    RWREQ+1                        ; Number Of Blocks To Read
            LSR    RWREQ+1                        ; Divide By 2
            ROR    RWREQ
            LDEQ   REFNUM;RWERR                   ; Get Refnum
            STA    RWREF
            JSR    MLI                            ; Call MLI
RWTYPE      DB     Read                           ; *** Modified ***
            DW     RWLST
            RTS

RWERR       SEC
            RTS

RWLST       DB     4
RWREF       DB     0
RWADR       DW     0
RWREQ       DW     128
            DW     0

*===============================
*   Name: PD_CLOSE - Close Disk File
*         PD_FLUSH - Flush Data To Disk File
*
*  Input: None
*
* Output: None
*===============================

PD_CLOSE    LDA    #Close                         ; Closing A File
            SKIP2                                 ; Skip Next Two Bytes
PD_FLUSH    MOV    #Flush;CLFL_MOD                ; Flushing A File
            MOV    REFNUM;CLFLREF
            JSR    MLI
CLFL_MOD    DB     Close
            DW     CLFLLST
            RTS

CLFLLST     DB     1
CLFLREF     DB     0

*===============================
*   Name: PD_SMARK - Set 16 Bit Disk File Mark
*         PD_SPOS  - Set 24 Bit Disk File Mark
*
*  Input: X, A, Y - Position
*         PD_SMARK - Y=0
*
* Output: None
*===============================

PD_SMARK    LDY    #0                             ; Setting 16 Bit Mark
*-------------------------------
* Do Actual Position Set Within File
*-------------------------------
PD_SPOS     ST24   SMARK                          ; Setting 24 Bit Mark
            MOV    REFNUM;SMARKREF
SETPOS2     PDOS   Setmark;SMARKLST
            CPNE   #outOfRange;SETPOS3            ; Check For Out-Of-Range

            PDOS   Seteof;SMARKLST                ; Set EOF To New Mark
            BEQ    SETPOS2                        ; Position Again

SETPOS3     RTS

SMARKLST    DB     2
SMARKREF    DB     0
SMARK       DB     0,0,0

*===============================
*   Name: PD_GMARK - Get Disk File Mark
*
*  Input: None
*
* Output: None
*===============================

PD_GMARK    MOV    REFNUM;GMARKREF                ; Save Refnum
            PDOS   Getmark;GMARKLST
            LDX    #0                             ; Make Zero In Case Error
            TXA
            TAY
            BCS    GETMRK2                        ; Opps, Error

            LD24   GMARK                          ; All Is Well
GETMRK2     RTS

GMARKLST    DB     2
GMARKREF    DB     0
GMARK       DB     0,0,0

*===============================
*   Name: PD_GEOF - Get Disk File EOF Pointer
*
*  Input: None
*
* Output: X, A, Y - End Of File
*===============================

PD_GEOF     MOV    REFNUM;GEOFREF                 ; Save Refnum
            PDOS   Geteof;GEOFLST
            LD24   GEOF                           ; get length
            RTS

GEOFLST     DB     2
GEOFREF     DB     0
GEOF        DB     0,0,0

*===============================
*   Name: PD_APEND - Set Mark To End Of Disk File
*
*  Input: None
*
* Output: None
*===============================

PD_APEND    JSR    PD_GEOF                        ; Get End Of File
            JMP    PD_SPOS                        ; Append

*===============================
*   Name: PD_CKEOF - Check For End Of Disk File
*
*  Input: None
*
* Output: X = 0: Not At End
*         X = 1: At End
*===============================

PD_CKEOF    JSR    PD_GMARK                       ; Get The Current Place
            SVXAY
            JSR    PD_GEOF                        ; Get The End Of File
            ST24   TEMP
            RSTXAY
            CPLTY  TEMP+2;CHKEOF2                 ; Are They The Same?
            CPLT   TEMP+1;CHKEOF2
            CPLTX  TEMP;CHKEOF2
            LDX    #1                             ; Yep, Mark It
            SKIP2
CHKEOF2     LDX    #0
            RTS

*===============================
*   Name: NEW_MLI - Entry Point For All ProDOS Calls
*                   Patched In ProDOS Global Page
*
*  Input: None
*
* Output: A = ProDOS Error Code
*         P = Status Code
*===============================

NEW_MLI     PHP                                   ; Get Processor Status In A
            PULL   STSAVE                         ; Save For Later
            SEI                                   ; Interrupts Off
            STX    DISK_X                         ; Save X & Y
            STY    DISK_Y
            PULL   DOSPARM
            PULLY  DOSPARM+1
            CLC                                   ; Set Up Return Address
            ADC    #3
            BCC    MLI_OK
            INY
MLI_OK      PHY
            PHA
            LDY    #3                             ; Get Call Number
MLI_MOVE    MOV    (DOSPARM),Y;OURPARM-1,Y
            DBNE   Y;MLI_MOVE                     ; and parameter address

            TSX                                   ; Get Stack Pointer
            STX    $101                           ; Save Aux Stack Pointer
            LDX    $100                           ; Restore Std Stack Pointer
            TXS
            STA    SETSTDZP                       ; ProDOS Is In Standard Area
            PUSHA  STSAVE                         ; Restore Status
            PLP
            JSR    GO_MLI                         ; Call ProDOS Itself
OURPARM     DB     0
            DW     0
            PHP                                   ; Save Status On Stack
            SEI                                   ; Interrupts Off
            TAY                                   ; Save Return Code In Y
            PULL   SETALTZP                       ; Back To Alternate Memory
            TSX                                   ; Save Std Stack
            STX    $100
            LDX    $101                           ; Restore Aux Stack
            TXS
            PHA                                   ; Save Status On Stack
            TYA                                   ; Get Back DOS Error Code
            LDX    DISK_X                         ; Restore X & Y
            LDY    DISK_Y
            PLP                                   ; Restore Status
            RTS

GO_MLI      JMP    (PDOSVEC)

STSAVE      DB     0
            LST    OFF

