               TR
               TR    ADR
* Use "A:Protocol.Up",100,1,"L10:","               " = Batch
* Use "A:Protocol.Up",100,0,"L10:NEW.FILE" = Single File
*
* Written By Andy Nicholas
*-------------------------------

               ORG   $9E00

* Protocol Stuff
*-------------------------------

Soh            =     1                 ; <Soh>  = 128  Byte Block
Stx            =     2                 ; <Stx>  = 1024 Byte Block
Sstx           =     $82               ; <Sstx> = 4096 Byte Block
Eot            =     4                 ; <Eot>  = End Of Transfer
Ack            =     6                 ; <Ack>  = Good Packet
Nak            =     $15               ; <Nak>  = Bad Packet
Can            =     $18               ; <Can>  = Cancel Transfer
Syn            =     $16
Etb            =     $17
Esc            =     $9B               ; Escape Keypress
Bs             =     8

* ProDOS MLI Calls
*-------------------------------

CREATE         =     $C0
DESTROY        =     $C1
SET_FILE_INFO  =     $C3
GET_FILE_INFO  =     $C4
OPEN           =     $C8
WRITE          =     $CB
CLOSE          =     $CC
FLUSH          =     $CD
SET_EOF        =     $D0

* General Global Equates
*-------------------------------

POINTER        =     0
FAILFLAG       =     $A
TMODE          =     $B
HTAB           =     $24               ; Horizontal Locations
GOBCOM         =     $386              ; Acos Routine To Eat Commas
INPNUM         =     $389              ; Get Character Into X Reg
INPSTR         =     $38C              ; Get A String
MOVNAME        =     $38F              ; Get Filename Into Filename Buffer
SETOVEC        =     $3A1              ; Set Output Vector To Y Reg
LOG            =     $3C8              ; Move Pathname Into Path Buffer
ACOSPATH       =     $3CB              ; Pathname Addr Lo From Acos
LOCPRINT       =     $906              ; Print To The Local Screen
MDMIN          =     $E15              ; Modem Driver Input Routine
MDMOUT         =     $E18              ; Modem Driver Output Routine
MDMDCD         =     $E1B              ; Modem Driver Carrier Detect
MLI            =     $BF00             ; Prodos Calls
KEY            =     $C000             ; Grab A Keystroke
STORE80        =     $C001
STROBE         =     $C010             ; Keyboard Strobe
PAGE1          =     $C054
PAGE2          =     $C055
LORES          =     $C056
HIRES          =     $C057
PTRIG          =     $C070             ; Paddle Trigger

BLOCKBUFFER    =     $2000
FILEBUFFER     =     $AE00             ; 1K File Buffer For Prodos
CRCLO          =     $3100             ; CRC Table Addresses
CRCHI          =     $3200

* Program Starts Here...
*-------------------------------

UPLOAD         JMP   DOSTART
               JMP   DOSTART

*
* Get/Set File Info Parms
*
PARMLIST       DB    $C3               ; Access
               DB    4                 ; Filetype (Text)
               DA    0                 ; Auxtype
               DB    1                 ; Not Used
               DA    0                 ; Length In Prodos Blocks
               DA    0                 ; Mod Date
               DA    0                 ; Mod Time
               DA    0                 ; Create Date
               DA    0                 ; Create Time

*
* EOF Parms To Set The Proper End Of The File
*
:EOFPARMS      DB    2                 ; Parm Count
               DB    0                 ; Reference Number
               DA    0

BLOCKCOUNT     DA    0                 ; Current Block Number
TOTALERR       DA    0                 ; How Many Total Errors Occurred
XMODEMSIZE     DA    0                 ; Size In Xmodem Blocks

* Actual Xmodem Routines Begin Here
*-------------------------------

DOSTART        LDA   #0
               STA   HTAB
               STA   USECSUM           ; Don't Use Checksum Initially
               STA   PACKETNUM
               STA   PACKET1K
               STA   PACKET4K
               STA   FAILFLAG          ; Innocent Until Proven Guilty
               STA   STROBE            ; Reset The Keyboard Strobe
               STA   BLOCKCOUNT        ; Zero Out Block Count Lo
               STA   BLOCKCOUNT+1      ; Zero Out Block Count Hi
               STA   TOTALERR
               STA   TOTALERR+1
               STA   CONSECERR
               STA   BATCHMODE         ; Batchmode = False
               STA   RENAMETRIES       ; 0 Rename Tries
               LDA   #30               ; 30 Retries For The First
               STA   RETRY             ; Header Block.. Fast Ones
               LDY   #3
               JSR   SETOVEC           ; Sysop Local Output Vector
               LDA   #<SCREENTEXT
               STA   POINTER
               LDA   #>SCREENTEXT
               STA   POINTER+1
               JSR   PRINTPSTRING      ; Put The Mode Stuff On The Screen
               JSR   PRINTCOUNT        ; Print The Block Count On The Screen
               JSR   PRINTERR          ; Print The # Of Errors On The Screen
               JSR   GOBCOM
               JSR   INPNUM            ; Get Timeout
               STX   TIMEOUT
               STX   WAITFOR
               STA   TIMEOUT+1
               STA   WAITFOR+1
               JSR   GOBCOM            ; Get Protocol
               JSR   INPNUM
               BNE   :DIE

               CPX   #0
               BEQ   INTELLIGENT       ; Is It 0? Yes, Intelligent

               STX   BATCHMODE         ; Batchmode = True
               STX   TMODE             ; 1=Ymodem,2=Ymodem-4K
               JMP   YBATCH            ; Yes, Batch Ymodem

:DIE           LDA   #255              ; Syntax Error
               STA   FAILFLAG
               RTS

* Start Of Intelligent Protocol Routines
*-------------------------------

INTELLIGENT    JSR   GOBCOM            ; Search For First Delimiter
               JSR   MOVNAME           ; Get Pathname In Buff
               LDA   ACOSPATH
               STA   POINTER
               LDA   ACOSPATH+1
               STA   POINTER+1
               LDY   #0                ; Get Length Of Filename
               LDA   (POINTER),Y
               STA   FILENAME
               TAY
