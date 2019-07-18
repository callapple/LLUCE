            LST    RTN
            TTL    'LLUCE - Message File Handlers'
            PAG
*===============================
* Contents:
*
* CRUNCH  - Compact A Message File
* KILL2   - Delete A Message
* MAKEMSG - Create A Message File
* MSG     - Get Message Info/Number Of Messages
* RDMAIL  - Read from mail file
* RDMSG   - Read from message file
* READY   - Ready A Message File
* REWIND  - Point To Previous Message Start
* WRMSG   - Write to message file
*===============================

*===============================
*   Name: MAKEMSG - Create A Message File
*
*  Input: Program Pointer
*
* Output: None
*===============================

MAKEMSG     JSR    GETBYT                           ; Eat The Msg Token
            JSR    COMNUM16                         ; Get Message File Size
            TAY                                     ; Round Up To Next 128
            TXA
            AND    #%01111111
            BEQ    MM_OK                            ; (X Mod 128)=0

            TXA
            AND    #%10000000                       ; Clear Off Low
            CLC
            ADC    #$80                             ; Add In Added 128
            TAX
            BCC    MM_OK                            ; Carry To Hi Byte?

            INY                                     ; Yes
MM_OK       STY    TEMP2                            ; Save For Later
            TXA                                     ; Temp2=# Of 128 Messages
            ASL    A
            ROL    TEMP2

            LDEQ   MSGREF;NOTOPEN                   ; Is A File Open?

            STA    REFNUM                           ; Close The Message File
            JSR    PD_CLOSE
            STZ    DEVUSE+7                         ; Flag Not Used
            STZ    DEVUSE+8
NOTOPEN     LDY    #^messages                       ; Create The New File
            LD16   #messages
            JSR    PD_MAKE
            BCS    MM_ERR

            LDY    #ioFile3                         ; Open It
            LDA    #%00110011                       ; Request All, Deny All
            JSR    PD_BOPEN                         ; Open The File
            BCS    MM_ERR                           ; Not There

            STA    MSGREF                           ; Save Reference
            LDX    #31                              ; Clear Header
CLRHEAD     STZ    MSGINFO,X
            DBPL   X;CLRHEAD

            LDA    TEMP2                            ; 8 Bit Blocks Per 128 Msgs
            ASL    A
            ASL    A
            ASL    A
            STA    BITSIZE                          ; Save Bitmap Size
            ASL    A                                ; 16 Dir Blocks Per 128 Msgs
            STA    DIRSIZE
            JSR    FINISH                           ; Write Out Header
            STZ    BITSEG                           ; Start At 0
            STZ    DIRSEG
            LDX    #32
            LDA    BITSIZE                          ; number of bit blocks
            LSR    A
            STA    TEMP
            LDA    DIRSIZE                          ; number of dir blocks
            LSR    A
            CLC
            ADC    TEMP                             ; now have total bytes in X,A
            JSR    PD_SMARK                         ; this also sets the EOF
            JMP    PD_CLOSE                         ; Close The File

MM_ERR      LDA    #Badwrite
            JMP    BADERR                           ; File Exists

*===============================
*   Name: KILL2 - Delete A Message
*
*  Input: Program Pointer
*
* Output: None
*===============================

KILL2       JSR    GETDEV                           ; Get Msg Number
            LD16   MSGNUM
            JSR    GET_MSG                          ; Point To Message Data
            LDY    #1                               ; Get First Block Into A & X
            PUSHA  (TEMP)
            PUSHA  (TEMP),Y
            LDY    #15
            LDA    #0                               ; Zero Pointers
KILL3       STA    (TEMP),Y
            DBPL   Y;KILL3

            JSR    WRTDIR                           ; Write Dir Back To Disk
            PLXY                                    ; Get High, low
            TYA
