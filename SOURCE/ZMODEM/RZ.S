                    LST    OFF
                    LSTDO  OFF
*
* July 15, 1991
*
* This file is hereby dedicated to the public domain.
*                                 -- Andrew Nicholas
*
                    XC
                    TR
                    TR     ADR
Y                   =      1
y                   =      1
N                   =      0
n                   =      0
LISTOBJ             KBD    'List This Source? (Y/N)'
LISTSYM             KBD    'List Symbol Table? (Y/N)'
SAVEOBJ             KBD    'Save Object Code? (Y/N)'

                    DO     LISTOBJ
                    LST
                    FIN
                    LST    OFF

BUILDIIC            KBD    'Build IIc version? (Y/N)'
NOTBUILDIIC         =      1-BUILDIIC
BUILDFLUSH          KBD    'Build using MDMFLUSH calls? (GBBS v2.14 & later only) (Y/N)'
NOTBUILDFLUSH       =      1-BUILDFLUSH
BUILDDEBUG          KBD    'Build with debugging display? (Y/N)'
NOTBUILDDEBUG       =      1-BUILDDEBUG
                    DO     BUILDDEBUG
BUILDPRINT          KBD    'Build debug dumped to printer? (Y/N)'
                    ELSE
BUILDPRINT          =      0
                    FIN
NOTBUILDPRINT       =      1-BUILDPRINT

                    PUT    EQUATES
                    PUT    ZEQUATES
                    LST    RTN

*-------------------------------------------------
* RZ -- receive via ZMODEM
*
*       syntax is: call ed+3,lg$,f$
*       where f$ is 15 spaces and return the filename
*       and lg$ is the pathname to put it on
*
* second entry point syntax is: call ed+6,lg$,f$,0
*
* the second entry point passes a variable where
*
* 0 = overwrite the file unconditionally
* 1 = append to the existing file
* 2 = rename the incoming file
* 3 = skip this file
* 4 = abort the xfer

                    ORG    $9E00

*-------------------------------------------------
* receive via ZMODEM

                    JMP    FIRST
                    JMP    RZ                                                             ;+3
                    JMP    RZCONTINUE                                                     ;+6

INFOPARMS
                    DB     10                                                             ;+9
                    DA     PREFIX
                    DB     0                                                              ;access
                    DB     0                                                              ;filetype
                    DW     0                                                              ;total_blocks
                    DB     0                                                              ;storage_type
                    DW     0                                                              ;blocks_used
                    DW     0                                                              ;mod_date
                    DW     0                                                              ;mod_time
                    DW     0                                                              ;create_date
                    DW     0                                                              ;create_time

EOFPARMS            DB     2                                                              ;+27
                    DB     0

BYTECOUNT           DS     3
XBLOCKS             DS     3
PBLOCKS             DS     3

*-------------------------------------------------
* LOGVOLUME -- gobble the comma and log LG$

LOGVOLUME
                    JSR    GOBCOM                                                         ;gobble the comma
                    JSR    INPSTR                                                         ;get the first string
                    CPY    #5                                                             ;how many characters?
                    BCC    OVER                                                           ;less than 5! continue

DIE                 SEC
                    RTS

*-------------------------------------------------

STRIPHI             INY
                    LDA    ($D),Y
                    AND    #$7F
                    STA    DRIVESPEC,Y
                    RTS

DRIVESPEC           DB     0
LOG_LO              DB     0
LOG_HI              DB     0
ADDNUM              DB     0

*-------------------------------------------------
* After INPSTR call, $D points to the string that was just read..

OVER                DEY
                    LDA    ($D),Y
                    CMP    #':'                                                           ;is the last character ':'?
                    BNE    DIE                                                            ;nope trash it

                    TYA
                    TAX                                                                   ;save y in x
                    LDY    #0
                    STY    LOG_LO                                                         ;init DRIVESPEC's to 0
                    STY    LOG_HI                                                         ;and 0

                    LDA    ($D),Y                                                         ;get the first character
                    AND    #$7F                                                           ;strip high bit

                    CMP    #'a'                                                           ;is it 'a'?
                    BCC    UPPER                                                          ;nope, try others..
                    CMP    #'m'                                                           ;is it 'm'?
                    BCS    UPPER                                                          ;yes, trash it
                    SBC    #$1F                                                           ;nope, make it uppercase

UPPER               CMP    #'A'                                                           ;is it less than 'a'?
                    BCC    DIE                                                            ;yeah, trash it
                    CMP    #'M'                                                           ;is it greater than 'l'
                    BCS    DIE                                                            ;yeah, trash it

                    STA    DRIVESPEC                                                      ;actual letter specifier
                    DEX                                                                   ;get last character's position
                    BEQ    NOT3                                                           ;is it the last one already? yep

                    JSR    STRIPHI                                                        ;not last,strip high from letter
                    DEX                                                                   ;is it the last one now?
                    BEQ    NOT3                                                           ;yep, just continue
                    JSR    STRIPHI                                                        ;otherwise, strip bit again

NOT3                LDX    LOG_HI                                                         ;get high part of log #
                    LDA    LOG_LO                                                         ;get low part of log #
                    BNE    NOT0                                                           ;low part is not 0, try others
                    CMP    LOG_HI                                                         ;is the high part also 0?
                    BEQ    BOTH0                                                          ;yes, go do normal log

NOT0                CPX    #0                                                             ;is the high part a 0?
                    BNE    :NOT0
                    TAX

                    LDA    #0
:NOT0               AND    #$F
                    STA    ADDNUM

                    TXA
                    AND    #$F
                    LDY    #10
:LOOP               CLC
                    ADC    ADDNUM
                    DEY
                    BNE    :LOOP

                    TAX                                                                   ;x=number to log
BOTH0               LDA    DRIVESPEC                                                      ;a=letter to log
                    JSR    LOG                                                            ;set prefix for that pathname
                    CLC
                    RTS

*-------------------------------------------------
* RZ -- receive a file with zmodem

RZ                  STZ    SYNTAX
                    STZ    FAILFLAG

                    JSR    LOGVOLUME
                    BCC    :LOGOK
                    INC    SYNTAX

:LOGOK              JSR    GOBCOM                                                         ;grab the comma
                    JSR    INPSTR                                                         ;get filename area

                    LDA    SYNTAX
                    BNE    :DIE
                    CPY    #15                                                            ;is it >= than 15?
                    BEQ    REALLYRZ                                                       ;yes, go there

:DIE                LDA    #ERROR
                    STA    FAILFLAG
                    RTS

*-------------------------------------------------
* REALLYRZ -- really receive a file 'cause we're setup to do it right

REALLYRZ            JSR    CLEARFILENAME
                    JSR    CLEARTOSPACES
                    JSR    STARTUP

*
* we got the memory, make the crc lookup table and see if the other side wants
* to send us something with zmodem
*
                    JSR    TRYZ                                                           ;get something?

                    CMP    #ERROR
                    BEQ    :DONE                                                          ;nope, skip over the receive part
                    CMP    #ABORT
                    BEQ    :DONE
                    CMP    #TIMEOUT
                    BEQ    :DONE
                    CMP    #ZCOMPL
                    BEQ    :COMPLETE
                    CMP    #ZFILE
                    BNE    :DONE

                    JSR    RZFILES

                    CMP    #ZEOF
                    BEQ    :COMPLETE
                    CMP    #ZCOMPL
                    BNE    :DONE