:FNAME         LDA   (POINTER),Y       ; Move Acos's Filename To Ours
               STA   FILENAME,Y
               DEY
               BNE   :FNAME

               STA   STORE80           ; Switch To Aux Hires Bank
               STA   HIRES
               STA   PAGE2
               JSR   MAKETABLE         ; Quick! Go Make The CRC Table!
               LDA   #57
               STA   HTAB
               LDA   #<FILENAME        ; Print Filename As Pascal String
               STA   POINTER
               STA   DESTROYPARMS
               LDA   #>FILENAME
               STA   POINTER+1
               STA   DESTROYPARMS+1
               JSR   PRINTPSTRING
               JSR   MLI               ; Create Our Output File
               DB    CREATE
               DA    CREATEPARMS
               JSR   MLI
               DB    OPEN
               DA    OPENPARMS
               BCC   XSTART

               STA   FAILFLAG          ; Store Error In Peek(10)
               JMP   ERROUT

* The Actual X/Ymodem Routines Start Here
*-------------------------------

XSTART         LDA   OPENPARMS+5
               STA   CLOSEPARMS+1
               STA   EOFPARMS+1        ; Save For Eof Parms
               STA   WRITEPARMS+1      ; Save For Write Parms
               LDA   #$C3              ; Access =
               STA   SFIPARMS+3        ; Unlocked
               JMP   AEHEADER

* Ae Header Error
*-------------------------------

HEADERR        DEC   RETRY
               BNE   AEHEADER

               LDA   #1                ; Flag Header Timeout
               JMP   ERREND

* Attempt To Get The Ae Header And Set Proper Protocol
*-------------------------------

AEHEADER       LDA   #0
:LUP           STA   LASTCHAR
               JSR   INPUT
               BCC   :CLEAR            ; If Channel Is Clear,

               CMP   #Can              ; Is It A <Can>?
               BNE   :CHECKSOH

               CMP   LASTCHAR
               BNE   :CHECKSOH

               JMP   ERREND

:CHECKSOH      JSR   SOHENTRY          ; Check For Send Of Headers
               BCC   :GOTHEADER        ; Hey!  We Got A Header Too Soon
               BCS   :LUP              ; Must Have Been Line Noise... Weird

:CLEAR         JSR   CK_OUT            ; Output A Nak To Start Trans.
               JSR   SOHCHK            ; Look For Start Of Header
               BCS   HEADERR           ; Something Wrong->Start Over

:GOTHEADER     CMP   #Eot              ; Is This The EOT?
               BEQ   HEADERR           ; If So, Something's Screwed...

               LDA   #41
               STA   HTAB
               LDA   RETRY
               CMP   #8
               BCC   :CSUM

               LDA   #3
               STA   TMODE             ; Set Transfer Mode To CRC
               LDA   #<CRCMSG
               STA   POINTER
               LDA   #>CRCMSG
               STA   POINTER+1
               JSR   PRINTPSTRING
               JMP   :SHOW

:CSUM          LDA   #1
               STA   TMODE             ; Set Transfer Mode To Checksum
               STA   USECSUM           ; Tell Them We're Using Checksum Mode
               LDA   #<CSUMMSG
               STA   POINTER
               LDA   #>CSUMMSG
               STA   POINTER+1
               JSR   PRINTPSTRING
:SHOW          LDA   #46
               STA   HTAB
               LDA   LASTCHAR          ; Chk Last Sent Char For Hi Bit
               CMP   #$81
               BNE   XSET              ; Must Not Be AE

               JSR   INPUT             ; Get Input
               BCC   :HEADERRJMP       ; Nothing There

               STA   LASTCHAR          ; Otherwise, Save It
               JSR   INPUT             ; Get Next Input
               BCC   :HEADERRJMP       ; Nothing There

               EOR   #$FF              ; Otherwise, Flip Its Bits
               CMP   LASTCHAR          ; And See If It's First Eored
               BNE   :HEADERRJMP

               JSR   ACKOUT            ; Send Ack

               LDA   #10
               STA   RETRY
               LDA   #<PROMSG
               STA   POINTER
               LDA   #>PROMSG
               STA   POINTER+1
               JSR   PRINTPSTRING
               INC   PACKETNUM         ; Receiving Packet #1
               JMP   NEXTBLOCK         ; Start CRC Xmodem Packet Receive

:HEADERRJMP    JMP   HEADERR

* Set Standard Xmodem Send If There Was Some Problem With Ae
*-------------------------------

XSET           LDA   #<STANDARDMSG
               STA   POINTER
               LDA   #>STANDARDMSG
               STA   POINTER+1
               JSR   PRINTPSTRING
               LDA   #10
               STA   RETRY
               DEC   TMODE
               INC   PACKETNUM         ; Receiving Packet #1
               JMP   STANDARD

* Print A Character On Sysop's Screen, DEC Err Count
*-------------------------------

ERROR          INC   TOTALERR
               BNE   :NOROLL
               INC   TOTALERR+1
:NOROLL        LDA   RETRY
               CMP   #10
               BNE   :NO_CONSEC

               INC   CONSECERR
:NO_CONSEC     JSR   PRINTERR
               JSR   NAKOUT            ; Send <Nak>, Bad Something
               DEC   RETRY             ; More Retries?
               BNE   ERRENTRY          ; Yep, Once More..Till 10

               LDA   #2                ; More Than 2 Consecutive Errors
               JMP   ERREND            ; Nope, End It All

* Get A Block
*-------------------------------

NEXTBLOCK      LDA   #10
               STA   RETRY
ERRENTRY       JSR   SOHCHK
               BCS   ERROR

               JSR   CHECKEOT
STANDARD       LDA   LASTCHAR          ; Entry Point For Standard
               STA   BLK_TYPE
               JSR   BLKCHK
               BCS   ERROR

               LDA   BLK_TYPE
               CMP   #Soh
               BEQ   :GET_128

               CMP   #Stx
               BEQ   :X1024

:X4096         JSR   GET4096
               BCS   ERROR
               BCC   :WRITE_IT

:X1024         JSR   GET1024
               BCS   ERROR
               BCC   :WRITE_IT

:GET_128       LDA   USECSUM
               BNE   :CSUM

               JSR   GET128CRC
               BCS   ERROR
               BCC   :WRITE_IT

:CSUM          JSR   GET128CSUM
               BCS   ERROR

:WRITE_IT      JSR   WRITEBUFFER
               JSR   ACKOUT            ; Send Ack
               JMP   NEXTBLOCK

* Check For End Of Transfer
*-------------------------------