KILL4       ST16   MSGNUM                           ; Save Block Number
            ORA    MSGNUM                           ; Done?
            BEQ    KILL5                            ; Yep

            LDA    MSGNUM+1
            JSR    DEALLOC                          ; De-Alloc Block
            LD16   MSGNUM                           ; Get Block Number
            JSR    SETBLK                           ; Position To Block
            LD16   #LNBUF                           ; Read In Block
            LDY    #1
            JSR    PD_RDBLK
            LD16   LNBUF+126                        ; Get Next Block Number
            BRA    KILL4                            ; And Repeat

KILL5       JSR    WRTBIT                           ; Update Bitmap
            BRA    FINISH                           ; Write Out Dir Info

*===============================
*   Name: READY - Ready A Message File
*
*  Input: Program Pointer
*
* Output: None
*===============================

READY       IFNE   (PRGPTR);#'#'+Hibit;DO_RDY0      ; ready a message?
            JMP    GETDEV                           ; Fix Message

DO_RDY0     MOV    MSGREF;REFNUM                    ; Get Back Old Refnum
            BEQ    DO_RDY1                          ; File Is Closed

            JSR    PD_CLOSE                         ; Close Old Msgfile
DO_RDY1     JSR    MOVNAME                          ; Get Msg-File Name
            LDEQ   FLNAME;DO_RDY3                   ; They Are Done With It

            LDY    #ioFile3                         ; Use Msgfile Buffer
            LDA    #%00110011                       ; Request All, Deny All
            JSR    PD_BOPEN                         ; Open File
            BCS    DO_RDY4                          ; Hmmm, Thats Bad!

            MOV    REFNUM;MSGREF                    ; Save Refnum
            LDY    #0
DO_RDY2     JSR    PD_RDBYT                         ; Read In Info
            STA    MSGINFO,Y
            INY
            CPNEY  #32;DO_RDY2

            MOV    #-1;DIRSEG                       ; No Dir Or Bit Seg Loaded
            STA    BITSEG
            STA    DEVUSE+7
            STA    DEVUSE+8
DO_RDY3     RTS

DO_RDY4     LDA    #Msgnf                           ; Message File Not Found
            JMP    BADERR

*===============================
* Write Out File Data
*===============================

FINISH      MOV    MSGREF;REFNUM                    ; Get Refnum
            LDX    #0
            TXA                                     ; Goto First Byte
            JSR    PD_SMARK
            LDY    #0
FINISH2     LDA    MSGINFO,Y                        ; Write The Info
            JSR    PD_WRBYT
            INY
            CPNEY  #32;FINISH2

            RTS

*===============================
*   Name: MSG - Get Message Info/Number Of Messages
*
*  Input: Program Pointer
*
* Output: None
*===============================

MSG         IFEQ   (PRGPTR);#Free;MSGFREE
            CPNE   #Size;DO_MSG

*-------------------------------
* Get Message Board Capacity
*-------------------------------

            JSR    GETBYT
            STZ    TEMP                             ; Zero Temp
            LDA    DIRSIZE                          ; Multiple By 16
            ASL    A
            ROL    TEMP
            ASL    A
            ROL    TEMP
            ASL    A
            ROL    TEMP
            ASL    A
            ROL    TEMP
            TAX
            LDA    TEMP
            JMP    MATH_16                          ; Return # Of Entries

*-------------------------------
* Get Number Of Message Blocks Free
*-------------------------------

MSGFREE     JSR    GETBYT
            LDA    BITSIZE
            ASL    A
            ASL    A
            STA    TEMP                             ; Save Total # Of Bit Blocks
            SEC
            LDA    #0
            SBC    USEDBLKS                         ; Subtract To Get Remainder
            TAX
            LDA    TEMP
            SBC    USEDBLKS+1
            JMP    MATH_16                          ; Return Results

DO_MSG      JSR    INPNARG6                         ; Which Message?

            PHAX                                    ; Save Message Number
            IFNE   (PRGPTR);#','+Hibit;DO_MSG0      ; second argument?

            JSR    INPNARG8                         ; Get Second Argument
            TXA
            CPLT   #4;DO_MSG1                       ; Too Large?

