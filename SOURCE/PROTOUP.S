*-------------------------------------------------
* Xmodem/Ymodem uploads for LLUCE
*-------------------------------------------------
* use "a:protocol.up",100,1,"L10:","               " = batch
* use "a:protocol.up",100,0,"L10:NEW.FILE" = single file
*-------------------------------------------------
                DATE
*-------------------------------------------------

Id              =      3
Aux             =      1

                LST    OFF
                LSTDO  OFF
                XC
                TR
                TR     ADR
                EXP    ONLY
Y               =      1
y               =      1
N               =      0
n               =      0
NOLIST          =      Y
                DO     NOLIST
LISTOBJ         =      N
LISTSYM         =      N
                ELSE
LISTOBJ         KBD    'List This Source? (Y/N)'
LISTSYM         KBD    'List Symbol Table? (Y/N)'
                FIN
                DO     LISTOBJ
                LST
                FIN
                LST    OFF
                PUT    EQUATES/EQUATES
                PUT    EQUATES/OS.EQUATES
                PUT    EQUATES/ENTRY
                PUT    EQUATES/DRIVEREQU

]TYPE           =      ^overlays                                           ; set file type
]AUX            =      overlays                                            ; and aux type
                ORG    ]AUX                                                ; must be this way
                TYP    ]TYPE

                DSK    /MAIN/LLUCE/SYSTEM/PROTOCOL.UP
                LST    RTN

                TTL    'LLUCE - Xmodem/Ymodem Uploads'

HEADER          DB     Id
                DA     Aux
                DB     Aux/256!Aux!Id!$A5

*-------------------------------
* Size Of Code To Check CRC
*-------------------------------

                DW     CODEEND-main
                DW     0                                                   ; CRC Goes Here

                ORG    $D000

*-------------------------------------------------
* General Global equates

failflag        =      PRN
tmode           =      PRN+1

blockBuffer     =      ENDMOD                                              ; $9B00 need 1k space for block buffer
crcLo           =      ENDMOD+$1100                                        ; $AC00 crc table addresses
crcHi           =      crcLo+$100                                          ; $AD00
pdData          =      crcHi+$100                                          ; $AE00

*-------------------------------------------------
* Program starts here...

main            JMP    dostart
                JMP    dostart

*-------------------------------------------------
* actual xmodem routines begin here

dostart         LDX    #pdLen                                              ; move ProDOS lists into place
movePd          LDA    pdSource-1,X
                STA    pdData-1,X
                DEX
                BNE    movePd

                LDX    #parmsLen                                           ; move LLUCE readable parms into place
moveParm        LDA    parmStrt-1,X
                STA    FREESPACE-1,X
                DEX
                BNE    moveParm

                LDA    #0
                STA    CH
                STA    UseCsum                                             ; don't use checksum initially
                STA    PacketNum
                STA    packet1k
                STA    packet4k
                STA    failflag                                            ; innocent until proven guilty
                STA    KBDSTRB                                             ; reset the keyboard strobe
                STA    byteCount                                           ; zero out block count lo
                STA    byteCount+1                                         ; zero out block count hi
                STA    byteCount+2
                STA    TotalErr
                STA    TotalErr+1
                STA    ConsecErr
                STA    BatchMode                                           ; batchmode = false
                STA    RenameTries                                         ; 0 rename tries

                LDA    #40                                                 ; 40 retries for the first
                STA    retry                                               ; header block.. fast ones

                LDY    #ioLocal
                JSR    SETOVEC                                             ; sysop local output vector

                JSR    GOBCOM
                JSR    INPNUM                                              ; get timeout

                CMP    #>400                                               ; make the timeout have a minimum
                BEQ    tooSmall                                            ; if the high byte's equal, see if the low byte
                BGE    largeEnough                                         ; is at least 400
                BLT    waySmall                                            ; -- and if it's less than, it's way too small

tooSmall        CPX    #<400
                BGE    largeEnough

waySmall        LDA    #>400                                               ; otherwise, default to at least 400 ticks
                LDX    #<400

largeEnough     =      *
                STX    timeOut
                STX    waitFOR
                STA    timeOut+1
                STA    waitFOR+1

                JSR    GOBCOM                                              ; get protocol
                JSR    INPNUM
                BNE    die

                CPX    #batchMd
                BEQ    Intelligent                                         ; is it 0? yes, intelligent
                STX    BatchMode                                           ; batchmode = true
                STX    tmode                                               ; 1=ymodem,2=ymodem-4k
                JMP    Ybatch                                              ; yes, batch ymodem

die             LDA    #parmSyntax                                         ; syntax error
                STA    failflag

                LDY    #ioBoth                                             ; it's ok to exit from here since we didn't yet
                JSR    SETOVEC                                             ; trash any of main memory (we better not have)
                RTS

*-------------------------------------------------
* start of intelligent protocol routines

Intelligent     JSR    GOBCOM                                              ; search for first delimiter
                JSR    MOVNAME                                             ; get pathname in buff

                LDA    #<FLNAME
                STA    TEMP
                LDA    #>FLNAME
                STA    TEMP+1

                LDY    #0                                                  ; get length of filename
                LDA    (TEMP),Y
                STA    Filename
                TAY