:COMPLETE           LDA    #NO_ERROR
:DONE               STA    FAILFLAG

                    CMP    #ABORT
                    BNE    :NOABORT

                    JSR    CANCEL
:NOABORT

*-------------------------------------------------
* COMMONSHUTDOWN -- both RZ and RZCONTINUE arrive here

COMMONSHUTDOWN
                    DO     NOTBUILDDEBUG
                    JSR    CLEARLASTLINE
                    FIN

                    JSR    MLI                                                            ;how much did we receive, and what?
                    DB     $D1
                    DA     EOFPARMS
                    JSR    MLI
                    DB     $CC
                    DA     CLOSEPARMS

                    LDA    BYTECOUNT
                    STA    XBLOCKS
                    STA    PBLOCKS
                    LDA    BYTECOUNT+1
                    STA    XBLOCKS+1
                    STA    PBLOCKS+1
                    LDA    BYTECOUNT+2
                    STA    XBLOCKS+2
                    STA    PBLOCKS+2

                    LDX    #6                                                             ;divide bytes sent by 128 to find out
:XLOOP              LSR    XBLOCKS+2                                                      ;how many blocks were sent
                    ROR    XBLOCKS+1
                    ROR    XBLOCKS
                    DEX
                    BPL    :XLOOP

                    LDX    #8                                                             ;divide bytes sent by 512 to find out
:PLOOP              LSR    PBLOCKS+2                                                      ;how many blocks were sent
                    ROR    PBLOCKS+1
                    ROR    PBLOCKS
                    DEX
                    BPL    :PLOOP

                    LDA    #<PATHNAME
                    STA    INFOPARMS+1
                    LDA    #>PATHNAME
                    STA    INFOPARMS+2

                    JSR    MLI                                                            ;return the file's info
                    DB     $C4
                    DA     INFOPARMS
                    JSR    SHUTDOWN
                    JMP    MOVEFILENAME

*-------------------------------------------------
* RZCONTINUE -- figure out to do with the filename

RZCONTINUE
                    STZ    SYNTAX
                    STZ    FAILFLAG

                    JSR    LOGVOLUME
                    BCC    :LOGOK
                    INC    SYNTAX
:LOGOK

                    JSR    GOBCOM                                                         ;grab the comma
                    JSR    INPSTR                                                         ;get filename area
                    CPY    #15                                                            ;is it >= than 15?
                    BEQ    :FILENAMEOK                                                    ;yes, go there
                    INC    SYNTAX
:FILENAMEOK

                    JSR    GOBCOM
                    JSR    INPNUM                                                         ;get 0,1,2,3,4

                    LDA    SYNTAX
                    BNE    :DIE
                    CPX    #5
                    BLT    :ACTIONOK

:DIE                LDA    #ERROR
                    STA    FAILFLAG
                    RTS
:ACTIONOK

                    STX    NAMEHOW
                    STZ    RENAMETRIES

                    JSR    CLEARFILENAME
                    JSR    STARTUP

                    LDA    NAMEHOW
                    ASL    A
                    TAX
                    JMP    (:ADDR,X)

:ADDR               DA     :OVERWRITE
                    DA     :APPEND
                    DA     :RENAME
                    DA     :SKIP
                    DA     :ABORT

*
* trash the existing file and then create the file again
*
:OVERWRITE
                    LDA    #<PATHNAME
                    STA    INFOPARMS+1
                    LDA    #>PATHNAME
                    STA    INFOPARMS+2

                    JSR    MLI                                                            ;unlock it
                    DB     $C4
                    DA     INFOPARMS
                    BCS    :GORZDONE

                    LDA    #$C3
                    STA    INFOPARMS+3

                    JSR    MLI
                    DB     $C3
                    DA     INFOPARMS
                    BCS    :GORZDONE

                    JSR    MLI
                    DB     $C1
                    DA     DESTROYPARMS
                    BCS    :GORZDONE                                                      ;something screwed up again

                    JSR    CREATEFILE
                    CMP    #NO_ERROR
                    BEQ    :GORZFILEAT0
:GORZDONE           JMP    :RZDONE
:GORZFILEAT0        JMP    :RZFILEAT0

*
* append to the end of the existing file by finding its EOF and sending the
* ZRPOS packet from there
*
:APPEND
                    JSR    MLI
                    DB     $C8
                    DA     OPENPARMS
                    BCS    :GORZDONE

                    LDA    OPENPARMS+5
                    STA    WRITEPARMS+1
                    STA    CLOSEPARMS+1
                    STA    EOFPARMS+1
                    STA    MARKPARMS+1

                    JSR    MLI
                    DB     $D1
                    DA     EOFPARMS
                    BCS    :GORZDONE

                    LDA    EOFPARMS+2
                    STA    MARKPARMS+2
                    STA    RXCOUNT
                    LDA    EOFPARMS+3
                    STA    MARKPARMS+3
                    STA    RXCOUNT+1
                    LDA    EOFPARMS+4
                    STA    MARKPARMS+4
                    STA    RXCOUNT+2
                    STZ    RXCOUNT+3

                    JSR    MLI
                    DB     $CE
                    DA     MARKPARMS
                    BCS    :GORZDONE
                    JMP    :RZFILEATEOF

*
* rename the incoming file so that we can create it without incident
*
:RENAME             INC    RENAMETRIES
                    LDA    RENAMETRIES
                    CMP    #26
                    BNE    :RENAMEOK
                    LDA    #$47
                    BRA    :RZDONE

:RENAMEOK           LDY    PATHNAME
                    CPY    #15
                    BEQ    :GOT15

                    INY
                    LDA    #'.'
                    STA    PATHNAME,Y
                    STY    PATHNAME

                    JSR    CREATEFILE
                    CMP    #NO_ERROR
                    BEQ    :RZFILEAT0
                    CMP    #$47
                    BEQ    :RENAME
                    BRA    :RZDONE

:GOT15              LDA    PATHNAME+2
                    CMP    #'Z'
                    BEQ    :MAKEA
                    INC    PATHNAME+2

                    JSR    CREATEFILE
                    CMP    #NO_ERROR
                    BEQ    :RZFILEAT0
                    CMP    #$47                                                           ;if it's duplicate file, try again
                    BEQ    :RENAME
                    BRA    :RZDONE

:MAKEA              LDA    #'A'
                    STA    PATHNAME+2

                    JSR    CREATEFILE
                    CMP    #NO_ERROR
                    BEQ    :RZFILEAT0
                    CMP    #$47
                    BEQ    :RENAME
                    BRA    :RZDONE

*
* skip the file, someone doesn't want us to receive it
*
:SKIP               JSR    ZEROPOS
                    LDA    #ZSKIP
                    STA    FRAMETYPE

                    JSR    ZSENDHHEADER                                                   ;send the ZSKIP packet
                    LDA    #NO_ERROR                                                      ;tell it to more-or-less abort without an error
                    BRA    :RZDONE