DO_MSG0     LDA    #0                               ; Make It 0
DO_MSG1     STA    WMSGNUM                          ; Only 0-3 Allowed
            ASL    A                                ; Multiply By 3
            CLC
            ADA    WMSGNUM;WMSGNUM
            PLAX                                    ; Restore Message Number
            TSTMI  IMMDEF;DO_MSG4                   ; Is This An Assignment?
            CPNEX  NUMFILES;DO_MSG2                 ; Is It The Last Message?
            CPNE   NUMFILES+1;DO_MSG2

            LDX    WMSGNUM                          ; Dont Need To Load Dir
            PUSHA  HIMSGNUM,X                       ; Get Low Byte
            LDA    HIMSGNUM+1,X                     ; Get Mid Byte
            LDY    HIMSGNUM+2,X                     ; Get High Byte
            PLX                                     ; Restore Low Byte
            JMP    DO_MATH

DO_MSG2     ORA    NUMB                             ; Number Of Files?
            BNE    DO_MSG3                          ; Nope

            LD16   NUMFILES                         ; Get Number Of Files
            JMP    MATH_16

DO_MSG3     JSR    GETNUMB                          ; Get Message Number
            JSR    GET_MSG                          ; Get Info
            LDY    WMSGNUM                          ; Get Pointer To Number
            INY                                     ; Skip Block Pointer
            INY
            LDA    (TEMP),Y                         ; New Message # -> X, A & Y
            TAX
            INY
            PUSHA  (TEMP),Y
            INY
            LDA    (TEMP),Y
            TAY
            PLA
            JMP    DO_MATH

DO_MSG4     PHAX                                    ; Save Msg Number
            JSR    EQUNUM                           ; Get Number
            PLAX                                    ; Get Back Msg Number
            LDNEY  NUMFILES;DO_MSG5                 ; Any Messages Yet?
            LDEQY  NUMFILES+1;DO_MSG6

DO_MSG5     CPNEX  NUMFILES;DO_MSG7                 ; Is This Last Message?
            CPNE   NUMFILES+1;DO_MSG7               ; Check High

DO_MSG6     PHAX
            LDX    WMSGNUM
            MOV    NUMB;HIMSGNUM,X                  ; Update Highest New Message
            MOV    NUMB+1;HIMSGNUM+1,X
            MOV    NUMB+2;HIMSGNUM+2,X
            JSR    FINISH                           ; Write Info To Disk
            PLAX                                    ; Restore A And X
DO_MSG7     JSR    GET_MSG                          ; Position To Info
            LDY    WMSGNUM                          ; Get Message Number Offset
            INY                                     ; Skip Block Pointer
            INY
            MOV    NUMB;(TEMP),Y                    ; Save New Message Number
            INY
            MOV    NUMB+1;(TEMP),Y
            INY
            MOV    NUMB+2;(TEMP),Y
            JMP    WRTDIR                           ; Write Dir Back To Disk

*===============================
* Position And Load Directory For Needed Segment
* And Setup Pointers For Needed Entry
*===============================

GET_MSG     DEX                                     ; Msg = Msg - 1
            CPNEX  #-1;GET_MSG1

            DEC    A
GET_MSG1    STX    TEMP                             ; Save Msg Number
            STX    TEMP2
            ASL    TEMP2                            ; Compute Dir Section Number
            ROL    A                                ; 32 Bytes Each
            ASL    TEMP2
            ROL    A
            ASL    TEMP2
            ROL    A
            ASL    A
            ASL    A                                ; A=Actual Block Number
            CPEQ   DIRSEG;GET_MSG2

            STA    DIRSEG                           ; Save Loaded Dir Seg Number
            CLC
            ADC    BITSIZE                          ; Add In Dir Offset
            TAX
            LDA    #0                               ; We Have Starting Block
            JSR    POSMSG                           ; Position For Read
            LD16   #DIRBUF                          ; point to buffer
            LDY    #4                               ; Read 4 Blocks
            JSR    PD_RDBLK
