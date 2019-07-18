                    TR
                    TR    ADR
* Xmodem, Ymodem, Ymodem-4K, And 4Modem Transfer Drivers
* Written Damn Well By Andy Nicholas -- 2/8/89
*
* Format:
*
* Use "A:Protocol.Down",100,0,F$ = Intelligent Xmodem
* Use "A:Protocol.Down",100,1,F$ = Ymodem
*-------------------------------

                    ORG   $9E00

* Protocol Stuff
*-------------------------------

Soh                 =     1                    ; <Soh> = 128  Byte Block
Stx                 =     2                    ; <Stx> = 1024 Byte Block
Sstx                =     $82                  ; <Sstx> = 4096 Byte Block
Eot                 =     4                    ; <Eot> = End Of Transfer
Ack                 =     6                    ; <Ack> = Good Packet
Nak                 =     $15                  ; <Nak> = Bad Packet
Can                 =     $18                  ; <Can> = Cancel Transfer
Syn                 =     $16
Etb                 =     $17
Esc                 =     $9B                  ; Escape Keypress
Bs                  =     8

* ProDOS MLI Calls
*-------------------------------

GET_FILE_INFO       =     $C4
OPEN                =     $C8
READ                =     $CA
CLOSE               =     $CC
GET_EOF             =     $D1

* General Global Equates
*-------------------------------

Bad                 =     $FF                  ; Boolean Equates
Good                =     0

POINTER             =     0                    ; General Purpose Pointer
FAILFLAG            =     $A
TMODE               =     $B
HTAB                =     $24
GOBCOM              =     $386                 ; Acos Routine To Eat Commas
INPNUM              =     $389                 ; Get Character Into X Reg
INPSTR              =     $38C                 ; Get A String
MOVNAME             =     $38F                 ; Get Filename Into Filename Buffer
SETOVEC             =     $3A1                 ; Set Output Vector To Y Reg
ACOSPATH            =     $3CB                 ; Pathname Addr From Acos
LOCPRINT            =     $906                 ; Print To The Local Screen
MDMIN               =     $E15                 ; Modem Driver Input Routine
MDMOUT              =     $E18                 ; Modem Driver Output Routine
MDMDCD              =     $E1B                 ; Modem Driver Carrier Detect
MLI                 =     $BF00                ; Prodos Calls
KEY                 =     $C000                ; Read Keyboard
STROBE              =     $C010                ; Keyboard Strobe
PAGE1               =     $C054
PAGE2               =     $C055
HIRES               =     $C057
LORES               =     $C056
PTRIG               =     $C070                ; Paddle Trigger
CHKBYT              =     $383                 ; Check Next Byte In Segment

BLOCKBUFFER         =     $2000                ; 4K Block Buffer ($2000-$2Fff)
CRCLO               =     $3100                ; Page For Crc Lo Bytes
CRCHI               =     $3200                ; Page For Crc Hi Bytes
FILEBUFFER          =     $AE00

* Program Starts Here...
*-------------------------------

DOWNLOAD            JMP   DOSTART
                    JMP   DOSTART

*
* Get/Set File Info Parms
*
PARMLIST            DB    $C3                  ; Access
                    DB    4                    ; Filetype (Text)
                    DA    0                    ; Auxtype
                    DB    1                    ; Not Used
                    DA    0                    ; Blocks_Used
                    DA    0                    ; Mod Date
                    DA    0                    ; Mod Time
                    DA    0                    ; Create Date
                    DA    0                    ; Create Time

*
* EOF Parms To Set The Proper End Of The File
*
:EOFParms           DB    2                    ; Parm Count
                    DB    0                    ; Ref_Number
                    DS    3

BLOCKCOUNT          DA    0                    ; Blocks Sent
TOTALERR            DA    0                    ; Total Amount Of Errors

*
*  Rest Of The Code Starts Here
*
DIE                 LDA   #255                 ; Syntax Error
                    STA   FAILFLAG
                    RTS

DOSTART             LDA   #7                   ; Start At Prodos 4Modem
                    STA   TMODE                ; Trans Mode To Prodos 4Modem
                    LDA   #0
                    STA   FAILFLAG             ; Innocent Until Proven Guilty
                    STA   HTAB                 ; Htab 0
                    STA   PACKETNUM            ; Always Packet 0
                    STA   BLOCKCOUNT           ; Block = 0000
                    STA   BLOCKCOUNT+1
                    STA   TOTALERR
                    STA   TOTALERR+1
                    STA   CONSECERR
                    STA   INNERLOOP            ; Abort From Outer Loop, Not Inner
                    STA   USECSUM              ; Don't Use Checksum Mode
                    STA   SENDSMALL            ; Don't Send Small Packets
                    STA   ACKFLAG              ; Always Wait For Acks (No Ymodem-G)
                    LDY   #3                   ; Get Output Channel
                    JSR   SETOVEC              ; Channel 3, Sysop (Local)
                    JSR   GOBCOM
                    JSR   INPNUM               ; Get Timeout
                    STX   TIMEOUT
                    STX   WAITFOR
                    STA   TIMEOUT+1
                    STA   WAITFOR+1
                    STA   STROBE               ; Reset Keyboard Strobe
                    JSR   GOBCOM               ; Get Protocol
                    JSR   INPNUM
                    BNE   DIE

                    STX   TRANSTYPE
                    CPX   #0
                    BEQ   :NOTBATCH

                    JSR   CHKBYT
                    CMP   #","                 ; Is It A Comma?
                    BEQ   :NOTBATCH            ; Yes, Don't Try Final Stuff

                    LDA   #1
                    STA   LASTPACKET
                    LDA   #<FINALBLOCK
                    STA   POINTER
                    LDA   #>FINALBLOCK
                    STA   POINTER+1
                    JSR   PRINTPSTRING
                    STA   $C001                ; Switch Aux Memory In For
                    STA   HIRES                ; The Final Block
                    STA   PAGE2
                    JSR   MAKETABLE            ; Make The Crc Table
                    JSR   CLEARBUF             ; Clear The Block Buffer
                    JMP   SEND_FINAL

:NOTBATCH           JSR   GOBCOM               ; Go To Eat Next Comma
                    JSR   MOVNAME              ; Move Filename For Open Call
                    LDA   ACOSPATH
                    STA   POINTER
                    LDA   ACOSPATH+1
                    STA   POINTER+1
                    LDY   #0                   ; Get LENGTH Of Filename
                    LDA   (POINTER),Y
                    STA   FILENAME
                    TAY
:FNAME              LDA   (POINTER),Y          ; Move Acos's Filename To Ours
                    STA   FILENAME,Y
                    DEY
                    BNE   :FNAME

                    JSR   MLI                  ; Open Our File
                    DB    OPEN
                    DA    OPENPARMS
                    BCC   :OK3                 ; No Errors-Keep Going'

                    JMP   :DIE2

*
* Switch In Proper Memory Banks
*

:OK3                STA   $C001
                    STA   HIRES
                    STA   PAGE2
                    JSR   MAKETABLE            ; Make The Crc Table
                    JSR   CLEARBUF             ; Clear The Block Buffer
                    JSR   MLI
                    DB    GET_FILE_INFO        ; Mli Get_File_Info
                    DA    GFIPARMS
                    BCS   :DIE2

                    LDA   OPENPARMS+5          ; Get Ref_Num
                    STA   GETEOFPARMS+1        ; And Use For Eof Ref Number
                    STA   CLOSEPARMS+1
                    STA   READPARMS+1
                    JSR   MLI
                    DB    GET_EOF              Mli
                    DA    GETEOFPARMS
                    BCS   :DIE2

