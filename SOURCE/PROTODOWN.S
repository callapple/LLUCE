*-------------------------------------------------
*
* Xmodem/Ymodem downloads for LLUCE
*
*-------------------------------------------------
* use "a:protocol.down",100,1,"Filename" = batch
* use "a:protocol.down",100,0,"Filename" = single file
*-------------------------------------------------
                    DATE
*-------------------------------------------------

Id                  =      3
Aux                 =      2

                    LST    OFF
                    LSTDO  OFF
                    XC
                    TR
                    TR     ADR
                    EXP    ONLY
Y                   =      1
y                   =      1
N                   =      0
n                   =      0
NOLIST              =      Y
                    DO     NOLIST
LISTOBJ             =      N
LISTSYM             =      N
                    ELSE
LISTOBJ             KBD    'List This Source? (Y/N)'
LISTSYM             KBD    'List Symbol Table? (Y/N)'
                    FIN
                    DO     LISTOBJ
                    LST
                    FIN
                    LST    OFF
                    PUT    EQUATES/EQUATES
                    PUT    EQUATES/OS.EQUATES
                    PUT    EQUATES/ENTRY
                    PUT    EQUATES/DRIVEREQU

]TYPE               =      ^overlays                        ; set file type
]AUX                =      overlays                         ; and aux type
                    ORG    ]AUX                             ; must be this way
                    TYP    ]TYPE

                    DSK    /MAIN/LLUCE/SYSTEM/PROTOCOL.DOWN
                    LST    RTN

                    TTL    'LLUCE - Xmodem/Ymodem Uploads'

HEADER              DB     Id
                    DA     Aux
                    DB     Aux/256!Aux!Id!$A5

*-------------------------------
* Size Of Code To Check CRC
*-------------------------------

                    DW     CODEEND-main
                    DW     0                                ; CRC Goes Here

                    ORG    $D000

*-------------------------------------------------
* General Global equates

failflag            =      PRN
tmode               =      PRN+1

blockBuffer         =      ENDMOD                           ; $9B00
crcLo               =      ENDMOD+$1100                     ; $AC00 crc table addresses
crcHi               =      crcLo+$100                       ; $AD00
pdData              =      crcHi+$100                       ; $AE00

*-------------------------------------------------
* all good things start here

main                JMP    dostart
                    JMP    dostart
*
* rest of the code starts here
*
die                 LDA    #parmSyntax                      ; syntax error
                    STA    failflag
                    RTS

dostart             LDX    #pdLen                           ; move ProDOS lists into place
movePd              LDA    pdSource-1,X
                    STA    pdData-1,X
                    DEX
                    BNE    movePd

                    LDX    #parmsLen                        ; move LLUCE readable parms into place
moveParm            LDA    parmStrt-1,X
                    STA    FREESPACE-1,X
                    DEX
                    BNE    moveParm

                    LDA    #r4modemP                        ; start at prodos 4modem
                    STA    tmode                            trans

                    LDA    #noErrors
                    STA    failflag                         ; innocent until proven guilty
                    STA    CH                               ; htab 0
                    STA    PacketNum                        ; always packet 0
                    STA    byteCount                        ; block = 0
                    STA    byteCount+1
                    STA    byteCount+2
                    STA    TotalErr
                    STA    TotalErr+1
                    STA    ConsecErr
                    STA    InnerLoop                        ; abort from outer loop, not inner
                    STA    UseCsum                          ; don't use checksum mode
                    STA    SendSmall                        ; don't send small packets
                    STA    ackflag                          ; always wait for acks (no ymodem-g)

                    JSR    GOBCOM
                    JSR    INPNUM                           ; get timeout

                    CMP    #>400                            ; make the timeout have a minimum
                    BEQ    tooSmall                         ; if the high byte's equal, see if the low byte
                    BGE    largeEnough                      ; is at least 400
                    BLT    waySmall                         ; -- and if it's less than, it's way too small

tooSmall            CPX    #<400
                    BGE    largeEnough

waySmall            LDA    #>400                            ; otherwise, default to at least 400 ticks
                    LDX    #<400

largeEnough         STX    timeOut
                    STX    waitFOR
                    STA    timeOut+1
                    STA    waitFOR+1

                    STA    KBDSTRB                          ; reset keyboard strobe

                    JSR    GOBCOM                           ; get protocol
                    JSR    INPNUM
                    BNE    die

                    STX    transtype
                    CPX    #batchMd
                    BEQ    notbatch

                    JSR    CHKBYT
                    CMP    #','+128                         ; is it a comma?
                    BEQ    notbatch                         ; yes, don't try final stuff

                    LDA    #1
                    STA    LastPacket

                    JSR    clearLastLine

                    LDA    #<FinalBlock
                    STA    TEMP
                    LDA    #>FinalBlock
                    STA    TEMP+1

                    JSR    printPString

                    JSR    maketable                        ; make the crc table
                    JSR    clearBuf                         ; clear the block buffer
                    JMP    send_final

notbatch            JSR    GOBCOM                           ; go to eat next comma
                    JSR    MOVNAME                          ; move filename for open call

                    LDA    #<FLNAME
                    STA    TEMP
                    LDA    #>FLNAME
                    STA    TEMP+1

                    LDY    #0                               ; get length of filename
                    LDA    (TEMP),Y
                    STA    filename
                    TAY
fname               LDA    (TEMP),Y                         ; move filename to ours
                    STA    filename,Y
                    DEY
                    BNE    fname

                    JSR    MLI                              open
                    DB     Open
                    DA     openParms

                    BCC    ok3                              ; no errors-keep goin'
                    JMP    die2
*
* switch in proper memory banks
*
ok3                 JSR    maketable                        ; make the crc table
                    JSR    clearBuf                         ; clear the block buffer

                    JSR    MLI
                    DB     Getinfo                          ; MLI Getinfo
                    DA     GFIParms
                    BCS    die2

                    LDA    openParms+5                      ; get ref_num
                    STA    GetEOFParms+1                    ; and use for eof ref number
                    STA    CloseParms+1
                    STA    ReadParms+1

                    JSR    MLI
                    DB     Geteof
                    DA     GetEOFParms
                    BCS    die2

*
* put the status line on the bottom of the screen
*
                    LDY    #19                              ; move all 19 parameters
mloop               LDA    GFIParms+3,Y
                    STA    ParmList,Y
                    DEY
                    BPL    mloop

                    JSR    clearLastLine

                    LDA    #<ScreenTxt                      ; put the screentext on the screen
                    STA    TEMP
                    LDA    #>ScreenTxt
                    STA    TEMP+1
                    JSR    printPString
                    JSR    PrintCount                       ; show all 0's in the beginning
                    JSR    printErr
*
* put the filename on the screen
*
                    LDA    #64
                    STA    CH
                    LDA    #<filename                       ; get pointer to filename/lo
                    STA    TEMP                             ; set up indirect address
                    LDA    #>filename                       ; get pointer to filename/hi
                    STA    TEMP+1                           ; finish setting up
                    JSR    printPString

                    LDX    #0