CHECKEOT       LDA   LASTCHAR          ; Get Last Char Sent
               CMP   #Eot              ; Is It A Eot Flag?
               BEQ   :DONE             ; Yes, End It

               RTS                     ; And Back To Caller

:DONE          LDA   BATCHMODE         ; Were We In Batch Mode For This?
               BEQ   FILEEOT           ; Yes, Finish As Batch

               JMP   BATCHEOT          ; Nope, Finish As Batch Mode

* Yeah!  That's All She Wrote
*-------------------------------

FILEEOT        PLA                     ; Get Rid Of Return
               PLA                     ; Address
               JSR   ACKOUT            ; Send Ack
               LDA   TMODE             ; Get Trans Mode
               CMP   #1
               BEQ   GET_FOOT

               CMP   #3
               BEQ   GET_FOOT

NOFOOT         JMP   AESKIP

* Start With Ae Footer Packet
*-------------------------------

GET_FOOT       LDY   #6                ; Set Prodos Footer Retry Count
:LOOP          DEY                     ; Decrement Count
               BEQ   NOFOOT

               LDA   #$16              ; $16 = Syn (Prodos Proto)
               JSR   MDMOUT            ; Send It
               JSR   INPUT             ; Get Input
               CMP   #$17              ; Is It $17 (Etb Prodos Proto)
               BNE   :LOOP             ; Not Etb, Retry

               LDA   #10               ; Init To 10
               STA   RETRY             ; Retry Counter
               JMP   FOOTER

* Prodos Parms Error Restart
*-------------------------------

FOOTERR        INC   TOTALERR
               BNE   :NOROLL
               INC   TOTALERR+1
:NOROLL        LDA   RETRY
               CMP   #10
               BNE   :NO_CONSEC

               INC   CONSECERR
:NO_CONSEC     JSR   PRINTERR
               JSR   NAKOUT
               DEC   RETRY
               BNE   FOOTER

               LDA   #3                ; Footer Error
               JMP   ERREND

* Prodos Mli Info Packet
*-------------------------------

FOOTER         JSR   NAKOUT            ; Send A Nak
               LDA   #$AA
               STA   PACKETNUM
               JSR   SOHCHK            ; Look For Soh
               BCS   FOOTERR           ; Wrong-Retry

               JSR   BLKCHK
               BCS   FOOTERR

               LDA   #<SFIPARMS
               STA   POINTER
               LDA   #>SFIPARMS
               STA   POINTER+1
               LDA   USECSUM
               BNE   :CSUM

               JSR   GET128CRC
               BCS   FOOTERR
               BCC   :DONE

:CSUM          JSR   GET128CSUM
               BCS   FOOTERR

:DONE          JSR   ACKOUT

* Set The End Of The File
*-------------------------------

SETEOF         LDA   #2                ; Fill-In # Of Parameters
               STA   EOFPARMS
               LDA   OPENPARMS+5       ; Fill-In Ref_Num
               STA   EOFPARMS+1
               JSR   MLI
               DB    SET_EOF           Set
               DA    EOFPARMS
               JSR   CLOSEFILE
               LDA   #7                ; Set Info Parm
               STA   SFIPARMS          ; Count
               LDA   #<FILENAME        ; Anything Previous Was Detroyed
               STA   SFIPARMS+1        ; So We Put The Correct Path There
               LDA   #>FILENAME        ; And Hope It Works..Har
               STA   SFIPARMS+2
               JSR   MLI
               DB    SET_FILE_INFO     ; Set Info From What We Given It
               DA    SFIPARMS
               LDY   #19
:MLOOP         LDA   SFIPARMS+3,Y      ; Move All 20 Bytes
               STA   PARMLIST,Y
               DEY
               BPL   :MLOOP

AESKIP         JSR   CLOSEFILE         ; Skip Everything About The File
               LDA   PACKET1K          ; Check For 1K Blocks
               BEQ   :NONE

               INC   TMODE
               INC   TMODE
               LDA   PACKET4K          ; Check For 4K Blocks
               BEQ   :NONE

               INC   TMODE
               INC   TMODE
:NONE          JMP   ERROUT            ; Clear Line And Leave

* Batch Ymodem Starts Here
*-------------------------------

YBATCH         JSR   GOBCOM            ; Gobble The Comma
               JSR   INPSTR            ; Get The First String
               CPY   #5                ; How Many Characters?
               BCC   OVER              ; Less Than 5! Continue

* Routine To Flag Acos Error
*-------------------------------

DIE            LDA   #255
               STA   FAILFLAG
               RTS

* After INPSTR Call, $D Points
* To The String That Was Just Read..
*-------------------------------

OVER           DEY
               LDA   ($D),Y
               CMP   #':'              ; Is The Last Character ':'?
               BNE   DIE               ; Nope Trash It

               TYA
               TAX                     ; Save Y In X
               LDY   #0
               STY   LOG_LO            ; Init Drivespec's To 0
               STY   LOG_HI            ; And 0
               LDA   ($D),Y            ; Get The First Character
               AND   #$7F              ; Strip High Bit
               CMP   #'a'              ; Is It 'a'?
               BCC   :UPPER            ; Nope, Try Others..

               CMP   #'m'              ; Is It 'm'?
               BCS   :UPPER            ; Yes, Trash It

               SBC   #$1F              ; Nope, Make It Uppercase
:UPPER         CMP   #'A'              ; Is It Less Than 'a'?
               BCC   DIE               ; Yeah, Trash It

               CMP   #'M'              ; Is It Greater Than 'l'
               BCS   DIE               ; Yeah, Trash It

               STA   DRIVESPEC         ; Actual Letter Specifier
               DEX                     ; Get Last Character's Position
               BEQ   :NOT3             ; Is It The Last One Already? Yep

               JSR   STRIPHI           ; Not Last,Strip High From Letter
               DEX                     ; Is It The Last One Now?
               BEQ   :NOT3             ; Yep, Just Continue

               JSR   STRIPHI           ; Otherwise, Strip Bit Again
:NOT3          LDX   LOG_HI            ; Get High Part Of Log #
               LDA   LOG_LO            ; Get Low Part Of Log #
               BNE   :NOT0             ; Low Part Is Not 0, Try Others

               CMP   LOG_HI            ; Is The High Part Also 0?
               BEQ   :BOTH0            ; Yes, Go Do Normal Log