fname           LDA    (TEMP),Y                                            ; move acos's filename to ours
                STA    Filename,Y
                DEY
                BNE    fname

                JSR    maketable                                           ; go make the crc table...

                LDX    #<ScreenText
                LDY    #>ScreenText
                JSR    printPString                                        ; put the mode stuff on the screen

                JSR    PrintCount                                          ; print the block count on the screen
                JSR    PrintErr                                            ; print the # of errors on the screen

                LDA    #52
                STA    CH

                LDX    #<Filename                                          ; print filename as pascal string
                STX    DestroyParms
                LDY    #>Filename
                STY    DestroyParms+1
                JSR    printPString

                JSR    MLI                                                 ; create our output file
                DB     Create
                DA     CreateParms

                JSR    MLI
                DB     Open
                DA     OpenParms
                BCC    xstart

                STA    failflag                                            ; store error in peek(10)
                JMP    errout

*-------------------------------------------------
* The actual x/ymodem routines start here

xstart          LDA    OpenParms+5
                STA    CloseParms+1
                STA    EOFParms+1                                          ; save for eof parms
                STA    WriteParms+1                                        ; save for write parms

                LDA    #destroyEnable+renameEnable+readEnable+writeEnable
                STA    SFIParms+3                                          ; access = unlocked

                JMP    aeheader

*-------------------------------------------------
* ae header error

headerr         DEC    retry
                BNE    aeheader
                LDA    #headerErr                                          ; flag header timeout
                JMP    errend

*-------------------------------------------------
* attempt to get the ae header and set proper protocol

aeheader        LDA    #0
aelup           STA    LastChar
                JSR    input
                BCC    aeclear                                             ; if channel is clear,

                CMP    #can                                                ; is it a <Can>?
                BNE    aechkSOH
                CMP    LastChar
                BNE    aechkSOH
                JMP    errend

aechkSOH        JSR    sohEntry                                            ; check for send of headers
                BCC    aegotHdr                                            ; hey!  we got a header too soon
                BCS    aelup                                               ; must have been line noise... weird

aeclear         JSR    ck_out                                              ; output a nak to start trans.
                JSR    sohchk                                              ; look for start of header
                BCS    headerr                                             ; something wrong->start over

aegotHdr        CMP    #eot                                                ; is this the EOT?
                BEQ    headerr                                             ; if so, something's screwed...

                LDA    #41
                STA    CH

                LDA    retry
                CMP    #8
                BCC    xcsum

                LDA    #crcXmdm
                STA    tmode                                               ; set transfer mode to crc

                LDX    #<crcmsg
                LDY    #>crcmsg
                JSR    printPString
                JMP    show

xcsum           LDA    #yModem
                STA    tmode                                               ; set transfer mode to checksum
                STA    UseCsum                                             ; tell them we're using checksum mode

                LDX    #<csummsg
                LDY    #>csummsg
                JSR    printPString

show            LDA    #46
                STA    CH

                LDA    LastChar                                            ; chk last sent char for hi bit
                CMP    #soh+Hibit
                BNE    xset                                                ; must not be AE

                JSR    input                                               ; get input
                BCC    headErrJMP                                          ; nothing there
                STA    LastChar                                            ; otherwise, save it
                JSR    input                                               ; get next input
                BCC    headErrJMP                                          ; nothing there
                EOR    #-1                                                 ; otherwise, flip its bits
                CMP    LastChar                                            ; and see if it's first eored
                BNE    headErrJMP
                JSR    ackout                                              ; send ack

                LDA    #tenErrors
                STA    retry

                LDX    #<promsg
                LDY    #>promsg
                JSR    printPString

                INC    PacketNum                                           ; receiving packet #1
                JMP    nextblock                                           ; start crc xmodem packet receive

headErrJMP      JMP    headerr

*-------------------------------------------------
* Set standard xmodem send if there was some problem with ae

xset            LDX    #<standardMsg
                LDY    #>standardMsg
                JSR    printPString

                LDA    #tenErrors
                STA    retry

                DEC    tmode
                INC    PacketNum                                           ; receiving packet #1
                JMP    standard

*-------------------------------------------------
* Print a character on Sysop's screen, dec err count

Error           INC    TotalErr
                BNE    ernoroll
                INC    TotalErr+1
ernoroll        LDA    retry
                CMP    #tenErrors
                BNE    ENoConsec

                INC    ConsecErr

ENoConsec       JSR    PrintErr
                JSR    nakout                                              ; send <nak>, bad something
                DEC    retry                                               ; more retries?
                BNE    ErrEntry                                            ; yep, once more..till 10
                LDA    #blockErr                                           ; more than 2 consecutive errors
                JMP    errend                                              ; nope, end it all

*-------------------------------------------------
* get a block

nextblock       LDA    #tenErrors
                STA    retry

ErrEntry        JSR    sohchk
                BCS    Error
                JSR    CheckEOT

standard        LDA    LastChar                                            ; entry point for standard
                STA    blk_type

                JSR    blkchk
                BCS    Error

                LDA    blk_type
                CMP    #soh
                BEQ    get_128
                CMP    #stx
                BEQ    x1024

x4096           JSR    Get4096
                BCS    Error
                BCC    write_it

x1024           JSR    Get1024
                BCS    Error
                BCC    write_it

get_128         LDA    UseCsum
                BNE    csum128

                JSR    Get128CRC
                BCS    Error
                BCC    write_it

csum128         JSR    Get128Csum
                BCS    Error

write_it        JSR    WriteBuffer

                JSR    ackout                                              ; send ack
                JMP    nextblock

*-------------------------------------------------
* check for end of transfer

CheckEOT        LDA    LastChar                                            ; get last char sent
                CMP    #eot                                                ; is it a Eot flag?
                BEQ    EOTdone                                             ; yes, end it
                RTS                                                        ; and back to caller

EOTdone         LDA    BatchMode                                           ; were we in batch mode for this?
                BEQ    FileEOT                                             ; yes, finish as batch

                JMP    BatchEOT                                            ; nope, finish as batch mode