*
* just abort the transfer, the user is all messed up
*
:ABORT              LDA    #ERROR
                    BRA    :RZDONE

*
* receive something after we've either created, renamed, or deleted the file
*
:RZFILEAT0
                    JSR    GOODFILE                                                       ;this entry point zeroes ZRPOS's position
                    BRA    :RZDONE

:RZFILEATEOF
                    JSR    GOODHEADER

:RZDONE             CMP    #ZEOF
                    BEQ    :COMPLETE
                    CMP    #ZCOMPL
                    BNE    :DONE
:COMPLETE           LDA    #NO_ERROR
:DONE               STA    FAILFLAG

                    CMP    #ABORT
                    BNE    :NOABORT

                    JSR    CANCEL
:NOABORT

                    JMP    COMMONSHUTDOWN

RENAMETRIES         DB     0

*-------------------------------------------------
* TRYZ -- try to receive via zmodem - handle ZSINIT header

TRYZ
                    STZ    ERRORS

:RETRYZ             LDA    #<MAXBUFFERSIZE
                    STA    ZP0                                                            ;we have a 16k buffer
                    LDA    #>MAXBUFFERSIZE
                    STA    ZP1

                    STZ    ZF1                                                            ;we can't do squat

                    DO     BUILDFLUSH
                    LDA    #CANFC32+CANFDX                                                ;we can do CRC32 and do full duplex
                    ELSE
                    LDA    #CANFC32                                                       ;otherwise, it's an older driver and we can only
                    FIN                                                                   ;do half duplex, sort of (simulated full duplex)
                    STA    ZF0                                                            ;ivan better not send ZCRCQ packets

                    LDA    #ZRINIT
                    STA    FRAMETYPE

                    JSR    ZSENDHHEADER                                                   ;send the ZRINIT frame to the other end

:SWITCH             STZ    ZPTR                                                           ;init where the filename gets sent
                    LDA    #>ZBUFFER
                    STA    ZPTR+1

                    JSR    ZGETHEADER                                                     ;grab the return header

                    CMP    #20
                    BLT    :HEADER

                    CMP    #ABORT
                    BEQ    :ABORT
                    CMP    #TIMEOUT
                    BNE    :ABORT

                    INC    ERRORS
                    LDA    ERRORS
                    CMP    #5
                    BLT    :RETRYZ

                    LDA    #TIMEOUT
                    RTS

:RETURN             LDA    #ERROR
:ABORT              RTS

:HEADER             ASL    A
                    TAX
                    JMP    (:ADDR,X)

:ADDR               DA     TRYZ                                                           ZRQINIT
                    DA     :RETRYZ                                                        ZRINIT
                    DA     :DOZSINIT                                                      2
                    DA     :RETURN                                                        ZACK
                    DA     :DOZFILE                                                       4
                    DA     :RETURN                                                        ZSKIP
                    DA     :SWITCH                                                        ZNAK
                    DA     :RETURN                                                        ZABORT
                    DA     :DOZFIN                                                        ZFIN
                    DA     :RETURN                                                        ZRPOS
                    DA     :RETURN                                                        ZDATA
                    DA     :RETURN                                                        ZEOF
                    DA     :RETURN                                                        ZFERR
                    DA     :RETURN                                                        ZCRC
                    DA     :RETURN                                                        ZCHALLENGE
                    DA     :SWITCH                                                        ZCOMPL
                    DA     :RETURN                                                        ZCAN
                    DA     :DOZFREECNT                                                    17
                    DA     :DOZCOMMAND                                                    18
                    DA     :RETURN                                                        ZSTDERR

*
* handle ZFILE
*
:DOZFILE            LDA    ZF0
                    STA    ZCONVERT
                    LDA    ZF1
                    STA    ZMANAGE
                    LDA    ZF2
                    STA    ZTRANSPORT

                    LDA    #<ZBUFFER
                    STA    ZPTR
                    LDA    #>ZBUFFER
                    STA    ZPTR+1

                    JSR    ZRDATA

                    CMP    #ZCRCW
                    BNE    :ERRORZFILE

                    LDA    #0                                                             ;store an extra zero at the end so programs like
                    STA    (ZPTR)                                                         ;proterm which don't have the double zero after the
                                                                                          ;filename and no length will still work

                    LDA    #ZFILE                                                         ;we got a ZFILE packet
                    RTS                                                                   ;it was good

:ERRORZFILE
                    LDA    #ZNAK
                    STA    FRAMETYPE
                    JSR    ZSENDHHEADER
                    JMP    :SWITCH

*
* ZSINIT -- got ZSINIT
*
:DOZSINIT
                    JSR    ZRDATA                                                         ;get the attention string

                    CMP    #ZCRCW
                    BNE    :ERRORZSINIT

                    LDA    RXBYTES
                    STA    ATTNLENGTH

                    LDY    #0                                                             ;move the attention string
:ZSLOOP             LDA    (ZPTR),Y
                    STA    ATTENTION,Y
                    INY
                    CPY    #32
                    BGE    :DONEATTN
                    CPY    ATTNLENGTH
                    BLT    :ZSLOOP
:DONEATTN

                    JSR    ZEROPOS
                    LDA    #1
                    STA    ZP0

                    LDA    #ZACK
                    STA    FRAMETYPE

                    JSR    ZSENDHHEADER
                    JMP    :SWITCH

:ERRORZSINIT
                    LDA    #ZNAK
                    STA    FRAMETYPE
                    JSR    ZSENDHHEADER
                    JMP    :SWITCH

*
* doZFREECNT -- got ZFREECNT
*
:DOZFREECNT
                    JSR    MLI
                    DB     $C7
                    DA     PREFIXPARMS

                    LDX    #2
:PLOOP              LDA    PREFIX,X
                    CMP    #'/'
                    BEQ    :GOTSLASH
                    INX
                    CPX    PREFIX
                    BLT    :PLOOP

:GOTSLASH
                    STX    PREFIX

                    LDA    #<PREFIX
                    STA    INFOPARMS+1
                    LDA    #>PREFIX
                    STA    INFOPARMS+2

                    JSR    MLI
                    DB     $C4
                    DA     INFOPARMS

                    LDA    INFOPARMS+5                                                    ;free blocks is (total_blocks-used_blocks)
                    SEC
                    SBC    INFOPARMS+8
                    STA    ZP0
                    LDA    INFOPARMS+6
                    SBC    INFOPARMS+9
                    STA    ZP1
                    STZ    ZP2
                    STZ    ZP3

                    LDX    #0                                                             ;show them how many bytes are free by multiplying
:ZLOOP              ASL    ZP0                                                            ;the number of free blocks by 512 bytes (per block)
                    ROL    ZP1
                    ROL    ZP2
                    ROL    ZP3
                    INX
                    CPX    #9
                    BLT    :ZLOOP

                    LDA    #ZACK
                    STA    FRAMETYPE

                    JSR    ZSENDHHEADER
                    JMP    :SWITCH

*
* doZCOMMAND -- go ZCOMMAND
*
:DOZCOMMAND
                    JSR    ZRDATA

                    CMP    #ZCRCW
                    BNE    :ERRORZCOMMAND

                    LDA    ZF0
                    AND    #ZCACK1

                    STZ    ERRORS