*
*  Put The Status Line On The Bottom Of The Screen
*

                    LDY   #19                  ; Move All 19 Parameters
:MLOOP              LDA   GFIPARMS+3
                    STA   PARMLIST,Y
                    DEY
                    BPL   :MLOOP

                    LDA   #<SCREENTXT          ; Put The Screentext On The Screen
                    STA   POINTER
                    LDA   #>SCREENTXT
                    STA   POINTER+1
                    JSR   PRINTPSTRING
                    JSR   PRINTCOUNT           ; Show All 0's In The Beginning
                    JSR   PRINTERR
*
*  Put The Filename On The Screen
*
                    LDA   #64
                    STA   HTAB
                    LDA   #<FILENAME           ; Get Pointer To Filename/Lo
                    STA   POINTER              ; Set Up Indirect Address
                    LDA   #>FILENAME           ; Get Pointer To Filename/Hi
                    STA   POINTER+1            ; Finish Setting Up
                    JSR   PRINTPSTRING
                    LDY   #0
:LOOP               INY
                    LDA   FILENAME,Y           ; Get Character In Filename
                    STA   BLOCKBUFFER-1,Y
                    CPY   FILENAME
                    BNE   :LOOP

                    LDA   TRANSTYPE
                    CMP   #0
                    BEQ   XDOWN                ; Is It 0? Yes, Intelligent

                    CMP   #1                   ; Is It 1?
                    BNE   :DIE3                ; Nope, Try Ymodem

                    JMP   YBATCH               ; Yes, Batch Ymode

:DIE2               STA   FAILFLAG
:DIE3               JMP   ENDIT

* Init For Ae Xmodem Send
*-------------------------------

XDOWN               LDA   #10                  ; And 10
                    STA   RETRY                ; Retry
                    JSR   CIN                  ; Look For The Starting C
*
*  If We Got This Far, We Got The Initial Packet,
*  Now Check For AE Mode
*
                    LDA   #3
                    STA   CTRIES
:TRYC               DEC   CTRIES
                    BEQ   :STANDARD

                    LDA   #$81                 ; Soh With Hi Bit Set
                    JSR   MDMOUT               ; Send It
                    LDA   #0                   ; Get Ae Filetype
                    JSR   MDMOUT               ; Send It
                    LDA   #255                 ; Flip The Bits
                    JSR   MDMOUT               ; And Send That
                    JSR   ACKIN                ; Look For Ack
                    BCS   :TRYC                ; Error->Resend

                    JMP   :PRODOS

:STANDARD           DEC   TMODE                ; Drop Into Standard Mode
:PRODOS             LDA   TMODE
                    ASL
                    TAX
                    LDA   PROTOCOLTADDR,X      ; Get Low Byte Of Address
                    STA   POINTER              ; For Text
                    INX
                    LDA   PROTOCOLTADDR,X      ; Get High Byte Of Address For Text
                    STA   POINTER+1
                    LDA   #41
                    STA   HTAB                 ; Htab 12
                    JSR   PRINTPSTRING         ; Print The Xfer Type
                    LDA   TMODE                ; Get The Transfer Type
                    CMP   #6
                    BGE   X4096

                    CMP   #4                   ; Can We Use 1K Blocks?
                    BGE   :JMP1K               ; Yes, Send Via 1K

:JMP128             JMP   X128                 ; No, Only Send 128 Byte Packets

:JMP1K              JMP   X1024                ; Send 1K Blocks

* Start Of 4K Xmodem Packet Sending Routines....
*-------------------------------

X4096               LDX   #<1024
                    LDA   #>1024
                    JSR   READFILE             ; Read 8 Xmodem Blocks
                    JSR   SEND128PACKETS       ; Hopefully Send Them
                    LDA   READPARMS+7
                    CMP   #>1024
                    BEQ   :READ3K

                    JMP   FILEEOT

:READ3K             LDX   #<3072
                    LDA   #>3072
                    JSR   READFILE             ; Read 8 Xmodem Blocks
                    JSR   SEND1KPACKETS        ; Hopefully Send Them
                    LDA   READPARMS+7
                    CMP   #>3072
                    BEQ   :READF

                    JMP   FILEEOT

:READF              LDX   #<4096
                    LDA   #>4096
                    JSR   READFILE             ; Read 'em
                    BCS   :EOF                 ; Landed On A Block Boundary End It

                    CMP   #>4096               ; Did We Get A Big Packet?
                    BEQ   :NEXTBLOCK

                    JSR   SEND1KPACKETS
:EOF                JMP   FILEEOT

:NEXTBLOCK          LDA   SENDSMALL
                    BNE   :STILLERRORS

                    LDA   #10                  ; Initialize To 10 Retry
                    STA   RETRY                ; Store Counter
                    INC   PACKETNUM            ; Next Xmodem Block In Series
                    LDA   BLOCKCOUNT           ; Get Blocks Sent Lo
                    CLC
                    ADC   #32                  ; Blocks Sent=Blocks Sent+32
                    STA   BLOCKCOUNT           ; Store Result
                    BCC   :NOROLL

                    INC   BLOCKCOUNT+1
:NOROLL             JSR   PRINTCOUNT           ; Print # Of Blocks Sent (Again)

:LOOP2              JSR   INITCRC
                    JSR   SEND4096
                    BCC   :READF               ; Ok, Send The Next 1024 Byte Pack

                    LDA   CONSECERR            ; How Many Consecutive Errors Do We Have?
                    CMP   #2                   ; 2?
                    BNE   :LOOP2               ; Nope, Then Retry Large Block

                    DEC   PACKETNUM            ; Decrease Pack # By 1
                    LDA   BLOCKCOUNT           ; Decrease Block Count By 8
                    SEC
                    SBC   #32
                    STA   BLOCKCOUNT
                    BCS   :STILLERRORS         ; No Borrow Required, So No Dec

                    DEC   BLOCKCOUNT+1
:STILLERRORS        LDA   TOTALERR             ; 2 Consec Errors, So Find Out How Many
                    STA   ERRORSBEFORE         ; Before We Send Small Packets
                    LDA   #0
                    STA   SENDSMALL            ; Don't Send Small After This One
                    LDX   READPARMS+6          ; How Much Did We Get?
                    LDA   READPARMS+7
                    JSR   SEND1KPACKETS        ; Unless We Get Errors
                    LDA   ERRORSBEFORE
                    CMP   TOTALERR             ; Did We Get Any Extra Errors?
                    BEQ   :READF

                    LDA   #1
                    STA   SENDSMALL
                    JMP   :READF

* Start Of 1K Xmodem Packet Sending Routines....
*-------------------------------

X1024               LDX   #<512
                    LDA   #>512
                    JSR   READFILE             ; Read 4 Xmodem Blocks
                    JSR   SEND128PACKETS       ; Hopefully Send Them
                    LDA   READPARMS+7
                    CMP   #>512
                    BEQ   :READF

                    JMP   FILEEOT

:READF              LDX   #<1024
                    LDA   #>1024
                    JSR   READFILE             ; Read 'em
                    BCS   :EOF                 ; Landed On A Block Boundary End It

                    CMP   #>1024               ; Did We Get A Big Packet?
                    BEQ   :NEXTBLOCK

                    JSR   SEND128PACKETS
:EOF                JMP   FILEEOT

:NEXTBLOCK          LDA   SENDSMALL
                    BNE   :STILLERRORS

                    LDA   #10                  ; Initialize To 10 Retry
                    STA   RETRY                ; Store Counter
                    INC   PACKETNUM            ; Next Xmodem Block In Series
                    LDA   BLOCKCOUNT           ; Get Blocks Sent Lo
                    CLC
                    ADC   #8                   ; Blocks Sent=Blocks Sent+8
                    STA   BLOCKCOUNT           ; Store Result
                    BCC   :NOROLL

                    INC   BLOCKCOUNT+1