*-------------------------------------------------
* yeah! that's all she wrote

FileEOT         PLA                                                        ; get rid of return address
                PLA
                JSR    ackout                                              ; send ack
                LDA    tmode                                               ; get trans mode

                CMP    #yModem
                BEQ    get_foot
                CMP    #crcXmdm
                BEQ    get_foot
NoFoot          JMP    aeskip

*-------------------------------------------------
* start with ae footer packet

get_foot        LDY    #6                                                  ; set prodos footer retry count
fLoop           DEY                                                        ; decrement count
                BEQ    NoFoot
                LDA    #syn                                                ; $16 = syn (prodos proto)
                JSR    MDMOUT                                              ; send it
                JSR    input                                               ; get input
                CMP    #etb                                                ; is it $17 (etb prodos proto)
                BNE    fLoop                                               ; not etb, retry

                LDA    #tenErrors                                          ; init to 10
                STA    retry                                               ; retry counter
                JMP    Footer

*-------------------------------------------------
* prodos parms error restart

FootErr         INC    TotalErr
                BNE    fenoroll
                INC    TotalErr+1
fenoroll        LDA    retry
                CMP    #tenErrors
                BNE    FNoConsec

                INC    ConsecErr

FNoConsec       JSR    PrintErr
                JSR    nakout
                DEC    retry
                BNE    Footer
                LDA    #footerErr                                          ; footer error
                JMP    errend

*-------------------------------------------------
* prodos MLI info packet

Footer          JSR    nakout                                              ; send a nak

                LDA    #%10101010
                STA    PacketNum
                JSR    sohchk                                              ; look for soh
                BCS    FootErr                                             ; wrong-retry

                JSR    blkchk
                BCS    FootErr

                LDA    #<SFIParms
                STA    TEMP
                LDA    #>SFIParms
                STA    TEMP+1

                LDA    UseCsum
                BNE    csumFoot

                JSR    Get128CRC
                BCS    FootErr
                BCC    Footdone

csumFoot        JSR    Get128Csum
                BCS    FootErr

Footdone        JSR    ackout

*-------------------------------------------------
* set the end of the file

seteof          LDA    #2                                                  ; fill-in # of parameters
                STA    EOFParms
                LDA    OpenParms+5                                         ; fill-in ref_num
                STA    EOFParms+1

                JSR    MLI
                DB     Seteof
                DA     EOFParms
                JSR    closefile

                LDA    #7                                                  ; set info parm
                STA    SFIParms                                            ; count
                LDA    #<Filename                                          ; anything previous was detroyed
                STA    SFIParms+1                                          ; so we put the correct path there
                LDA    #>Filename                                          ; and hope it works..har
                STA    SFIParms+2

                JSR    MLI
                DB     Setinfo                                             ; set info from what we given it
                DA     SFIParms

                LDY    #19
mloop           LDA    SFIParms+3,Y                                        ; move all 20 bytes
                STA    ParmList,Y
                DEY
                BPL    mloop

aeskip          JSR    closefile                                           ; skip everything about the file

                LDA    packet1k                                            ; check for 1k blocks
                BEQ    none
                INC    tmode
                INC    tmode
                LDA    packet4k                                            ; check for 4k blocks
                BEQ    none
                INC    tmode
                INC    tmode

none            JMP    errout                                              ; clear line and leave

*-------------------------------------------------
* Batch Ymodem starts here

Ybatch          JSR    GOBCOM                                              ; gobble the comma
                JSR    INPSTR                                              ; get the first string
                CPY    #fnMaxLen                                           ; is it >= than 15?
                BEQ    do_ymodem                                           ; yes, go there

                LDA    #parmSyntax
                STA    failflag
                RTS

*-------------------------------------------------
* error routine - errors within the transfer

BatchError      INC    TotalErr
                BNE    benoroll
                INC    TotalErr
benoroll        JSR    PrintErr
                JSR    nakout

nonak           DEC    retry
                BNE    do_ymodem
                LDA    #headerErr                                          ; fatal header error
                JMP    no_del

*-------------------------------------------------
* here begin most of the important ymodem routines

do_ymodem       JSR    clrstring

                LDA    #0
                STA    CH

                LDX    #<ScreenText
                LDY    #>ScreenText
                JSR    printPString                                        ; put the mode stuff on the screen
                JSR    PrintCount                                          ; print the block count on the screen
                JSR    PrintErr                                            ; print the # of errors on the screen

                JSR    maketable                                           ; quick! make the crc-table!

                LDA    #0
ylup            STA    LastChar
                JSR    input
                BCC    yclear

                CMP    #can                                                ; is it a <Can> character?
                BNE    ychkSOH
                CMP    LastChar
                BNE    ychkSOH
                JMP    errend

ychkSOH         JSR    sohEntry                                            ; is is a block header?
                BCC    ygotHdr
                BCS    ylup                                                ; must've been line noise...

yclear          LDX    tmode                                               ; using ymodem or ymodem-4k?
                DEX                                                        ; was 1 or 2, now 0 or 1
                LDA    startsig,X                                          ; clear channel, send the 'c'
                JSR    MDMOUT                                              ; send it

                JSR    sohchk                                              ; get header
                BCS    nonak                                               ; something went wrong...

ygotHdr         LDA    LastChar
                CMP    #soh                                                ; must be small header packet
                BNE    BatchError                                          ; nope, we got problems

                JSR    blkchk                                              ; make sure the next 2 bytes
                BCS    BatchError                                          ; are in sync

                JSR    Get128CRC                                           ; get a small packet
                BCS    BatchError

                LDA    blockBuffer                                         ; get first byte of packet
                BNE    proc_file                                           ; 0? nope, process file...

                JSR    ackout                                              ; yeah! end of transfer
                JMP    errout                                              ; string is already clear so end

