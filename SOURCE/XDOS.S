*-------------------------------
* ProDOS Command Interpreter for GBBS "Pro"
* Written originally by Greg Schaefer
* Modified extensively by Scott Galbraith
* Rewritten/Converted to Orca/M by Andy Nicholas
* Binary II file contents lister by Andy Nicholas
* January, 1988
*-------------------------------
              DATE
*-------------------------------

Id            =      4
Aux           =      1

              LST    OFF
              LSTDO  OFF
              TR
              TR     ADR
              EXP    ONLY
Y             =      1
y             =      1
N             =      0
n             =      0
NOLIST        =      Y
              DO     NOLIST
LISTOBJ       =      N
LISTSYM       =      N
              ELSE
LISTOBJ       KBD    'List This Source? (Y/N)'
LISTSYM       KBD    'List Symbol Table? (Y/N)'
              FIN
              DO     LISTOBJ
              LST
              FIN
              LST    OFF
              PUT    EQUATES/EQUATES
              PUT    EQUATES/OS.EQUATES
              PUT    EQUATES/ENTRY

]TYPE         =      ^overlays                        ; set file type
]AUX          =      overlays                         ; and aux type
              ORG    ]AUX                             ; must be this way
              TYP    ]TYPE

              DSK    /MAIN/LLUCE/SYSTEM/XDOS
              LST    RTN

              TTL    'LLUCE - External DOS commands'
              DO     LISTOBJ
              LST
              FIN

              DB     Id
              DA     Aux
              DB     Aux/256!Aux!Id!$A5

*-------------------------------
* Size Of Code To Check CRC
*-------------------------------

              DA     CODEEND-XDOS
              DA     0                                ; CRC Goes Here

FAILFLAG      =      PRN

              ORG    $D000

* Start of Xdos routines
*-------------------------------

XDOS          LDX    #CODEEND-PARMLSTS
MOVEPDOS      LDA    PARMLSTS,X                       ; Move Parameter Lists
              STA    GFI_P,X
              DEX
              BPL    MOVEPDOS

              STZ    FAILFLAG                         ;Innocent until proven guilty

              LDA    #0
              TAX
FILL          STZ    LNBUF,X                          ;zero string buffer
              DEX
              BNE    FILL

              JSR    GOBCOM                           ;gobble
              JSR    INPSTR                           ;get string (dont use memory)

              LDY    #-1
MOVE          INY
              CPY    STRLEN                           ;at end of line?
              BEQ    DISPAT                           ;yep

              LDA    (STRLOC),Y
              CMP    #' '
              BNE    MOVE

              LDX    #0
MOVE2         CPY    STRLEN                           ;at end of line?
              BEQ    DISPAT                           ;yep

              LDA    (STRLOC),Y
              STA    LNBUF,X                          ;copy rest of line
              INX
              INY
              BRA    MOVE2

DISPAT        LDY    #0
              LDA    (STRLOC),Y                       ;get command
              JSR    CONV
              CMP    #'C'
              BEQ    JMP1
              CMP    #'X'
              BEQ    JMP2
              CMP    #'T'
              BEQ    TYPE
              CMP    #'F'
              BEQ    JMP4
              CMP    #'G'
              BEQ    JMP5
              CMP    #'B'
              BEQ    JMP7
              CMP    #'V'
              BEQ    JMP8

JMP1          LDA    #0                               ;set up for 40 col catalog function
              HEX    2C
JMP2          LDA    #-1                              ;set up for 80 col catalog function
              JMP    CAT

JMP4          JMP    FREE
JMP5          JMP    GET_INFO
JMP7          JMP    BINARYII
JMP8          JMP    VOLINFO

* change the type of a file
*-------------------------------

TYPE          JSR    GFNAME                           ;get filename to retype
              JSR    GETINFO                          ;get current file info
              JSR    FINDATA                          ;SET POINTER TO FIND NEW FILE TYPE IN BUFFER
              LDA    LNBUF,X
              CMP    #','
              BNE    KEEPON
              INX
KEEPON        LDA    #<TYPETBL                        ;Point to file types
              STA    TEMP
              LDA    #>TYPETBL
              STA    TEMP+1
NEXTTYP       LDY    #1
              LDA    LNBUF,X
              JSR    CONV
              CMP    (TEMP),Y
              BNE    TRYNEXT
              INY
              LDA    LNBUF+1,X
              JSR    CONV
              CMP    (TEMP),Y
              BNE    TRYNEXT
              INY
              LDA    LNBUF+2,X
              JSR    CONV
              CMP    (TEMP),Y
              BNE    TRYNEXT
              LDA    (TEMP)
              STA    P_INFO+4                         ;store new file type in file info buffers
              LDA    #7                               ;setup 7 for set-info
              STA    P_INFO
              JSR    MLI
              DB     Setinfo
              DA     P_INFO

              STA    FAILFLAG
              RTS

TRYNEXT       CLC                                     ;Point to next type name
              LDA    TEMP
              ADC    #4
              STA    TEMP
              BNE    TYPEEND
              INC    TEMP+1
TYPEEND       LDA    (TEMP)                           ;Any more?
              BNE    NEXTTYP                          ;yes
              LDA    #-1
              STA    FAILFLAG
              RTS

* Free space
*-------------------------------

FREE          JSR    GFNAME
              LDA    FNAME1
              BNE    DOFREE                           ;they typed a pathname

              JSR    MLI
              DB     Getpfx                           ;get the current prefix
              DA     P_CPFX