:NOT0          CPX   #0                ; Is The High Part A 0?
               BNE   :H9E57

               TAX
               LDA   #0
:H9E57         AND   #$F
               STA   HA1EF
               TXA
               AND   #$F
               LDY   #$A
:H9E61         CLC
               ADC   HA1EF
               DEY
               BNE   :H9E61

               TAX                     ; X=Number To Log
:BOTH0         LDA   DRIVESPEC         ; A=Letter To Log
               JSR   LOG               ; Set Prefix For That Pathname
               JSR   GOBCOM            ; Grab The Comma
               JSR   INPSTR            ; Get Filename Area
               CPY   #15               ; Is It >= Than 15?
               BEQ   DO_YMODEM         ; Yes, Go There

               LDA   #255
               STA   FAILFLAG
               RTS

* Error Routine - Errors Within The Transfer
*-------------------------------

BATCHERROR     INC   TOTALERR
               BNE   :NOROLL
               INC   TOTALERR
:NOROLL        JSR   PRINTERR
               JSR   NAKOUT
NONAK          DEC   RETRY
               BNE   DO_YMODEM

               LDA   #1                ; Fatal Header Error
               JMP   NO_DEL

* Here Begin Most Of The Important Ymodem Routines
*-------------------------------

DO_YMODEM      JSR   CLRSTRING
               STA   STORE80
               STA   HIRES
               STA   PAGE2
               JSR   MAKETABLE         ; Quick!  Make The CRC-Table!
               LDA   #0
:LUP           STA   LASTCHAR
               JSR   INPUT
               BCC   :CLEAR

               CMP   #Can              ; Is It A <Can> Character?
               BNE   :CHECKSOH

               CMP   LASTCHAR
               BNE   :CHECKSOH

               JMP   ERREND

:CHECKSOH      JSR   SOHENTRY          ; It Is A Block Header?
               BCC   :GOTHEADER
               BCS   :LUP              ; Must have Been Line Noise...

:CLEAR         LDX   TMODE             ; Using Ymodem Or Ymodem-4K?
               DEX                     ; Was 1 Or 2, Now 0 Or 1
               LDA   STARTSIG,X        ; Clear Channel, Send The 'c'
               JSR   MDMOUT            ; Send It
               JSR   SOHCHK            ; Get Header
               BCS   NONAK             ; Something Went Wrong...

:GOTHEADER     LDA   LASTCHAR
               CMP   #Soh              ; Must Be Small Header Packet
               BNE   BATCHERROR        ; Nope, We Got Problems

               JSR   BLKCHK            ; Make Sure The Next 2 Bytes
               BCS   BATCHERROR        ; Are In Sync

               JSR   GET128CRC         ; Get A Small Packet
               BCS   BATCHERROR

               LDA   BLOCKBUFFER       ; Get First Byte Of Packet
               BNE   PROC_FILE         ; 0? Nope, Process File...

               JSR   ACKOUT            ; Yeah! End Of Transfer
               JMP   ERROUT            ; String Is Already Clear So End

* Continue With File Transfer Since There Is A Filename
*-------------------------------

PROC_FILE      LDY   #0                ; Calculate Length Of File
:LEN_LOOP      LDA   BLOCKBUFFER,Y     ; Get A Byte Of The Filename
               BEQ   :ENDNAME

               STA   FILENAME+1,Y      ; Put It At The Filename
               INY
               BNE   :LEN_LOOP         ; Loop Until A (0) Found

:ENDNAME       STY   FILENAME          ; Save Length Of File
               LDY   #19
:MLOOP         LDA   BLOCKBUFFER+69,Y  ; Move The Gfi Parms And
               STA   SFIPARMS+3,Y      ; Eof Parms, All 20 Bytes
               STA   PARMLIST,Y
               DEY
               BPL   :MLOOP

               JSR   PRNTEXT
               LDA   BLOCKBUFFER+64    ; Is It Proterm Special Batch?
               CMP   #$1D
               BEQ   :PROTERM          ; Yes, Flag As Such

               LDA   #1                ; Nope, Must Be 'standard' Batch
               STA   BATCHTYPE
               JMP   CREATEAGAIN

:PROTERM       LDA   #0
               STA   BATCHTYPE
               LDA   #2                ; Make Sure The Parameter
               STA   EOFPARMS          ; Count Is Correct
               LDA   #7
               STA   SFIPARMS
               LDA   SFIPARMS+7        ; Get Storage Type For File
               STA   CREATEPARMS+7     ; Store It For Creation
               LDA   #<FILENAME        ; Get Pathname For File
               LDX   #>FILENAME
               STA   SFIPARMS+1        ; Store It For Later On
               STX   SFIPARMS+2        ; When Doing The Sfi Call
CREATEAGAIN    JSR   MLI
               DB    CREATE            ; Create A File
               DA    CREATEPARMS       ; Create Params
               BCC   CREATE_OK         ; Continue If Ok

* File Creation Was In Error
*-------------------------------

PRO_ERR        CMP   #$47              ; Is It A Duplicate Filename?
               BNE   KILL_FILE

               INC   RENAMETRIES
               LDA   RENAMETRIES
               CMP   #26
               BNE   :OK

               LDA   #$47              ; Duplicate Filename Error
               STA   FAILFLAG
               JMP   NO_DEL

:OK            LDY   FILENAME
               CPY   #15
               BEQ   :GOT15

               INY
               LDA   #'.'
               STA   FILENAME,Y
               STY   FILENAME
               JMP   CREATEAGAIN

:GOT15         LDA   FILENAME+2
               CMP   #'Z'
               BEQ   :MAKEA

               INC   FILENAME+2
               JMP   CREATEAGAIN

:MAKEA         LDA   #'A'
               STA   FILENAME+2
               JMP   CREATEAGAIN

KILL_FILE      PHA                     ; Save Our Error Code
               STA   PAGE1
               JSR   CLRSTRING
               STA   PAGE2
               PLA                     ; Restore Our Error Code
               JMP   ERREND

* Continue With The Transfer If File Create Was Successful
*-------------------------------

CREATE_OK      STA   PAGE1
               LDY   FILENAME          ; Move Filename To String