fnLoop              LDA    filename+1,X                     ; get character in filename
                    CMP    #'A'                             ; if it's a period, or a number, then don't lowercase
                    BLT    lower                            ; it...
                    CMP    #'a'                             ; if it's already lowercase, don't convert it
                    BGE    lower
                    CLC
                    ADC    #CaseDiff
lower               STA    blockBuffer,X
                    INX
                    CPX    filename
                    BLT    fnLoop

                    LDA    transtype
                    CMP    #batchMd
                    BEQ    xdown                            ; is it 0? yes, intelligent
                    CMP    #fileMd                          ; is it 1?
                    BNE    die3                             ; nope, try ymodem
                    JMP    Ybatch                           ; yes, batch ymode

die2                STA    failflag
die3                JMP    endit

*-------------------------------------------------
* init for ae xmodem send

xdown               LDA    #tenErrors                       ; and 10
                    STA    retry                            ; retry
                    JSR    cin                              ; look for the starting c
*
* if we got this far, we got the initial packet, now check for AE Mode
*
                    LDA    #3
                    STA    ctries
TryC                DEC    ctries
                    BEQ    Standard

                    LDA    #ssoh                            ; soh with hi bit set
                    JSR    MDMOUT                           ; send it
                    LDA    #nul                             ; get ae filetype
                    JSR    MDMOUT                           ; send it
                    LDA    #-1                              ; flip the bits
                    JSR    MDMOUT                           ; and send that
                    JSR    ackin                            ; look for ack
                    BCS    Standard                         ; bcs tryC
                    JMP    prodos

Standard            DEC    tmode                            ; drop into Standard mode
prodos              LDA    tmode
                    ASL    A
                    TAX
                    LDA    ProtocolTAddr,X                  ; get low byte of address
                    STA    TEMP                             ; for text
                    INX
                    LDA    ProtocolTAddr,X                  ; get high byte of address for text
                    STA    TEMP+1

                    LDA    #41
                    STA    CH                               ; htab 41

                    JSR    printPString                     print

                    LDA    tmode                            ; get the transfer type
                    CMP    #r4modem
                    BGE    x4096
                    CMP    #r1k                             ; can we use 1k blocks?
                    BGE    jmp1k                            ; yes, send via 1k
jmp128              JMP    x128                             ; no, only send 128 byte packets
jmp1k               JMP    x1024                            ; send 1k blocks

*-------------------------------------------------
* start of 4k xmodem packet sending routines....

x4096               LDX    #<1024
                    LDA    #>1024
                    JSR    readfile                         ; read 8 xmodem blocks
                    JSR    Send128Packets                   ; hopefully send them
                    LDA    ReadParms+7
                    CMP    #>1024
                    BEQ    read3k96
                    JMP    FileEOT

read3k96            LDX    #<3072
                    LDA    #>3072
                    JSR    readfile                         ; read 8 xmodem blocks
                    JSR    Send1kPackets                    ; hopefully send them
                    LDA    ReadParms+7
                    CMP    #>3072
                    BEQ    readf96
                    JMP    FileEOT

readf96             LDX    #<4096
                    LDA    #>4096
                    JSR    readfile                         ; read 'em
                    BCS    eof96                            ; landed on a block boundary end it
                    CMP    #>4096                           ; did we get a big packet?
                    BEQ    nxtBlk96
                    JSR    Send1kPackets
eof96               JMP    FileEOT

nxtBlk96            LDA    SendSmall
                    BNE    MoreErrs96

                    LDA    #tenErrors                       ; initialize to 10 retry
                    STA    retry                            ; store counter
                    INC    PacketNum                        ; next xmodem block in series

                    LDA    byteCount+1
                    CLC
                    ADC    #>4096
                    STA    byteCount+1
                    BCC    noroll96
                    INC    byteCount+2
noroll96            JSR    PrintCount                       ; print # of blocks sent (again)

loop296             JSR    initcrc
                    JSR    Send4096
                    BCC    readf96                          ; ok, send the next 4096 byte pack

                    LDA    ConsecErr                        ; how many consecutive errors do we have?
                    CMP    #2                               ; 2?
                    BNE    loop296                          ; nope, then retry large block

                    DEC    PacketNum                        ; decrease pack # by 1

                    LDA    byteCount+1
                    SEC
                    SBC    #>4096
                    STA    byteCount+1
                    LDA    byteCount+2
                    SBC    #0
                    STA    byteCount+2

MoreErrs96          LDA    TotalErr                         ; 2 consec errors, so find out how many
                    STA    ErrorsBefore                     ; before we send small packets
                    LDA    #0
                    STA    SendSmall                        ; don't send small after this one

                    LDX    ReadParms+6                      ; how much did we get?
                    LDA    ReadParms+7
                    JSR    Send1kPackets                    ; unless we get errors
                    LDA    ErrorsBefore
                    CMP    TotalErr                         ; did we get any extra errors?
                    BEQ    readf96

                    LDA    #1
                    STA    SendSmall
                    JMP    readf96

*-------------------------------------------------
* start of 1k xmodem packet sending routines....

x1024               LDX    #<512
                    LDA    #>512
                    JSR    readfile                         ; read 4 xmodem blocks
                    JSR    Send128Packets                   ; hopefully send them
                    LDA    ReadParms+7
                    CMP    #>512
                    BEQ    readf24
                    JMP    FileEOT

readf24             LDX    #<1024
                    LDA    #>1024
                    JSR    readfile                         ; read 'em
                    BCS    eof24                            ; landed on a block boundary end it
                    CMP    #>1024                           ; did we get a big packet?
                    BEQ    nxtBlk24
                    JSR    Send128Packets
eof24               JMP    FileEOT

nxtBlk24            LDA    SendSmall
                    BNE    MoreErrs24

                    LDA    #tenErrors                       ; initialize to 10 retry
                    STA    retry                            ; store counter
                    INC    PacketNum                        ; next xmodem block in series

                    LDA    byteCount+1
                    CLC
                    ADC    #>1024
                    STA    byteCount+1
                    BCC    noroll24
                    INC    byteCount
noroll24            JSR    PrintCount                       ; print # of blocks sent (again)

loop224             JSR    initcrc
                    JSR    Send1024
                    BCC    readf24                          ; ok, send the next 1024 byte pack

                    LDA    ConsecErr                        ; how many consecutive errors do we have?
                    CMP    #2                               ; 2?
                    BNE    loop224                          ; nope, then retry large block

                    DEC    PacketNum                        ; decrease pack # by 1

                    LDA    byteCount+1
                    SEC
                    SBC    #>1024
                    STA    byteCount+1
                    LDA    byteCount+2
                    SBC    #0
                    STA    byteCount+2