DOFREE        LDA    DEVNUM                           ;get device # of most recent accessed device
              STA    P_ONLIN+1                        ;store it for 'Online' call

              JSR    MLI
              DB     Online
              DA     P_ONLIN

              LDA    FNAME1+1
              AND    #$F
              INC    A                                ;increase name character length by '1'
              STA    FNAME1                           ;store new name length
              LDA    #'/'                             ;load '/' character to make name a vol name
              STA    FNAME1+1                         ;insert character into name string

              JSR    GETINFO                          ;get info on volume

              LDA    #cr
              JSR    COUT
              JSR    XPR
              ASC    'Blocks Total: '00

              LDX    P_INFO+5                         ;get low byte of total blocks
              LDA    P_INFO+6                         ;get high byte of total blocks
              JSR    DECOUT0                          ;print total blocks on volume

              JSR    XPR
              ASC    '    Blocks Used: '00

              LDX    P_INFO+8                         ;get low byte of blocks used #
              LDA    P_INFO+9                         ;get high byte of blocks used #
              JSR    DECOUT0                          ;print total blocks used on volume

              JSR    XPR
              ASC    '    Blocks Free: '00

              LDA    P_INFO+5
              SEC
              SBC    P_INFO+8
              TAX

              LDA    P_INFO+6
              SBC    P_INFO+9
              JSR    DECOUT0

              LDA    #cr                              ;send cr/lf and exit back to program
              JMP    COUT

* get info on a particular file
*-------------------------------

GET_INFO      JSR    GFNAME
              LDA    FNAME1
              BNE    DO_GFI
              INC    FNAME1
              LDA    #'/'
              STA    FNAME1+1

DO_GFI        JSR    MLI
              DB     Getinfo
              DA     GFI_P

              JSR    MLI                              ;open the file
              DB     Open
              DA     P_COPEN

              LDA    P_COPEN+5                        ;get refnum
              STA    GET_REF
              STA    P_CLOSE+1

              JSR    MLI
              DB     Geteof
              DA     GETEOF_P

              LDA    GET_REF+1
              STA    GETEOF_P
              LDA    GET_REF+2
              STA    GET_REF
              LDA    GET_REF+3
              STA    RBYTE

              LDX    #7                               ;divide by 128
NLOOP         LSR    RBYTE
              ROR    GETEOF_P+1
              ROR    GETEOF_P
              DEX
              BNE    NLOOP

              LDA    GET_REF+1                        ;get low byte
              AND    #$7F                             ;is number divisable by 128?
              BEQ    DONE                             ;yes, even multiple, don't add 1
              INC    GETEOF_P                         ;no, add 1 for extra bytes
              BNE    DONE                             ;didn't roll over, go print it
              INC    GETEOF_P+1                       ;low byte rolled over, increment mid

DONE          LDA    GETEOF_P+1                       ;mask off high byte if set
              AND    #$7F
              STA    GETEOF_P+1

              JSR    MLI                              ;close file
              DB     Close
              DA     P_CLOSE

              RTS                                     ;done, so return

* get info on the current volume/file
* return K instead of 1/2k
*-------------------------------

VOLINFO       JSR    GFNAME
              LDA    FNAME1
              BNE    DO_VINF
              INC    FNAME1
              LDA    #'/'
              STA    FNAME1+1

DO_VINF       JSR    MLI
              DB     Getinfo
              DA     GFI_P

              STA    FAILFLAG

              LSR    IBLOCKS_USED+1
              ROR    IBLOCKS_USED
              LSR    IAUXTYPE+1
              ROR    IAUXTYPE
              RTS

* Error/Abort
*-------------------------------

FINBERR       STA    FAILFLAG
              LDA    #cr                              ;end line
              JSR    COUT

              BRA    CLOSE_BII

* Error/Abort
*-------------------------------

NOT_BII       LDA    #cr                              ;end line
              JSR    COUT
              LDA    #-2
              STA    FAILFLAG

CLOSE_BII     JSR    MLI                              ;close file
              DB     Close
              DA     P_CLOSE
              RTS

* Binary II file contents lister
*-------------------------------

BINARYII      JSR    GFNAME                           ;get pathname/drive specifier
              LDA    FNAME1
              BNE    BCAT2                            ;they typed a pathname

              JSR    MLI
              DB     Getpfx                           ;get the current prefix
              DA     P_CPFX

BCAT2         JSR    MLI                              ;open the current prefix
              DB     Open
              DA     P_COPEN
              BCS    FINBERR

              LDA    P_COPEN+5                        ;get refnum
              STA    BII_READ+1
              STA    BII_GMARK+1
              STA    BII_SMARK+1
              STA    P_CLOSE+1

              STZ    NUMFLS                           ;0 files processed
              STZ    NUMFLS+1

BRDLOOP       LDA    #<DIRBLOK                        ;point to buf
              STA    TEMP
              LDA    #>DIRBLOK
              STA    TEMP+1

              JSR    MLI
              DB     Read
              DA     BII_READ
              BCS    FINBERR

              LDA    DIRBLOK                          ;check ID bytes for Binary II
              CMP    #$A
              BNE    NOT_BII
              LDA    DIRBLOK+1
              CMP    #'G'                             ;check ID2
              BNE    NOT_BII
              LDA    DIRBLOK+2
              CMP    #'L'                             ;check ID3
              BNE    NOT_BII
              LDA    DIRBLOK+18
              CMP    #2                               ;check ID4
              BNE    NOT_BII

              LDX    #'*'                             ;default = locked
              LDA    DIRBLOK+3
              AND    #3
              CMP    #3
              BNE    BLOCKED
              LDX    #' '

BLOCKED       TXA
              JSR    COUT                             ;print lock/unlock status

              LDX    #0
LOOP          LDA    DIRBLOK+24,X                     ;default to printing name
              JSR    COUT
              INX
              CPX    #15
              BEQ    NOSUBDIR
              CPX    DIRBLOK+23
              BNE    LOOP