:LOOP2         LDA   FILENAME,Y
               DEY
               STA   ($D),Y
               CPY   #0
               BNE   :LOOP2

               STA   PAGE2
               JSR   MLI
               DB    OPEN              ; Open
               DA    OPENPARMS         ; Open Params
               BCS   KILL_FILE         ; On Error Close Shop

               LDA   OPENPARMS+5       ; Number Of Open File??
               STA   EOFPARMS+1
               STA   WRITEPARMS+1
               STA   CLOSEPARMS+1
               JSR   ACKOUT
               LDA   #$3C              ; Change The Length To Wait
               STA   WAITFOR
               LDA   #0
               STA   WAITFOR+1
:LOOP          JSR   INPUT             ; Look For Input For 0.5 SECond
               BCS   :LOOP             ; Keep Waiting Till Nothing Is Incoming

               LDA   TIMEOUT
               STA   WAITFOR
               LDA   TIMEOUT+1
               STA   WAITFOR+1
               LDX   TMODE             ; Get Either The C Or 4
               DEX
               LDA   STARTSIG,X
               JSR   MDMOUT
               JMP   NEXTBLOCK         ; Go Get A *LOT* Of Blocks

* Strip High Bit From Acos Pathname
*-------------------------------

STRIPHI        INY
               LDA   ($D),Y
               AND   #$7F
               STA   DRIVESPEC,Y
               RTS

DRIVESPEC      DB    0                 ; Drivespec
LOG_LO         DB    0                 ; 1's Or 10's
LOG_HI         DB    0                 ; 1's Or 10's

* <Ack> Output Routine
*-------------------------------

ACKOUT         LDX   CONSECERR
               LDA   #0                ; We Got Something Good, No Consec Errs
               STA   CONSECERR
               CPX   #0                ; Did We Have Any Consec?
               BEQ   :RESETERR         ; Nope, Don't Erase Anything

               JSR   PRINTERR          ; Yes, Erase The Consec
:RESETERR      LDA   #Ack              ; Get Ack
               JMP   MDMOUT            ; Send It Out The Modem

* <Nak> Output Routine
*-------------------------------

NAKOUT         LDA   #$3C
               STA   WAITFOR
               LDA   #0
               STA   WAITFOR+1
:LOOP          JSR   INPUT             ; Look For Input
               BCS   :LOOP             ; Keep Waiting Till Nothing Is Incoming

               LDA   TIMEOUT
               STA   WAITFOR
               LDA   TIMEOUT+1
               STA   WAITFOR+1
               LDA   #Nak              ; Get Nak
               JMP   MDMOUT            ; Send It And Return To Caller

* Send A 'CKL' To Start Transmission
*-------------------------------

CK_OUT         JSR   MDMDCD
               BCC   CLRSTK

               LDA   RETRY
               CMP   #8                ; Is This The 8Th Retry?
               BCC   :SEND_NAK         ; Yes, Start Sending <Nak>S

:SEND_CK       JSR   MDMIN             ; Look For Input
               BCS   :SEND_CK          ; Keep Waiting Till Nothing Is Incoming

               LDA   #'C'              ; Get C
               JSR   MDMOUT            ; Send It
               LDA   #'K'              ; Get K
               JSR   MDMOUT            ; Send It
               LDA   #'L'              ; Get L
               JMP   MDMOUT            ; Have Sent <C><K><L>

:SEND_NAK      JSR   MDMIN             ; Look For Input
               BCS   :SEND_NAK         ; Keep Waiting Till Nothing Is Incoming

               LDA   #Nak              ; Get Nak
               JMP   MDMOUT            ; Send It And Return To Caller

* Write Xxxx Bytes To File
*-------------------------------

WRITEBUFFER    STX   WRITEPARMS+4
               STA   WRITEPARMS+5
               JSR   MLI
               DB    WRITE             ; Write A Packet
               DA    WRITEPARMS
               BCS   CLRSTK            ; Onerr Exit...

               RTS                     ; Return To Caller

* Clrstk And Errend Go Together...
*-------------------------------

CLRSTK         TAX                     ; Save Our Error Number
               PLA                     ; Pull Extra Return
               PLA
               TXA                     ; Restore Our Error Number
ERREND         STA   FAILFLAG          ; Store Our Error In FAILFLAG
               JSR   CLOSEFILE
               JSR   DESTROYFILE
NO_DEL         JSR   CLOSEFILE
               LDY   #6                ; Send 5 <Can> Characters
               LDA   #Can
:LOOP          JSR   MDMOUT
               DEY
               BNE   :LOOP

               LDY   #6                ; Followed By 5 Backspace Characters
               LDA   #Bs
:BS_LOOP       JSR   MDMOUT
               DEY
               BNE   :BS_LOOP

               JMP   ERROUT

* Get Header Routine... SEC=No Sohchk, CLC=Sohchk
*-------------------------------

SOHCHK         LDA   KEY               ; Read The Keyboard
               BPL   :NOPRESS          ; Anyone Pressed A Key? Nope

               CMP   #Esc              ; Yes, Is It The Escape Key?
               BEQ   CLRSTK            ; Yes, Exit Violently

               STA   STROBE            ; No, Reset Strobe, Continue
:NOPRESS       LDA   #0
               STA   CRC               ; Init The CRC Counter
               STA   CRC+1
               STA   CHECKSUM
               JSR   MDMDCD            ; Is Caller Still There?
               BCC   CLRSTK            ; No, Exit

               JSR   INPUT             ; Yes, Get Some Data
               BCC   BAD               ; Nothing There, Lose It

SOHENTRY       CMP   #Can              ; Is It A <Can>?
               BNE   :CONTINUE         ; No, Continue

               CMP   LASTCHAR          ; Yes, Is It 2 In A Row?
               BEQ   CLRSTK            ; Yes, Leave Suddenly

:CONTINUE      STA   LASTCHAR
               CMP   #Eot
               BEQ   :OK

               CMP   #Sstx             ; Is It A 4K Packet?
               BEQ   :XLARGE           ; Yes, Go Handle It

               CMP   #Stx              ; Is It A Large Packet?
               BEQ   :LARGE            ; Go Handle It

               AND   #$7F              ; Strip High Off For AE Mode
               CMP   #Soh
               BNE   BAD               ; Nothing We've Ever Seen

:OK            CLC
               RTS

:LARGE         LDY   #1
               STY   PACKET1K
               CLC
               RTS