:NOROLL             JSR   PRINTCOUNT           ; Print # Of Blocks Sent (Again)

:LOOP2              JSR   INITCRC
                    JSR   SEND1024
                    BCC   :READF               ; Ok, Send The Next 1024 Byte Pack

                    LDA   CONSECERR            ; How Many Consecutive Errors Do We Have?
                    CMP   #2                   ; 2?
                    BNE   :LOOP2               ; Nope, Then Retry Large Block

                    DEC   PACKETNUM            ; Decrease Pack # By 1
                    LDA   BLOCKCOUNT           ; Decrease Block Count By 8
                    SEC
                    SBC   #8
                    STA   BLOCKCOUNT
                    BCS   :STILLERRORS         ; No Borrow Required, So No Dec

                    DEC   BLOCKCOUNT+1
:STILLERRORS        LDA   TOTALERR             ; 2 Consec Errors, So Find Out How Many
                    STA   ERRORSBEFORE         ; Before We Send Small Packets
                    LDA   #0
                    STA   SENDSMALL            ; Don't Send Small After This One
                    LDX   READPARMS+6          ; How Much Did We Get?
                    LDA   READPARMS+7
                    JSR   SEND128PACKETS       ; Unless We Get Errors
                    LDA   ERRORSBEFORE
                    CMP   TOTALERR             ; Did We Get Any Extra Errors?
                    BEQ   :READF

                    LDA   #1
                    STA   SENDSMALL
                    JMP   :READF

* Start Of 128 Byte Packet Sending Routines
*-------------------------------

X128                LDX   #<1024
                    LDA   #>1024
                    JSR   READFILE             ; Read 1K Of File Always
                    BCS   :EOF                 ; We Landed On A 1K Boundary, All Done

                    CMP   #>1024               ; Did We Get 1K From The File?
                    BNE   :LAST                ; No, Must Be At End, Send Last Blocks

                    JSR   SEND128PACKETS       ; Else Send 1K Worth Of Blocks
                    JMP   X128                 ; Go Read Some More

:LAST               JSR   SEND128PACKETS       ; Send Buffer Full Of Packets
:EOF                JMP   FILEEOT              ; All Done

* End Of File Transmission
*-------------------------------

FILEEOT             LDA   #10                  ; Init To 10
                    STA   RETRY                ; Retry
                    LDA   #1
                    STA   LASTPACKET           ; This Is The Footer
:LOOP               LDA   #Eot
                    JSR   MDMOUT               ; Send It
                    JSR   ACKIN                ; Look For An Ack Response
                    BCS   :LOOP

                    LDA   TMODE                ; Get Trans Mode
                    AND   #%00000001           ; Is It Odd?
                    BNE   FOOTER               ; Yes, Send A Footer Packet

                    JMP   ENDIT                ; Else No Footer Needed, End The Xfer

* Prodos Footer
*-------------------------------

FOOTER              LDY   #5                   ; Init Counter
:LOOP               JSR   INPUT                ; Look For Input
                    CMP   #Syn                 ; Is It A Ctrl-Y?
                    BEQ   :GOT_SYN             ; You Bet!

                    DEY
                    BNE   :LOOP                ; Try Again

                    LDA   #3
                    JMP   BAD_FILE

:GOT_SYN            LDA   #Etb                 ; Etb (Ae Prodos Proto)
                    JSR   MDMOUT               ; Send It
                    JSR   NAKIN                ; Look For Nak
                    JSR   CLEARBUF             ; Clear Out The Block Buffer
                    LDA   #4                   ; 4 Retries
                    STA   RETRY
:LOOP2              LDA   #$AA
                    STA   PACKETNUM            ; Change Block Number To $Aa For AE
                    STA   LASTPACKET           ; Yep, This *IS* The Last Packet
                    JSR   INITCRC
                    LDA   #<GFIPARMS
                    STA   POINTER
                    LDA   #>GFIPARMS
                    STA   POINTER+1
                    LDA   USECSUM              ; Is It In A Checksum Mode?
                    BNE   :CSUM                ; Yes, Send The Last Via Csum

                    JSR   SEND128CRC
                    BCS   :LOOP2               ; Error, Retry

                    JMP   ENDIT

:CSUM               JSR   SEND128CSUM
                    BCS   :LOOP2               ; Error, Retry

                    JMP   ENDIT

* Close File And End
*-------------------------------

ENDIT               JSR   CLOSEFILE
                    LDY   #0
                    STY   HTAB
                    LDA   #' '
:LOOP               JSR   LOCPRINT
                    INY
                    CPY   #79
                    BNE   :LOOP

                    LDY   #0                   ; Return To
                    JSR   SETOVEC              ; Normal Output Vector
                    STA   LORES                ; Reset For Normal Stuff
                    STA   PAGE1                ; Main
                    RTS                        ; Back To Acos

* Start Of Ymodem Batch Sending Routines
*-------------------------------

YBATCH              LDA   #41
                    STA   HTAB
                    LDA   #<YMODEMTEXT         ; Print 'Ymodem' After "Mode:"
                    STA   POINTER
                    LDA   #>YMODEMTEXT
                    STA   POINTER+1
                    JSR   PRINTPSTRING
                    LDA   #$1D                 ; Put The ID Byte There
                    STA   BLOCKBUFFER+64
                    LDA   #$47                 ; Put A "G" For Greg
                    STA   BLOCKBUFFER+65
                    LDX   #0                   ; Move The Gfi And Get Eof
:PARM_LOOP          LDA   GFIPARMS,X           ; Results To Header Packet
                    STA   BLOCKBUFFER+66,X
                    INX
                    CPX   #$17                 ; Done All?
                    BNE   :PARM_LOOP           ; No, Loop

SEND_FINAL          LDA   #10
                    STA   RETRY
                    JSR   BIN                  ; Wait For A 'C'

* Send The Header Packet With Some File Information In It
*-------------------------------

SENDHEAD            JSR   INITCRC
                    JSR   SEND128CRC
                    BCS   SENDHEAD             ; Ack Not Received, Resend Header

                    LDA   BLOCKBUFFER          ; Last One?
                    BNE   PROCEED              ; No, Send File

                    JMP   ENDIT

* If There Is An Actual File To Send, Send It
*-------------------------------

PROCEED             JSR   NAKIN                ; Wait For Another <Nak> Or <C>
; Or Anything For That Matter
                    LDA   GFLAG                ; Skip Acks
                    STA   ACKFLAG
                    LDA   TMODE
                    CMP   #2
                    BNE   :INITSEND

                    JMP   PROCEED4K

:INITSEND           LDX   #<512
                    LDA   #>512
                    JSR   READFILE             ; Read 4 Xmodem Blocks
                    JSR   SEND128PACKETS       ; Hopefully Send Them
                    LDA   READPARMS+7
                    CMP   #>512
                    BEQ   :READF

                    JMP   BATCHEOT

:READF              LDX   #<1024
                    LDA   #>1024
                    JSR   READFILE             ; Read 'em
                    BCS   :EOF                 ; Landed On A Block Boundary End It

                    CMP   #>1024               ; Did We Get A Big Packet?
                    BEQ   :NEXTBLOCK

                    JSR   SEND128PACKETS
:EOF                JMP   BATCHEOT