NOSUBDIR      LDA    #' '
LOOP2         JSR    COUT                             ;adjust
              INX
              CPX    #16
              BLT    LOOP2                            ;less than

              LDA    DIRBLOK+4
              STA    FILETYP
              JSR    PTYPE

              LDA    #' '
              JSR    COUT

              LDA    DIRBLOK+8
              STA    NUM
              LDA    DIRBLOK+9
              STA    NUM+1
              JSR    DECOUT1

              LDA    #' '
              JSR    COUT

              LDA    #10                              ;now setup to get creation date
              STA    POSITION
              JSR    CONVDAT                          ;get, convert and display creation date
              LDA    #12                              ;and creation time
              STA    POSITION
              JSR    CONVTIM

              LDA    #' '
              JSR    COUT
              LDA    #' '
              JSR    COUT

              LDA    #14                              ;setup to get mod-date
              STA    POSITION
              JSR    CONVDAT
              LDA    #16                              ;else continue with full catalog by setting
              STA    POSITION                         ;pointers to mod time data
              JSR    CONVTIM

              LDA    DIRBLOK+20
              STA    NUM
              LDA    DIRBLOK+21
              STA    NUM+1
              LDA    DIRBLOK+22
              STA    NUM+2
              JSR    DECOOT1

              LDA    #4                               ;now check for txt or bin files
              CMP    FILETYP
              BNE    BCHKBIN
              LDA    #'R'
              JSR    COUT
              BRA    BCONT

BCHKBIN       LDA    #6                               ;checking for bin file
              CMP    FILETYP
              BNE    BFINISHU
              LDA    #'A'
              JSR    COUT
BCONT         LDA    #'='
              JSR    COUT
              LDA    DIRBLOK+5
              STA    NUM
              LDA    DIRBLOK+6
              STA    NUM+1
              JSR    DECOUT1                          ;convert and display data
BFINISHU      LDA    #cr                              ;send cr/lf and exit back to cat routine
              JSR    COUT

              LDA    DIRBLOK+127
              BEQ    BFINISH                          ;we are done, no more files

              LDA    DIRBLOK+4
              CMP    #$F                              ;directory file
              BNE    NOTDIR
              JMP    BRDLOOP

NOTDIR        JSR    MLI
              DB     Getmark
              DA     BII_GMARK
              BCC    GETOK
              JMP    FINBERR

GETOK         LDA    BII_GMARK+2                      ;add low byte of current mark
              CLC                                     ;to site of next header
              ADC    DIRBLOK+20
              STA    BII_SMARK+2

              LDA    BII_GMARK+3                      ;add mid-byte to site of
              ADC    DIRBLOK+21                       ;next header
              STA    BII_SMARK+3

              LDA    BII_GMARK+4                      ;add high byte to site of
              ADC    DIRBLOK+22                       ;next header
              STA    BII_SMARK+4

              LDA    BII_SMARK+2                      ;get lo byte of next mark
              AND    #$7F                             ;chop off high bit
              BEQ    SETMARK                          ;already on a page, go set the mark
              EOR    #$7F                             ;get complement of number
              CLC
              ADC    BII_SMARK+2                      ;add it to number
              STA    BII_SMARK+2                      ;save corrected mark

              INC    BII_SMARK+2                      ;make it on an even boundary
              BNE    SETMARK                          ;$80, so go set mark
              INC    BII_SMARK+3
              BNE    SETMARK
              INC    BII_SMARK+4

SETMARK       JSR    MLI
              DB     Setmark
              DA     BII_SMARK
              BCC    DOLOOP
              JMP    FINBERR

DOLOOP        JMP    BRDLOOP                          ;do another block

BFINISH       JSR    MLI                              ;close file
              DB     Close
              DA     P_CLOSE
              RTS

* cat the currently logged path
*-------------------------------

CAT           STA    CATTYPE

              JSR    GFNAME                           ;get pathname/drive specifier
              LDA    FNAME1
              BNE    CAT2                             ;they typed a pathname

              JSR    MLI
              DB     Getpfx                           ;get the current prefix
              DA     P_CPFX                           ;into the filename buffer

CAT2          LDA    #cr                              ;add a linefeed
              JSR    COUT

              LDX    #0
CAT3          INX
              LDA    FNAME1,X                         ;print pathname
              JSR    COUT
              CPX    FNAME1
              BNE    CAT3

              LDA    #cr                              ;add 2 linefeeds
              JSR    COUT
              JSR    COUT

              JSR    MLI                              ;open the current prefix
              DB     Open
              DA     P_COPEN
              BCC    CAT4

              STA    FAILFLAG
              LDA    #cr                              ;end line
              JSR    COUT
              RTS

CAT4          LDA    P_COPEN+5                        ;get refnum
              STA    P_CPOS+1
              STA    P_CRINF+1
              STA    P_CRDIR+1
              STA    P_CLOSE+1

              JSR    MLI                              ;read dir info
              DB     Read
              DA     P_CRINF

              JSR    MLI                              ;set back to start
              DB     Setmark
              DA     P_CPOS

              STZ    NUMFLS                           ;0 files processed
              STZ    NUMFLS+1
              LDX    #-1
              STX    BLKCNT                           ;start at file 1 in block

CRDLOOP       LDA    #<DIRBLOK+4                      ;point to buf
              STA    TEMP
              LDA    #>DIRBLOK+4
              STA    TEMP+1

              JSR    MLI                              ;read block
              DB     Read
              DA     P_CRDIR

              LDA    BLKCNT                           ;first pass?
              BPL    CRDLOOP2                         ;nope

              STZ    BLKCNT                           ;set to 0
              BRA    CRDLOOP5                         ;go to next entry

CRDLOOP2      LDA    NUMFLS                           ;we done?
              CMP    DIRINFO+$25
              BNE    CRDLOOP3                         ;nope

              LDA    NUMFLS+1                         ;check high
              CMP    DIRINFO+$26
              BNE    CRDLOOP3                         ;were done

              JSR    DOFREE                           ;print freespace
              JSR    MLI                              ;close file
              DB     Close
              DA     P_CLOSE
              RTS