:XLARGE        LDY   #1
               STY   PACKET4K
               CLC
               RTS

BAD            SEC
               RTS

* Get Input - SEC=Input, CLC=No Input
*             Wait Up To 1 SECond Before Timing Out
*-------------------------------

INPUT          JSR   MDMIN             ; Look For Byte Incoming
               BCC   :NOTHING          ; Nothing Found, Setup Loop

               RTS                     ; Byte Found! Return To Caller

:NOTHING       LDA   #0
               STA   :LASTVBL
               STA   :SIXTY            ; Sixtieths Of A SECond We've Waited
               STA   :SIXTY+1
:LOOP          JSR   MDMIN             ; Get Byte From Modem
               BCC   :NO_INP           ; Nothing There, Adjust Loop Counters

               RTS

:NO_INP        LDA   $C019             ; Has There Been A Change?
               AND   #$80              ; Mask All But High Bit
               CMP   :LASTVBL          ; Look For A Change In The Value
               BEQ   :LOOP             ; Indicating A Transition

               STA   :LASTVBL
               INC   :SIXTY
               BNE   :NOROLL
               INC   :SIXTY+1
:NOROLL        LDA   :SIXTY
               CMP   WAITFOR
               BNE   :LOOP

               LDA   :SIXTY+1
               CMP   WAITFOR+1
               BNE   :LOOP

               CLC                     ; Input Was Bad
               LDA   #0
               RTS

:LASTVBL       DB    0
:SIXTY         DA    0
WAITFOR        DA    $F0

* Check Block Number And Complement
*-------------------------------

BLKCHK         LDA   #<BLOCKBUFFER
               STA   POINTER
               LDA   #>BLOCKBUFFER
               STA   POINTER+1
               JSR   INPUT             ; Get Input
               BCC   SETRTS            ; Nothing There

               STA   LASTCHAR          ; Otherwise, Save It
               CMP   PACKETNUM         ; Is It The Current Block #?
               BNE   SETRTS            ; Nope, Return In Error

               JSR   INPUT             ; Get Next Input
               BCC   SETRTS            ; Nothing There

               EOR   #$FF              ; Otherwise, Flip Its Bits
               CMP   LASTCHAR          ; And See If It's First Eored
               BNE   SETRTS

               CLC                     ; Otherwise Flag Ok
               RTS                     ; And Return

SETRTS         SEC                     ; Flag Error
               RTS                     ; And Return

* End Of Transmission
*-------------------------------

BATCHEOT       PLA
               PLA
               JSR   ACKOUT            ; Respond In Kind
               LDA   BATCHTYPE         ; If The Kind Of Batch Is Forsberg
               BNE   :SETOK            ; Then Don't Bother To Set_EOF

               JSR   MLI
               DB    SET_EOF           ; Set_Eof
               DA    EOFPARMS          ; Parms
               BCC   :SETOK

:ERR_JUMP      JMP   ERREND

:SETOK         JSR   CLOSEFILE
               LDA   BATCHTYPE         ; What Kind Of Batch?
               BNE   ERROUT            ; Forsberg, Skip This Step

               JSR   MLI
               DB    SET_FILE_INFO     ; Set_File_Info
               DA    SFIPARMS          ; Sfi Params
               BCS   :ERR_JUMP         ; On Error Kill The File, Exit

ERROUT         LDY   #0
               STY   HTAB
               LDA   #$20
:LOOP          JSR   LOCPRINT          ; Clear Bottom Line...
               INY
               CPY   #79
               BNE   :LOOP

               LDY   #0
               STY   HTAB              ; Start At HTAB 0
               STA   LORES             ; Reset Our Memory Bank
               STA   PAGE1
               JMP   SETOVEC           ; Set #0 To Output Vector
; Return To Acos

* Close Whatever We Have Opened
*-------------------------------

CLOSEFILE      JSR   MLI
               DB    CLOSE             ; Close
               DA    CLOSEPARMS        ; Close Params
               RTS

* ProDOS MLI Destroy A File Call
*-------------------------------

DESTROYFILE    JSR   MLI
               DB    DESTROY           ; Destroy
               DA    DESTROYPARMS
               RTS

* Print Error Count
*-------------------------------

PRINTERR       LDA   #19
               STA   HTAB              ; Horizontal Location
               LDX   TOTALERR          ; Low
               LDA   TOTALERR+1        ; High
               JSR   DECOUT            ; Print It
               LDA   #31
               STA   HTAB
               LDX   CONSECERR         ; Low
               LDA   #0                ; High
               JSR   DECOUT            ; Print It
               RTS                     ; Return

* Print Block Count
*-------------------------------

PRINTCOUNT     LDA   #6
               STA   HTAB              ; Horizontal Location
               LDX   BLOCKCOUNT        ; Block Count Low Byte
               LDA   BLOCKCOUNT+1      ; Block Count High Byte
               JSR   DECOUT            ; Go Print It
               RTS                     ; Return

* Print Mode:Ymodem File:XSGFDGDFG[12345] On Screen
*-------------------------------

PRNTEXT        LDA   #41
               STA   HTAB
               LDA   #<YMODEMTEXT
               STA   POINTER
               LDA   #>YMODEMTEXT
               STA   POINTER+1
               JSR   PRINTPSTRING
               LDA   #57
               STA   HTAB
               LDA   #<FILENAME
               STA   POINTER
               LDA   #>FILENAME
               STA   POINTER+1
               JSR   PRINTPSTRING
               LDA   #'['
               JSR   LOCPRINT
*
*  Calculate Xmodem Blocks
*
               LDA   EOFPARMS+2        ; Get EOF, PLAce It At Num
               STA   NUM
               LDA   EOFPARMS+3
               STA   NUM+1
               LDA   EOFPARMS+4
               STA   NUM+2
               LDX   #7                ; Divide By 128
:NLOOP         LSR   NUM+2
               ROR   NUM+1
               ROR   NUM
               DEX
               BNE   :NLOOP

               LDA   EOFPARMS+2        ; Get Low Byte
               AND   #$7F              ; Is Number Divisible By 128?
               BEQ   :PRINTX           ; Yes, Even Multiple, Don't Add 1

               INC   NUM               ; No, Add 1 For Extra Bytes
               BNE   :PRINTX           ; Didn't Roll Over, Go Print It
               INC   NUM+1             ; Low Byte Rolled Over, Increment Mid