:NEXTBLOCK          LDA   SENDSMALL
                    BNE   :STILLERRORS

                    LDA   #10                  ; Initialize To 10 Retry
                    STA   RETRY                ; Store Counter
                    INC   PACKETNUM            ; Next Xmodem Block In Series
                    LDA   BLOCKCOUNT           ; Get Blocks Sent Lo
                    CLC
                    ADC   #8                   ; Blocks Sent=Blocks Sent+8
                    STA   BLOCKCOUNT           ; Store Result
                    BCC   :NOROLL

                    INC   BLOCKCOUNT+1
:NOROLL             JSR   PRINTCOUNT           ; Print # Of Blocks Sent (Again)
:LOOP2              JSR   INITCRC
                    JSR   SEND1024
                    BCC   :READF               ; Ok, Send The Next 1024 Byte Pack

                    LDA   CONSECERR            ; How Many Consecutive Errors Do We Have?
                    CMP   #2                   ; 2?
                    BNE   :LOOP2               ; Nope, Then Retry Large Block

                    DEC   PACKETNUM            ; Decrease Pack # By 1
                    LDA   BLOCKCOUNT           ; Decrease Block Count By 8
                    SEC
                    SBC   #8
                    STA   BLOCKCOUNT
                    BCS   :STILLERRORS         ; No Borrow Required, So No Dec

                    DEC   BLOCKCOUNT+1
:STILLERRORS        LDA   TOTALERR             ; 2 Consec Errors, So Find Out How Many
                    STA   ERRORSBEFORE         ; Before We Send Small Packets
                    LDA   #0
                    STA   SENDSMALL            ; Don't Send Small After This One
                    LDX   READPARMS+6          ; How Much Did We Get?
                    LDA   READPARMS+7
                    JSR   SEND128PACKETS       ; Unless We Get Errors
                    LDA   ERRORSBEFORE
                    CMP   TOTALERR             ; Did We Get Any Extra Errors?
                    BEQ   :READF

                    LDA   #1
                    STA   SENDSMALL
                    JMP   :READF

* Start Of 4K Ymodem-4K Packet Sending Routines....
*-------------------------------

PROCEED4K
:READF              LDX   #<4096
                    LDA   #>4096
                    JSR   READFILE             ; Read 'em
                    BCS   :EOF                 ; Landed On A Block Boundary End It

                    CMP   #>4096               ; Did We Get A Big Packet?
                    BEQ   :NEXTBLOCK

                    JSR   SEND1KPACKETS
:EOF                JMP   BATCHEOT

:NEXTBLOCK          LDA   SENDSMALL
                    BNE   :STILLERRORS

                    LDA   #10                  ; Initialize To 10 Retry
                    STA   RETRY                ; Store Counter
                    INC   PACKETNUM            ; Next Xmodem Block In Series
                    LDA   BLOCKCOUNT           ; Get Blocks Sent Lo
                    CLC
                    ADC   #32                  ; Blocks Sent=Blocks Sent+32
                    STA   BLOCKCOUNT           ; Store Result
                    BCC   :NOROLL

                    INC   BLOCKCOUNT+1
:NOROLL             JSR   PRINTCOUNT           ; Print # Of Blocks Sent (Again)
:LOOP2              JSR   INITCRC
                    JSR   SEND4096
                    BCC   :READF               ; Ok, Send The Next 1024 Byte Pack

                    LDA   CONSECERR            ; How Many Consecutive Errors Do We Have?
                    CMP   #2                   ; 2?
                    BNE   :LOOP2               ; Nope, Then Retry Large Block

                    DEC   PACKETNUM            ; Decrease Pack # By 1
                    LDA   BLOCKCOUNT           ; Decrease Block Count By 8
                    SEC
                    SBC   #32
                    STA   BLOCKCOUNT
                    BCS   :STILLERRORS         ; No Borrow Required, So No Dec

                    DEC   BLOCKCOUNT+1
:STILLERRORS        LDA   TOTALERR             ; 2 Consec Errors, So Find Out How Many
                    STA   ERRORSBEFORE         ; Before We Send Small Packets
                    LDA   #0
                    STA   SENDSMALL            ; Don't Send Small After This One
                    LDX   READPARMS+6          ; How Much Did We Get?
                    LDA   READPARMS+7
                    JSR   SEND1KPACKETS        ; Unless We Get Errors
                    LDA   ERRORSBEFORE
                    CMP   TOTALERR             ; Did We Get Any Extra Errors?
                    BEQ   :READF

                    LDA   #1
                    STA   SENDSMALL
                    JMP   :READF

* End Of Transmission Of One File, Return To Caller...
*-------------------------------

BATCHEOT            LDA   #1
                    STA   LASTPACKET
                    LDA   #10                  ; Initialize Count For Last Byte
                    STA   RETRY
:LOOP               LDA   #Eot                 ; Get An Eot
                    JSR   MDMOUT               ; Send It
                    LDA   #0                   ; Always Wait For Acks On EOT
                    STA   ACKFLAG
                    JSR   ACKIN                ; Wait For An Ack
                    BCS   :LOOP                ; If Ok, Finish Up

                    JMP   ENDIT

* Print A Single Character On The Screen
* To Indicate Error Status
*-------------------------------

PRINTERR            PHA                        ; Save The Acc
                    TXA
                    PHA                        ; Save The X-Reg
                    LDA   #19
                    STA   HTAB                 ; Horizontal Location
                    LDX   TOTALERR             ; Total Errors Low Byte
                    LDA   TOTALERR+1           ; Total Errors High Byte
                    JSR   DECOUT               ; Go Print It
                    LDA   #31
                    STA   HTAB                 ; Horizontal Location
                    LDX   CONSECERR            ; Consec Errs Low Byte
                    LDA   #0                   ; Consec Errs High Byte
                    JSR   DECOUT               ; Go Print It
                    PLA                        ; Recover X
                    TAX
                    PLA                        ; Recover Acc
                    RTS                        ; Return

* Print Block Count On Screen After "Block:"
*-------------------------------

PRINTCOUNT          LDA   #6
                    STA   HTAB                 ; Horizontal Location
                    LDX   BLOCKCOUNT           ; Block Count Low Byte
                    LDA   BLOCKCOUNT+1         ; Block Count High Byte
                    JSR   DECOUT               ; Go Print It
                    RTS                        ; Return

* Wait For An <Ack>
*-------------------------------

ACKIN               LDY   #10
:LOOP               LDA   KEY                  ; Get A Keystroke
                    BPL   :NOPRESS             ; Nothing There...

                    CMP   #Esc                 ; Got A Keypress
                    BEQ   :ERR_OUT             ; If It's Escape, Exit Violently

                    STA   STROBE               ; Otherwise, Reset Strobe And Continue
:NOPRESS            JSR   MDMDCD               ; Check For Carrier
                    BCC   :ERR_OUT             ; Ooops Seems We've Lost It

                    LDA   ACKFLAG              ; Should We Check For Ymodem-G?
                    BEQ   :NOTYG               ; Nope

                    JSR   MDMIN                ; Look For Byte Incoming
                    BCC   :GOTIT               ; Nothing Found, Continue Transfer

                    CMP   #Can
                    BNE   :GOTIT               ; If We Get A Single <Can>, Wait

                    JSR   INPUT                ; For Another <Can>, Else Continue
                    BCC   :GOTIT

                    CMP   #Can                 ; If Input = <Can>, Abort
                    BEQ   :ERR_OUT             ; Else Continue
                    BNE   :GOTIT

:NOTYG              JSR   INPUT                ; Look For Input
                    BCC   :NOTHING             ; Nothing Found

                    CMP   #Ack                 ; Is It An <Ack>?
                    BEQ   :GOTIT               ; Yes, Return

                    CMP   #Nak                 ; Is It A <Nak>?
                    BEQ   :BADBLOCK            ; Yes, Flag As Bad

                    AND   #$7F                 ; Strip Hi Bit
                    CMP   LASTCHAR             ; Same Char As Before
                    BNE   :NOT_LAST            ; Nope...But Remember It

                    CMP   #Can                 ; Double <Can>?
                    BEQ   :ERR_OUT             ; Yes...End The Trans.