CRDLOOP3      LDY    #0
              LDA    (TEMP),Y                         ;get length and type
              AND    #$F
              STA    (TEMP),Y                         ;get rid of extra stuff
              STA    TEMP2
              BEQ    CRDLOOP5                         ;oops, deleted file

              INC    NUMFLS                           ;inc file count
              BNE    CRDLOOP4
              INC    NUMFLS+1

CRDLOOP4      JSR    PRENT                            ;print the entry

CRDLOOP5      CLC
              LDA    TEMP                             ;go to next entry
              ADC    DIRINFO+$23
              STA    TEMP
              LDA    TEMP+1
              ADC    #0
              STA    TEMP+1

              INC    BLKCNT                           ;inc place within block
              LDA    BLKCNT
              CMP    DIRINFO+$24
              BEQ    CRDLOOP6                         ;go to next block

              BRA    CRDLOOP2                         ;do next entry within this block

CRDLOOP6      STZ    BLKCNT                           ;reset count
              JMP    CRDLOOP                          ;do another block

* print the entry
*-------------------------------

PRENT         LDX    #'*'                             ;default = locked
              LDY    #$1E                             ;check access
              LDA    (TEMP),Y
              AND    #3
              CMP    #3
              BNE    LOCKED
              LDX    #' '
LOCKED        TXA
              JSR    COUT                             ;print lock/unlock status

              LDY    #$1C+1                           ; Valid filename case flags?
              LDA    (TEMP),Y
              STA    doCase                           ; set flag

              STA    TEMP3+1                          ; save flags for shift
              DEY
              LDA    (TEMP),Y
              STA    TEMP3

              LDY    #1
              ASL    TEMP3
              ROL    TEMP3+1

PRENT2        LDA    (TEMP),Y                         ;default to printing name
              CPY    TEMP2                            ;check against length
              BCC    PRENT2A                          ;opps, too long
              BEQ    PRENT2A
              LDA    #' '
PRENT2A       BIT    doCase
              BPL    uCase
              ASL    TEMP3                            ; is this lower case?
              ROL    TEMP3+1
              BCC    uCase                            ; nope
              CMP    #'A'                             ; is it alpha?
              BLT    uCase                            ; nope
              CMP    #'Z'+1
              BGE    uCase                            ; nope
              ADC    #$20                             ; make lower case
uCase         JSR    COUT                             ;print char
              INY
              CPY    #17                              ;print 18 chars
              BCC    PRENT2

              LDY    #$10                             ;get filetype
              LDA    (TEMP),Y
              STA    FILETYP                          ;store file type in data byte for later
              JSR    PTYPE

NONENT        LDA    #' '
              JSR    COUT

              LDY    #$13                             ;get blocks used
              LDA    (TEMP),Y
              STA    NUM                              ;save number
              INY
              LDA    (TEMP),Y
              STA    NUM+1
              JSR    DECOUT1

              LDA    #' '
              JSR    COUT

              LDA    #$18                             ;now setup to get creation date
              STA    POSITION
              JSR    CONVDAT                          ;get, convert and display creation date
              LDA    #0                               ;check to see if command was 'cat' or
              CMP    CATTYPE                          ;if it was 'x'(='catalog')
              BNE    CONCAT                           ;keep going if 'catalog' was wanted
              LDA    #cr                              ;else load end of line
              JMP    COUT                             ;send cr/lf and exit back to program

CONCAT        LDA    #$1A                             ;and creation time
              STA    POSITION
              JSR    CONVTIM

              LDA    #' '
              JSR    COUT
              LDA    #' '
              JSR    COUT
              LDA    #$21                             ;setup to get mod-date
              STA    POSITION
              JSR    CONVDAT
              LDA    #$23                             ;else continue with full catalog by setting
              STA    POSITION                         ;pointers to mod time data
              JSR    CONVTIM

              LDY    #$15                             ;now get file length (eof), convert and
              LDA    (TEMP),Y                         ;display it with max of 8 decimal digits
              STA    NUM
              INY
              LDA    (TEMP),Y                         ;get middle byte of 3 byte value
              STA    NUM+1
              INY
              LDA    (TEMP),Y                         ;get high byte of 3 byte value
              STA    NUM+2
              JSR    DECOOT1

              LDA    #4                               ;now check for txt or bin files
              CMP    FILETYP
              BNE    CHECKBIN
              LDA    #'R'
              JSR    COUT
              BRA    CONTINUE

CHECKBIN      LDA    #6                               ;checking for bin file
              CMP    FILETYP
              BNE    FINISHUP
              LDA    #'A'
              JSR    COUT
CONTINUE      LDA    #'='
              JSR    COUT
              LDY    #$1F                             ;get aux.type data  either bin load address
              LDA    (TEMP),Y                         ;or the txt file record length
              STA    NUM
              INY
              LDA    (TEMP),Y
              STA    NUM+1
              JSR    DECOUT1                          ;convert and display data
FINISHUP      LDA    #cr                              ;send cr/lf and exit back to cat routine
              JMP    COUT

*-------------------------------

DECOUT1       STZ    NUM+2                            ;reset total
              STZ    NUM+3
              STZ    NUM+4
              STZ    NUM+5
              STZ    NUM+6
              CLC

              SED
              LDY    #16                              ;use decimal mode
DECOUT2       ASL    NUM
              ROL    NUM+1
              LDA    NUM+2
              ADC    NUM+2                            ;do actual 'woz' conversion
              STA    NUM+2
              LDA    NUM+3
              ADC    NUM+3
              STA    NUM+3
              ROL    NUM+4
              DEY                                     ;loop down
              BNE    DECOUT2

              CLD                                     ;done with decimal
              LDY    #4                               ;print 5 digits

DECOUT3       LDA    NUM+4                            ;get digit
              AND    #$F
              BNE    DECOUT4                          ;is it zero?

              LDX    #' '
              BIT    NUM+5                            ;is this a leading zero?
              BPL    DECOUT8                          ;yep