:ZCLOOP             JSR    ZEROPOS

                    LDA    #ZCOMPL
                    STA    FRAMETYPE
                    JSR    ZSENDHHEADER

                    INC    ERRORS
                    LDA    ERRORS
                    CMP    #20
                    BGE    :ZCERRS

                    JSR    ZGETHEADER

                    CMP    #20
                    BGE    :ZCERRS
                    CMP    #ZFIN
                    BNE    :ZCLOOP

                    JSR    ACKBIBI

:ZCERRS             LDA    #ZCOMPL
                    RTS

:ERRORZCOMMAND
                    LDA    #ZNAK
                    STA    FRAMETYPE
                    JSR    ZSENDHHEADER
                    JMP    :SWITCH

*
* doZFIN -- got ZFIN
*
:DOZFIN             JSR    ACKBIBI                                                        ;hey bud, we're done!

                    LDA    #ZCOMPL
                    RTS

*-------------------------------------------------
* PROCHEADER -- process the header we got
*               longest allowable filename is 15 chars.
*               we parse a valid prodos filename from the
*               name we are given, provided we are given a name

PROCHEADER
                    STZ    ZPTR
                    LDA    #>ZBUFFER
                    STA    ZPTR+1

                    LDA    (ZPTR)
                    BNE    :GOODNAME

                    LDA    #ERROR
                    SEC
                    RTS

*
* if we get this far, we have at least a single char filename, so it's ok and
* no one's been fooling with us.
*
:GOODNAME
                    LDY    #0
:FLOOP              LDA    (ZPTR),Y                                                       ;get the length of the filename
                    BEQ    :GOTEND
                    INY
                    CPY    #15
                    BLT    :FLOOP
                    LDY    #15

:GOTEND             TYA
                    STA    PATHNAME                                                       ;save the length byte

                    LDY    #0
:PLOOP              LDA    (ZPTR),Y

                    CMP    #$80
                    BGE    :REPLACE

                    CMP    #'{'
                    BGE    :REPLACE
                    CMP    #'a'
                    BGE    :UPPER                                                         ;change lowercase into uppercase
                    CMP    #'['
                    BGE    :REPLACE
                    CMP    #'A'
                    BGE    :VALID
                    CMP    #':'
                    BGE    :REPLACE
                    CMP    #'0'
                    BLT    :REPLACE
                    BRA    :VALID

:UPPER              SEC                                                                   ;take lowercase and make it uppercase
                    SBC    #$20
                    BRA    :VALID

:REPLACE            LDA    #'.'                                                           ;replace bad char with period
:VALID              STA    PATHNAME+1,Y

                    INY
                    CPY    PATHNAME
                    BLT    :PLOOP

                    LDA    PATHNAME+1
                    CMP    #'A'
                    BGE    :FIRSTNOTDOT
                    LDA    #'A'                                                           ;always change the first char to an alpha char
                    STA    PATHNAME+1

:FIRSTNOTDOT
*
* start setting up the statLine by putting spaces over top of the # of bytes
* being received (our moving counter), and then putting the length of the file
* over top of the 'xxxxx's
*

                    DO     NOTBUILDDEBUG
                    LDX    #0                                                             ;put spaces on top of the old byte counts
                    LDA    #' '
:RSLOOP             STA    RZSTATLINE+16,X
                    STA    RZSTATLINE+28,X
                    INX
                    CPX    #8
                    BLT    :RSLOOP

                    LDY    #0                                                             ;then find the end of the filename
:NEXTC              LDA    (ZPTR),Y
                    BEQ    :FOUNDFEND
                    INY
                    BNE    :NEXTC

:FOUNDFEND          LDX    #0
:LENLOOP            INY                                                                   ;next character after the filename should be
                    LDA    (ZPTR),Y                                                       ;the length of the file, unless someone just didn't
                    BEQ    :DONEWLENGTH                                                   ;include the filename, like greg in proterm
                    AND    #$7F
                    CMP    #' '
                    BEQ    :DONEWLENGTH
                    STA    RZSTATLINE+28,X
                    INX
                    BRA    :LENLOOP

:DONEWLENGTH
                    FIN

                    LDA    #<PATHNAME
                    STA    CREATEPARMS+1
                    STA    DESTROYPARMS+1
                    STA    OPENPARMS+1
                    LDA    #>PATHNAME
                    STA    CREATEPARMS+2
                    STA    DESTROYPARMS+2
                    STA    OPENPARMS+2

                    JSR    CREATEFILE
                    RTS

*-------------------------------------------------
* CREATEFILE -- create the file or return an error code in (A)

CREATEFILE
                    JSR    MLI                                                            ;create the file
                    DB     $C0
                    DA     CREATEPARMS
                    BCS    :BAD
                    JSR    MLI                                                            ;open it
                    DB     $C8
                    DA     OPENPARMS
                    BCS    :BAD

                    LDA    OPENPARMS+5
                    STA    WRITEPARMS+1
                    STA    CLOSEPARMS+1
                    STA    EOFPARMS+1
                    STA    MARKPARMS+1

                    LDA    #NO_ERROR
:BAD                RTS

*-------------------------------------------------
* RZFILES -- receive a bunch of files (wow, something high-level for a change)

RZFILES             JSR    RZFILE

                    CMP    #ERROR
                    BEQ    :DONE
                    CMP    #ABORT
                    BEQ    :DONE
                    CMP    #TIMEOUT
                    BEQ    :DONE

                    CMP    #ZSKIP
                    BEQ    RZFILES

                    CMP    #ZEOF
                    BEQ    :DONE

                    CMP    #ZFILE                                                         ;(we'd really be screwed.. hmmm...)
                    BEQ    :TRYAGAIN

                    CMP    #$47                                                           ;duplicate filename error
                    BEQ    :DONE

                    LDA    #NO_ERROR
:DONE               RTS

:TRYAGAIN           JSR    TRYZ                                                           ;try to get another filename or quit

                    CMP    #ERROR
                    BEQ    :DONE                                                          ;nope, skip over the receive part
                    CMP    #ABORT
                    BEQ    :DONE
                    CMP    #TIMEOUT
                    BEQ    :DONE
                    CMP    #ZCOMPL
                    BEQ    :DONE
                    CMP    #ZFILE
                    BEQ    RZFILES

                    LDA    #NO_ERROR
                    RTS

*-------------------------------------------------
* RZFILE -- try to receive a single file via zmodem.  this assumes we've
*           already got a filename and the ZSINIT and ZRINIT packets have
*           been exchanged.

RZFILE              JSR    PROCHEADER                                                     ;process what we got as the header
                    CMP    #NO_ERROR
                    BEQ    GOODFILE

                    RTS

GOODFILE            LDX    #3
:RXBYTES            STZ    RXBYTES,X                                                      ;we haven't received squat yet
                    DEX
                    BPL    :RXBYTES

                    LDX    #3
:RXCOUNT            STZ    RXCOUNT,X
                    DEX
                    BPL    :RXCOUNT

                    LDX    #2
:BYTECOUNT          STZ    BYTECOUNT,X
                    DEX
                    BPL    :BYTECOUNT