MoreErrs24          LDA    TotalErr                         ; 2 consec errors, so find out how many
                    STA    ErrorsBefore                     ; before we send small packets
                    LDA    #0
                    STA    SendSmall                        ; don't send small after this one

                    LDX    ReadParms+6                      ; how much did we get?
                    LDA    ReadParms+7
                    JSR    Send128Packets                   ; unless we get errors
                    LDA    ErrorsBefore
                    CMP    TotalErr                         ; did we get any extra errors?
                    BEQ    readf24

                    LDA    #1
                    STA    SendSmall
                    JMP    readf24

*-------------------------------------------------
* Start of 128 byte packet sending routines

x128                LDX    #<1024
                    LDA    #>1024
                    JSR    readfile                         ; read 1k of file always
                    BCS    eof128                           ; we landed on a 1k boundary, all done
                    CMP    #>1024                           ; did we get 1k from the file?
                    BNE    last                             ; no, must be at end, send last blocks
                    JSR    Send128Packets                   ; else send 1k worth of blocks
                    JMP    x128                             ; go read some more

last                JSR    Send128Packets                   ; send buffer full of packets
eof128              JMP    FileEOT                          ; all done

*-------------------------------------------------
* end of file transmission

FileEOT             LDA    #tenErrors                       ; init to 10
                    STA    retry                            ; retry
                    LDA    #1
                    STA    LastPacket                       ; this is the footer

EOTLoop             LDA    #eot
                    JSR    MDMOUT                           ; send it
                    JSR    ackin                            ; look for an ack response
                    BCS    EOTLoop

                    LDA    tmode                            ; get trans mode
                    AND    #rProDOS                         ; is it odd?
                    BNE    Footer                           ; yes, send a footer packet
                    JMP    endit                            ; else no footer needed, end the xfer

*-------------------------------------------------
* prodos footer

Footer              LDY    #5                               ; init counter
FtLoop              JSR    input                            ; look for input
                    CMP    #syn                             ; is it a ctrl-y?
                    BEQ    got_syn                          ; you bet!
                    DEY
                    BNE    FtLoop                           ; try again
                    LDA    #footerErr
                    JMP    Bad_File

got_syn             LDA    #etb                             ; etb (ae prodos proto)
                    JSR    MDMOUT                           ; send it
                    JSR    nakin                            ; look for nak

                    JSR    clearBuf                         ; Clear out the Block Buffer

                    LDA    #4                               ; 4 retries
                    STA    retry

loop2Ft             LDA    #%10101010
                    STA    PacketNum                        ; change block number to $aa for AE
                    STA    LastPacket                       ; yep, this *IS* the last packet

                    JSR    initcrc
                    LDA    #<GFIParms
                    STA    TEMP
                    LDA    #>GFIParms
                    STA    TEMP+1

                    LDA    UseCsum                          ; is it in a checksum mode?
                    BNE    FtCsum                           ; yes, send the last via csum

                    JSR    Send128CRC
                    BCS    loop2Ft                          ; error, retry
                    JMP    endit

FtCsum              JSR    Send128Csum
                    BCS    loop2Ft                          ; error, retry

*-------------------------------------------------
* close file and end

endit               JMP    closefile

*-------------------------------------------------
* start of ymodem batch sending routines

Ybatch              LDA    #41
                    STA    CH

                    LDA    #<YmodemText                     ; print 'Ymodem' after "Mode:"
                    STA    TEMP
                    LDA    #>YmodemText
                    STA    TEMP+1
                    JSR    printPString

                    LDA    GetEOFParms+2
                    STA    num
                    LDA    GetEOFParms+3
                    STA    num+1
                    LDA    GetEOFParms+4
                    STA    num+2

                    JSR    long2Dec

                    LDY    filename                         ; if the filename is longer than
                    CPY    #54                              ; 54 characters, it won't fit before the
                    BGE    Ydone                            ; prodos information, so skip it
                    INY
                    LDX    #0
dLoop               LDA    decimal,X                        ; move the decimal length to conform to
                    BEQ    Ydone                            ; "true ymodem"
                    STA    blockBuffer,Y
                    INX
                    INY
                    JMP    dLoop

Ydone               LDA    #']'-Ctrl                        ; ; put the ID byte there
                    STA    blockBuffer+64
                    LDA    #'G'                             ; put a "G" for greg (just in case)
                    STA    blockBuffer+65

                    LDX    #0                               ; move the gfi and get eof
parm_loop           LDA    GFIParms,X                       ; results to header packet
                    STA    blockBuffer+66,X
                    INX
                    CPX    #$17                             ; done all?
                    BNE    parm_loop                        ; no, loop

send_final          LDA    #tenErrors
                    STA    retry
                    JSR    bin                              ; wait for a 'C' or a 'G'

                    LDA    gflag                            ; skip acks
                    STA    ackflag

*-------------------------------------------------
* send the header packet with some file information in it

sendhead            JSR    initcrc
                    JSR    Send128CRC
                    BCS    sendhead                         ; ack not received, resend header

                    LDA    blockBuffer                      ; last one?
                    BNE    proceed                          ; no, send file

                    JSR    clearLastLine                    ; get rid of the "final packet" text on the last
                    JMP    endit                            ; line

*-------------------------------------------------
* if there is an actual file to send, send it


proceed             JSR    nakin                            ; wait for another <nak> or <C>
;   or anything for that matter

                    LDA    tmode
                    CMP    #rCRC
                    BNE    initsend
                    JMP    proceed4k

initsend            LDX    #<512
                    LDA    #>512
                    JSR    readfile                         ; read 4 xmodem blocks
                    JSR    Send128Packets                   ; hopefully send them
                    LDA    ReadParms+7
                    CMP    #>512
                    BEQ    readfHdr
                    JMP    BatchEOT

readfHdr            LDX    #<1024
                    LDA    #>1024
                    JSR    readfile                         ; read 'em
                    BCS    eofHdr                           ; landed on a block boundary end it
                    CMP    #>1024                           ; did we get a big packet?
                    BEQ    nxtBlkHdr
                    JSR    Send128Packets
eofHdr              JMP    BatchEOT

nxtBlkHdr           LDA    SendSmall
                    BNE    MoreErrsHd

                    LDA    #tenErrors                       ; initialize to 10 retry
                    STA    retry                            ; store counter
                    INC    PacketNum                        ; next xmodem block in series

                    LDA    byteCount+1
                    CLC
                    ADC    #>1024
                    STA    byteCount+1
                    BCC    norollHd
                    INC    byteCount+2
norollHd            JSR    PrintCount                       ; print # of blocks sent (again)

loop2Hd             JSR    initcrc
                    JSR    Send1024
                    BCC    readfHdr                         ; ok, send the next 1024 byte pack

                    LDA    ConsecErr                        ; how many consecutive errors do we have?
                    CMP    #2                               ; 2?
                    BNE    loop2Hd                          ; nope, then retry large block

                    DEC    PacketNum                        ; decrease pack # by 1

                    LDA    byteCount+1
                    SEC
                    SBC    #>1024
                    STA    byteCount+1
                    LDA    byteCount+2
                    SBC    #0
                    STA    byteCount+2