DECOUT4       DEC    NUM+5
              CLC
              ADC    #'0'                             ;print digit
              TAX
              INC    NUM+6

DECOUT8       TXA
              JSR    COUT                             ;show digit or spacer

DECOUT5       LDX    #3                               ;move up next digit
DECOUT6       ASL    NUM+1
              ROL    NUM+2
              ROL    NUM+3
              ROL    NUM+4
              DEX
              BPL    DECOUT6

              DEY                                     ;count down digits
              BMI    DECOUT7
              BNE    DECOUT3

              STX    NUM+5                            ;print last zero for sure
              BPL    DECOUT3

DECOUT7       CLC
              RTS

*-------------------------------

DECOOT1       STZ    NUM+3                            ;reset total
              STZ    NUM+4                            ;convert and display an 8 digit number
              STZ    NUM+5
              STZ    NUM+6
              STZ    NUM+7
              STZ    NUM+8
              STZ    NUM+9
              CLC

              SED
              LDY    #24                              ;use decimal mode - shift out 24 bits
DECOOT2       ASL    NUM
              ROL    NUM+1
              ROL    NUM+2                            ;do actual 'woz' conversion
              LDA    NUM+3
              ADC    NUM+3
              STA    NUM+3
              LDA    NUM+4
              ADC    NUM+4
              STA    NUM+4
              LDA    NUM+5
              ADC    NUM+5
              STA    NUM+5
              LDA    NUM+6
              ADC    NUM+6
              STA    NUM+6
              ROL    NUM+7
              DEY                                     ;loop down
              BNE    DECOOT2

              CLD                                     ;done with decimal
              LDY    #8                               ;print 8 digits

DECOOT3       LDA    NUM+7                            ;get digit
              AND    #$F
              BNE    DECOOT4                          ;is it zero?

              LDX    #' '
              BIT    NUM+8                            ;is this a leading zero?
              BPL    DECOOT8                          ;yep

DECOOT4       DEC    NUM+8
              CLC
              ADC    #'0'                             ;print digit
              TAX
              INC    NUM+9

DECOOT8       TXA
              JSR    COUT                             ;show digit or spacer

DECOOT5       LDX    #3                               ;move up next digit
DECOOT6       ASL    NUM+1
              ROL    NUM+2
              ROL    NUM+3
              ROL    NUM+4
              ROL    NUM+5
              ROL    NUM+6
              ROL    NUM+7
              DEX
              BPL    DECOOT6

              DEY                                     ;count down digits
              BMI    DECOOT7
              BNE    DECOOT3

              STX    NUM+8                            ;print last zero for sure
              BPL    DECOOT3

DECOOT7       CLC
              LDA    #' '
              JMP    COUT

* subroutine to print "[No Date] "
*-------------------------------

NODATE        LDY    #10
              LDX    #0
NDLOOP        LDA    DEFDATE,X
              JSR    COUT
              INX
              DEY
              BNE    NDLOOP
              RTS

* subroutine to convert and print dates on the screen
*-------------------------------

CONVDAT       LDY    POSITION                         ;get day of mod-date
              LDA    (TEMP),Y
              BEQ    NODATE                           ;default display if no date on file
              PHA

              AND    #%00011111                       ;just get date
              JSR    BINDEC8
              JSR    COUT
              TXA                                     ;display date
              JSR    COUT
              LDA    #'-'                             ;put in seperator
              JSR    COUT

              LDY    POSITION                         ;get last bit of month
              INY
              LDA    (TEMP),Y
              LSR    A
              PLA
              ROR    A                                ;move in month bit
              LSR    A
              LSR    A
              AND    #%00111100                       ;just get month
              TAX                                     ;make into offset

              LDY    #4
PR_DATE       LDA    MONTH-4,X
              JSR    COUT                             ;show month
              INX
              DEY
              BNE    PR_DATE

              LDY    POSITION
              INY
              LDA    (TEMP),Y                         ;get year
              LSR    A
              JSR    BINDEC8                          ;translate
              JSR    COUT
              TXA
              JSR    COUT                             ;print year
              LDA    #' '
              JMP    COUT

* Convert and print time to screen
*-------------------------------

CONVTIM       LDY    POSITION                         ;get time data, convert to decimal and
              INY                                     ;get hours first
              LDA    (TEMP),Y                         ;then display it
              AND    #%00011111                       ;mask for needed digits
              JSR    BINDEC8                          ;convert binary to decimal and return
              JSR    COUT                             ;display tens digit
              TXA                                     ;shift in other digit
              JSR    COUT                             ;display ones digit
              LDA    #':'                             ;print separator
              JSR    COUT
              LDY    POSITION                         ;get minutes now
              LDA    (TEMP),Y
              AND    #%00111111                       ;mask for needed bits
              JSR    BINDEC8                          ;convert to decimal
              JSR    COUT                             ;display tens digit
              TXA
              JMP    COUT                             ;display ones digit and return

* convert lower to upper and clear high bit
*-------------------------------

CONV          AND    #$7F                             ;strip high bit
              CMP    #'a'
              BCC    CONV2
              CMP    #'z'+1
              BCS    CONV2

              SBC    #$1F                             ;since carry is clear, -$20
CONV2         RTS

* get filename and place into buffer
*-------------------------------

GFNAME        STZ    FNAME1                           ;zero buffer

              JSR    FINDATA                          ;locate data within buffer
              BCS    CONV2                            ;error, no more data

              LDA    LNBUF,X                          ;get first byte
              JSR    CONV

              JSR    FINDATA                          ;find the name itself
              BCS    GFNAME7

              LDY    #0
GFNAME5       LDA    LNBUF,X                          ;get data
              BEQ    GFNAME6
              CMP    #' '
              BEQ    GFNAME6                          ;at end of line
              CMP    #','
              BEQ    GFNAME6

              STA    FNAME1+1,Y                       ;save data
              LDA    #' '
              STA    LNBUF,X                          ;kill name
              INX
              INY
              BNE    GFNAME5