*-------------------------------------------------
* continue with file transfer since there is a filename

proc_file       LDY    #0                                                  ; calculate length of file
len_loop        LDA    blockBuffer,Y                                       ; get a byte of the filename
                AND    #Clrhi                                              ; strip the high bit
                BEQ    endname

                CMP    #'.'
                BEQ    valid

                CMP    #'z'+1
                BGE    notValid

                CMP    #'a'                                                ; if it's lowercase, make it uppercase
                BLT    notLower
                SEC
                SBC    #CaseDiff
                JMP    valid

notLower        CMP    #'Z'+1
                BGE    notValid
                CMP    #'A'
                BGE    valid
                CMP    #':'
                BGE    notValid
                CMP    #'0'
                BGE    valid

notValid        LDA    #'.'
valid           STA    Filename+1,Y                                        ; put it at the filename
                INY
                CPY    #fnMaxLen
                BLT    len_loop                                            ; loop until a (0) found or we hit 15 chars

                LDY    #fnMaxLen
endname         STY    Filename                                            ; save length of file

                LDA    Filename+1                                          ; make sure the first character is an alpha char
                CMP    #'A'
                BGE    firstIsAlpha
                LDA    #'A'
                STA    Filename+1

firstIsAlpha    =      *
                LDA    blockBuffer+64                                      ; is it proterm special batch?
                CMP    #']'-Ctrl
                BEQ    proterm                                             ; yes, flag as such
                LDA    #fileMd                                             ; nope, must be 'standard' batch
                STA    batchtype

                LDA    #0
                STA    EOFParms+2
                STA    EOFParms+3
                STA    EOFParms+4
                JSR    prntext

                LDX    #0
bLoop           LDA    blockBuffer,X
                BEQ    foundEnd
                INX
                BNE    bLoop
                JMP    noEnd

foundEnd        INX                                                        ; next character in buffer is the file length
                LDA    blockBuffer,X
                BEQ    noEnd

                LDA    #','
                JSR    VIDCOUT
                LDA    #' '
                JSR    VIDCOUT

                TXA                                                        ; according to true ymodem
                CLC
                ADC    #<blockBuffer
                TAX
                LDA    #>blockBuffer
                ADC    #0
                TAY
                JSR    printCString
noEnd           JMP    CreateAgain

proterm         LDA    #batchMd
                STA    batchtype

                LDY    #19
ptmloop         LDA    blockBuffer+69,Y                                    ; move the gfi parms and
                STA    SFIParms+3,Y                                        ; eof parms, all 20 bytes
                STA    ParmList,Y
                DEY
                BPL    ptmloop

                JSR    prntext

                LDA    #2                                                  ; make sure the parameter
                STA    EOFParms                                            ; count is correct
                LDA    #7
                STA    SFIParms

                LDA    SFIParms+7                                          ; get storage type for file
* lda #1
                STA    CreateParms+7                                       ; store it for creation
                LDA    #<Filename                                          ; get pathname for file
                LDX    #>Filename
                STA    SFIParms+1                                          ; store it for later on
                STX    SFIParms+2                                          ; when doing the sfi call

CreateAgain     =      *
                JSR    MLI
                DB     Create                                              ; create a file
                DA     CreateParms                                         ; create params
                BCC    create_ok                                           ; continue if ok

*-------------------------------------------------
* File creation was in error

Pro_Err         CMP    #dupPathname                                        ; is it a duplicate filename?
                BNE    killFile

                INC    RenameTries
                LDA    RenameTries
                CMP    #'Z'-Ctrl
                BNE    ProErrok
                LDA    #dupPathname                                        ; duplicate filename error
                STA    failflag
                JMP    no_del

ProErrok        LDY    Filename
                CPY    #fnMaxLen
                BGE    got15

                INY
                LDA    #'.'
                STA    Filename,Y
                STY    Filename
                JMP    CreateAgain

got15           LDA    Filename+2
                CMP    'Z'
                BEQ    makeA
                INC    Filename+2
                JMP    CreateAgain

makeA           LDA    #'A'
                STA    Filename+2
                JMP    CreateAgain

killFile        STA    failflag
                JSR    clrstring
                JMP    no_del

*-------------------------------------------------
* Continue with the transfer if file create was successful

create_ok       LDY    Filename                                            ; move filename to string
cloop2          LDA    Filename,Y
                DEY
                STA    (STRLOC),Y
                CPY    #0
                BNE    cloop2

                JSR    MLI
                DB     Open                                                ; open
                DA     OpenParms                                           ; open params
                BCC    openOK

                PHA
                JSR    clrstring
                PLA
                JMP    errend

openOK          LDA    OpenParms+5                                         ; number of open file??
                STA    EOFParms+1
                STA    WriteParms+1
                STA    CloseParms+1
                JSR    ackout

                LDA    #60                                                 ; change the length to wait
                STA    waitFOR
                LDA    #0
                STA    waitFOR+1
cloop           JSR    input                                               ; look for input for 0.5 second
                BCS    cloop                                               ; keep waiting till nothing is incoming
                LDA    timeOut
                STA    waitFOR
                LDA    timeOut+1
                STA    waitFOR+1

                LDX    tmode                                               ; get either the C or 4
                DEX
                LDA    startsig,X
                JSR    MDMOUT

                JMP    nextblock                                           ; go get a *LOT* of blocks