MoreErrsHd          LDA    TotalErr                         ; 2 consec errors, so find out how many
                    STA    ErrorsBefore                     ; before we send small packets
                    LDA    #0
                    STA    SendSmall                        ; don't send small after this one

                    LDX    ReadParms+6                      ; how much did we get?
                    LDA    ReadParms+7
                    JSR    Send128Packets                   ; unless we get errors
                    LDA    ErrorsBefore
                    CMP    TotalErr                         ; did we get any extra errors?
                    BEQ    readfHdr

                    LDA    #1
                    STA    SendSmall
                    JMP    readfHdr

*-------------------------------------------------
* start of 4k ymodem-4k packet sending routines....

proceed4k           LDX    #<1024
                    LDA    #>1024
                    JSR    readfile                         ; read 8 xmodem blocks
                    JSR    Send128Packets                   ; hopefully send them
                    LDA    ReadParms+7
                    CMP    #>1024
                    BEQ    read3k4k
                    JMP    BatchEOT

read3k4k            LDX    #<3072
                    LDA    #>3072
                    JSR    readfile                         ; read 8 xmodem blocks
                    JSR    Send1kPackets                    ; hopefully send them
                    LDA    ReadParms+7
                    CMP    #>3072
                    BEQ    readf4k
                    JMP    BatchEOT

readf4k             LDX    #<4096
                    LDA    #>4096
                    JSR    readfile                         ; read 'em
                    BCS    eof4k                            ; landed on a block boundary end it
                    CMP    #>4096                           ; did we get a big packet?
                    BEQ    nxtBlk4k
                    JSR    Send1kPackets
eof4k               JMP    BatchEOT

nxtBlk4k            LDA    SendSmall
                    BNE    MoreErrs4k

                    LDA    #tenErrors                       ; initialize to 10 retry
                    STA    retry                            ; store counter
                    INC    PacketNum                        ; next xmodem block in series

                    LDA    byteCount+1
                    CLC
                    ADC    #>4096
                    STA    byteCount+1
                    BCC    noroll4k
                    INC    byteCount+2
noroll4k            JSR    PrintCount                       ; print # of blocks sent (again)

loop24k             JSR    initcrc
                    JSR    Send4096
                    BCC    readf4k                          ; ok, send the next 1024 byte pack

                    LDA    ConsecErr                        ; how many consecutive errors do we have?
                    CMP    #2                               ; 2?
                    BNE    loop24k                          ; nope, then retry large block

                    DEC    PacketNum                        ; decrease pack # by 1

                    LDA    byteCount+1
                    SEC
                    SBC    #>4096
                    STA    byteCount+1
                    LDA    byteCount+2
                    SBC    #0
                    STA    byteCount+2

MoreErrs4k          LDA    TotalErr                         ; 2 consec errors, so find out how many
                    STA    ErrorsBefore                     ; before we send small packets
                    LDA    #0
                    STA    SendSmall                        ; don't send small after this one

                    LDX    ReadParms+6                      ; how much did we get?
                    LDA    ReadParms+7
                    JSR    Send1kPackets                    ; unless we get errors
                    LDA    ErrorsBefore
                    CMP    TotalErr                         ; did we get any extra errors?
                    BEQ    readf4k

                    LDA    #1
                    STA    SendSmall
                    JMP    readf4k

*-------------------------------------------------
* end of transmission of one file, return to caller...

BatchEOT            LDA    #1
                    STA    LastPacket
                    LDA    #tenErrors                       ; initialize count for last byte
                    STA    retry

EOTBLoop            LDA    #eot                             ; get an eot
                    JSR    MDMOUT                           ; send it

                    LDA    #0                               ; always wait for acks on EOT
                    STA    ackflag

                    JSR    ackin                            ; wait for an ack
                    BCS    EOTBLoop                         ; if ok, finish up
                    JMP    endit

*-------------------------------------------------
* print a single character on the screen to indicate error status


printErr            PHA
                    TXA                                     ; save ;the x-reg
                    PHA

                    LDA    #20
                    STA    CH                               ; horizontal location
                    LDA    TotalErr                         ; low
                    STA    num
                    LDA    TotalErr+1                       ; high
                    STA    num+1
                    LDA    #0
                    STA    num+2
                    JSR    long2Dec                         ; print it

                    LDX    #<decimal
                    LDY    #>decimal
                    JSR    printCString

                    LDA    #33
                    STA    CH
                    LDA    ConsecErr                        ; low
                    STA    num
                    LDA    #0                               ; high
                    STA    num+1
                    STA    num+2
                    JSR    long2Dec                         ; print it

                    LDX    #<decimal
                    LDY    #>decimal
                    JSR    printCString

                    PLA
                    TAX
                    PLA                                     ; recover acc
                    RTS                                     ; return

*-------------------------------------------------
* print block count

PrintCount          LDA    #6
                    STA    CH                               ; horizontal location

                    LDA    byteCount
                    STA    num
                    LDA    byteCount+1
                    STA    num+1
                    LDA    byteCount+2
                    STA    num+2

                    JSR    long2Dec

                    LDX    #<decimal
                    LDY    #>decimal
                    JMP    printCString

*-------------------------------------------------
* wait for an <ack>

ackin               LDY    #10
ackLoop             LDA    KYBD                             ; get a keystroke
                    BPL    ackNoPr                          ; nothing there...
                    CMP    #escKey                          ; got a keypress
                    BEQ    err_out                          ; if it's escape, exit violently
                    STA    KBDSTRB                          ; otherwise, reset strobe and continue

ackNoPr             JSR    MDMDCD                           ; check for carrier
                    BCC    err_out                          ; ooops seems we've lost it

                    LDA    ackflag                          ; should we check for ymodem-g?
                    BEQ    notyg                            ; nope
                    JSR    MDMIN                            ; look for byte incoming
                    BCC    gotit                            ; nothing found, continue transfer
                    CMP    #can
                    BNE    gotit                            ; if we get a single <can>, wait
                    JSR    input                            ; for another <can>, else continue
                    BCC    gotit
                    CMP    #can                             ; if input = <can>, abort
                    BEQ    err_out                          ; else continue
                    BNE    gotit

notyg               JSR    input                            ; look for input
                    BCC    ackNf                            ; nothing found
                    CMP    #ack                             ; is it an <ack>?
                    BEQ    gotit                            ; yes, return
                    CMP    #nak                             ; is it a <nak>?
                    BEQ    badblock                         ; yes, flag as bad
                    CMP    #'C'
                    BEQ    badblock
                    AND    #Clrhi                           ; strip hi bit
                    CMP    LastChar                         ; same char as before
                    BNE    ackNotL                          ; nope...but remember it
                    CMP    #can                             ; double <can>?
                    BEQ    err_out                          ; yes...end the trans.

ackNotL             STA    LastChar                         ; save char for later chk
ackNf               DEY    decrement                        ; loop count
                    BNE    ackLoop                          ; still some left

badblock            INC    TotalErr
                    BNE    skip
                    INC    TotalErr+1