*
* this is the entry point for zContinue when it decides that it's going to
* append to the file
*
GOODHEADER
                    DO     NOTBUILDDEBUG
                    JSR    PRINTRZSTAT
                    FIN

                    STZ    ERRORS

                    STZ    ZPTR                                                           ;init where the data, etc, goes to
                    LDA    #>ZBUFFER
                    STA    ZPTR+1

:CONTINUE           LDA    RXCOUNT
                    STA    ZP0
                    STA    BYTES
                    LDA    RXCOUNT+1
                    STA    ZP1
                    STA    BYTES+1
                    LDA    RXCOUNT+2
                    STA    ZP2
                    STA    BYTES+2
                    LDA    RXCOUNT+3
                    STA    ZP3

                    JSR    PRINTBYTES

                    LDA    #ZRPOS
                    STA    FRAMETYPE

                    JSR    ZSENDHHEADER                                                   ;send our received position

*
* loop -- come back here every time we need to get a new zmodem packet header
*
:LOOP               JSR    ZGETHEADER

                    CMP    #20
                    BLT    :HEADER

                    CMP    #ABORT
                    BEQ    :GOTABORT
                    CMP    #TIMEOUT
                    BNE    :IGNORE                                                        ;if anything else happened, try real hard to get
                                                                                          ;back in sync with the other side

                    INC    ERRORS
                    LDA    ERRORS
                    CMP    #5
                    BLT    :IGNORE

:RETURN             JSR    WRITEZBUFFER
                    LDA    #ERROR
                    RTS

:HEADER             ASL    A
                    TAX
                    JMP    (:ADDR,X)

:ADDR               DA     :IGNORE                                                        ;ZRQINIT    -                       0
                    DA     :IGNORE                                                        ;ZRINIT     -                       1
                    DA     :IGNORE                                                        ;ZSINIT     -                       2
                    DA     :IGNORE                                                        ;ZACK       -                       3
                    DA     :GOTZFILE                                                      ;ZFILE      -                       4
                    DA     :GOTZSKIP                                                      ;ZSKIP      -                       5
                    DA     :IGNORE                                                        ;ZNAK       -                       6
                    DA     :GOTABORT                                                      ;ZABORT     -                       7
                    DA     :RETURN                                                        ;ZFIN       -                       8
                    DA     :IGNORE                                                        ;ZRPOS      -                       9
                    DA     :GOTZDATA                                                      ;ZDATA      -                       10
                    DA     :GOTZEOF                                                       ;ZEOF       -                       11
                    DA     :IGNORE                                                        ;ZFERR      -                       12
                    DA     :IGNORE                                                        ;ZCRC       -                       13
                    DA     :IGNORE                                                        ;ZCHALLENGE -                       14
                    DA     :IGNORE                                                        ;ZCOMPL     -                       15
                    DA     :GOTABORT                                                      ;ZCAN       -                       16
                    DA     :IGNORE                                                        ;ZFREECNT   -                       17
                    DA     :IGNORE                                                        ;ZCOMMAND   -                       18
                    DA     :IGNORE                                                        ;ZSTDERR    -                       19

*
* ignore -- the other side is doing some wacko stuff.. try to get in sync
*           again
*
:IGNORE             JSR    WRITEZBUFFER

                    JSR    SENDATTN
                    JMP    :CONTINUE

*
* gotABORT -- someone aborted us
*
:GOTABORT
                    JSR    WRITEZBUFFER

                    LDA    #ABORT
                    RTS

*
* ZSKIP -- close our file we were about to receive and return zskip
*
:GOTZSKIP
                    JSR    WRITEZBUFFER                                                   ;write out what we got so far

                    LDA    #ZSKIP
                    RTS

*
* ZEOF -- test for correct EOF, if not, force timeout -- if EOF, then just
*         return normally
*
:GOTZEOF            JSR    WRITEZBUFFER                                                   ;write (ZPTR-ZBUFFER) bytes

                    JSR    GETRXPOSITION                                                  ;munge a longword from the header

                    LDX    #3
:RCMPLOOP1          LDA    RXPOSITION,X
                    CMP    RXCOUNT,X
                    BNE    :GOLOOP
                    DEX
                    BPL    :RCMPLOOP1
                    JMP    :ZEOFCLOSE                                                     ;ignore eof if it's at the wrong place
:GOLOOP             JMP    :LOOP                                                          ;force a timeout because the eof might
;eof might have gone out before our ZRPOS
:ZEOFCLOSE
                    LDA    #ZEOF
                    RTS

*
* ZFILE -- receive a packet after the zfile header, then keep going
*          this naughty bit of code protects us against the foolishness
*          of people who sent multiple ZFILE packets before they start
*          sending the file data
*
:GOTZFILE
                    JSR    ZRDATA
                    JMP    GOODFILE

*
* ZDATA -- oh joy, get possibly streamed packets from the sender
*
:GOTZDATA
                    JSR    GETRXPOSITION                                                  ;munge a longword from the header

                    LDX    #3
:RCMPLOOP2          LDA    RXPOSITION,X
                    CMP    RXCOUNT,X
                    BNE    :SENDATTENTION
                    DEX
                    BPL    :RCMPLOOP2
                    JMP    :GETDATA

:SENDATTENTION
                    JSR    SENDATTN
                    JMP    :CONTINUE                                                      ;resend the ZRPOS

*
* GETDATA -- get data subpackets (ZCRCQ, ZCRCE, ZCRCW, and ZCRCG)
*
:GETDATA            JSR    ZRDATA

                    CMP    #ERROR
                    BNE    :DATANOTERROR

:ZDATAERROR
                    JSR    WRITEZBUFFER
                    JSR    SENDATTN
                    JMP    :CONTINUE                                                      ;resend the ZRPOS

:DATANOTERROR
                    CMP    #OVERFLOW                                                      ;if we overflowed, write what we HAD, then
                    BEQ    :ZDATAERROR                                                    ;reset the buffer and tell it how much
                                                                                          ;we have NOW

                    CMP    #TIMEOUT
                    BEQ    :ZDATAERROR

                    CMP    #ABORT
                    BNE    :DATANOTABORT

                    JSR    WRITEZBUFFER
                    LDA    #ABORT
                    RTS

:DATANOTABORT
                    CMP    #ZCRCW
                    BNE    :DATANOTZCRCW

*
* ZCRCW -- wait for a response from us.  The sender is waiting for us to
*          send a ZACK packet in response to their overture
*          so, while we sit there, we might as well write out our buffer
*
                    JSR    ADDRXBYTES2RXCOUNT
                    JSR    PRINTBYTES

                    JSR    WRITEZBUFFER                                                   ;this also resets ZPTR

                    LDX    #3
:RXLOOP1            LDA    RXCOUNT,X
                    STA    ZP0,X
                    DEX
                    BPL    :RXLOOP1

                    LDA    #ZACK
                    STA    FRAMETYPE

                    JSR    ZSENDHHEADER                                                   ;receiver always sends a HEX header
                    JMP    :LOOP                                                          ;next header

:DATANOTZCRCW
                    CMP    #ZCRCQ
                    BNE    :DATANOTZCRCQ