*-------------------------------------------------
* <ack> output routine

ackout          LDX    ConsecErr
                LDA    #0                                                  ; we got something good, no consec errs
                STA    ConsecErr
                CPX    #0                                                  ; did we have any consec?
                BEQ    resetErr                                            ; nope, don't erase anything
                JSR    PrintErr                                            ; yes, erase the consec

resetErr        LDA    #ack                                                ; get ack
                JMP    MDMOUT                                              ; send it out the modem

*-------------------------------------------------
* <nak> output routine

nakout          LDA    #60
                STA    waitFOR
                LDA    #0
                STA    waitFOR+1

noloop          JSR    input                                               ; look for input
                BCS    noloop                                              ; keep waiting till nothing is incoming
                LDA    timeOut
                STA    waitFOR
                LDA    timeOut+1
                STA    waitFOR+1

                LDA    #nak                                                ; get nak
                JMP    MDMOUT                                              ; send it and return to caller

*-------------------------------------------------
* Send a 'CKL' to start transmission

ck_out          JSR    MDMDCD
                BCC    clrstk

                LDA    retry
                CMP    #8                                                  ; is this the 8th retry?
                BCC    send_nak                                            ; yes, start sending <nak>s

send_ck         JSR    MDMIN                                               ; look for input
                BCS    send_ck                                             ; keep waiting till nothing is incoming
                LDA    #'C'                                                ; get C
                JSR    MDMOUT                                              ; send it
                LDA    #'K'                                                ; get K
                JSR    MDMOUT                                              ; send it
                LDA    #'L'                                                ; get L
                JMP    MDMOUT                                              ; have sent <C><K><L>

send_nak        JSR    MDMIN                                               ; look for input
                BCS    send_nak                                            ; keep waiting till nothing is incoming
                LDA    #nak                                                ; get nak
                JMP    MDMOUT                                              ; send it and return to caller

*-------------------------------------------------
* write xxxx bytes to file

WriteBuffer     STX    WriteParms+4
                STA    WriteParms+5

                JSR    MLI
                DB     Write
                DA     WriteParms
                BCS    clrstk                                              ; onerr exit...
                RTS                                                        ; return to caller

*-------------------------------------------------
* clrstk and errend go together...

clrstk          TAX                                                        ; save our error number
                PLA                                                        ; pull extra return
                PLA
                TXA                                                        ; restore our error number

errend          STA    failflag                                            ; store our error in failflag
                JSR    closefile
                JSR    destroyfile

no_del          JSR    closefile

                LDY    #6                                                  ; send 5 <Can> characters
                LDA    #can
canloop         JSR    MDMOUT
                DEY
                BNE    canloop

                LDY    #6                                                  ; followed by 5 backspace characters
                LDA    #bs
bs_loop         JSR    MDMOUT
                DEY
                BNE    bs_loop
                JMP    errout

*-------------------------------------------------
* get header routine... sec=no sohchk, clc=sohchk

sohchk          LDA    KYBD                                                ; read the keyboard
                BPL    nopress                                             ; anyone pressed a key? nope
                CMP    #escKey                                             ; yes, is it the escape key?
                BEQ    clrstk                                              ; yes, exit violently
                STA    KBDSTRB                                             ; no, reset strobe, continue

nopress         LDA    #0
                STA    crc                                                 ; init the crc counter
                STA    crc+1
                STA    CheckSum

                JSR    MDMDCD                                              ; is caller still there?
                BCC    clrstk                                              ; no, exit
                JSR    input                                               ; yes, get some data
                BCC    sohbad                                              ; nothing there, lose it

sohEntry        CMP    #can                                                ; is it a <Can>?
                BNE    continue                                            ; no, continue
                CMP    LastChar                                            ; yes, is it 2 in a row?
                BEQ    clrstk                                              ; yes, leave suddenly

continue        STA    LastChar
                CMP    #eot
                BEQ    SOHok
                CMP    #sstx                                               ; is it a 4k packet?
                BEQ    xlarge                                              ; yes, go handle it
                CMP    #stx                                                ; is it a large packet?
                BEQ    large                                               ; go handle it
                AND    #Clrhi                                              ; strip high off for AE mode
                CMP    #soh
                BNE    sohbad                                              ; nothing we've ever seen
SOHok           CLC
                RTS

large           LDY    #1
                STY    packet1k
                CLC
                RTS

xlarge          LDY    #1
                STY    packet4k
                CLC
                RTS

sohbad          SEC
                RTS

*-------------------------------------------------
* get input - sec=input, clc=no input
*  wait up to 1 second before timing out

input           LDA    #0
                STA    lastVBL
                STA    sixty                                               ; sixtieths of a second we've waited
                STA    sixty+1

inploop         JSR    MDMIN                                               ; get byte from modem
                BCC    no_inp                                              ; nothing there, adjust loop counters
                RTS

no_inp          LDA    VBL                                                 ; has there been a change?
                AND    #Hibit                                              ; mask all but high bit
                CMP    lastVBL                                             ; look for a change in the value
                BEQ    inploop                                             ; indicating a transition

                STA    lastVBL

                INC    sixty
                BNE    innoroll
                INC    sixty+1

innoroll        LDA    sixty
                CMP    waitFOR
                BNE    inploop
                LDA    sixty+1
                CMP    waitFOR+1
                BNE    inploop

                CLC                                                        ; input was bad
                LDA    #0
                RTS

*-------------------------------------------------
* check block number and complement