:NOT_LAST           STA   LASTCHAR             ; Save Char For Later Chk
:NOTHING            DEY                        ; Decrement Loop Count
                    BNE   :LOOP                ; Still Some Left

:BADBLOCK           INC   TOTALERR
                    BNE   :SKIP

                    INC   TOTALERR+1
:SKIP               DEC   RETRY
                    LDA   RETRY
                    CMP   #9
                    BEQ   :NO_CONSEC

                    INC   CONSECERR
                    LDA   CONSECERR
                    CMP   #10
                    BEQ   :ERR_OUT

                    JSR   PRINTERR
:NO_CONSEC          LDA   #0                   ; Zero Acc. We Got Nothing
                    SEC                        ; Set Flag
                    RTS                        ; Return To Caller

:GOTIT              LDX   CONSECERR            ; Get Current Consecutive Error Count
                    LDA   #0                   ; We Got A Good Block, Say That
                    STA   CONSECERR
                    CPX   #0                   ; Check Again For What Once Was
                    BEQ   :GOTIT2              ; If It Already WAS 0, Don't Bother

                    JSR   PRINTERR             ; Else Show The New Consec Err Count
:GOTIT2             CLC
                    RTS

:ERR_OUT            JMP   CLRSTK               ; Go Clear Stack, End Transfer

* Look For <Nak>
*-------------------------------

NAKIN               LDY   #10
:LOOP               LDA   KEY                  ; Get A Keystroke
                    BPL   :NOPRESS             ; Nothing There...

                    CMP   #Esc                 ; Got A Keypress
                    BEQ   :GONE                ; If It's Escape, Exit Violently

                    STA   STROBE               ; Otherwise, Reset Strobe And Continue
:NOPRESS            JSR   MDMDCD               ; Look For Carrier
                    BCC   :GONE                ; Seems Not To Be There!

                    JSR   INPUT                ; Look For Input
                    BCC   :NOTHING             ; Nothing Found

                    CMP   #Nak                 ; Is It Nak?
                    BEQ   :CLEAR               ; Yes, Then Return To Caller

                    CMP   #'C'                 ; Is It A "C" For Ymodem?
                    BEQ   :CLEAR

                    CMP   #'G'                 ; Is It A "G" For Ymodem-G?
                    BEQ   :CLEAR

                    CMP   #'4'                 ; Is It A "4" For Ymodem-4K?
                    BEQ   :CLEAR

                    AND   #$7F
                    CMP   LASTCHAR             ; Same As Before
                    BNE   :NOT_LAST            ; Not The Same As Before

                    CMP   #Can                 ; Double <Can>?
                    BEQ   :GONE

:NOT_LAST           STA   LASTCHAR             ; Remember Char For Checking
:NOTHING            DEY                        ; Decrement Loop Cpunt
                    BNE   :LOOP                ; Still Some Loop Left

                    LDA   #1                   ; Timed Out Waiting
:GONE               JMP   CLRSTK               ; Clear Stack, End Trans..

:CLEAR              CLC
                    RTS

* Wait For A 'C' To Start The Batch Transmission
*-------------------------------

BIN                 LDY   #15                  ; Wait 30 Seconds
:LOOP               LDA   KEY                  ; Get A Keystroke
                    BPL   :NOPRESS             ; Nothing There...

                    CMP   #Esc                 ; Got A Keypress
                    BEQ   :ABORTED             ; If It's Escape, Exit Violently

                    STA   STROBE               ; Otherwise, Reset Strobe And Continue
:NOPRESS            JSR   MDMDCD
                    BCC   :ABORTED

                    JSR   INPUT                ; Get A Character From The Modem
                    CMP   #'C'                 ; Is It A 'c'?
                    BEQ   :OK                  ; Yes, Also Return Gracefully

                    CMP   #'G'                 ; Is It Ymodem-G?
                    BEQ   :OK_G                ; Yes!  Ack!!

                    CMP   #'4'                 ; Was Is Ymodem-4K?
                    BEQ   :OK_4

                    AND   #$7F
                    CMP   LASTCHAR             ; Same As Before
                    BNE   :MAKELAST            ; Not The Same As Before

                    CMP   #Can                 ; Double <Can>?
                    BEQ   :ABORTED             ; Yes, Leave It

:MAKELAST           STA   LASTCHAR
                    DEY                        ; Keep Trying
                    BNE   :LOOP                ; Not Done Yet, Try Again

                    LDA   #1                   ; Timed Out Waiting
:ABORTED            JMP   CLRSTK

:OK                 LDA   #0
                    STA   GFLAG
                    STA   TMODE
                    RTS

:OK_G               LDA   #1                   ; Was Ymodem-G, Flag As Such
                    STA   GFLAG
                    STA   TMODE
                    RTS

:OK_4               LDA   #0                   ; Was Ymodem-4K, Flag As Such
                    STA   GFLAG
                    LDA   #2
                    STA   TMODE
                    RTS

* Look For A 'C' To Start The Transmission
*-------------------------------

CIN                 LDA   #2
                    STA   CTRIES               ; Tries For A C Are 2
                    LDY   #15                  ; Wait 30 Seconds
:LOOP               LDA   KEY                  ; Get A Keystroke
                    BPL   :NOPRESS             ; Nothing There

                    CMP   #Esc                 ; Is It Esc?
                    BEQ   CLRSTK               ; Yes, Exit

                    STA   STROBE               ; Else, Reset Strobe And Continue
:NOPRESS            JSR   MDMDCD               ; Look For Carrier
                    BCC   CLRSTK               ; Lost It

                    JSR   INPUT                ; Input For 2.00 SECs
                    CMP   #'C'                 ; Is It A 'C'
                    BEQ   :GOT_C               ; Yes Return To Caller

                    CMP   #Nak                 ; Is It A <Nak>?
                    BEQ   :GOT_NAK             ; Yes, One More Try

                    AND   #$7F
                    CMP   LASTCHAR             ; Same As Before
                    BNE   :MAKELAST            ; Not The Same As Before

                    CMP   #Can                 ; Double <Can>?
                    BEQ   CLRSTK

:MAKELAST           STA   LASTCHAR
                    DEY
                    BNE   :LOOP

                    LDA   #1                   ; Timed Out Waiting
                    JMP   CLRSTK

:GOT_NAK            DEC   CTRIES
                    BNE   :LOOP                ; Exhausted All Possibilities

                    LDA   #1                   ; Yes, Drop Down Into Cksum
                    STA   TMODE
                    STA   USECSUM              ; Change From CRC To Checksum Mode
                    RTS

:GOT_C              JSR   INPUT                ; Wait For A Second For Inp
                    BCC   :CRC_XMODEM          ; Nothing Found

                    CMP   #'K'                 ; Is It The "K" In CK?
                    BNE   :CRC_XMODEM

:GOT_K              JSR   INPUT                ; Wait For A Second For Inp
                    BCC   :XMODEM_1K           ; Nothing Found

                    CMP   #'L'                 ; Is It The "L" In CKL?
                    BNE   :XMODEM_1K

                    LDA   #7                   ; Set 4Modem Mode
                    STA   TMODE
                    RTS

:XMODEM_1K          LDA   #5
                    STA   TMODE                ; Set Xmodem-1K
                    RTS

:CRC_XMODEM         LDA   #3                   ; Set Crc Xmodem
                    STA   TMODE
                    RTS