*
* ZCRCQ -- query exactly where we are in the file, send ZACK and keep
*          receiving cause we CANFDX, just not CANOVIO
*          if we are about to overflow our buffer, write the buffer out
*
                    JSR    ADDRXBYTES2RXCOUNT
                    JSR    PRINTBYTES

                    LDA    ZPTR+1                                                         ;so, did they (almost) overflow our buffer?
                    CMP    #>ZBUFFER+MAXBUFFERSIZE
                    BLT    :ZCRCQNOWRITE                                                  ;not yet

                    JSR    WRITE2000                                                      ;fall through and send our ZACK frame

:ZCRCQNOWRITE
                    LDX    #3
:RXLOOP2            LDA    RXCOUNT,X
                    STA    ZP0,X
                    DEX
                    BPL    :RXLOOP2

                    LDA    #ZACK
                    STA    FRAMETYPE

                    JSR    ZSENDHHEADER                                                   ;receiver always sends a HEX header
                    JMP    :GETDATA                                                       ;get more data

:DATANOTZCRCQ
                    CMP    #ZCRCG
                    BNE    :DATANOTZCRCG

*
* ZCRCG -- go.  sender doesn't want a response unless something screwed up
*          the CRC for this packet, just keep receiving
*          if the buffer is about to overflow, write it out
*
                    JSR    ADDRXBYTES2RXCOUNT
                    JSR    PRINTBYTES

                    LDA    ZPTR+1                                                         ;so, did they overflow our buffer?
                    CMP    #>ZBUFFER+MAXBUFFERSIZE
                    BLT    :ZCRCGNOWRITE                                                  ;not yet

                    JSR    WRITE2000
:ZCRCGNOWRITE
                    JMP    :GETDATA

:DATANOTZCRCG
                    CMP    #ZCRCE
                    BEQ    :GOTZCRCE
                    JMP    :GETDATA                                                       ;get some more data no matter what

*
* ZCRCE -- they encountered EOF while sending the packet.  sender doesn't
*          want a response unless there's an error
*          is the buffer is full, write it out
*
:GOTZCRCE
                    JSR    ADDRXBYTES2RXCOUNT
                    JSR    PRINTBYTES

                    LDA    ZPTR+1                                                         ;so, did they overflow our buffer?
                    CMP    #>ZBUFFER+MAXBUFFERSIZE
                    BLT    :ZCRCENOWRITE                                                  ;not yet

                    JSR    WRITE2000
:ZCRCENOWRITE
                    JMP    :LOOP                                                          ;better get ZEOF next time!

*-------------------------------------------------
* ADDRXBYTES2RXCOUNT

ADDRXBYTES2RXCOUNT
                    LDA    RXBYTES
                    CLC
                    ADC    RXCOUNT
                    STA    RXCOUNT
                    LDA    RXBYTES+1
                    ADC    RXCOUNT+1
                    STA    RXCOUNT+1
                    LDA    RXBYTES+2
                    ADC    RXCOUNT+2
                    STA    RXCOUNT+2

                    LDA    RXBYTES
                    CLC
                    ADC    BYTES
                    STA    BYTES
                    LDA    RXBYTES+1
                    ADC    BYTES+1
                    STA    BYTES+1
                    LDA    RXBYTES+2
                    ADC    BYTES+2
                    STA    BYTES+2

                    LDA    RXBYTES
                    CLC
                    ADC    BYTECOUNT
                    STA    BYTECOUNT
                    LDA    RXBYTES+1
                    ADC    BYTECOUNT+1
                    STA    BYTECOUNT+1
                    LDA    RXBYTES+2
                    ADC    BYTECOUNT+2
                    STA    BYTECOUNT+2
                    RTS

*-------------------------------------------------
* WRITEZBUFFER -- write (ZPTR-ZBuffer) bytes

WRITEZBUFFER
                    LDA    ZPTR
                    BNE    :WRITE
                    LDA    ZPTR+1
                    CMP    #>ZBUFFER
                    BEQ    :NOWRITE

:WRITE              STZ    WRITEPARMS+2                                                   ;where
                    LDA    #>ZBUFFER
                    STA    WRITEPARMS+3

                    LDA    ZPTR                                                           ;how much
                    SEC
                    SBC    #<ZBUFFER
                    STA    WRITEPARMS+4
                    LDA    ZPTR+1
                    SBC    #>ZBUFFER
                    STA    WRITEPARMS+5

                    JSR    MLI
                    DB     $CB
                    DA     WRITEPARMS

                    STZ    ZPTR                                                           ;reset the buffer!!
                    LDA    #>ZBUFFER
                    STA    ZPTR+1
:NOWRITE            RTS

*-------------------------------------------------
* WRITE2000 -- write MAXBUFFERSIZE bytes to the file

WRITE2000
                    STZ    WRITEPARMS+2                                                   ;where
                    LDA    #>ZBUFFER
                    STA    WRITEPARMS+3

                    LDA    #<MAXBUFFERSIZE                                                ;how much
                    STA    WRITEPARMS+4
                    LDA    #>MAXBUFFERSIZE
                    STA    WRITEPARMS+5

                    JSR    MLI
                    DB     $CB
                    DA     WRITEPARMS

                    STZ    ZPTR                                                           ;reset the buffer!!
                    LDA    #>ZBUFFER
                    STA    ZPTR+1
                    RTS

*-------------------------------------------------
* SENDATTN -- send the attention string to the other end

SENDATTN            LDA    ATTNLENGTH                                                     ;if we don't have an attention string,
                    BEQ    :DONE                                                          ;we shouldn't send anything

                    LDY    #0
:LOOP               LDA    ATTENTION,Y
                    JSR    MDMOUT
                    INY
                    CPY    #32                                                            ;never send more than we got
                    BEQ    :DONE
                    CPY    ATTNLENGTH
                    BLT    :LOOP

:DONE
                    DO     BUILDFLUSH
                    JSR    MDMFLUSH
                    FIN

                    RTS

*-------------------------------------------------
* ACKBIBI() -- send a ZFIN packet and say goodbye...

ACKBIBI             JSR    ZEROPOS

                    LDA    #ZFIN
                    STA    FRAMETYPE

                    JSR    ZSENDHHEADER

                    DO     BUILDFLUSH
                    JSR    MDMFLUSH
                    FIN

:OLOOP              JSR    GETC                                                           ;get the OO or wait 10 seconds trying
                    BCC    :DONE
                    CMP    #'O'
                    BEQ    :NEXTO
                    CMP    #CAN                                                           ;also accept CAN characters
                    BEQ    :DONE
                    BRA    :OLOOP

:NEXTO              JSR    GETC
                    CMP    #'O'
                    BEQ    :DONE
                    CMP    #CAN
                    BNE    :NEXTO

:DONE               RTS

*-------------------------------------------------
* GETRXPOSITION -- munge a longword from ZP0..ZP3

GETRXPOSITION
                    LDA    ZP0
                    STA    RXPOSITION
                    LDA    ZP1
                    STA    RXPOSITION+1
                    LDA    ZP2
                    STA    RXPOSITION+2
                    LDA    ZP3
                    STA    RXPOSITION+3
                    RTS

*-------------------------------------------------
* ZRDATA -- get a data subpacket and return a result code
*
* outputs = (A) = result code