blkchk          LDA    #<blockBuffer
                STA    TEMP
                LDA    #>blockBuffer
                STA    TEMP+1

                JSR    input                                               ; get input
                BCC    setrts                                              ; nothing there
                STA    LastChar                                            ; otherwise, save it
                CMP    PacketNum                                           ; is it the current block #?
                BNE    setrts                                              ; nope, return in error
                JSR    input                                               ; get next input
                BCC    setrts                                              ; nothing there
                EOR    #-1                                                 ; otherwise, flip its bits
                CMP    LastChar                                            ; and see if it's first eored
                BNE    setrts

                CLC                                                        ; otherwise flag ok
                RTS                                                        ; and return

setrts          SEC                                                        ; flag error
                RTS                                                        ; and return

*-------------------------------------------------
* End of transmission

BatchEOT        PLA
                PLA
                JSR    ackout                                              ; respond in kind

                LDA    batchtype                                           ; if the kind of batch is forsberg
                BNE    setok                                               ; then don't bother to Seteof

                JSR    MLI
                DB     Seteof
                DA     EOFParms
                BCC    setok
err_jump        JMP    errend

setok           JSR    closefile

                LDA    batchtype                                           ; what kind of batch?
                BNE    errout                                              ; forsberg, skip this step

                JSR    MLI
                DB     Setinfo                                             ; Setinfo
                DA     SFIParms
                BCS    err_jump                                            ; on error kill the file, exit

errout          LDY    #0
                STY    CH

                LDA    #' '
spcloop         JSR    VIDCOUT                                             ; clear bottom line...
                INY
                CPY    #79
                BNE    spcloop

                LDY    #0
                STY    CH                                                  ; start at htab 0
                JMP    SETOVEC                                             ; set #0 to output vector

*-------------------------------------------------
* Close whatever we have opened

closefile       JSR    MLI
                DB     Close                                               ; close
                DA     CloseParms                                          ; close params
                RTS

*-------------------------------------------------
* ProDOS MLI Destroy a file call

destroyfile     JSR    MLI
                DB     Destroy                                             ; destroy
                DA     DestroyParms
                RTS

*-------------------------------------------------
* print error count

PrintErr        LDA    #20
                STA    CH                                                  ; horizontal location
                LDA    TotalErr                                            ; low
                STA    num
                LDA    TotalErr+1                                          ; high
                STA    num+1
                LDA    #0
                STA    num+2
                JSR    long2Dec                                            ; print it

                LDX    #<decimal
                LDY    #>decimal
                JSR    printCString

                LDA    #33
                STA    CH
                LDA    ConsecErr                                           ; low
                STA    num
                LDA    #0                                                  ; high
                STA    num+1
                STA    num+2
                JSR    long2Dec                                            ; print it

                LDX    #<decimal
                LDY    #>decimal
                JMP    printCString

*-------------------------------------------------
* print block count

PrintCount      LDA    #6
                STA    CH                                                  ; horizontal location

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
* print Mode:Ymodem XSGFDGDFG, 12345678 on screen

prntext         LDA    #41
                STA    CH

                LDX    #<YmodemText
                LDY    #>YmodemText
                JSR    printPString

                LDA    #52
                STA    CH

                LDX    #<Filename
                LDY    #>Filename
                JSR    printPString
*
*  calculate xmodem blocks
*
                LDA    EOFParms+2                                          ; get EOF, place it at num
                STA    num
                LDA    EOFParms+3
                STA    num+1
                LDA    EOFParms+4
                STA    num+2
                BNE    printSomething

                LDA    num+1
                BNE    printSomething
                LDA    num
                BEQ    printNothing

printSomething  =      *
                LDA    #','
                JSR    VIDCOUT
                LDA    #' '
                JSR    VIDCOUT

                JSR    long2Dec

                LDX    #<decimal
                LDY    #>decimal
                JSR    printCString

printNothing    =      *
                RTS

*-------------------------------------------------
* long2Dec -- convert a 3 byte long to decimal

long2Dec        LDA    #0                                                  ; reset total - convert and display an 8 digit
                STA    num+3                                               ; number
                STA    num+4
                STA    num+5
                STA    num+6
                STA    num+7
                STA    num+8
                STA    num+9
                CLC

                SED
                LDY    #24                                                 ; use decimal mode - shift out 24 bits
dLoop           ASL    num
                ROL    num+1
                ROL    num+2                                               ; do actual 'woz' conversion
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
                DEY                                                        ; loop down
                BNE    dLoop
                CLD                                                        ; done with decimal

                LDA    #0
                STA    at

                LDY    #8                                                  ; print 8 digits
nextDecDigit    LDA    num+7                                               ; get digit
                AND    #LoNibble
                BNE    notZero                                             ; is it zero?

                BIT    num+8                                               ; but, is it a leading zero?
                BPL    nextDigit                                           ; yep

notZero         DEC    num+8
                CLC
                ADC    #'0'                                                ; print digit
                TAX
                INC    num+9

                TXA
                LDX    at
                STA    decimal,X                                           ; put digit or spacer, no front spaces
                INC    at

nextDigit       LDX    #3                                                  ; move up next digit
ndgloop         ASL    num+1
                ROL    num+2
                ROL    num+3
                ROL    num+4
                ROL    num+5
                ROL    num+6
                ROL    num+7
                DEX
                BPL    ndgloop

                DEY                                                        ; count down digits
                BMI    L2Ddone
                BNE    nextDecDigit

                STX    num+8                                               ; print last zero for sure
                BPL    nextDecDigit

L2Ddone         LDX    at                                                  ; store trailing zero in decimal for cstr
                LDA    #0
                STA    decimal,X
                RTS

*-------------------------------------------------
* put 15 spaces in the filename string, regardless