GFNAME6       STY    FNAME1                           ;save length of name
GFNAME7       CLC
              RTS

* find data within lnbuf
*-------------------------------

FINDATA       LDX    #-1
FIND2         INX
              LDA    LNBUF,X                          ;end of line?
              SEC
              BEQ    FIND3                            ;yep

              CMP    #' '
              BEQ    FIND2

              CLC
FIND3         RTS

* jsr xpr ; data ; 0 -- quick print routine
*-------------------------------

XPR           PLA                                     ;save calling address
              STA    PRN
              PLA
              STA    PRN+1

XPR2          INC    PRN                              ;get next byte
              BNE    XPR3
              INC    PRN+1

XPR3          LDY    #0
              LDA    (PRN),Y                          ;get byte
              BEQ    XPR4                             ;were done

              JSR    COUT
              BRA    XPR2

XPR4          INC    PRN                              ;inc for return
              BNE    XPR5
              INC    PRN+1
XPR5          JMP    (PRN)

* translate a binary to text [0-99]
*-------------------------------

BINDEC8       LDY    #0                               ;start 10's counter
BIN8          CMP    #10
              BCC    BIN8A                            ;less than 10, were done

              SBC    #10                              ;minus 10
              INY                                     ;add 1 to the 10's counter
              BNE    BIN8                             ;loop

BIN8A         ADC    #'0'                             ;make 1's into text
              TAX                                     ;save
              TYA
              ADC    #'0'                             ;make 10's into text
              RTS                                     ;were done

* get info on a file
*-------------------------------

GETINFO       LDA    #10                              ;setup 10 for get-info
              STA    P_INFO
              JSR    MLI
              DB     Getinfo
              DA     P_INFO
              RTS

* Print file type
*-------------------------------

PTYPE         LDX    #<TYPETBL                        ; Point To File Types
              STX    TEMP3
              LDX    #>TYPETBL
              STX    TEMP3+1
              LDY    #0                               ; Index Is Zero
              PHA                                     ; Save Type
TLOOP         PLA                                     ; Restore Type
              CMP    (TEMP3),Y                        ; Same Type?
              BEQ    SHOWTYP                          ; Yes, Show It
              PHA                                     ; Save Type
              CLC                                     ; Add 4 To Skip Last Type
              LDA    #4
              ADC    TEMP3
              STA    TEMP3
              BCC    TLOOP
              INC    TEMP3+1
              BRA    TLOOP

SHOWTYP       INY                                     ; Print First Character
              LDA    (TEMP3),Y
              JSR    COUT
              INY                                     ; Print Second Character
              LDA    (TEMP3),Y
              JSR    COUT
              INY                                     ; Print Last Character
              LDA    (TEMP3),Y
              JMP    COUT

* print hex subroutine for catalog
*-------------------------------

PRHEX         STA    FILETYP

              PHA
              LDA    #'$'
              JSR    COUT

              PLA
              PHA
              LSR    A
              LSR    A
              LSR    A
              LSR    A
              JSR    PRINTDIG
              PLA
PRINTDIG      AND    #%00001111
              ORA    #'0'
              CMP    #'9'+1
              BCC    DOCOUT
              ADC    #6
DOCOUT        JMP    COUT

* variables and stuff
*-------------------------------

COPYRIGHT     ASC    'Copyright (c), 1987-1993 - L & L Productions'

MONTH         ASC    'Jan-'
              ASC    'Feb-'
              ASC    'Mar-'
              ASC    'Apr-'
              ASC    'May-'
              ASC    'Jun-'
              ASC    'Jul-'
              ASC    'Aug-'
              ASC    'Sep-'
              ASC    'Oct-'
              ASC    'Nov-'
              ASC    'Dec-'

DEFDATE       ASC    '[No Date] '

*-------------------------------

PARMLSTS      =      *

              ORG    FREESPACE

GFI_P         DB     10                               ;number of parms
              DA     FNAME1                           ;address of filename/path
              DB     00                               ;access bits
              DB     00                               ;filetype

IAUXTYPE      DA     0                                ;aux filetype
              DB     0                                ;storage type

IBLOCKS_USED  DA     0                                ;prodos blocks
              DA     0                                ;date of last modification
              DA     0                                ;time of last mod
              DA     0                                ;date of creation
              DA     0                                ;time of creation

* get end of file params..
*-------------------------------

GETEOF_P      DB     2

GET_REF       DB     0
              DS     3

P_ONLIN       DB     2
              DB     0
              DA     FNAME1+1

P_CPFX        DB     1
              DA     FNAME1

P_COPEN       DB     3
              DA     FNAME1
              DA     FBUF1
              DB     0

P_CPOS        DB     2
              DB     0
              DS     3

P_CRINF       DB     4
              DB     0
              DA     DIRINFO
              DA     64
              DA     0

P_CRDIR       DB     4
              DB     0
              DA     DIRBLOK
              DA     512
              DA     0

P_CLOSE       DB     1
              DB     0

P_INFO        DB     10
              DA     FNAME1
              DB     0
              DB     0
              DA     0
              DB     0
              DA     0
              DA     0
              DA     0
              DA     0

BII_READ      DB     4
              DB     0
              DA     DIRBLOK
              DA     128
              DA     0

BII_GMARK     DB     2
              DB     0
              DS     3

BII_SMARK     DB     2
              DB     0
              DS     3

              ORG

CODEEND       =      *