* Prepare To Exit To Acos
*-------------------------------

CLRSTK              TAX                        ; Save Error In X Reg
                    LDA   INNERLOOP            ; Are We In An InnerLoop
                    BEQ   :PULL1               ; Nope, In Main Code, Pull Ackin Off Stack

                    PLA                        ; Yes, Pull Ackin Return Then
                    PLA                        ; Previous Return
:PULL1              PLA
                    PLA
                    TXA
BAD_FILE            STA   FAILFLAG
                    LDX   #6                   ; Send 5 <Can> Characters
:LOOP1              LDA   #Can
                    JSR   MDMOUT
                    DEX
                    BNE   :LOOP1

                    LDX   #6                   ; Followed By 5 Backspaces
:LOOP2              LDA   #Bs
                    JSR   MDMOUT
                    DEX
                    BNE   :LOOP2

                    LDA   LASTPACKET           ; Was This The Last?
                    BEQ   :NOTLAST             ; Nope, =0 So Normal Fail

                    LDA   #254
                    STA   FAILFLAG
:NOTLAST            JMP   ENDIT

* Mli Read In The Data
*-------------------------------

READFILE            STX   READPARMS+4
                    STA   READPARMS+5
                    JSR   MLI
                    DB    READ
                    DA    READPARMS
                    PHP                        ; Save State Of Carry Flag
                    LDA   READPARMS+7
                    CMP   READPARMS+5
                    BEQ   :DONE

*
*  Since We Were Not Able To Read All We Wanted,
*  Zero Out The Rest Of The Block Buffer With 00's
*
                    LDA   READPARMS+7          ; Calculate Page To Start On
                    CLC
                    ADC   #>BLOCKBUFFER
                    STA   POINTER+1
                    LDA   #0                   ; Always Start Even
                    STA   POINTER
                    LDY   READPARMS+6          ; Low Byte Offset To Start On
                    LDA   #0                   ; Value To Store
:LOOP               STA   (POINTER),Y          ; Store It
                    INY                        ; Next Value
                    BNE   :LOOP                ; Did The Pages Roll Over?

; Y Rolled Over
:NOROLL             INC   POINTER+1            ; Do Next Page In Series
                    LDA   POINTER+1
                    CMP   #>BLOCKBUFFER+$1000  ; Did We Reach $3000?
                    BNE   :LOOP                ; Nope, Get Some More (Y=0)

:DONE               LDX   READPARMS+6
                    LDA   READPARMS+7
                    PLP                        ; Get State Of Carry Flag Back
                    RTS                        ; Back To Caller

* Clear The 1K Block Buffer
*-------------------------------

CLEARBUF            LDA   #<BLOCKBUFFER
                    STA   POINTER
                    LDA   #>BLOCKBUFFER
                    STA   POINTER+1
                    LDY   #128
                    LDA   #0
:LOOP               STA   (POINTER),Y
                    DEY
                    BPL   :LOOP
                    RTS

* CLOSEFILE - Close The File And Return
*-------------------------------

CLOSEFILE           JSR   MLI
                    DB    CLOSE
                    DA    CLOSEPARMS
                    RTS

* Get Input - SEC=Input, CLC=No Input
*             Wait Up To 1 Second Before Timing Out
*-------------------------------

INPUT               JSR   MDMIN                ; Look For Byte Incoming
                    BCC   :NOTHING             ; Nothing Found, Setup Loop

                    RTS                        ; Byte Found! Return To Caller

:NOTHING            LDA   #0
                    STA   :LASTVBL
                    STA   :SIXTY               ; Sixtieths Of A Second We've Waited
                    STA   :SIXTY+1
:LOOP               JSR   MDMIN                ; Get Byte From Modem
                    BCC   :NO_INP              ; Nothing There, Adjust Loop Counters

                    RTS

:NO_INP             LDA   $C019                ; Has There Been A Change?
                    AND   #$80                 ; Mask All But High Bit
                    CMP   :LASTVBL             ; Look For A Change In The Value
                    BEQ   :LOOP                ; Indicating A Transition

                    STA   :LASTVBL
                    INC   :SIXTY
                    BNE   :NOROLL

                    INC   :SIXTY+1
:NOROLL             LDA   :SIXTY
                    CMP   WAITFOR
                    BNE   :LOOP

                    LDA   :SIXTY+1
                    CMP   WAITFOR+1
                    BNE   :LOOP

                    CLC                        ; Input Was Bad
                    LDA   #0
                    RTS

:LASTVBL            DB    0
:SIXTY              DA    0
WAITFOR             DA    $F0

* Send Soh, Block Number, And Complemented Block Number
*-------------------------------

SENDSOH             LDA   #Soh                 ; Soh
                    JSR   MDMOUT               ; Send It
                    LDA   PACKETNUM            ; Get Block Number
                    JSR   MDMOUT               ; Send It
                    EOR   #$FF                 ; Flip The Bits
                    JSR   MDMOUT               ; Send It
                    RTS

* Send <Stx> (1K Block), Block Number,
* And Complemented Block Number
*-------------------------------

SENDSTX             LDA   #Stx                 ; Stx
                    JSR   MDMOUT               ; Send It
                    LDA   PACKETNUM            ; Get Block Number
                    JSR   MDMOUT               ; Send It
                    EOR   #$FF                 ; Flip The Bits
                    JSR   MDMOUT               ; Send It
                    RTS

* Send <Sstx> (4K Block), Block Number,
* And Complemented Block Number
*-------------------------------

SENDSSTX            LDA   #Sstx                ; Sstx
                    JSR   MDMOUT               ; Send It
                    LDA   PACKETNUM            ; Get Block Number
                    JSR   MDMOUT               ; Send It
                    EOR   #$FF                 ; Flip The Bits
                    JSR   MDMOUT               ; Send It
                    RTS

* Send CRC Bytes Out The Modem
*-------------------------------

SENDCRC             LDA   CRC+1                ; Get Crc Hi Byte
                    JSR   MDMOUT               ; Send It
                    LDA   CRC                  ; Get Crc Lo Byte
                    JSR   MDMOUT               ; Send It
                    RTS

* MAKETABLE -- Make The Crc Table
*-------------------------------

MAKETABLE           LDX   #0                   ; Zero First Page
                    LDA   #0
:LOOP1              STA   CRCLO,X              ; Zero Crc Lo Bytes
                    STA   CRCHI,X              ; Zero Crc Hi Bytes
                    INX
                    BNE   :LOOP1

* The Following Is The Normal Bitwise Computation
* Tweaked A Little To Work In The Table-Maker
*
                    LDX   #0                   ; Number To Do Crc For
:FETCH              TXA
                    EOR   CRCHI,X              ; Add Byte Into High
                    STA   CRCHI,X              ; Of Crc
                    LDY   #8                   ; Do 8 Bits
:LOOP2              ASL   CRCLO,X              ; Shift Current Crc-16 Left
                    ROL   CRCHI,X
                    BCC   :NOADD

* If Previous High Bit Wasn't Set, Then Don't Add Crc
* Polynomial ($1021) Into The Cumulative Crc.  Else Add It.
*
                    LDA   CRCHI,X              ; Add Hi Part Of Crc Poly Into
                    EOR   #$10                 ; Cumulative Crc Hi
                    STA   CRCHI,X
                    LDA   CRCLO,X              ; Add Lo Part Of Crc Poly Into
                    EOR   #$21                 ; Cumulative Crc Lo
                    STA   CRCLO,X
:NOADD              DEY                        ; Do Next Bit
                    BNE   :LOOP2               ; Done? Nope, Loop

                    INX                        ; Do Next Number In Series (0-255)
                    BNE   :FETCH               ; Didn't Roll Over, So Fetch More
                    RTS                        ; Done