clrstring       LDA    #' '
                LDY    #fnMaxLen-1                                         ; 15 characters
csloop          STA    (STRLOC),Y                                          ; store at end of string
                DEY                                                        ; next character
                BPL    csloop                                              ; all done?
                RTS                                                        ; yes, return

*-------------------------------------------------
* maketable -- make the crc table

maketable       LDX    #0                                                  ; zero first page
                LDA    #0
mtloop1         STA    crcLo,X                                             ; zero crc lo bytes
                STA    crcHi,X                                             ; zero crc hi bytes
                INX
                BNE    mtloop1

* the following is the normal bitwise computation
* tweeked a little to work in the table-maker
*
                LDX    #0                                                  ; number to do crc for
fetch           TXA
                EOR    crcHi,X                                             ; add byte into high
                STA    crcHi,X                                             ; of crc

                LDY    #8                                                  ; do 8 bits
mtloop2         ASL    crcLo,X                                             ; shift current crc-16 left
                ROL    crcHi,X
                BCC    noadd

* if previous high bit wasn't set, then don't add crc
* polynomial ($1021) into the cumulative crc.  else add it.
*
                LDA    crcHi,X                                             ; add hi part of crc poly into
                EOR    #>$1021                                             ; cumulative crc hi
                STA    crcHi,X

                LDA    crcLo,X                                             ; add lo part of crc poly into
                EOR    #<$1021                                             ; cumulative crc lo
                STA    crcLo,X
noadd           DEY                                                        ; do next bit
                BNE    mtloop2                                             ; done? nope, loop

                INX                                                        ; do next number in series (0-255)
                BNE    fetch                                               ; didn't roll over, so fetch more
                RTS                                                        ; done

*-------------------------------------------------
* do a crc on a single byte in A, X is preserved, A is not

do_crc          STA    tempcrc
                TXA                                                        ; save X
                PHA

                LDA    tempcrc
                EOR    crc+1                                               ; add byte into crc hi byte
                TAX    to                                                  ; make offset into tables

                LDA    crc                                                 ; get previous lo byte back
                EOR    crcHi,X                                             ; add it to the proper table entry
                STA    crc+1                                               ; save it

                LDA    crcLo,X                                             ; get new lo byte
                STA    crc                                                 ; save it back

                PLA
                TAX                                                        ; restore X
                RTS                                                        ; all done

*-------------------------------------------------
* Check the incoming CRC-16

chkcrc          JSR    input                                               ; is there input?
                BCC    crcbad
                CMP    crc+1
                BNE    crcbad
                JSR    input
                BCC    crcbad
                CMP    crc
                BNE    crcbad
                CLC
                RTS

crcbad          SEC
                RTS

*-------------------------------------------------
* Get a 128 byte block verified with a checksum

Get128Csum      LDY    #0                                                  ; zero out offset
loop128c        JSR    input                                               ; get data sent
                BCC    error8c
                STA    (TEMP),Y                                            ; store in block buffer
                CLC                                                        ; prepare for add
                ADC    CheckSum                                            ; add to checksum
                STA    CheckSum                                            ; and save it
                INY                                                        ; bump offset for next data
                BPL    loop128c                                            ; keep going for all 128 bytes

                JSR    input                                               ; data done get checksum
                BCC    error8c
                CMP    CheckSum                                            ; his CheckSum same as ours?
                BNE    error8c                                             ; let's try again

                INC    PacketNum                                           ; bump block number counter

                LDA    byteCount
                CLC
                ADC    #128
                STA    byteCount
                BCC    noroll8c
                INC    byteCount+1
                BNE    noroll8c
                INC    byteCount+2
noroll8c        JSR    PrintCount

                LDX    #<128
                LDA    #>128
                CLC
                RTS

error8c         SEC
                RTS

*-------------------------------------------------
* Get a 128 byte block

Get128CRC       LDY    #0
loop128x        JSR    input
                BCC    error8x
                STA    (TEMP),Y
                JSR    do_crc
                INY
                BPL    loop128x

                JSR    chkcrc
                BCS    error8x

                INC    PacketNum

                LDA    byteCount
                CLC
                ADC    #128
                STA    byteCount
                BCC    noroll8x
                INC    byteCount+1
                BNE    noroll8x
                INC    byteCount+2
noroll8x        JSR    PrintCount

                LDX    #<128
                LDA    #>128
                CLC
                RTS

error8x         SEC
                RTS

*-------------------------------------------------
* get a 1024 byte block

Get1024         LDX    #4
                LDY    #0
loop24          JSR    input
                BCC    error24
                STA    (TEMP),Y
                JSR    do_crc
                INY
                BNE    loop24
                INC    TEMP+1
                DEX
                BNE    loop24

                JSR    chkcrc
                BCS    error24

                INC    PacketNum

                LDA    byteCount+1
                CLC
                ADC    #>1024
                STA    byteCount+1
                BCC    noroll24
                INC    byteCount+2
noroll24        JSR    PrintCount

                LDX    #<1024
                LDA    #>1024
                CLC
                RTS

error24         SEC
                RTS

*-------------------------------------------------
* get a 4096 byte block

Get4096         LDX    #16
                LDY    #0
loop96          JSR    input
                BCC    error96
                STA    (TEMP),Y
                JSR    do_crc
                INY
                BNE    loop96
                INC    TEMP+1
                DEX
                BNE    loop96

                JSR    chkcrc
                BCS    error96

                INC    PacketNum

                LDA    byteCount+1
                CLC
                ADC    #>4096
                STA    byteCount+1
                BCC    noroll96
                INC    byteCount+2