skip                DEC    retry
                    LDA    retry
                    CMP    #tenErrors-1
                    BEQ    no_consec

                    INC    ConsecErr
                    LDA    ConsecErr
                    CMP    #tenErrors
                    BEQ    err_out
                    JSR    printErr

no_consec           LDA    #nul                             ; zero acc. we got nuthin
                    SEC                                     ; set flag
                    RTS                                     ; return to caller

gotit               LDX    ConsecErr                        ; get current Consecutive error count
                    LDA    #0                               ; we got a good block, say that
                    STA    ConsecErr
                    CPX    #0                               ; check again for what once was
                    BEQ    gotit2                           ; if it already WAS 0, don't bother
                    JSR    printErr                         ; else show the new Consec Err count
gotit2              CLC
                    RTS

err_out             JMP    clrstk                           ; go clear stack, end transfer

*-------------------------------------------------
* look for <nak>

nakin               LDY    #10                              ; only have to wait, say, 20 seconds or so... no rush
nakLoop             LDA    KYBD                             ; get a keystroke
                    BPL    nakNoPr                          ; nothing there...
                    CMP    #escKey                          ; got a keypress
                    BEQ    nakGone                          ; if it's escape, exit violently
                    STA    KBDSTRB                          ; otherwise, reset strobe and continue

nakNoPr             JSR    MDMDCD                           ; look for carrier
                    BCC    nakGone                          ; seems not to be there!

                    JSR    input                            ; look for input
                    BCC    nakNf                            ; nothing found
                    CMP    #nak                             ; is it nak?
                    BEQ    nakClr                           ; yes, then return to caller
                    CMP    #'C'                             ; is it a "C" for ymodem?
                    BEQ    nakClr
                    CMP    #'G'                             ; is it a "G" for ymodem-g?
                    BEQ    nakClr
                    CMP    #'4'                             ; is it a "4" for ymodem-4k?
                    BEQ    nakClr

                    AND    #Clrhi
                    CMP    LastChar                         ; same as before
                    BNE    nakNotL                          ; not the same as before
                    CMP    #can                             ; double <can>?
                    BEQ    nakGone

nakNotL             STA    LastChar                         ; remember char for checking
nakNf               DEY                                     ; decrement loop cpunt
                    BNE    nakLoop                          ; still some loop left
                    LDA    #1                               ; timed out waiting
nakGone             JMP    clrstk                           ; clear stack, end trans..

nakClr              CLC
                    RTS

*-------------------------------------------------
* Wait for a 'C' to start the batch transmission

bin                 LDY    #30                              ; wait 1 minute
binLoop             LDA    KYBD                             ; get a keystroke
                    BPL    binNoPr                          ; nothing there...
                    CMP    #escKey                          ; got a keypress
                    BEQ    aborted                          ; if it's escape, exit violently
                    STA    KBDSTRB                          ; otherwise, reset strobe and continue

binNoPr             JSR    MDMDCD
                    BCC    aborted

                    JSR    input                            ; get a character from the modem
                    CMP    #'C'                             ; is it a 'c'?
                    BEQ    ok                               ; yes, also return gracefully
                    CMP    #'G'                             ; is it Ymodem-g?
                    BEQ    ok_g                             ; yes!  ack!!
                    CMP    #'4'                             ; was is ymodem-4k?
                    BEQ    ok_4

                    AND    #Clrhi
                    CMP    LastChar                         ; same as before
                    BNE    binMkLst                         ; not the same as before
                    CMP    #can                             ; double <can>?
                    BEQ    aborted                          ; yes, leave it

binMkLst            STA    LastChar
                    DEY                                     ; keep trying
                    BNE    binLoop                          ; not done yet, try again
                    LDA    #1                               ; timed out waiting
aborted             JMP    clrstk

ok                  LDA    #xModem
                    STA    gflag
                    STA    tmode
                    RTS

ok_g                LDA    #yModem                          ; was ymodem-g, flag as such
                    STA    gflag
                    STA    tmode
                    RTS

ok_4                LDA    #0                               ; was ymodem-4k, flag as such
                    STA    gflag
                    LDA    #yModem4k
                    STA    tmode
                    RTS

*-------------------------------------------------
* Look for a 'C' to start the transmission

cin                 LDA    #2
                    STA    ctries                           ; tries for a C are 2

                    LDY    #30                              ; wait 1 minute
cinLoop             LDA    KYBD                             ; get a keystroke
                    BPL    cinNoPr                          ; nothing there
                    CMP    #escKey                          ; is it esc?
                    BEQ    clrstk                           ; yes, exit
                    STA    KBDSTRB                          ; else, reset strobe and continue

cinNoPr             JSR    MDMDCD                           ; look for carrier
                    BCC    clrstk                           ; lost it

                    JSR    input                            ; input for 2.00 secs
                    CMP    #'C'                             ; is it a 'C'
                    BEQ    got_C                            ; yes return to caller
                    CMP    #nak                             ; is it a <nak>?
                    BEQ    got_nak                          ; yes, one more try

                    AND    #Clrhi
                    CMP    LastChar                         ; same as before
                    BNE    cinMkLst                         ; not the same as before
                    CMP    #can                             ; double <can>?
                    BEQ    clrstk

cinMkLst            STA    LastChar
                    DEY
                    BNE    cinLoop
                    LDA    #1                               ; timed out waiting
                    JMP    clrstk

got_nak             DEC    ctries
                    BNE    cinLoop                          ; exhausted all possibilities
                    LDA    #rXModemP                        ; yes, drop down into cksum
                    STA    tmode
                    STA    UseCsum                          ; change from CRC to checksum mode
                    RTS

got_C               JSR    input                            ; wait for a second for inp
                    BCC    crc_Xmodem                       ; nothing found
                    CMP    #'K'                             ; is it the "K" in CK?
                    BNE    crc_Xmodem

got_K               JSR    input                            ; wait for a second for inp
                    BCC    xmodem_1k                        ; nothing found
                    CMP    #'L'                             ; is it the "L" in CKL?
                    BNE    xmodem_1k

                    LDA    #r4modemP                        ; set 4modem mode
                    STA    tmode
                    RTS

xmodem_1k           LDA    #r1kP
                    STA    tmode                            ; set xmodem-1k
                    RTS

crc_Xmodem          LDA    #rCRCp                           ; set crc xmodem
                    STA    tmode
                    RTS

*-------------------------------------------------
* Prepare to exit to acos

clrstk              TAX                                     ; save error in x reg
                    LDA    InnerLoop                        ; are we in an InnerLoop
                    BEQ    pull1                            ; nope, in main code, pull ackin off stack
                    PLA                                     ; yes, pull ackin return then
                    PLA                                     ; previous ;return

pull1               PLA
                    PLA
                    TXA

Bad_File            STA    failflag

                    LDX    #6                               ; send 5 <can> characters
canLoop             LDA    #can
                    JSR    MDMOUT
                    DEX
                    BNE    canLoop

                    LDX    #6                               ; followed by 5 backspaces