* Do A CRC On A Single Byte In A, X Is Preserved, A Is Not
*-------------------------------

DO_CRC              STX   :TEMPX
                    EOR   CRC+1                ; Add Byte Into Crc Hi Byte
                    TAX                        ; To Make Offset Into Tables
                    LDA   CRC                  ; Get Previous Lo Byte Back
                    EOR   CRCHI,X              ; Add It To The Proper Table Entry
                    STA   CRC+1                ; Save It
                    LDA   CRCLO,X              ; Get New Lo Byte
                    STA   CRC                  ; Save It Back
                    LDX   :TEMPX
                    RTS                        ; All Done

:TEMPX              DA    0

* Init Some Pointers, Etc
*-------------------------------

INITCRC             LDA   #<BLOCKBUFFER        ; Set Up Indirect Address To
                    STA   POINTER              ; Point To 1K Buffer Space
                    LDA   #>BLOCKBUFFER
                    STA   POINTER+1
                    LDA   #0
                    STA   CRC
                    STA   CRC+1
                    STA   CHECKSUM
                    RTS

* Send A Packet Of 128 Bytes Protected By A Crc
*-------------------------------

SEND128CRC          JSR   SENDSOH              ; Send <Soh> And Block Number
                    LDY   #0                   ; Zero
:LOOP               LDA   (POINTER),Y          ; Get Character
                    JSR   MDMOUT               ; Send It
                    JSR   DO_CRC
                    INY                        ; Bump Offset
                    BPL   :LOOP                ; Do 128 Bytes

                    JSR   SENDCRC              ; Send CRC Bytes
                    JMP   ACKIN                ; Look For Ack

* SEND128CSUM
* Send A Block Of 128 Bytes Protected By A Checksum
*-------------------------------

SEND128CSUM         JSR   SENDSOH
                    LDY   #0                   ; Zero
:LOOP               LDA   (POINTER),Y          ; Get Character
                    JSR   MDMOUT               ; Send It
                    CLC                        ; Prepare For Add
                    ADC   CHECKSUM             ; Add It To CheckSum
                    STA   CHECKSUM             ; Save CheckSum
                    INY                        ; Bump Offset
                    BPL   :LOOP                ; Do 128 Bytes

                    LDA   CHECKSUM             ; Get Checksum
                    JSR   MDMOUT               ; Send It
                    JMP   ACKIN                ; Look For Ack

* SEND1024 -- Send A 1024 Byte Packet Protected By A CRC
*-------------------------------

SEND1024            JSR   SENDSTX
                    LDX   #4                   ; Send 4 Packs Of 256 Bytes
                    LDY   #0
:LOOP               LDA   (POINTER),Y          ; Get The Byte
                    JSR   MDMOUT               ; Send It
                    JSR   DO_CRC               ; Compute The Cumulative Crc
                    INY                        ; Next Byte
                    BNE   :LOOP                ; Done 256? No, Do Some More

                    INC   POINTER+1            ; Yes, Next 256 Bytes
                    DEX                        ; Are We Done With The 4 Packs?
                    BNE   :LOOP                ; No, Go Send Some More

                    JSR   SENDCRC
                    JMP   ACKIN                ; Check For An Ack

* SEND4096 -- Send A 4096 Byte Packet Protected By A CRC
*-------------------------------

SEND4096            JSR   SENDSSTX
                    LDX   #16                  ; Send 16 Packs Of 256 Bytes
                    LDY   #0
:LOOP               LDA   (POINTER),Y          ; Get The Byte
                    JSR   MDMOUT               ; Send It
                    JSR   DO_CRC               ; Compute The Cumulative Crc
                    INY                        ; Next Byte
                    BNE   :LOOP                ; Done 256? No, Do Some More

                    INC   POINTER+1            ; Yes, Next 256 Bytes
                    DEX                        ; Are We Done With The 16 Packs?
                    BNE   :LOOP                ; No, Go Send Some More

                    JSR   SENDCRC
                    JMP   ACKIN                ; Check For An Ack

* Send Final Set Of Packets If Not 1K Available To Send
*-------------------------------

SEND128PACKETS      STX   BYTES                ; # Of Bytes We Gotta Send
                    STA   BYTES+1
                    LDA   #1
                    STA   INNERLOOP
SEND1KENTRY         LDA   BYTES                ; Packs Remain
                    ASL                        ; Shift High Bit Into Carry
                    LDA   BYTES+1
                    ROL                        ; Rol It Into The Byte
                    STA   PACKSREMAIN

*Number In PacksRemain Is The Num Of 128 Byte Packets Remaining

                    LDA   BYTES                ; If Any Bits Are Set In B128, Then
                    AND   #$7F
                    BEQ   :NOINC               ; There Was A Remainder After The Divide

                    INC   PACKSREMAIN          ; A Remainder
:NOINC              LDA   #<BLOCKBUFFER        ; Make It Initially Point To The
                    STA   POINTER              ; Beginning Of The Block Buffer
                    LDA   #>BLOCKBUFFER
                    STA   POINTER+1
SEND128PACKETSLOOP
:LOOP               LDA   #10                  ; 10 Retries
                    STA   RETRY
                    INC   PACKETNUM            ; Next Xmodem Block In Series
                    INC   BLOCKCOUNT           ; 1 More Block Sent
                    BNE   :NOROLL

                    INC   BLOCKCOUNT+1
:NOROLL             JSR   PRINTCOUNT           ; Print # Of Blocks Sent (Again)
:LOOP2              LDA   #0
                    STA   CRC
                    STA   CRC+1
                    STA   CHECKSUM
                    LDA   USECSUM
                    BNE   :CSUM

                    JSR   SEND128CRC
                    BCS   :LOOP2               ; Not Ok, Resend The Last Block

                    DEC   PACKSREMAIN
                    BNE   :NOTDONE

                    LDA   #0
                    STA   INNERLOOP
                    RTS

:CSUM               JSR   SEND128CSUM
                    BCS   :LOOP2               ; Not Ok, Resend The Last Block

                    DEC   PACKSREMAIN
                    BNE   :NOTDONE

                    LDA   #0
                    STA   INNERLOOP
                    RTS

:NOTDONE            LDA   POINTER              ; Get [Buffer] Address
                    CLC                        ; Next Block Is Gotten 128 Bytes Hence
                    ADC   #128
                    STA   POINTER
                    BCC   :LOOP                ; Didn't Roll Over

                    INC   POINTER+1            ; We Rolled Over!
                    JMP   :LOOP

* Send Final Set Of Packets If 4K Not Available To Send
*-------------------------------

SEND1KPACKETS       STX   BYTES
                    STA   BYTES+1
                    LDA   #1
                    STA   INNERLOOP
                    LDA   BYTES+1              ; Divide Bytes / 1024
                    LSR
                    LSR
                    AND   #%00000111           ; How Many 1K Packets We Got?
                    BNE   :GOT1KPACKETS

                    JMP   SEND1KENTRY

:GOT1KPACKETS       STA   PACKSREMAIN

*Number In PacksRemain Is The Num Of 1K Byte Packets Remaining

                    LDA   #<BLOCKBUFFER        ; Make It Initially Point To The
                    STA   POINTER              ; Beginning Of The Block Buffer
                    LDA   #>BLOCKBUFFER
                    STA   POINTER+1
:LOOP               LDA   #10                  ; 10 Retries
                    STA   RETRY
                    INC   PACKETNUM            ; Next Ymodem Block In Series
                    LDA   BLOCKCOUNT
                    CLC
                    ADC   #8
                    STA   BLOCKCOUNT
                    BCC   :NOROLL

                    INC   BLOCKCOUNT+1