GET_MSG2    LDA    TEMP                             ; Get Msg Number
            ASL    A
            ASL    A                                ; A = A * 4
            ASL    A
            ASL    A
            STA    TEMP
            LDA    #0                               ; Put Last Bit Into A
            ROL    A
            CLC
            ADA    #>DIRBUF;TEMP+1                  ; Add In Location Of Buffer
            RTS                                     ; All Is Set Up

*===============================
* Read A Mail File
*===============================

RDMAIL      TSTMI  DEVCLR;RDMAIL2                   ; Is This Start?

            STX    BUF_X                            ; Save X
            LDX    #2
RDMAIL1     MOV    MSGPTR,X;RWDPTR,X                ; Copy All 5 Bytes
            DBPL   X;RDMAIL1                        ; Loop

            LDX    BUF_X
            DEC    DEVCLR                           ; Clear Change
RDMAIL2     BRA    RDMSG

*===============================
*   Name: REWIND - Point To Previous Message Start
*
*  Input: Program Pointer
*
* Output: None
*===============================

REWIND      LD16   RWDBLK                           ; Get Old Block Number
            CPNEX  RMXBLK;DO_RWD1                   ; Check Low
            CPEQ   RMXBLK+1;DO_RWD2                 ; Check High

DO_RWD1     ST16   RMXBLK                           ; Update
            JSR    SETBLK                           ; Point To Block
            LD16   #BLKBUF                          ; read block back in
            LDY    #1
            JSR    PD_RDBLK
DO_RWD2     MOV    RWDPTR;MSGPTR                    ; Move Pointers
            RTS

*===============================
* Setup Message For Read
*===============================

SETMSG      MOV    #-1;MSGINIT                      ; Init Message Base
            LD16   MSGNUM                           ; Get Message Number
            JSR    GET_MSG                          ; Locate Message
            LDY    #1                               ; Get Starting Block Number
            LDA    (TEMP)
            TAX
            ORA    (TEMP),Y                         ; Check For No Data...
            BEQ    SETMSG2
            LDA    (TEMP),Y
SETMSG1     ST16   RMXBLK                           ; Save Current Block Number
            JSR    SETBLK                           ; Position And Translate
            STZ    RDEND                            ; Reset End Pointer
            STZ    BLKBUF
            LD16   #BLKBUF
            LDY    #1                               ; And Read Data
            JSR    PD_RDBLK
            STZ    MSGPTR                           ; Reset Pointer
            LDX    MSG_X                            ; Get Back X And Y
            LDY    MSG_Y

*-------------------------------
* ... Fall Through And Read A Byte ...
*-------------------------------
* Read A Byte Of Message
*-------------------------------

RDMSG       STX    MSG_X                            ; Save Both X And Y
            STY    MSG_Y
            TSTPL  MSGINIT;SETMSG                   ; Is Read In Progress?
            TSTMI  RDEND;SETMSG2                    ; At End Of Data?
            IFEQY  MSGPTR;#126;RDMSG3               ; Need More Data?
            LDEQ   BLKBUF,Y;RDMSG4                  ; Get Byte, end of data
            IBRA   MSGPTR;SETMSG3                   ; Inc Pointer

RDMSG3      LDA    BLKBUF+126
            TAX
            ORA    BLKBUF+127                       ; Is Next Block 0?
            BEQ    RDMSG4                           ; Yep

            LDRA   BLKBUF+127;SETMSG1               ; Read Next Block

RDMSG4      DEC    RDEND                            ; At End Of Data
SETMSG2     LDA    #0                               ; Opps, No Data
SETMSG3     LDX    MSG_X                            ; Get Back Data
            LDY    MSG_Y
            RTS

*===============================
* Setup Message For Write
*===============================

WRTMSG      LD16   MSGNUM                           ; Get Msg Number
            CPEQ   NUMFILES+1;WRTMSG0               ; Is Message File This Big?
            BLT    WRTMSG1
            BRA    WRTMSG5

WRTMSG0     CPLTX  NUMFILES;WRTMSG1