ZRDATA              LDA    FRAMEKIND
                    CMP    #ZBIN32
                    BNE    :NORMAL
                    JMP    ZRDATA32

:NORMAL             STZ    CRC
                    STZ    CRC+1

                    STZ    RXBYTES
                    STZ    RXBYTES+1

                    LDA    ZPTR
                    STA    ZSTART
                    CLC
                    ADC    #<1025
                    STA    ZEND
                    LDA    ZPTR+1
                    STA    ZSTART+1
                    ADC    #>1025
                    STA    ZEND+1

:LOOP               JSR    ZGETCHAR

                    LDX    ESCAPED
                    BEQ    :NOTESCAPED
                    CPX    #ABORT
                    BEQ    :BOGUS
                    CPX    #TIMEOUT
                    BNE    :NOTBOGUS
:BOGUS              TXA
                    JMP    :BAD

:NOTBOGUS           CMP    #ZCRCW
                    BEQ    :GOOUT                                                         ;damn 128 byte branches
                    CMP    #ZCRCQ
                    BEQ    :GOOUT                                                         ;**** 128 byte branches
                    CMP    #ZCRCG
                    BEQ    :GOOUT                                                         ;**** 128 byte branches
                    CMP    #ZCRCE
                    BNE    :NOTESCAPED
:GOOUT              JMP    :OUT

:NOTESCAPED         INC    RXBYTES
                    BNE    :NC
                    INC    RXBYTES+1
:NC                 JSR    CRCBYTE
                    STA    (ZPTR)

                    LDA    ZCONVERT
                    AND    #ZCBIN
                    BNE    :NOCONVERT

                    LDA    ZCONVERT
                    AND    #ZCNL
                    BEQ    :NOCONVERT

                    LDA    (ZPTR)
                    CMP    #cr
                    BNE    :NOTCR

                    LDA    #$FF
                    STA    GOTCR                                                          ;this falls through to go to NOCONVERT
                    INC    ZPTR
                    BNE    :AFTERMSDOS
                    INC    ZPTR+1
                    BRA    :AFTERMSDOS

:NOTCR              CMP    #lf
                    BNE    :NOCONVERT

                    LDA    GOTCR
                    BMI    :MSDOS

:UNIX               LDA    #cr
                    STA    (ZPTR)

:NOCONVERT          INC    ZPTR
                    BNE    :MSDOS
                    INC    ZPTR+1
:MSDOS              STZ    GOTCR                                                          ;always reset this so we don't have any stragling LFs

:AFTERMSDOS
                    LDA    ZPTR+1                                                         ;see if we have received a packet larger than
                    CMP    ZEND+1                                                         ;1k -- this is a good thing to do because Chuck
                    BLT    :NOTOVER1K                                                     ;Forsberg's routines also can't receive larger than
                    LDA    ZPTR                                                           ;1k packets, and we are protecting against lost
                    CMP    ZEND                                                           ;characters at 9600 baud concatenating 2 packets
                    BEQ    :OVER1K                                                        ;together

:NOTOVER1K
                    LDA    ZPTR+1
                    CMP    #>ZBUFFER+MAXBUFFERSIZE+1
                    BLT    :LOOP
                    LDA    ZPTR                                                           ;see if they went 1 byte over since we
                    CMP    #<ZBUFFER+MAXBUFFERSIZE+1                                      ;can match $4000 bytes exactly and not overflow
                    BEQ    :OVER1K
                    JMP    :LOOP                                                          ;but we need to check for overflow when we get back

:OVER1K
                    DO     BUILDDEBUG
                    LDA    ZPTR
                    SEC
                    SBC    ZSTART
                    TAY
                    LDA    ZPTR+1
                    SBC    ZSTART+1
                    TAX
                    LDA    #1                                                             ;zr
                    JSR    PRINTSUB                                                       ;print the subpacket
                    FIN

                    LDA    ZSTART+1                                                       ;we overflowed.  This is very bad.  restore ZPTR
                    STA    ZPTR+1                                                         ;to the last good spot (where we started this
                    LDA    ZSTART                                                         ;subpacket within the buffer)
                    STA    ZPTR

                    LDA    #OVERFLOW
                    RTS

:OUT                STA    FRAMEEND

                    JSR    CRCBYTE                                                        ;add the frameend into the CRC

                    JSR    ZGETCHAR
                    STA    FRAMECRC+1
                    JSR    ZGETCHAR
                    STA    FRAMECRC

                    CMP    CRC
                    BNE    :BADPACKET
                    LDA    FRAMECRC+1
                    CMP    CRC+1
                    BEQ    :GOODPACKET

:BADPACKET
                    DO     BUILDDEBUG
                    LDA    ZPTR
                    SEC
                    SBC    ZSTART
                    TAY
                    LDA    ZPTR+1
                    SBC    ZSTART+1
                    TAX
                    LDA    #1
                    JSR    PRINTSUB                                                       ;print the subpacket
                    FIN

                    LDA    #ERROR                                                         ;tell zfile to try again
:BAD                LDX    ZSTART+1
                    STX    ZPTR+1
                    LDX    ZSTART
                    STX    ZPTR
                    RTS

:GOODPACKET                                                                               ; hey! ;it's good!
                    DO     BUILDDEBUG
                    LDY    RXBYTES
                    LDX    RXBYTES+1
                    LDA    #1
                    JSR    PRINTSUB                                                       ;print the subpacket
                    FIN

                    LDA    FRAMEEND                                                       ;tell them the kind of frame we got
                    RTS

*-------------------------------------------------
* ZRDATA32 -- get a data subpacket and return a result code
*
* outputs = (A) = result code

ZRDATA32            LDA    #$FF                                                           ;init the CRC32
                    STA    CRC32
                    STA    CRC32+1
                    STA    CRC32+2
                    STA    CRC32+3

                    STZ    RXBYTES
                    STZ    RXBYTES+1

                    LDA    ZPTR
                    STA    ZSTART
                    CLC
                    ADC    #<1025
                    STA    ZEND
                    LDA    ZPTR+1
                    STA    ZSTART+1
                    ADC    #>1025
                    STA    ZEND+1

:LOOP               JSR    ZGETCHAR

                    LDX    ESCAPED
                    BEQ    :NOTESCAPED
                    CPX    #ABORT
                    BEQ    :BOGUS
                    CPX    #TIMEOUT
                    BNE    :NOTBOGUS
:BOGUS              TXA
                    JMP    :BAD

:NOTBOGUS           CMP    #ZCRCW
                    BEQ    :GOOUT
                    CMP    #ZCRCQ
                    BEQ    :GOOUT
                    CMP    #ZCRCG
                    BEQ    :GOOUT
                    CMP    #ZCRCE
                    BNE    :NOTESCAPED
:GOOUT              JMP    :OUT

:NOTESCAPED         INC    RXBYTES
                    BNE    :NC
                    INC    RXBYTES+1