:NOROLL             JSR   PRINTCOUNT           ; Print # Of Blocks Sent (Again)
:LOOP2              LDA   #0
                    STA   CRC
                    STA   CRC+1
                    JSR   SEND1024
                    BCS   :LOOP2               ; Not Ok, Resend The Last Block

                    DEC   PACKSREMAIN
                    BNE   :NOTDONE

                    LDA   BYTES
                    BNE   :SEND128STUFF

                    LDA   BYTES+1
                    AND   #%00000011
                    BNE   :SEND128STUFF

                    LDA   #0
                    STA   INNERLOOP
                    RTS

:NOTDONE            LDA   POINTER              ; Get [Buffer] Address
                    CLC                        ; Next Block Is Gotten 1024 Bytes Hence
                    ADC   #<1024
                    STA   POINTER
                    LDA   POINTER+1
                    ADC   #>1024
                    STA   POINTER+1
                    JMP   :LOOP

:SEND128STUFF       LDA   BYTES                ; Packs Remain
                    ASL
                    LDA   BYTES+1
                    ROL
                    STA   PACKSREMAIN

*Number In PacksRemain Is The Num Of 128 Byte Packets Remaining

                    LDA   BYTES                ; If Any Bits Are Set In B128, Then
                    AND   #$7F
                    BEQ   :NOINC128            ; There Was A Remainder After The Divide

                    INC   PACKSREMAIN          ; A Remainder
:NOINC128           JMP   SEND128PACKETSLOOP

* Print The Pascal String At (POINTER) At Current Cursor Loc
*-------------------------------

PRINTPSTRING        LDY   #0
                    LDA   (POINTER),Y          ; Get Filename Length Byte
                    STA   :LENGTH
:LOOP               INY
                    LDA   (POINTER),Y          ; Get Character In Filename
                    JSR   LOCPRINT
                    CPY   :LENGTH
                    BNE   :LOOP

                    STA   PAGE2
                    RTS

:LENGTH             DB    0

* DECOUT -- Print A Decimal Number
*-------------------------------

; Print A Decimal Number To Stdio.
DECOUT              STA   :HIBYTE              ; Save The Number To Print.
                    STX   :LOBYTE
                    LDX   #9                   ; Start At Largest Value In Table.
                    STX   :NUMFLAG
:P_DEC1             LDY   #"0"                 ; Assume Value Is 0 To Start.
:P_DEC2             LDA   :LOBYTE              ; Is This Value Less Than Table?
                    CMP   :DECTAB-1,X
                    LDA   :HIBYTE
                    SBC   :DECTAB,X
                    BCC   :P_DEC3              ; Yes, Print A Digit From The Table.

                    STA   :HIBYTE              ; No, Keep Dividing Until It Is.
                    LDA   :LOBYTE
                    SBC   :DECTAB-1,X
                    STA   :LOBYTE
                    INY                        ; Next Digit Value.
                    BNE   :P_DEC2              ; Always.

:P_DEC3             TYA                        ; Digit Character To A-Reg For Printing...
                    DEX                        ; Last Digit?
                    BEQ   :PRINTIT             ; Yes, So Output Something.
                    CMP   #"0"                 ; No.  Is This Value A Zero?
                    BEQ   :PRZERO              ; Yes, Must Print At Least One.

                    STA   :NUMFLAG             ; No, We're Going To Print A Digit Though.
:PRZERO             BIT   :NUMFLAG             ; Have We Printed A Real Digit Yet?
                    BMI   :PRINTIT             ; Yes, So We Must Print This One.

                    LDA   JUSTIFY              ; No, So Check For User Justification.
                    BPL   :OVER                ; None.

:PRINTIT            JSR   LOCPRINT             ; Else, This Must Be The Character To Use.
:OVER               DEX                        ; Next Value In Table.
                    BPL   :P_DEC1              ; Until None Left.

                    STA   PAGE2
                    RTS

:HIBYTE             DB    0
:LOBYTE             DB    0
:NUMFLAG            DB    0

:DECTAB             DA    1,10,100,1000,10000

JUSTIFY             DB    0

* Global Data Areas
*-------------------------------

COPYRIGHT           ASC   'Copyright 1987-89 By L & L Productions'
DATE                ASC   '&Sysdate'
TIME                ASC   '&Systime'

PROTOCOLTADDR       DA    STDCSUM
                    DA    PROCSUM
                    DA    STDCRC
                    DA    PROCRC
                    DA    STD1K
                    DA    PRO1K
                    DA    STD4K
                    DA    PRO4K

PRO4K               STR   '4Modem / AE'
STD4K               STR   '4Modem'
PRO1K               STR   'Xmodem-1K / AE'
STD1K               STR   'Xmodem-1K'
PROCRC              STR   'CRC-Xmodem / AE'
STDCRC              STR   'CRC-Xmodem'
PROCSUM             STR   'Xmodem / AE'
STDCSUM             STR   'Xmodem'
YMODEMTEXT          STR   'Ymodem'

SCREENTXT           DB    FINALBLOCK-*
                    ASC   'Block:      Errors:     Consec:     '
                    ASC   'Mode:                  File:'
FINALBLOCK          STR   'Final Packet'

TIMEOUT             DA    0                    ; Timeout In 120Ths Of A Second
CONSECERR           DB    0                    ; # Of Consecutive Errors
CRC                 DA    0                    ; CRC Lo
CHECKSUM            DB    0                    ; Checksum Register
LASTCHAR            DB    0                    ; Last Character
PACKETNUM           DB    0                    ; Block Number
RETRY               DB    0                    ; Retry Count
CTRIES              DB    0                    ; Look For C's Retry Count
TRANSTYPE           DB    0
LENGTH              DB    0                    ; Length Of The Filename
INNERLOOP           DB    0                    ; Are We In An Innerloop? (1=Yes)
USECSUM             DB    0                    ; 0= Use Crc Error Checks,1= Use Checksum
LASTPACKET          DB    0                    ; Was This The Last Packet?
GFLAG               DB    0                    ; Ymodem-G? (0=No, 1=Yes)
ACKFLAG             DB    0                    ; 1=No Wait For Acks, 0=Wait
SENDSMALL           DB    0                    ; Send Small Packets? (0=No,1=Yes)
ERRORSBEFORE        DB    0                    ; How Many Errors Before Send128Packets?
BYTES               DA    0                    ; # Of Bytes Read
PACKSREMAIN         DB    0

*
*  Parms For Open Call
*

OPENPARMS           DB    3                    ; Parm_Count
                    DA    FILENAME             ; Filename
                    DA    FILEBUFFER           ; Buffer Address
                    DB    0                    ; Ref_Num

*
*  ReadParms -- Parameters For Prodos Read Call
*

READPARMS           DB    4                    ; # Of Parms
                    DB    0                    ; Ref_Num
                    DA    BLOCKBUFFER          ; Where
                    DA    0                    ; How Many (Ask)
                    DA    0                    ; How Many (Got)

*
* Close Parameter List
*

CLOSEPARMS          DB    1                    ; Number Of Parms
                    DB    0                    ; Ref_Num

*
*  Storage For Our Filename
*

FILENAME            DS    64

*
* GET_FILE_INFO Parameter List
*

GFIPARMS            DB    $A
                    DA    FILENAME
                    DB    0
                    DB    0
                    DA    0
                    DB    0
                    DA    0
                    DA    0
                    DA    0
                    DA    0
                    DA    0

*
* GetEOF Parameter List
*

GETEOFPARMS         DB    2                    ; Parameter Count
                    DB    0
                    DS    3