:PRINTX        LDA   NUM+1
               AND   #$7F              ; Always Chop High Byte
               STA   XMODEMSIZE+1
               LDX   NUM
               STX   XMODEMSIZE
               JSR   DECOUT
               LDA   #']'
               JSR   LOCPRINT
               STA   PAGE2
               RTS

* Put 15 Spaces In The Filename String, Regardless
*-------------------------------

CLRSTRING      LDA   #' '              ; Make A Space
               LDY   #$E               ; 15 Characters
:LOOP          STA   ($D),Y            ; Store At End Of String
               DEY                     ; Next Character
               BPL   :LOOP             ; All Done?
               RTS                     ; Yes, Return

* MAKETABLE -- Make The CRC Table
*-------------------------------

MAKETABLE      LDX   #0                ; Zero First Page
               LDA   #0
:LOOP1         STA   CRCLO,X           ; Zero CRC Lo Bytes
               STA   CRCHI,X           ; Zero CRC Hi Bytes
               INX
               BNE   :LOOP1

* The Following Is The Normal Bitwise Computation
* Tweaked A Little To Work In The Table-Maker
*
               LDX   #0                ; Number To Do CRC For
:FETCH         TXA
               EOR   CRCHI,X           ; Add Byte Into High
               STA   CRCHI,X           ; Of CRC
               LDY   #8                ; Do 8 Bits
:LOOP2         ASL   CRCLO,X           ; Shift Current CRC-16 Left
               ROL   CRCHI,X
               BCC   :NOADD

* If Previous High Bit Wasn't Set, Then Don't Add CRC
* Polynomial ($1021) Into The Cumulative CRC.  Else Add It.
*
               LDA   CRCHI,X           ; Add Hi Part Of CRC Poly Into
               EOR   #$10              ; Cumulative CRC Hi
               STA   CRCHI,X
               LDA   CRCLO,X           ; Add Lo Part Of CRC Poly Into
               EOR   #$21              ; Cumulative CRC Lo
               STA   CRCLO,X
:NOADD         DEY                     ; Do Next Bit
               BNE   :LOOP2            ; Done? Nope, Loop

               INX                     ; Do Next Number In Series (0-255)
               BNE   :FETCH            ; Didn't Roll Over, So Fetch More
               RTS                     ; Done

* Do A CRC On A Single Byte In A, X Is Preserved, A Is Not
*-------------------------------

DO_CRC         STA   :TEMPCRC
               TXA                     ; Save X
               PHA
               LDA   :TEMPCRC
               EOR   CRC+1             ; Add Byte Into CRC Hi Byte
               TAX                     ; To Make Offset Into Tables
               LDA   CRC               ; Get Previous Lo Byte Back
               EOR   CRCHI,X           ; Add It To The Proper Table Entry
               STA   CRC+1             ; Save It
               LDA   CRCLO,X           ; Get New Lo Byte
               STA   CRC               ; Save It Back
               PLA
               TAX                     ; Restore X
               RTS                     ; All Done

:TEMPCRC       DA    0

* Check The Incoming CRC-16
*-------------------------------

CHKCRC         JSR   INPUT             ; Is There Input?
               BCC   :BAD

               CMP   CRC+1
               BNE   :BAD

               JSR   INPUT
               BCC   :BAD

               CMP   CRC
               BNE   :BAD

               CLC
               RTS

:BAD           SEC
               RTS

* Get A 128 Byte Block Verified With A Checksum
*-------------------------------

GET128CSUM     LDY   #0                ; Zero Out Offset
:LOOP          JSR   INPUT             ; Get Data Sent
               BCC   :ERROR

               STA   (POINTER),Y       ; Store In Block Buffer
               CLC                     ; Prepare For Add
               ADC   CHECKSUM          ; Add To Checksum
               STA   CHECKSUM          ; And Save It
               INY                     ; Bump Offset For Next Data
               BPL   :LOOP             ; Keep Going For All 128 Bytes

               JSR   INPUT             ; Data Done Get Checksum
               BCC   :ERROR

               CMP   CHECKSUM          ; His CheckSum Same As Ours?
               BNE   :ERROR            ; Let's Try Again

               INC   PACKETNUM         ; Bump Block Number Counter
               INC   BLOCKCOUNT
               BNE   :NOROLL
               INC   BLOCKCOUNT+1
:NOROLL        JSR   PRINTCOUNT
               LDX   #<128
               LDA   #>128
               CLC
               RTS

:ERROR         SEC
               RTS

* Get A 128 Byte Block
*-------------------------------

GET128CRC      LDY   #0
:LOOP          JSR   INPUT
               BCC   :ERROR

               STA   (POINTER),Y
               JSR   DO_CRC
               INY
               BPL   :LOOP

               JSR   CHKCRC
               BCS   :ERROR

               INC   PACKETNUM
               INC   BLOCKCOUNT
               BNE   :NOROLL
               INC   BLOCKCOUNT+1
:NOROLL        JSR   PRINTCOUNT
               LDX   #<128
               LDA   #>128
               CLC
               RTS

:ERROR         SEC
               RTS

* Get A 1024 Byte Block
*-------------------------------

GET1024        LDX   #4
               LDY   #0
:LOOP          JSR   INPUT
               BCC   :ERROR

               STA   (POINTER),Y
               JSR   DO_CRC
               INY
               BNE   :LOOP

               INC   POINTER+1
               DEX
               BNE   :LOOP

               JSR   CHKCRC
               BCS   :ERROR

               INC   PACKETNUM
               LDA   BLOCKCOUNT
               CLC
               ADC   #8
               STA   BLOCKCOUNT
               BCC   :NOROLL
               INC   BLOCKCOUNT+1
:NOROLL        JSR   PRINTCOUNT
               LDX   #<1024
               LDA   #>1024
               CLC
               RTS

:ERROR         SEC
               RTS

* Get A 4096 Byte Block
*-------------------------------

GET4096        LDX   #16
               LDY   #0
:LOOP          JSR   INPUT
               BCC   :ERROR

               STA   (POINTER),Y
               JSR   DO_CRC
               INY
               BNE   :LOOP

               INC   POINTER+1
               DEX
               BNE   :LOOP

               JSR   CHKCRC
               BCS   :ERROR

               INC   PACKETNUM
               LDA   BLOCKCOUNT
               CLC
               ADC   #32
               STA   BLOCKCOUNT
               BCC   :NOROLL
               INC   BLOCKCOUNT+1