TYPETBL       DB     $00
              ASC    'UNK'
              DB     $01
              ASC    'BAD'
              DB     $02
              ASC    'PCD'
              DB     $03
              ASC    'PTX'
              DB     $04
              ASC    'TXT'
              DB     $05
              ASC    'PDA'
              DB     $06
              ASC    'BIN'
              DB     $07
              ASC    'FNT'
              DB     $08
              ASC    'FOT'
              DB     $09
              ASC    'BA3'
              DB     $0A
              ASC    'DA3'
              DB     $0B
              ASC    'WPF'
              DB     $0C
              ASC    'SOS'
              DB     $0D
              ASC    '$0D'
              DB     $0E
              ASC    '$0E'
              DB     $0F
              ASC    'DIR'
              DB     $10
              ASC    'RPD'
              DB     $11
              ASC    'RPI'
              DB     $12
              ASC    'AFD'
              DB     $13
              ASC    'AFM'
              DB     $14
              ASC    'AFR'
              DB     $15
              ASC    'SCL'
              DB     $16
              ASC    'PFS'
              DB     $17
              ASC    '$17'
              DB     $18
              ASC    '$18'
              DB     $19
              ASC    'ADB'
              DB     $1A
              ASC    'AWP'
              DB     $1B
              ASC    'ASP'
              DB     $1C
              ASC    '$1C'
              DB     $1D
              ASC    '$1D'
              DB     $1E
              ASC    '$1E'
              DB     $1F
              ASC    '$1F'
              DB     $20
              ASC    'TDM'
              DB     $21
              ASC    '$21'
              DB     $22
              ASC    '$22'
              DB     $23
              ASC    '$23'
              DB     $24
              ASC    '$24'
              DB     $25
              ASC    '$25'
              DB     $26
              ASC    '$26'
              DB     $27
              ASC    '$27'
              DB     $28
              ASC    '$28'
              DB     $29
              ASC    '$29'
              DB     $2A
              ASC    '8SC'
              DB     $2B
              ASC    '8OB'
              DB     $2C
              ASC    '8IC'
              DB     $2D
              ASC    '8LD'
              DB     $2E
              ASC    '8PC'
              DB     $2F
              ASC    '$2F'
              DB     $30
              ASC    '$30'
              DB     $31
              ASC    '$31'
              DB     $32
              ASC    '$32'
              DB     $33
              ASC    '$33'
              DB     $34
              ASC    '$34'
              DB     $35
              ASC    '$35'
              DB     $36
              ASC    '$36'
              DB     $37
              ASC    '$37'
              DB     $38
              ASC    '$38'
              DB     $39
              ASC    '$39'
              DB     $3A
              ASC    '$3A'
              DB     $3B
              ASC    '$3B'
              DB     $3C
              ASC    '$3C'
              DB     $3D
              ASC    '$3D'
              DB     $3E
              ASC    '$3E'
              DB     $3F
              ASC    '$3F'
              DB     $40
              ASC    '$40'
              DB     $41
              ASC    '$41'
              DB     $42
              ASC    'FTD'
              DB     $43
              ASC    '$43'
              DB     $44
              ASC    '$44'
              DB     $45
              ASC    '$45'
              DB     $46
              ASC    '$46'
              DB     $47
              ASC    '$47'
              DB     $48
              ASC    '$48'
              DB     $49
              ASC    '$49'
              DB     $4A
              ASC    '$4A'
              DB     $4B
              ASC    '$4B'
              DB     $4C
              ASC    '$4C'
              DB     $4D
              ASC    '$4D'
              DB     $4E
              ASC    '$4E'
              DB     $4F
              ASC    '$4F'
              DB     $50
              ASC    'GWP'
              DB     $51
              ASC    'GSS'
              DB     $52
              ASC    'GDB'
              DB     $53
              ASC    'DRW'
              DB     $54
              ASC    'GDP'
              DB     $55
              ASC    'HMD'
              DB     $56
              ASC    'EDU'
              DB     $57
              ASC    'STN'
              DB     $58
              ASC    'HLP'
              DB     $59
              ASC    'COM'
              DB     $5A
              ASC    'CFG'
              DB     $5B
              ASC    'ANM'
              DB     $5C
              ASC    'MUM'
              DB     $5D
              ASC    'ENT'
              DB     $5E
              ASC    'DVU'
              DB     $5F
              ASC    '$5F'
              DB     $60
              ASC    '$60'
              DB     $61
              ASC    '$61'
              DB     $62
              ASC    '$62'
              DB     $63
              ASC    '$63'
              DB     $64
              ASC    '$64'
              DB     $65
              ASC    '$65'
              DB     $66
              ASC    '$66'
              DB     $67
              ASC    '$67'
              DB     $68
              ASC    '$68'
              DB     $69
              ASC    '$69'
              DB     $6A
              ASC    '$6A'
              DB     $6B
              ASC    'BIO'
              DB     $6D
              ASC    'TDR'
              DB     $6E
              ASC    'PRE'
              DB     $6F
              ASC    'HDV'
              DB     $70
              ASC    '$70'
              DB     $71
              ASC    '$71'
              DB     $72
              ASC    '$72'
              DB     $73
              ASC    '$73'
              DB     $74
              ASC    '$74'
              DB     $75
              ASC    '$75'
              DB     $76
              ASC    '$76'
              DB     $77
              ASC    '$77'
              DB     $78
              ASC    '$78'
              DB     $79
              ASC    '$79'
              DB     $7A
              ASC    '$7A'
              DB     $7B
              ASC    '$7B'
              DB     $7C
              ASC    '$7C'
              DB     $7D
              ASC    '$7D'
              DB     $7E
              ASC    '$7E'
              DB     $7F
              ASC    '$7F'
              DB     $80
              ASC    '$80'
              DB     $81
              ASC    '$81'
              DB     $82
              ASC    '$82'
              DB     $83
              ASC    '$83'
              DB     $84
              ASC    '$84'
              DB     $85
              ASC    '$85'
              DB     $86
              ASC    '$86'
              DB     $87
              ASC    '$87'
              DB     $88
              ASC    '$88'
              DB     $89
              ASC    '$89'
              DB     $8A
              ASC    '$8A'
              DB     $8B
              ASC    '$8B'
              DB     $8C
              ASC    '$8C'
              DB     $8D
              ASC    '$8D'
              DB     $8E
              ASC    '$8E'
              DB     $8F
              ASC    '$8F'
              DB     $90
              ASC    '$90'
              DB     $91
              ASC    '$91'
              DB     $92
              ASC    '$92'
              DB     $93
              ASC    '$93'
              DB     $94
              ASC    '$94'
              DB     $95
              ASC    '$95'
              DB     $96
              ASC    '$96'
              DB     $97
              ASC    '$97'
              DB     $98
              ASC    '$98'
              DB     $99
              ASC    '$99'
              DB     $9A
              ASC    '$9A'
              DB     $9B
              ASC    '$9B'
              DB     $9C
              ASC    '$9C'
              DB     $9D
              ASC    '$9D'
              DB     $9E
              ASC    '$9E'
              DB     $9F
              ASC    '$9F'
              DB     $A0
              ASC    'WP '
              DB     $A1
              ASC    '$A1'
              DB     $A2
              ASC    '$A2'
              DB     $A3
              ASC    '$A3'
              DB     $A4
              ASC    '$A4'
              DB     $A5
              ASC    '$A5'
              DB     $A6
              ASC    '$A6'
              DB     $A7
              ASC    '$A7'
              DB     $A8
              ASC    '$A8'
              DB     $A9
              ASC    '$A9'
              DB     $AA
              ASC    '$AA'
              DB     $AB
              ASC    'GSB'
              DB     $AC
              ASC    'TDF'
              DB     $AD
              ASC    'BDF'
              DB     $AE
              ASC    '$AE'
              DB     $AF
              ASC    '$AF'
              DB     $B0
              ASC    'SRC'
              DB     $B1
              ASC    'OBJ'
              DB     $B2
              ASC    'LIB'
              DB     $B3
              ASC    'S16'
              DB     $B4
              ASC    'RTL'
              DB     $B5
              ASC    'EXE'
              DB     $B6
              ASC    'PIF'
              DB     $B7
              ASC    'TIF'
              DB     $B8
              ASC    'NDA'
              DB     $B9
              ASC    'CDA'
              DB     $BA
              ASC    'TOL'
              DB     $BB
              ASC    'DVR'
              DB     $BC
              ASC    'LDF'
              DB     $BD
              ASC    'FST'
              DB     $BE
              ASC    '$BE'
              DB     $BF
              ASC    'DOC'
              DB     $C0
              ASC    'PNT'
              DB     $C1
              ASC    'PIC'
              DB     $C2
              ASC    'ANI'
              DB     $C3
              ASC    'PAL'
              DB     $C4
              ASC    '$C4'
              DB     $C5
              ASC    'OOG'
              DB     $C6
              ASC    'SCR'
              DB     $C7
              ASC    'CDV'
              DB     $C8
              ASC    'FON'
              DB     $C9
              ASC    'FND'
              DB     $CA
              ASC    'ICN'
              DB     $CB
              ASC    '$CB'
              DB     $CC
              ASC    '$CC'
              DB     $CD
              ASC    '$CD'
              DB     $CE
              ASC    '$CE'
              DB     $CF
              ASC    '$CF'
              DB     $D0
              ASC    '$D0'
              DB     $D1
              ASC    '$D1'
              DB     $D2
              ASC    '$D2'
              DB     $D3
              ASC    '$D3'
              DB     $D4
              ASC    '$D4'
              DB     $D5
              ASC    'MUS'
              DB     $D6
              ASC    'INS'
              DB     $D7
              ASC    'MDI'
              DB     $D8
              ASC    'SND'
              DB     $D9
              ASC    '$D9'
              DB     $DA
              ASC    '$DA'
              DB     $DB
              ASC    'DBM'
              DB     $DC
              ASC    '$DC'
              DB     $DD
              ASC    '$DD'
              DB     $DE
              ASC    '$DE'
              DB     $DF
              ASC    '$DF'
              DB     $E0
              ASC    'LBR'
              DB     $E1
              ASC    '$E1'
              DB     $E2
              ASC    'ATK'
              DB     $E3
              ASC    '$E3'
              DB     $E4
              ASC    '$E4'
              DB     $E5
              ASC    '$E5'
              DB     $E6
              ASC    '$E6'
              DB     $E7
              ASC    '$E7'
              DB     $E8
              ASC    '$E8'
              DB     $E9
              ASC    '$E9'
              DB     $EA
              ASC    '$EA'
              DB     $EB
              ASC    '$EB'
              DB     $EC
              ASC    '$EC'
              DB     $ED
              ASC    '$ED'
              DB     $EE
              ASC    'R16'
              DB     $EF
              ASC    'PAS'
              DB     $F0
              ASC    'CMD'
              DB     $F1
              ASC    'UT1'
              DB     $F2
              ASC    'UT2'
              DB     $F3
              ASC    'UT3'
              DB     $F4
              ASC    'UT4'
              DB     $F5
              ASC    'UT5'
              DB     $F6
              ASC    'UT6'
              DB     $F7
              ASC    'UT7'
              DB     $F8
              ASC    'UT8'
              DB     $F9
              ASC    'OS '
              DB     $FA
              ASC    'INT'
              DB     $FB
              ASC    'IVR'
              DB     $FC
              ASC    'BAS'
              DB     $FD
              ASC    'VAR'
              DB     $FE
              ASC    'REL'
              DB     $FF
              ASC    'SYS'
              DB     0

NUMFLS        DA     0
BLKCNT        DB     0

FILETYP       DB     0
POSITION      DB     0
CATTYPE       DB     0
RBYTE         DS     1

doCase        DB     0

              DUM    FBUF2
DIRBLOK       DS     512                              B700
DIRINFO       DS     256                              B900
FNAME1        DS     64                               BA00
FNAME2        DS     64                               BA40
NUM           DS     10                               BA80
              DEND