WRTMSG5     ST16   NUMFILES                         ; Update Message Count
WRTMSG1     JSR    GET_MSG                          ; Locate Message
            LDY    #1
            LDA    (TEMP)
            ORA    (TEMP),Y
            BNE    WRTMSG2

            JSR    ALLOC                            ; Allocate New Block
            ST16   WRKBLK                           ; Update Block Number
            LDY    #1
            STA    (TEMP),Y
            TXA
            STA    (TEMP)
            JSR    WRTDIR                           ; Write Dir Back To Disk
            LDX    MSG_X
            DEC    MSGINIT                          ; Init Msg
            STZ    MSGPTR2                          ; Init Message Pointer
            BRA    WRTMSG4

WRTMSG2     IFNE   BITSEG;#-1;WRTMS2A               ; bitmap loaded?

            LDY    #1                               ; Read In Bitmap
            LDA    (TEMP)
            TAX
            LDA    (TEMP),Y
            JSR    GETBITS
WRTMS2A     JSR    SWPBLK                           ; Swap Pointers
            LDX    MSG_X                            ; Restore X And Y
            LDY    MSG_Y
WRTMSG3     JSR    RDMSG                            ; Do Append To Current Data
            CPNE   #0;WRTMSG3

            JSR    SWPBLK                           ; Swap Back
WRTMSG4     STZ    WRTEND                           ; Let Them Write Data
WRTMSG6     LDX    MSG_X                            ; Get Back Parms
            LDY    MSG_Y
            PLA

*-------------------------------
* ... Fall Through And Write Byte ...
*-------------------------------
* Write A Byte To A Message
*-------------------------------

WRMSG       PHA
            STX    MSG_X                            ; Save X And Y
            STY    MSG_Y
            TSTPL  MSGINIT;WRTMSG                   ; Have We Started?
            TSTMI  WRTEND;WRMSG1B                   ; end written?, no more
            IFEQY  MSGPTR2;#126;WRMSG1              ; Allocate New Block?
            STA    BLKBUF2,Y                        ; Save Data And Continue
            INC    MSGPTR2
            CPNE   #0;WRMSG4

            LDX    MSGPTR2                          ; Zero Rest Of Block & Links
WRMSG0A     STZ    BLKBUF2,X
            IBPL   X;WRMSG0A
            BRA    WRMSG1A                          ; Skip Around Link Setup

WRMSG1      JSR    ALLOC                            ; Allocate New Block
            ST16   BLKBUF2+126

WRMSG1A     LD16   WRKBLK                           ; Translate/Position Block
            JSR    SETBLK
            LD16   #BLKBUF2                         ; Write The Block
            LDY    #1
            JSR    PD_WRBLK

            STZ    MSGPTR2                          ; Reset Pointer
            MOVD   BLKBUF2+126;WRKBLK               ; Save New Block Number
            ORA    WRKBLK                           ; Is There Another Block?
            BNE    WRTMSG6                          ; Yep

            JSR    WRTBIT                           ; Write Out Bitmap
            JSR    FINISH                           ; Write Out Info
            DEC    WRTEND                           ; End Has Been Written
WRMSG4      LDX    MSG_X
            LDY    MSG_Y
WRMSG1B     PLA
            RTS

*===============================
* Allocate A Block For Data
*===============================

ALLOC       IFEQ   BITSEG;#-1;ALLOC4                ; fresh start?

            LDY    #0                               ; Start Count
ALLOC2      LDX    #0
ALLOC3      LDA    BITBUF,Y                         ; Search For Free Block
            AND    BITVAL,X
            BEQ    ALLOC5                           ; Found One

            INX                                     ; Done With Byte?
            CPNEX  #8;ALLOC3
            IBPL   Y;ALLOC2                         ; Done With Buffer?

            JSR    WRTBIT                           ; Write Bit Map Back To Disk
ALLOC4      INC    BITSEG                           ; Is There More Space?
            JSR    RDBIT                            ; Read In Bit Map Segment
            BRA    ALLOC                            ; Start (Keep) Looking