:NOROLL        JSR   PRINTCOUNT
               LDX   #<4096
               LDA   #>4096
               CLC
               RTS

:ERROR         SEC
               RTS

* Print The Pascal String At (POINTER) At Current Cursor Loc
*-------------------------------

PRINTPSTRING   LDY   #0
               LDA   (POINTER),Y       ; Get Filename Length Byte
               STA   :LENGTH
:LOOP          INY
               LDA   (POINTER),Y       ; Get Character In Filename
               JSR   LOCPRINT
               CPY   :LENGTH
               BNE   :LOOP

               STA   PAGE2
               RTS

:LENGTH        DB    0

* DECOUT -- Print A Decimal Number
*-------------------------------

; Print A Decimal Number To Stdio.
DECOUT         STA   :HIBYTE           ; Save The Number To Print.
               STX   :LOBYTE
               LDX   #9                ; Start At Largest Value In Table.
               STX   :NUMFLAG
:P_DEC1        LDY   #"0"              ; Assume Value Is 0 To Start.
:P_DEC2        LDA   :LOBYTE           ; Is This Value Less Than Table?
               CMP   :DECTAB-1,X
               LDA   :HIBYTE
               SBC   :DECTAB,X
               BCC   :P_DEC3           ; Yes, Print A Digit From The Table.

               STA   :HIBYTE           ; No, Keep Dividing Until It Is.
               LDA   :LOBYTE
               SBC   :DECTAB-1,X
               STA   :LOBYTE
               INY                     ; Next Digit Value.
               BNE   :P_DEC2           ; Always.

:P_DEC3        TYA                     ; Digit Character To A-Reg For Printing...
               DEX                     ; Last Digit?
               BEQ   :PRINTIT          ; Yes, So Output Something.

               CMP   #"0"              ; No.  Is This Value A Zero?
               BEQ   :PRZERO           ; Yes, Must Print At Least One.

               STA   :NUMFLAG          ; No, We're Going To Print A Digit Though.
:PRZERO        BIT   :NUMFLAG          ; Have We Printed A Real Digit Yet?
               BMI   :PRINTIT          ; Yes, So We Must Print This One.

               LDA   JUSTIFY           ; No, So Check For User Justification.
               BPL   :OVER             ; None.

:PRINTIT       JSR   LOCPRINT          ; Else, This Must Be The Character To Use.
:OVER          DEX                     ; Next Value In Table.
               BPL   :P_DEC1           ; Until None Left.

               STA   PAGE2
               RTS

:HIBYTE        DB    0
:LOBYTE        DB    0
:NUMFLAG       DB    0

:DECTAB        DA    1,10,100,1000,10000

JUSTIFY        DB    0

* Data Segment
*-------------------------------

COPYRIGHT      ASC   'Copyright 1987-89 By L & L Productions'
DATE           ASC   '&Sysdate'
TIME           ASC   '&Systime'

CRCMSG         STR   'CRC'
CSUMMSG        STR   'Csum'
PROMSG         STR   'AE'
STANDARDMSG    STR   'Stnd'
YMODEMTEXT     STR   'Ymodem'

SCREENTEXT     STR   'Block:      Errors:     Consec:     Mode:           File:'

STARTSIG       ASC   'C4'              ; Characters For Ymodem Start
TIMEOUT        DA    0                 ; Timeout In 120Ths Of A SECond
CONSECERR      DB    0                 ; # Of Consecutive Errors
BATCHTYPE      DB    0                 ; Which Batch Mode? (0=Proterm,1=Forsberg)
RETRY          DB    0                 ; Remaining Retries
PACKETNUM      DB    0                 ; Current Block Number Modulo 256
LASTCHAR       DB    0                 ; Last Character Received
CRC            DA    0                 ; Low Part Of The CRC
BLK_TYPE       DB    0                 ; Small Or Large Block?
HA1EF          DB    0
CHECKSUM       DB    0                 ; Checksum Register
PACKET1K       DB    0                 ; Was There A 1K Packet?
PACKET4K       DB    0                 ; Was There A 4K Packet?
USECSUM        DB    0
BATCHMODE      DB    0                 ; Batch Mode? (0=No, 1=Yes)
RENAMETRIES    DB    0                 ; How Many Tried To Rename The File
NUM            DA    0

*
*  Filename Buffer
*
FILENAME       DB    15                ; Area For Filename
               DS    20

*
* Open Parameters
*
OPENPARMS      DB    3                 ; 3 Parameters Follow
               DA    FILENAME          ; File's Name/No Prefix
               DA    FILEBUFFER        ; Address Of 1K File Buffer
               DB    0                 ; Ref_Num
*
* Close Parameters
*
CLOSEPARMS     DB    1                 ; Number Of Parameters
               DB    0                 ; Ref_Num

*
* Create A File Parameters
*
CREATEPARMS    DB    7
               DA    FILENAME          ; Address Of Filename
               DB    $C3               ; Access Attributes
               DB    4                 ; Filetype (Text)
               DA    0                 ; Aux Filetype
               DB    1                 ; Storage Type (Seedling)
               DA    0                 ; Date Of Creation
               DA    0                 ; Time Of Creation

*
* Destroy File Parameters
*
DESTROYPARMS   DB    1
               DA    FILENAME          ; File To Delete

*
* Write To A File Parameter List
*
WRITEPARMS     DB    4                 ; Number Of Parameters
               DB    0                 ; Reference Number
               DA    BLOCKBUFFER       ; Address Of File Buffer
               DA    0                 ; Length Of Buffer
               DA    0                 ; Actual Length

*
* Get/Set File Info Parms
*
SFIPARMS       DB    7                 ; Parm Count
               DA    FILENAME          ; Path Addr
               DB    $C3               ; Access
               DB    4                 ; Filetype (Text)
               DA    0                 ; Auxtype
               DB    1                 ; Not Used
               DA    0
               DA    0                 ; Mod Date
               DA    0                 ; Mod Time
               DA    0                 ; Create Date
               DA    0                 ; Create Time

*
* EOF Parms To Set The Proper End Of The File
*
EOFPARMS       DB    2                 ; Parm Count
               DB    0                 ; Reference Number
               DA    0