bsLoop              LDA    #bs
                    JSR    MDMOUT
                    DEX
                    BNE    bsLoop

                    LDA    LastPacket                       ; was this the last?
                    BEQ    notlast                          ; nope, =0 so normal fail
                    LDA    #lastBlkAbt
                    STA    failflag
notlast             JMP    endit

*-------------------------------------------------
* MLI read in the data

readfile            STX    ReadParms+4
                    STA    ReadParms+5

                    JSR    MLI
                    DB     Read
                    DA     ReadParms
                    PHP                                     ; save state of carry flag

                    LDA    ReadParms+7
                    CMP    ReadParms+5
                    BEQ    RfDone
*
* since we were not able to read all we wanted, zero out the rest
* of the block buffer with 00's
*
                    LDA    ReadParms+7                      ; calculate page to start on
                    CLC
                    ADC    #>blockBuffer
                    STA    TEMP+1

                    LDA    #0                               ; always start even
                    STA    TEMP

                    LDY    ReadParms+6                      ; low byte offset to start on
loop2rf             LDA    #0                               ; value to store
rfLoop              STA    (TEMP),Y                         ; store it
                    INY                                     ; next value
                    BNE    rfLoop                           ; did the pages roll over?

                    INC    TEMP+1                           ; y rolled over, do next page in series
                    LDA    TEMP+1
                    CMP    #>blockBuffer+$1000              ; did we reach $3000?
                    BNE    loop2rf                          ; nope, get some more (y=0)

RfDone              LDX    ReadParms+6
                    LDA    ReadParms+7
                    PLP                                     ; get state of carry flag back
                    RTS                                     ; back to caller

*-------------------------------------------------
* Clear the 1k block buffer

clearBuf            LDA    #<blockBuffer
                    STA    TEMP
                    LDA    #>blockBuffer
                    STA    TEMP+1

                    LDY    #128
                    LDA    #0
CbLoop              STA    (TEMP),Y
                    DEY
                    BPL    CbLoop
                    RTS

*-------------------------------------------------
* closefile - close the file and return

closefile           JSR    MLI
                    DB     Close
                    DA     CloseParms
                    RTS

*-------------------------------------------------
* get input - sec=input, clc=no input
* wait up to 1 second before timing out

input               JSR    MDMIN                            ; look for byte incoming
                    BCC    inNf                             ; nothing found, setup loop
                    RTS                                     ; byte found! return to caller

inNf                LDA    #0
                    STA    lastVBL
                    STA    sixty                            ; sixtieths of a second we've waited
                    STA    sixty+1

InLoop              JSR    MDMIN                            ; get byte from modem
                    BCC    no_inp                           ; nothing there, adjust loop counters
                    RTS

no_inp              LDA    VBL                              ; has there been a change?
                    AND    #Hibit                           ; mask all but high bit
                    CMP    lastVBL                          ; look for a change in the value
                    BEQ    InLoop                           ; indicating a transition

                    STA    lastVBL

                    INC    sixty
                    BNE    norollIn
                    INC    sixty+1

norollIn            LDA    sixty
                    CMP    waitFOR
                    BNE    InLoop
                    LDA    sixty+1
                    CMP    waitFOR+1
                    BNE    InLoop

                    CLC                                     ; input was bad
                    LDA    #0
                    RTS

*-------------------------------------------------
* send soh, block number, and complemented block number

SendSOH             LDA    #soh                             ; soh
                    JSR    MDMOUT                           ; send it
                    LDA    PacketNum                        ; get block number
                    JSR    MDMOUT                           ; send it
                    EOR    #-1                              ; flip the bits
                    JSR    MDMOUT                           ; send it
                    RTS

*-------------------------------------------------
* send <stx> (1k block), block number, and complemented block number

SendSTX             LDA    #stx                             ; stx
                    JSR    MDMOUT                           ; send it
                    LDA    PacketNum                        ; get block number
                    JSR    MDMOUT                           ; send it
                    EOR    #-1                              ; flip the bits
                    JSR    MDMOUT                           ; send it
                    RTS

*-------------------------------------------------
* send <sstx> (4k block), block number, and complemented block number

SendSSTX            LDA    #sstx                            ; sstx
                    JSR    MDMOUT                           ; send it
                    LDA    PacketNum                        ; get block number
                    JSR    MDMOUT                           ; send it
                    EOR    #-1                              ; flip the bits
                    JSR    MDMOUT                           ; send it
                    RTS

*-------------------------------------------------
* send CRC bytes out the modem

SendCRC             LDA    crc+1                            ; get crc hi byte
                    JSR    MDMOUT                           ; send it
                    LDA    crc
                    JSR    MDMOUT                           ; send it
                    RTS

*-------------------------------------------------
* maketable -- make the crc table

maketable           LDX    #0                               ; zero first page
                    LDA    #0
MkCLoop             STA    crcLo,X                          ; zero crc lo bytes
                    STA    crcHi,X                          ; zero crc hi bytes
                    INX
                    BNE    MkCLoop

*
* the following is the normal bitwise computation
* tweeked a little to work in the table-maker
*
                    LDX    #0                               ; number to do crc for
fetch               TXA
                    EOR    crcHi,X                          ; add byte into high
                    STA    crcHi,X                          ; of crc

                    LDY    #8                               ; do 8 bits
MkCLoop2            ASL    crcLo,X                          ; shift current crc-16 left
                    ROL    crcHi,X
                    BCC    noadd
*
* if previous high bit wasn't set, then don't add crc
* polynomial ($1021) into the cumulative crc.  else add it.
*
                    LDA    crcHi,X                          ; add hi part of crc poly into
                    EOR    #>$1021                          ; cumulative crc hi
                    STA    crcHi,X

                    LDA    crcLo,X                          ; add lo part of crc poly into
                    EOR    #$1021                           ; cumulative crc lo
                    STA    crcLo,X
noadd               DEY                                     ; do next bit
                    BNE    MkCLoop2                         ; done? nope, loop

                    INX                                     ; do next number in series (0-255)
                    BNE    fetch                            ; didn't roll over, so fetch more
                    RTS                                     ; done

*-------------------------------------------------
* do a crc on a single byte in A, X is preserved, A is not

do_crc              STA    tempcrc
                    TXA                                     ; save X
                    PHA

                    LDA    tempcrc
                    EOR    crc+1                            ; add byte into crc hi byte
                    TAX                                     ; to make offset into tables

                    LDA    crc                              ; get previous lo byte back
                    EOR    crcHi,X                          ; add it to the proper table entry
                    STA    crc+1                            ; save it

                    LDA    crcLo,X                          ; get new lo byte
                    STA    crc                              ; save it back

                    PLA
                    TAX                                     ; restore X
                    RTS                                     ; all done

*-------------------------------------------------
* init some pointers, etc

initcrc             LDA    #<blockBuffer                    ; set up indirect address to
                    STA    TEMP                             ; point to 1k buffer space
                    LDA    #>blockBuffer
                    STA    TEMP+1

                    LDA    #0
                    STA    crc
                    STA    crc+1
                    STA    CheckSum
                    RTS