ALLOC5      LDA    BITBUF,Y
            ORA    BITVAL,X                         ; Mark Byte
            STA    BITBUF,Y
            STY    TEMP2                            ; Shift Y Into 16 Bits
            LDA    #0                               ; Bit16 = Y * 8
            ASL    TEMP2
            ROL    A
            ASL    TEMP2
            ROL    A
            ASL    TEMP2
            ROL    A
            STA    TEMP2+1

            TXA                                     ; Add In X
            SEC                                     ; Special (+1)
            ADC    TEMP2                            ; Bit16 = Bit16 + X + 1
            TAX
            BCC    ALLOC6
            INC    TEMP2+1
ALLOC6      LDA    BITSEG                           ; Add In Segment
            ASL    A
            ASL    A                                ; A = A * 4
            CLC
            ADC    TEMP2+1                          ; Bit16 = Bit16 + A
            INCD   USEDBLKS                         ; Add 1 To Used Blocks
            RTS

*===============================
* De-Alloc
*===============================

DEALLOC     JSR    GETBITS
            LDA    TEMP                             ; Shift Down 3 Bits Into A
            LSR    TEMP+1
            ROR    A
            LSR    TEMP+1
            ROR    A
            LSR    A
            TAY
            LDX    TEMP2                            ; Get Bit Offset
            LDA    BITVAL,X
            EOR    #%11111111
            AND    BITBUF,Y                         ; Clear Bit
            STA    BITBUF,Y                         ; And Save

            DECD   USEDBLKS                         ; Used blocks = Used blocks-1
            RTS

*===============================
* Get Bitmap For Current Msg Location
*===============================

GETBITS     SEC
            PHA
            TXA
            SBA    #1;TEMP
            AND    #%00000111
            STA    TEMP2                            ; Save Offset (In Bits)
            PLA
            SBA    #0;TEMP+1                        ; Temp = (AX)-1
            LSR    A
            LSR    A                                ; A = A / 4
            CPEQ   BITSEG;DEALL2                    ; Are We In Position?

            PHA
            IFEQ   BITSEG;#-1;DEALL1                ; first access?

            JSR    WRTBIT                           ; Write Out Current Bitmap
DEALL1      PULL   BITSEG                           ; Update Segment
            JSR    RDBIT                            ; Read Bit Map
DEALL2      RTS

*===============================
* Read or write Bit Map
*===============================

RDBIT       CLC
            SKIPCS
WRTBIT      SEC
            PHP
            LDX    BITSEG
            LDA    #0
            JSR    POSMSG                           ; Position To Block
            LD16   #BITBUF                          ; read in block
            LDY    #1
            PLP
            BCS    WRTBIT2

            JMP    PD_RDBLK

WRTBIT2     JMP    PD_WRBLK

*===============================
* Position To False Block Number
*===============================

SETBLK      ST16   POSBLK                           ; Save Block Number
            CLC
            LDA    BITSIZE                          ; A = Msginfo + Msginfo(1)
            ADC    DIRSIZE
            DEC    A                                ; A = A - 1
            CLC
            ADC    POSBLK                           ; Blk = Blk + A
            TAX
            LDA    POSBLK+1
            ADC    #0
            JMP    POSMSG

*===============================
* Write The Current Directory Segment Back To Disk
*===============================

WRTDIR      CLC
            LDA    DIRSEG                           ; Position To Dir Segment
            ADC    BITSIZE
            TAX
            LDA    #0
            JSR    POSMSG
            SEC
            LDA    DIRSIZE                          ; Get # Of Dir Blocks
            SBC    DIRSEG                           ; Subtract Current Pointer
            CPLT   #4;WRTDIR1                       ; Less Than 4 Blocks Left?
            LDA    #4                               ; More, Only Write 4
WRTDIR1     TAY                                     ; # Of Blocks To Write
            LD16   #DIRBUF                          ; Write It
            JMP    PD_WRBLK