noroll96        JSR    PrintCount

                LDX    #<4096
                LDA    #>4096
                CLC
                RTS

error96         SEC
                RTS

*-------------------------------------------------
* printCString -- print the cstring pointed to by X & Y
*
* a space will also terminate this kind of string

printCString    LDA    TEMP+1
                PHA
                LDA    TEMP
                PHA

                STX    TEMP
                STY    TEMP+1

                LDY    #0
cstloop         LDA    (TEMP),Y
                BEQ    cstdone
                AND    #Clrhi
                CMP    #' '
                BEQ    cstdone
                JSR    VIDCOUT
                INY
                BRA    cstloop

cstdone         PLA
                STA    TEMP
                PLA
                STA    TEMP+1
                RTS

*-------------------------------------------------
* print the pascal string at (TEMP) at current cursor loc

printPString    LDA    TEMP+1
                PHA
                LDA    TEMP
                PHA

                STX    TEMP
                STY    TEMP+1

                LDY    #0
                LDA    (TEMP),Y                                            ; get filename length byte
                STA    length

pLoop           INY
                LDA    (TEMP),Y                                            ; get character in filename
                JSR    VIDCOUT
                CPY    length
                BNE    pLoop

                PLA
                STA    TEMP
                PLA
                STA    TEMP+1
                RTS

*-------------------------------------------------
* Text Strings

STRINGS         =      *
YmodemText      STR    'Ymodem'
crcmsg          STR    'CRC'
csummsg         STR    'Csum'
promsg          STR    'AE'
standardMsg     STR    'Stnd'

ScreenText      STR    'Bytes:         Errs:      Consec:   Mode:'
CODEEND         =      *

*-------------------------------------------------
* Data segment

MAINDATA        =      *
startsig        ASC    'C4'                                                ; characters for ymodem start
timeOut         DW     0                                                   ; timeout in 120ths of a second
ConsecErr       DB     0                                                   ; # of consecutive errors
batchtype       DB     0                                                   ; which batch mode? (0=proterm,1=forsberg)
retry           DB     0                                                   ; remaining retries
PacketNum       DB     0                                                   ; current block number modulo 256
LastChar        DB     0                                                   ; last character received
crc             DW     0                                                   ; low part of the crc
blk_type        DB     0                                                   ; small or large block?
CheckSum        DB     0                                                   ; checksum register
packet1k        DB     0                                                   ; was there a 1k packet?
packet4k        DB     0                                                   ; was there a 4k packet?
UseCsum         DB     0
BatchMode       DB     0                                                   ; batch mode? (0=no, 1=yes)
RenameTries     DB     0                                                   ; how many tried to rename the file

at              DB     0
num             DS     10
decimal         DS     10

lastVBL         DB     0
sixty           DW     0
waitFOR         DA     $F0

tempcrc         DW     0

length          DB     0
pdSource        =      *
                ORG    pdData
*
* open parameters
*
OpenParms       DB     3                                                   ; 3 parameters follow
                DA     Filename                                            ; file's name/no prefix
                DA     FBUF2                                               ; address of 1k file buffer
                DB     0                                                   ; ref_num
*
* close parameters
*
CloseParms      DB     1                                                   ; number of parameters
                DB     0                                                   ; ref_num

*
* create a file parameters
*
CreateParms     DB     7
                DA     Filename                                            ; address of Filename
                DB     destroyEnable+renameEnable+writeEnable+readEnable
                DB     Txt                                                 ; filetype (text)
                DW     0                                                   ; aux filetype
                DB     Seedling                                            ; storage type (seedling)
                DW     0                                                   ; date of creation
                DW     0                                                   ; time of creation

*
* destroy file parameters
*
DestroyParms    DB     1
                DA     Filename                                            ; file to delete

*
* write to a file parameter list
*
WriteParms      DB     4                                                   ; number of parameters
                DB     0                                                   ; reference number
                DA     blockBuffer                                         ; address of file buffer
                DW     0                                                   ; length of buffer
                DW     0                                                   ; actual length

*
* Get/Set File info parms
*
SFIParms        DB     7                                                   ; parm count
                DA     Filename                                            ; path addr
                DB     destroyEnable+renameEnable+writeEnable+readEnable
                DB     Txt                                                 ; filetype (text)
                DW     0                                                   ; auxtype
                DB     Seedling                                            ; not used
                DW     0
                DW     0                                                   ; mod date
                DW     0                                                   ; mod time
                DW     0                                                   ; create date
                DW     0                                                   ; create time

*
* EOF Parms to set the proper end of the file
*
EOFParms        DB     2                                                   ; parm count
                DB     0                                                   ; reference number
                DS     3

*
*  filename buffer
*
Filename        DS     64                                                  ; area for filename

pdLen           =      *-pdData
                ORG

parmStrt        =      *
                ORG    FREESPACE
*
* Get/Set File info parms
*
ParmList        DB     destroyEnable+renameEnable+writeEnable+readEnable
                DB     Txt                                                 ; filetype (text)
                DW     0                                                   ; auxtype
                DB     Seedling                                            ; not used
                DW     0                                                   ; length in prodos blocks
                DW     0                                                   ; mod date
                DW     0                                                   ; mod time
                DW     0                                                   ; create date
                DW     0                                                   ; create time

*
* EOF Parms to set the proper end of the file
*
                DB     2                                                   ; parm count
                DB     0                                                   ; reference number
                DS     3

BlockCount      DW     0                                                   ; current block number
TotalErr        DW     0                                                   ; how many total errors occured
byteCount       DS     3
parmsLen        =      *-FREESPACE
                ORG