*-------------------------------------------------
* send a packet of 128 bytes protected by a crc

Send128CRC          JSR    SendSOH                          ; send <soh> and block number

                    LDY    #0                               ; zero
loop128c            LDA    (TEMP),Y                         ; get character
                    JSR    MDMOUT                           ; send it
                    JSR    do_crc
                    INY                                     ; bump offset
                    BPL    loop128c                         ; do 128 bytes

                    JSR    SendCRC                          ; send CRC bytes
                    JMP    ackin                            ; look for ack

*-------------------------------------------------
* Send128Csum -- send a block of 128 bytes protected by a checksum

Send128Csum         JSR    SendSOH

                    LDY    #0                               ; zero
loop128x            LDA    (TEMP),Y                         ; get character
                    JSR    MDMOUT                           ; send it
                    CLC                                     ; prepare for add
                    ADC    CheckSum                         ; add it to CheckSum
                    STA    CheckSum                         ; save CheckSum
                    INY                                     ; bump offset
                    BPL    loop128x                         ; do 128 bytes

                    LDA    CheckSum                         ; get checksum
                    JSR    MDMOUT                           ; send it
                    JMP    ackin                            ; look for ack

*-------------------------------------------------
* Send1024 -- send a 1024 byte packet protected by a CRC

Send1024            JSR    SendSTX

                    LDX    #4                               ; send 4 packs of 256 bytes
                    LDY    #0
loop1024            LDA    (TEMP),Y                         ; get the byte
                    JSR    MDMOUT                           ; send it
                    JSR    do_crc                           ; compute the cumulative crc
                    INY                                     ; next byte
                    BNE    loop1024                         ; done 256? no, do some more
                    INC    TEMP+1                           ; yes, next 256 bytes
                    DEX                                     ; are we done with the 4 packs?
                    BNE    loop1024                         ; no, go send some more

                    JSR    SendCRC
                    JMP    ackin                            ; check for an ack

*-------------------------------------------------
* Send4096 -- send a 4096 byte packet protected by a CRC

Send4096            JSR    SendSSTX

                    LDX    #16                              ; send 16 packs of 256 bytes
                    LDY    #0
loop4096            LDA    (TEMP),Y                         ; get the byte
                    JSR    MDMOUT                           ; send it
                    JSR    do_crc                           ; compute the cumulative crc
                    INY                                     ; next byte
                    BNE    loop4096                         ; done 256? no, do some more
                    INC    TEMP+1                           ; yes, next 256 bytes
                    DEX                                     ; are we done with the 16 packs?
                    BNE    loop4096                         ; no, go send some more

                    JSR    SendCRC
                    JMP    ackin                            ; check for an ack

*-------------------------------------------------
* send final set of packets if not 1k available to send

Send128Packets      STX    bytes                            ; # of bytes we gotta send
                    STA    bytes+1
                    LDA    #1
                    STA    InnerLoop

send1kEntry         LDA    bytes                            ; packs remain
                    ASL    A                                ; shift high bit into carry
                    LDA    bytes+1
                    ROL    A                                ; rol it into the byte
                    AND    #%00001111
                    STA    packsRemain

; number in packsRemain is the num of 128 byte packets remaining

                    LDA    bytes                            ; if any bits are set in b128, then
                    AND    #Clrhi
                    BEQ    noinc                            ; there was a remainder after the divide
                    INC    packsRemain                      ; a remainder

noinc               LDA    #<blockBuffer                    ; make it initially point to the
                    STA    TEMP                             ; beginning of the block buffer
                    LDA    #>blockBuffer
                    STA    TEMP+1

send128PacketsLoop  =      *
loop128P            LDA    #tenErrors                       ; 10 retries
                    STA    retry

                    INC    PacketNum                        ; next xmodem block in series

                    LDA    byteCount
                    CLC
                    ADC    #128
                    STA    byteCount
                    BCC    noroll128
                    INC    byteCount+1
                    BNE    noroll128
                    INC    byteCount+2
noroll128           JSR    PrintCount                       ; print # of blocks sent (again)

loop2128            LDA    #0
                    STA    crc
                    STA    crc+1
                    STA    CheckSum

                    LDA    UseCsum
                    BNE    csum128

                    JSR    Send128CRC
                    BCS    loop2128                         ; not ok, resend the last block
                    DEC    packsRemain
                    BNE    notdone
                    LDA    #0
                    STA    InnerLoop
                    RTS

csum128             JSR    Send128Csum
                    BCS    loop2Csum                        ; not ok, resend the last block
                    DEC    packsRemain
                    BNE    notdone
                    LDA    #0
                    STA    InnerLoop
                    RTS

notdone             LDA    TEMP                             ; get [Buffer] address
                    CLC                                     ; next block is gotten 128 bytes hence
                    ADC    #128
                    STA    TEMP
                    BCC    loop128P                         ; didn't roll over
                    INC    TEMP+1                           ; we rolled over!
                    JMP    loop128P

*-------------------------------------------------
* send final set of packets if 4k not available to send

Send1kPackets       STX    bytes
                    STA    bytes+1
                    LDA    #1
                    STA    InnerLoop

                    LDA    bytes+1                          ; divide bytes / 1024
                    LSR    A
                    LSR    A
                    AND    #%00000111                       ; how many 1k packets we got?
                    BNE    got1kPackets
                    JMP    send1kEntry

got1kPackets        STA    packsRemain

; number in packsRemain is the num of 1k byte packets remaining

                    LDA    #<blockBuffer                    ; make it initially point to the
                    STA    TEMP                             ; beginning of the block buffer
                    LDA    #>blockBuffer
                    STA    TEMP+1

loop1kP             LDA    #tenErrors                       ; 10 retries
                    STA    retry

                    INC    PacketNum                        ; next ymodem block in series

                    LDA    byteCount+1
                    CLC
                    ADC    #>1024
                    STA    byteCount+1
                    BCC    noroll1k
                    INC    byteCount+2

noroll1k            JSR    PrintCount                       ; print # of blocks sent (again)

loop2Csum           LDA    #0
                    STA    crc
                    STA    crc+1

                    JSR    Send1024
                    BCS    loop2Csum                        ; not ok, resend the last block

                    LDA    bytes                            ; keep byte count accurate
                    SEC
                    SBC    #<1024
                    STA    bytes
                    LDA    bytes+1
                    SBC    #>1024
                    STA    bytes+1

                    DEC    packsRemain
                    BNE    loop1kP

                    LDA    bytes
                    BNE    send128Stuff
                    LDA    bytes+1
                    AND    #%00000011
                    BNE    send128Stuff
                    LDA    #0
                    STA    InnerLoop
                    RTS

send128Stuff        LDA    bytes                            ; packs remain after sending all of those
                    ASL    A
                    LDA    bytes+1
                    ROL    A
                    AND    #%00001111
                    STA    packsRemain