*===============================
* Switch Block Buffers
*===============================

SWPBLK      STZ    SETRAM1
            JSR    SWPBLK0
            STZ    SETRAM2
            RTS

*===============================
*   Name: CRUNCH - Compact A Message File
*
*  Input: Program Pointer
*
* Output: None
*===============================

CRUNCH      MOVX   #-1;DIRSEG
            STX    DIRSEG+1                         ; Load In First Dir Block
            STZ    NUMFILES                         ; Reset Number Of Msgs
            STZ    NUMFILES+1
            LDX    #$80
            LDY    #$80
CRUNCH2     CPEQX  #$80;CRUNCH3                     ; At End Of Block?

            IFEQ   DIRSEG;DIRSIZE;CRUNCH7           ; more data?

            LDA    DIRBUF,X                         ; Is There Any Entry?
            ORA    DIRBUF+1,X
            BNE    CRUNCH4                          ; Yep

            CLC                                     ; X = X + 16
            TXA
            ADC    #$10
            TAX
            BPL    CRUNCH2                          ; Keep Going Until 128 Done

CRUNCH3     INC    DIRSEG
            LDX    #0
            IFEQ   DIRSEG;DIRSIZE;CRUNCH2           ; done?

            PHY                                     ; Save Y
            CLC
            ADC    BITSIZE                          ; Add In Bitmap Offset
            TAX
            LDA    #0
            JSR    POSMSG                           ; Position
            LD16   #DIRBUF                          ; Read Next Dir Block
            LDY    #1
            JSR    PD_RDBLK
            PLY                                     ; Restore Y
            LDEQX  #0;CRUNCH2                       ; Keep Going   CHANGE TO BRA

CRUNCH7     MOVX   #0;DIRBUF                        ; Use 0 Offset
            STX    DIRBUF+1
            STX    DIRBUF+2                         ; Zero Pointers
            STX    DIRBUF+3
CRUNCH4     CPEQY  #$80;CRUNCH6                     ; At End Of Block?

CRUNCH5     IFEQ   DIRSEG;DIRSIZE;CRUNCH5A          ; at end?

            INCD   NUMFILES                         ; Add One To Message Count
CRUNCH5A    STZ    POSBLK
CRUNCH5B    LDA    DIRBUF,X                         ; Copy All Bytes
            PHX
            LDX    POSBLK
            STA    HIMSGNUM-2,X
            PLX
            STA    DIRBUF+128,Y
            INX
            INY
            INC    POSBLK
            IFNE   POSBLK;#16;CRUNCH5B              ; Moving 16 Bytes

            JMP    CRUNCH2

CRUNCH6     IFEQ   DIRSEG+1;#-1;CRUNCH8             ; Do We Want To Write This?

            PHX                                     ; Save X
            CLC
            ADC    BITSIZE                          ; Add In Bitmap
            TAX
            LDA    #0
            JSR    POSMSG                           ; Position
            LD16   #DIRBUF+128                      ; Write Out Dir Segment
            LDY    #1
            JSR    PD_WRBLK
            PLX                                     ; Restore X
            LDY    #$80
CRUNCH8     LDA    #0                               ; Fill Buffer With 0s
CRUNCH9     STA    DIRBUF+127,Y
            DBNE   Y;CRUNCH9

            INC    DIRSEG+1                         ; Use Next Segment
            TAY
            IFNE   DIRSEG+1;DIRSIZE;CRUNCH5         ; Are We At End?

            JSR    FINISH                           ; Write Out 16 Byte Header
            MOV    #-1;DIRSEG                       ; Reset Dir Segment
            RTS

*===============================
* Position File
*===============================

POSMSG      MOVY   MSGREF;REFNUM                    ; Save Refnum
            LSR    A                                ; Setup Y,A,X W/Exact Byte
            TAY
            TXA
            ROR    A
            PHA
            LDA    #%01000000                       ; For 32 Byte Header
            ROR    A
            TAX
            PLA
            JMP    PD_SPOS
            LST    OFF