:NC                 JSR    UPDATECRC32
                    STA    (ZPTR)

                    LDA    ZCONVERT
                    AND    #ZCBIN
                    BNE    :NOCONVERT

                    LDA    ZCONVERT
                    AND    #ZCNL
                    BEQ    :NOCONVERT

                    LDA    (ZPTR)
                    CMP    #cr
                    BNE    :NOTCR

                    LDA    #$FF
                    STA    GOTCR                                                          ;this falls through to go to NOCONVERT
                    INC    ZPTR
                    BNE    :AFTERMSDOS
                    INC    ZPTR+1
                    BRA    :AFTERMSDOS

:NOTCR              CMP    #lf
                    BNE    :NOCONVERT

                    LDA    GOTCR
                    BMI    :MSDOS

:UNIX               LDA    #cr
                    STA    (ZPTR)

:NOCONVERT          INC    ZPTR
                    BNE    :MSDOS
                    INC    ZPTR+1
:MSDOS              STZ    GOTCR                                                          ;always reset this so we don't have any stragling LFs

:AFTERMSDOS
                    LDA    ZPTR+1                                                         ;see if we have received a packet larger than
                    CMP    ZEND+1                                                         ;1k -- this is a good thing to do because Chuck
                    BLT    :NOTOVER1K                                                     ;Forsberg's routines also can't receive larger than
                    LDA    ZPTR                                                           ;1k packets, and we are protecting against lost
                    CMP    ZEND                                                           ;characters at 9600 baud concatenating 2 packets
                    BEQ    :OVER1K                                                        ;together

:NOTOVER1K
                    LDA    ZPTR+1
                    CMP    #>ZBUFFER+MAXBUFFERSIZE+1
                    BLT    :LOOP
                    LDA    ZPTR                                                           ;see if they went 1 byte over since we can
                    CMP    #<ZBUFFER+MAXBUFFERSIZE+1                                      ;can match $2000 bytes exactly and not overflow
                    BEQ    :OVER1K
                    JMP    :LOOP                                                          ;but we need to check for overflow when we get back

:OVER1K
                    DO     BUILDDEBUG
                    LDA    ZPTR
                    SEC
                    SBC    ZSTART
                    TAY
                    LDA    ZPTR+1
                    SBC    ZSTART+1
                    TAX
                    LDA    #3                                                             ;zr32
                    JSR    PRINTSUB                                                       ;print the subpacket
                    FIN

                    LDA    ZSTART+1                                                       ;we overflowed.  This is very bad.  restore ZPTR
                    STA    ZPTR+1                                                         ;to the last good spot (where we started this
                    LDA    ZSTART                                                         ;subpacket within the buffer)
                    STA    ZPTR

                    LDA    #OVERFLOW
                    RTS

:OUT                STA    FRAMEEND

                    JSR    UPDATECRC32                                                    ;add the frameend into the CRC

                    JSR    ZGETCHAR
                    STA    FRAMECRC32
                    JSR    ZGETCHAR
                    STA    FRAMECRC32+1
                    JSR    ZGETCHAR
                    STA    FRAMECRC32+2
                    JSR    ZGETCHAR
                    STA    FRAMECRC32+3

                    JSR    invertCRC32

                    LDX    #3
:CRC32LOOP          LDA    FRAMECRC32,X
                    CMP    CRC32,X
                    BNE    :BADPACKET
                    DEX
                    BPL    :CRC32LOOP
                    BRA    :GOODPACKET

:BADPACKET
                    DO     BUILDDEBUG
                    LDA    ZPTR
                    SEC
                    SBC    ZSTART
                    TAY
                    LDA    ZPTR+1
                    SBC    ZSTART+1
                    TAX
                    LDA    #3                                                             ;zr32
                    JSR    PRINTSUB                                                       ;print the subpacket
                    FIN

                    LDA    #ERROR                                                         ;tell zfile to try again
:BAD                LDX    ZSTART+1
                    STX    ZPTR+1
                    LDX    ZSTART
                    STX    ZPTR
                    RTS

:GOODPACKET                                                                               ; hey! ;it's good!
                    DO     BUILDDEBUG
                    LDY    RXBYTES
                    LDX    RXBYTES+1
                    LDA    #3                                                             ;zr32
                    JSR    PRINTSUB                                                       ;print the subpacket
                    FIN

                    LDA    FRAMEEND                                                       ;tell them the kind of frame we got
                    RTS

*-------------------------------------------------
* MOVEFILENAME

MOVEFILENAME
                    LDY    #0                                                             ;move the filename to a spot where it can be used
:NLOOP              LDA    PATHNAME+1,Y                                                   ;by acos
                    STA    ($D),Y
                    INY
                    CPY    PATHNAME
                    BLT    :NLOOP
                    RTS

*-------------------------------------------------
* CLEARFILENAME -- put spaces into acos's filename

CLEARFILENAME
                    LDY    #14                                                            ;clear out the last filename string
                    LDA    #' '
:CLOOP              STA    ($D),Y
                    DEY
                    BPL    :CLOOP
                    RTS

*-------------------------------------------------
* CLEARTOSPACES -- clear the filename to spaces

CLEARTOSPACES
                    LDX    #15                                                            ;and clear out the pathname since it's going
                    STX    PATHNAME                                                       ;to be copied back to acos's name
                    LDA    #' '
:PLOOP              STA    PATHNAME+1,X
                    DEX
                    BPL    :PLOOP
                    RTS

*-------------------------------------------------
* PRINTRZSTAT -- print the receiver's status line

                    DO     NOTBUILDDEBUG

PRINTRZSTAT
                    JSR    CLEARLASTLINE

                    LDX    #<RZSTATLINE
                    LDA    #>RZSTATLINE
                    JSR    PRINTCSTRING

                    LDX    #<PATHNAME
                    LDA    #>PATHNAME
                    JMP    PRINTPSTRING

*-------------------------------------------------
* CLEARLASTLINE -- get rid of anything on the last line

CLEARLASTLINE
                    LDY    #0
                    STY    HTAB
:LOOP               LDA    #" "
                    JSR    LOCPRINT
                    INY
                    CPY    #79
                    BLT    :LOOP
                    STZ    HTAB
                    RTS

RZSTATLINE          ASC    'Receiving byte #         of         file '00
                    FIN

*-------------------------------------------------
* put the common zmodem routines at the end of RZ

NAMEHOW             DB     0                                                              ;rename this thing how?
SYNTAX              DB     0                                                              ;Did something they didn't provide kill us?
WAITFOR             DW     120*9                                                          ;9 second timeout, don't wait long

CREATEPARMS
                    DB     7
                    DW     0                                                              ;pathname
                    DB     $C3
                    DB     4                                                              ;TXT
                    DW     0                                                              ;auxtype = 0
                    DB     1                                                              ;storage type
                    DW     0                                                              ;create date
                    DW     0                                                              ;create time

PREFIXPARMS
                    DB     1
                    DA     PREFIX

WRITEPARMS
                    DB     4
                    DB     0
                    DA     ZBUFFER
                    DW     $1000
                    DW     0

DESTROYPARMS
                    DB     1
                    DW     0

                    DO     BUILDDEBUG
                    PUT    NO.LONG2DEC
                    FIN

                    DO     NOTBUILDDEBUG
                    PUT    LONG2DEC
                    FIN

                    PUT    ZMODEM                                                         ;always
                    PUT    ZMODEM2                                                        ;always

                    SAV    RZ