; number in packsRemain is the num of 128 byte packets remaining

                    LDA    bytes                            ; if any bits are set in b128, then
                    AND    #Clrhi
                    BEQ    noinc128                         ; there was a remainder after the divide
                    INC    packsRemain                      ; a remainder
noinc128            JMP    send128PacketsLoop

*-------------------------------------------------
* printCString -- print the cstring pointed to by X & Y
*
* a space will also terminate this kind of string

printCString        LDA    TEMP+1
                    PHA
                    LDA    TEMP
                    PHA

                    STX    TEMP
                    STY    TEMP+1

                    LDY    #0
CSloop              LDA    (TEMP),Y
                    BEQ    CSdone
                    AND    #Clrhi
                    CMP    #' '
                    BEQ    CSdone
                    JSR    VIDCOUT
                    INY
                    BRA    CSloop

CSdone              PLA
                    STA    TEMP
                    PLA
                    STA    TEMP+1
                    RTS

*-------------------------------------------------
* print the pascal string at (TEMP) at current cursor loc

printPString        LDY    #0
                    LDA    (TEMP),Y                         ; get filename length byte
                    STA    length

PSloop              INY
                    LDA    (TEMP),Y                         ; get character in filename
                    JSR    VIDCOUT
                    CPY    length
                    BNE    PSloop
                    RTS

*-------------------------------------------------
* long2Dec -- convert a 3 byte long to decimal

long2Dec            LDA    #0                               ; reset total - convert and display an 8 digit
                    STA    num+3                            ; number
                    STA    num+4
                    STA    num+5
                    STA    num+6
                    STA    num+7
                    STA    num+8
                    STA    num+9
                    CLC

                    SED
                    LDY    #24                              ; use decimal mode - shift out 24 bits
DecLoop             ASL    num
                    ROL    num+1
                    ROL    num+2                            ; do actual 'woz' conversion
                    LDA    num+3
                    ADC    num+3
                    STA    num+3
                    LDA    num+4
                    ADC    num+4
                    STA    num+4
                    LDA    num+5
                    ADC    num+5
                    STA    num+5
                    LDA    num+6
                    ADC    num+6
                    STA    num+6
                    ROL    num+7
                    DEY                                     ; loop down
                    BNE    DecLoop
                    CLD                                     ; done with decimal

                    LDA    #0
                    STA    at

                    LDY    #8                               ; print 8 digits
nextDecDigit        LDA    num+7                            ; get digit
                    AND    #LoNibble
                    BNE    notZero                          ; is it zero?

                    BIT    num+8                            ; but, is it a leading zero?
                    BPL    nextDigit                        ; yep

notZero             DEC    num+8
                    CLC
                    ADC    #'0'                             ; print digit
                    TAX
                    INC    num+9

                    TXA
                    LDX    at
                    STA    decimal,X                        ; put digit or spacer, no front spaces
                    INC    at

nextDigit           LDX    #3                               ; move up next digit
DecLoop2            ASL    num+1
                    ROL    num+2
                    ROL    num+3
                    ROL    num+4
                    ROL    num+5
                    ROL    num+6
                    ROL    num+7
                    DEX
                    BPL    DecLoop2

                    DEY                                     ; count down digits
                    BMI    Decdone
                    BNE    nextDecDigit

                    STX    num+8                            ; print last zero for sure
                    BPL    nextDecDigit

Decdone             LDX    at                               ; store trailing zero in decimal for cstr
                    LDA    #0
                    STA    decimal,X
                    RTS

*-------------------------------
* clear the last line to blanks

clearLastLine       LDY    #0
                    STY    CH
cLoop               LDA    #' '+128
                    JSR    VIDCOUT
                    INY
                    CPY    #79
                    BLT    cLoop
                    LDY    #0
                    STY    CH
                    RTS

*-------------------------------------------------
* Text Strings

YmodemText          STR    'Ymodem'

ProtocolTAddr       DA     stdcsum
                    DA     procsum
                    DA     stdcrc
                    DA     procrc
                    DA     std1k
                    DA     pro1k
                    DA     std4k
                    DA     pro4k

pro4k               STR    '4modem / AE'
std4k               STR    '4modem'
pro1k               STR    'Xmodem-1k / AE'
std1k               STR    'Xmodem-1k'
procrc              STR    'CRC-Xmodem / AE'
stdcrc              STR    'CRC-Xmodem'
procsum             STR    'Xmodem / AE'
stdcsum             STR    'Xmodem'

ScreenTxt           STR    'Bytes:         Errs:      Consec:   Mode:                  File:'
FinalBlock          STR    'Final Packet'
CODEEND             =      *

*-------------------------------------------------
* Data segment

timeOut             DW     0                                timeout
ConsecErr           DB     0                                #
crc                 DW     0                                crc
CheckSum            DB     0                                checksum
LastChar            DB     0                                last
PacketNum           DB     0                                block
retry               DB     0                                retry
ctries              DB     0                                look
transtype           DB     0
length              DB     0                                length
InnerLoop           DB     0                                are
UseCsum             DB     0                                0=
LastPacket          DB     0                                was
gflag               DB     0                                ymodem-g?
ackflag             DB     0                                1=no
SendSmall           DB     0                                send
ErrorsBefore        DB     0                                how
bytes               DW     0                                #
packsRemain         DB     0
at                  DB     0
num                 DS     10
decimal             DS     10
lastVBL             DB     0
sixty               DW     0
waitFOR             DW     120
tempcrc             DW     0

pdSource            ORG    pdData
*
* parms for open call
*
openParms           DB     3                                parm_count
                    DA     filename                         filename
                    DA     FBUF2                            buffer
                    DB     0                                ref_num
*
* ReadParms -- parameters for prodos read call
*
ReadParms           DB     4                                #
                    DB     0                                ref_num
                    DA     blockBuffer                      where
                    DW     0                                how
                    DW     0                                how
*
* close parameter list
*
CloseParms          DB     1                                number
                    DB     0                                ref_num
*
* Getinfo parameter list
*
GFIParms            DB     10
                    DA     filename
                    DB     0
                    DB     0
                    DW     0
                    DB     0
                    DW     0
                    DW     0
                    DW     0
                    DW     0
                    DW     0
*
* GetEOF Parameter List
*
GetEOFParms         DB     2                                parameter
                    DB     0
                    DS     3
*
* storage for our filename
*
filename            DS     64

pdLen               =      *-pdData
                    ORG

parmStrt            ORG    FREESPACE
*
* Get/Set File info parms
*
ParmList            DB     destroyEnable+renameEnable+writeEnable+readEnable
                    DB     Txt                              filetype
                    DW     0                                auxtype
                    DB     Seedling                         not
                    DW     0                                blocks_used
                    DW     0                                mod
                    DW     0                                mod
                    DW     0                                create
                    DW     0                                create
*
* EOF Parms to set the proper end of the file
*
EOFParms            DB     2                                parm
                    DB     0                                ref_number
                    DS     3

BlockCount          DW     0                                blocks
TotalErr            DW     0                                total
byteCount           DS     3
parmsLen            =      *-FREESPACE
                    ORG

