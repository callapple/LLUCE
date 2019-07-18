* Custom catalog maker external file for LLUCE
* Written January, 1988 -- Andy Nicholas
* Major changes made for LLUCE October, 1992
*
* useage:
*
* overlay xcat,<filenumber>,vl$<opt 2nd time>,f$,ta$,th$,bu$,md$,mt$,cd$,ct$,by$
*
* <filenumber> = file to get or 0 for all files
* vl$ = directory prefix to read
* f$  = fifteen character filename
* ta$ = filetype in ASCII (ex -- REL)
* th$ = filetype in hex (ex -- $FE)
* bu$ = blocks used by file
* md$ = modification date
* mt$ = modification time
* xd$ = creation date
* xt$ = creation time
* by$ = bytes used
*-------------------------------------------------

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
                PUT    EQUATES/DRIVEREQU
                PUT    EQUATES/ENTRY

* General Global equates
*-------------------------------------------------

dirinfo         =      ENDMOD                      ; 256
dStypLen        =      4
dFname          =      5
dCDate          =      $1C
dCTime          =      $1E
dVersion        =      $20
dMinVer         =      $21
dAccess         =      $22
dEntLen         =      $23
dEntBlk         =      $24
dFilCnt         =      $25
dParent         =      $27
dParNum         =      $29
dParLen         =      $2A

dirbuf          =      ENDMOD+256                  ; 512
fStypLen        =      0
fFname          =      1
fFType          =      $10
fKeyPtr         =      $11
fBlocks         =      $13
fEOF            =      $15
fCDate          =      $18
fCTime          =      $1A
fFNCase         =      $1C
fAccess         =      $1E
fAType          =      $1F
fMDate          =      $21
fMTime          =      $23
fParent         =      $25

Id              =      4
Aux             =      1

]TYPE           =      ^overlays                   ; set file type
]AUX            =      overlays                    ; and aux type
                ORG    ]AUX                        ; must be this way
                TYP    ]TYPE

                DSK    /MAIN/LLUCE/SYSTEM/XCAT
                LST    RTN

                TTL    'LLUCE - Catalog reader'

                DB     Id
                DA     Aux
                DB     Aux/256!Aux!Id!$A5

*-------------------------------
* Size Of Code To Check For CRC
*-------------------------------

                DA     CODEEND-cat
                DA     0                           ; CRC Goes Here

                ORG    $D000

* cat the currently logged path
*-------------------------------------------------

cat             LDA    FirstTime
                BNE    keeptbl

                LDX    #PDOS_END-PDOS_BGN          ; copy ProDOS tables
MV_PDOS         LDA    PDOS_BGN-1,X
                STA    FileLength-1,X
                DEX
                BNE    MV_PDOS

keeptbl         JSR    GOBCOM
                JSR    INPNUM                      ; file number we want
                STA    filenum+1
                STX    filenum

                ORA    filenum
                BNE    notall

                HEX    2C
notall          LDA    #-1
                STA    allflag
*
* if we are not supposed to do every entry, then always get the prefix
*
                TAX
                BNE    chkOpen
*
* if this is not the first time through, then go get the filename
*
                LDA    FirstTime
                BNE    getfile
*
* call MOVNAME, and set the prefix to that acos path
*
chkOpen         LDA    old_close
                BEQ    getpref
                STA    p_close+1
                JSR    finish

getpref         JSR    GOBCOM                      ; get pathname
                JSR    MOVNAME

                LDA    FLNAME
                BNE    getfile

                JSR    MLI                         ; put a full pathname in path buffer
                DB     Getpfx
                DA     getpfxparms

getfile         JSR    GOBCOM                      ; grab the comma
                JSR    INPSTR                      ; get filename area
                CPY    #fnMaxLen                   ; is it <> than 15?
                BEQ    ok_name                     ; yes, go there

                LDA    #cr                         ; end line
                JSR    COUT
                JMP    finish                      ; close up shop and exit

; clear the string with 15 spaces
ok_name         LDA    #' '                        ; make a space
                LDY    #fnMaxLen-1                 ; 15 characters
loop            STA    (STRLOC),Y                  ; store at end of string
                DEY                                ; next character
                BPL    loop                        ; all done?

                LDA    temp_alt
                STA    TEMP
                LDA    temp_alt+1
                STA    TEMP+1

                LDA    FirstTime                   ; first time around?
                BEQ    First                       ; yes, first time through
                JMP    rdloop5a

First           LDA    #1
                STA    FirstTime                   ; mark it as having been used

                JSR    MLI
                DB     Open
                DA     openparms

                LDA    openparms+5                 ; set ref parms
                STA    p_cpos+1
                STA    p_crinf+1
                STA    p_crdir+1
                STA    p_close+1
                STA    old_close                   ; in case it's needed

                JSR    MLI                         ; read dir info
                DB     Read
                DA     p_crinf

                JSR    MLI                         ; set back to start
                DB     Setmark
                DA     p_cpos

                LDA    #-1
                STA    blkcnt                      ; start at file 1 in block

                STZ    numfls                      ; 0 files processed
                STZ    numfls+1

rdloop          LDA    #<dirbuf+4                  ; point to buf
                STA    TEMP
                STA    temp_alt
                LDA    #>dirbuf+4
                STA    TEMP+1
                STA    temp_alt+1

                JSR    MLI                         ; read block
                DB     Read
                DA     p_crdir

                LDA    blkcnt                      ; first pass?
                BPL    rdloop2                     ; nope

                STZ    blkcnt                      ; set to 0
                JMP    rdloop5a                    ; go to next entry

rdloop2         LDA    numfls                      ; we done?
                CMP    dirinfo+dFilCnt
                BNE    rdloop3                     ; nope

                LDA    numfls+1                    ; check high
                CMP    dirinfo+dFilCnt+1
                BNE    rdloop3                     ; were done

                JSR    GOBCOM                      ; get ','
                JSR    INPSTR                      ; get ta$
                JSR    GOBCOM                      ; get ','
                JSR    INPSTR                      ; get th$
                JSR    GOBCOM                      ; get ','
                JSR    INPSTR                      ; get bu$
                JSR    GOBCOM                      ; get ','
                JSR    INPSTR                      ; get md$ -- modification date
                JSR    GOBCOM                      ; get ','
                JSR    INPSTR                      ; get mt$ -- modification time
                JSR    GOBCOM                      ; get ','
                JSR    INPSTR                      ; get cd$ -- creation date
                JSR    GOBCOM                      ; get ','
                JSR    INPSTR                      ; get ct$ -- creation time
                JSR    GOBCOM                      ; get ','
                JSR    INPSTR                      ; get by$ -- size in bytes
                JMP    finish

rdloop3         LDA    (TEMP)                      ; get length and type
                AND    #LoNibble
                STA    (TEMP)                      ; get rid of extra stuff
                STA    FileLength
                BEQ    rdloop5a                    ; opps, deleted file

                INC    numfls                      ; inc file count
                BNE    rdloop3a
                INC    numfls+1

rdloop3a        LDA    allflag
                BEQ    rdloop4

                LDA    numfls
                CMP    filenum
                BNE    rdloop5a
                LDA    numfls+1
                CMP    filenum+1
                BNE    rdloop5a
                JMP    gotfile

rdloop4         JSR    prent                       ; put the entry in the strings

*-------------------------------------------------

rdloop5         RTS

rdloop5a        CLC
                LDA    TEMP                        ; go to next entry
                ADC    dirinfo+dEntLen
                STA    TEMP
                STA    temp_alt

                LDA    TEMP+1
                ADC    #0
                STA    TEMP+1
                STA    temp_alt+1

                INC    blkcnt                      ; inc place within block
                LDA    blkcnt
                CMP    dirinfo+dEntBlk
                BEQ    rdloop6                     ; go to next block
                JMP    rdloop2                     ; do next entry within this block

rdloop6         STZ    blkcnt                      ; reset count
                JMP    rdloop

gotfile         JSR    prent

finish          STZ    FirstTime
                STZ    old_close                   ; mark as closed

                JSR    MLI                         ; close file
                DB     Close
                DA     p_close
                RTS

* print the entry
*-------------------------------------------------

prent           LDY    #fFNCase+1                  ; Valid filename case flags?
                LDA    (TEMP),Y
                STA    doCase                      ; set flag

                STA    TEMP2+1                     ; save flags for shift
                DEY
                LDA    (TEMP),Y
                STA    TEMP2

                LDY    #fFname-1                   ; 1-1
                ASL    TEMP2
                ROL    TEMP2+1
prent2          INY
                LDA    (TEMP),Y                    ; default to printing name
                BIT    doCase
                BPL    uCase
                ASL    TEMP2                       ; is this lower case?
                ROL    TEMP2+1
                BCC    uCase                       ; nope
                CMP    #'A'                        ; is it alpha?
                BLT    uCase                       ; nope
                CMP    #'Z'+1
                BGE    uCase                       ; nope
                ADC    #$20                        ; make lower case
uCase           DEY                                ; save char
                STA    (STRLOC),Y
                INY
                CPY    FileLength
                BNE    prent2
*
* now get the proper filetype into ta$ -- ascii filetype
*
                JSR    getstring
                JSR    texttype
*
* insert hexadecimal filetype into string -- th$ [type_hex$]
*
dohextype       JSR    getstring

                LDY    #fFType                     $10
                LDA    (TEMP),Y
                JSR    prhex
*
* insert blocks used into string
*
                JSR    getstring

                LDY    #fBlocks                    ; $13 get blocks used
                LDA    (TEMP),Y
                STA    num                         ; save number
                INY
                LDA    (TEMP),Y
                STA    num+1
                JSR    decout1
*
* setup modification date
*
                JSR    getstring

                LDA    #fMDate                     ; $21 date
                STA    position
                JSR    convdat                     ; convert mod date
*
* setup modification time
*
                JSR    getstring

                LDA    #fMTime                     ; $23 and mod time
                STA    position
                JSR    convtim
*
* setup conversion for creation date
*
                JSR    getstring

                LDA    #fCDate                     ; $18 setup to get create-date
                STA    position
                JSR    convdat
*
* setup for creation time
*
                JSR    getstring

                LDA    #fCTime                     ; $1A else continue with full catalog by sett
                STA    position                    ; pointers to mod time data
                JSR    convtim
*
* do conversion of the number of bytes used
*
                JSR    getstring

                LDY    #fEOF                       ; $15 now get file length (eof), convert and
                LDA    (TEMP),Y                    ; display it with max of 8 decimal digits
                STA    num
                INY                                ; $16
                LDA    (TEMP),Y                    ; get middle byte of 3 byte value
                STA    num+1
                INY                                ; $17
                LDA    (TEMP),Y                    ; get high byte of 3 byte value
                STA    num+2
                JSR    decoot1

* setup the GFI parameter table on return -- FileLength already there
*-------------------------------------------------

makegfi         LDY    #fStypLen                   ; 0
                LDA    (TEMP),Y
                AND    #HiNibble
                STA    t_StorageType

                LDY    #fFType                     ; $10
                LDA    (TEMP),Y
                STA    t_FileType

                LDY    #fBlocks                    ; $13
                LDA    (TEMP),Y
                STA    t_BlocksUsed
                INY                                ; $14
                LDA    (TEMP),Y
                STA    t_BlocksUsed+1

                INY                                ; $15 fEOF
                LDA    (TEMP),Y
                STA    t_BytesUsed
                INY                                ; $16
                LDA    (TEMP),Y
                STA    t_BytesUsed+1
                INY                                ; $17
                LDA    (TEMP),Y
                STA    t_BytesUsed+2

                INY                                ; $18 fCDate
                LDA    (TEMP),Y
                STA    t_CreateDate
                INY                                ; $19
                LDA    (TEMP),Y
                STA    t_CreateDate+1

                INY                                ; $1A fCTime
                LDA    (TEMP),Y
                STA    t_CreateTime
                INY                                ; $1B
                LDA    (TEMP),Y
                STA    t_CreateTime+1

                INY                                ; $1C fFNCase
                LDA    (TEMP),Y
                STA    t_CaseFlags
                INY                                ; $1D
                LDA    (TEMP),Y
                STA    t_CaseFlags+1

                INY                                ; $1E fAccess
                LDA    (TEMP),Y
                STA    t_Access

                INY                                ; $1F fAType
                LDA    (TEMP),Y
                STA    t_AuxType
                INY                                ; $20
                LDA    (TEMP),Y
                STA    t_AuxType+1

                INY                                ; $21 fMDate
                LDA    (TEMP),Y
                STA    t_ModDate
                INY                                ; $22
                LDA    (TEMP),Y
                STA    t_ModDate+1

                INY                                ; $23 fMTime
                LDA    (TEMP),Y
                STA    t_ModTime
                INY                                ; $24
                LDA    (TEMP),Y
                STA    t_ModTime+1

                LDA    t_BytesUsed
                STA    t_XmodemBlocks
                LDA    t_BytesUsed+1
                STA    t_XmodemBlocks+1
                LDA    t_BytesUsed+2

                LDX    #7                          ; divide by 128
nloop           LSR    A
                ROR    t_XmodemBlocks+1
                ROR    t_XmodemBlocks
                DEX
                BNE    nloop

                LDA    t_BytesUsed                 ; get low byte
                AND    #Clrhi                      ; is number divisable by 128?
                BEQ    done                        ; yes, even multiple, don't add 1
                INC    t_XmodemBlocks              ; no, add 1 for extra bytes
                BNE    done                        ; didn't roll over, go print it
                INC    t_XmodemBlocks+1            ; low byte rolled over, increment mid

done            LDA    t_XmodemBlocks+1            ; mask off high byte if set
                AND    #Clrhi
                STA    t_XmodemBlocks+1

                RTS                                ; finally done!!

* get a string parsed by LLUCE with a comma
*-------------------------------------------------

getstring       JSR    GOBCOM
                JSR    INPSTR

                LDA    temp_alt
                STA    TEMP
                LDA    temp_alt+1
                STA    TEMP+1
                RTS

* print hex subroutine for catalog
*-------------------------------------------------

prhex           STA    filetype

                LDY    #0
                LDA    #'$'
                STA    (STRLOC),Y

                LDA    filetype
                AND    #HiNibble
                LSR    A
                LSR    A
                LSR    A
                LSR    A
                JSR    printdig
                LDA    filetype
                AND    #LoNibble
printdig        INY
                ORA    #'0'
                CMP    #'9'+1
                BCC    docout
                CLC
                ADC    #7
docout          STA    (STRLOC),Y
                RTS

*-------------------------------------------------

decout1         LDA    #0                          ; reset total
                STA    num+2
                STA    num+3
                STA    num+4
                STA    num+5
                STA    num+6
                CLC

                SED
                LDY    #16                         ; use decimal mode
decout2         ASL    num
                ROL    num+1
                LDA    num+2
                ADC    num+2                       ; do actual 'woz' conversion
                STA    num+2
                LDA    num+3
                ADC    num+3
                STA    num+3
                ROL    num+4
                DEY                                ; loop down
                BNE    decout2

                CLD                                ; done with decimal
                LDY    #0                          ; print 5 digits

decout3         LDA    num+4                       ; get digit
                AND    #LoNibble
                BNE    decout4                     ; is it zero?

                LDX    #' '
                BIT    num+5                       ; is this a leading zero?
                BPL    decout8                     ; yep

decout4         DEC    num+5
                CLC
                ADC    #'0'                        ; print digit
                TAX
                INC    num+6

decout8         TXA
                STA    (STRLOC),Y

decout5         LDX    #3                          ; move up next digit
decout6         ASL    num+1
                ROL    num+2
                ROL    num+3
                ROL    num+4
                DEX
                BPL    decout6

                INY                                ; count digits
                CPY    #4
                BEQ    decout7a
                BCS    decout7
                BCC    decout3

decout7a        STX    num+5                       ; print last zero for sure
                BPL    decout3

decout7         CLC
                RTS

*-------------------------------------------------

decoot1         LDA    #0                          ; reset total - convert and display an 8 digit
                STA    num+3                       ; number
                STA    num+4
                STA    num+5
                STA    num+6
                STA    num+7
                STA    num+8
                STA    num+9
                CLC

                SED
                LDY    #24                         ; use decimal mode - shift out 24 bits
decoot2         ASL    num
                ROL    num+1
                ROL    num+2                       ; do actual 'woz' conversion
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
                DEY                                ; loop down
                BNE    decoot2

                CLD                                ; done with decimal
                LDY    #0                          ; print 8 digits

decoot3         LDA    num+7                       ; get digit
                AND    #LoNibble
                BNE    decoot4                     ; is it zero?

                LDX    #' '
                BIT    num+8                       ; is this a leading zero?
                BPL    decoot8                     ; yep

decoot4         DEC    num+8
                CLC
                ADC    #'0'                        ; print digit
                TAX
                INC    num+9

decoot8         TXA
                STA    (STRLOC),Y

decoot5         LDX    #3                          ; move up next digit
decoot6         ASL    num+1
                ROL    num+2
                ROL    num+3
                ROL    num+4
                ROL    num+5
                ROL    num+6
                ROL    num+7
                DEX
                BPL    decoot6

                INY                                ; count down digits
                CPY    #8
                BEQ    decoot7a
                BCS    decoot7
                BCC    decoot3

decoot7a        STX    num+8                       ; print last zero for sure
                BPL    decoot3

decoot7         CLC
                RTS

* put "[No Date]"
*-------------------------------------------------

nodate          LDY    #8
dloop           LDA    defdate,Y
                STA    (STRLOC),Y
                DEY
                BPL    dloop
                RTS

defdate         ASC    '[No Date]'

* subroutine to convert and print dates on the screen
*-------------------------------------------------

convdat         LDY    position                    ; get day of mod-date
                LDA    (TEMP),Y
                BEQ    nodate                      ; default display if no date on file
                PHA

                AND    #$1F                        ; just get date
                JSR    bindec8
                LDY    #0
                STA    (STRLOC),Y
                TXA                                ; display date
                INY
                STA    (STRLOC),Y
                LDA    #'-'                        ; put in seperator
                INY
                STA    (STRLOC),Y

                LDY    position                    ; get last bit of month
                INY
                LDA    (TEMP),Y
                LSR    A
                PLA
                ROR    A                           ; move in month bit
                LSR    A
                LSR    A
                AND    #$3C                        ; just get month
                TAX                                ; make into offset

                LDY    #3
date            LDA    month-4,X
                STA    (STRLOC),Y
                INX
                INY
                CPY    #6
                BNE    date

                LDA    #'-'
                STA    (STRLOC),Y

                LDY    position
                INY
                LDA    (TEMP),Y                    ; get year
                LSR    A
                JSR    bindec8                     ; translate

                LDY    #7
                STA    (STRLOC),Y
                TXA
                INY
                STA    (STRLOC),Y
                RTS

month           ASC    'Jan-'
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

* Convert and print time to screen
*-------------------------------------------------

convtim         LDY    position                    ; get time data, convert to decimal and
                INY                                ; get hours first
                LDA    (TEMP),Y                    ; then display it
                AND    #$1F                        ; mask for needed digits
                JSR    bindec8                     ; convert binary to decimal and return

                LDY    #0
                STA    (STRLOC),Y
                TXA
                INY
                STA    (STRLOC),Y
                LDA    #':'
                INY
                STA    (STRLOC),Y
*
* now do minutes
*
                LDY    position
                LDA    (TEMP),Y
                AND    #$3F                        ; mask for needed bits
                JSR    bindec8                     ; convert to decimal

                LDY    #3
                STA    (STRLOC),Y
                TXA
                INY
                STA    (STRLOC),Y
                RTS

* translate a binary to text [0-99]
*-------------------------------------------------

bindec8         LDY    #0                          ; start 10's counter
bin8            CMP    #10
                BCC    bin8a                       ; less than 10, were done

                SBC    #10                         ; minus 10
                INY                                ; add 1 to the 10's counter
                BNE    bin8                        ; loop

bin8a           ADC    #'0'                        ; make 1's into text
                TAX                                ; save
                TYA
                ADC    #'0'                        ; make 10's into text
                RTS                                ; were done

* convert file type code to text
*-------------------------------------------------

texttype        LDY    #fFType                     ; get filetype
                LDA    (TEMP),Y

                STA    filetype                    ; store file type in data byte for later

                LDX    #<typetbl                   ; Point To File Types
                STX    TEMP2
                LDX    #>typetbl
                STX    TEMP2+1
                LDY    #0                          ; Index Is Zero
                PHA                                ; Save Type
type2           PLA                                ; Restore Type
                CMP    (TEMP2),Y                   ; Same Type?
                BEQ    type4                       ; Yes, Show It
                PHA                                ; Save Type
                CLC                                ; Add 4 To Skip Last Type
                LDA    #4
                ADC    TEMP2
                STA    TEMP2
                BCC    type3
                INC    TEMP2+1
type3           LDA    (TEMP2),Y                   ; Check For End Of List
                BNE    type2                       ; Not End, Do Next
                PLA                                ; Throw Out Type
                JMP    prhex

type4           INC    TEMP2
                BNE    type6
                INC    TEMP2+1
type6           LDA    (TEMP2),Y                   ; print filetype
                STA    (STRLOC),Y
                INX
                INY
                CPY    #3
                BNE    type6
                RTS

* data area for GFI return list / we make this ourself
*-------------------------------------------------

PDOS_BGN        =      *

                ORG    FREESPACE

FileLength      DS     1                           ;             +0
t_Access        DS     1                           ;             +1
t_FileType      DS     1                           ;             +2
t_AuxType       DS     2                           ; dbl byte    +3
t_StorageType   DS     1                           ;             +5
t_BlocksUsed    DS     2                           ; dbl byte    +6
t_ModDate       DS     2                           ; dbl byte    +8
t_ModTime       DS     2                           ; dbl byte    +10
t_CreateDate    DS     2                           ; dbl byte    +12
t_CreateTime    DS     2                           ; dbl byte    +14
t_XmodemBlocks  DS     2                           ; dbl byte    +16
t_BytesUsed     DS     3                           ; triple byte +18
t_CaseFlags     DS     2                           ; dbl byte    +21

*
* prodos parameter lists
*

openparms       DB     3                           ; parm numbers
                DA     FLNAME
                DA     FBUF3                       ; address of file buffer
                DB     0

p_cpos          DB     2
                DB     0
                DS     3

p_crinf         DB     4
                DB     0
                DA     dirinfo
                DW     64
                DW     0

p_crdir         DB     4
                DB     0
                DA     dirbuf
                DW     512
                DW     0

getpfxparms     DB     1
                DA     FLNAME

p_close         DB     1
                DB     0

                ORG

PDOS_END        =      *

* variables and stuff
*-------------------------------------------------

copyright       ASC    'Copyright (c), 1988 -- Andy Nicholas'
*date ASC '&SYSDATE'
*time ASC '&SYSTIME'

CODEEND         =      *

typetbl         HEX    01
                ASC    'BAD'
                HEX    02
                ASC    'PCD'
                HEX    03
                ASC    'PTX'
                HEX    04
                ASC    'TXT'
                HEX    05
                ASC    'PDA'
                HEX    06
                ASC    'BIN'
                HEX    07
                ASC    'FNT'
                HEX    08
                ASC    'FOT'
                HEX    09
                ASC    'BA3'
                HEX    0A
                ASC    'DA3'
                HEX    0B
                ASC    'WPF'
                HEX    0C
                ASC    'SOS'
                HEX    0D
                ASC    '$0D'
                HEX    0E
                ASC    '$0E'
                HEX    0F
                ASC    'DIR'
                HEX    10
                ASC    'RPD'
                HEX    11
                ASC    'RPI'
                HEX    12
                ASC    'AFD'
                HEX    13
                ASC    'AFM'
                HEX    14
                ASC    'AFR'
                HEX    15
                ASC    'SCL'
                HEX    16
                ASC    'PFS'
                HEX    17
                ASC    '$17'
                HEX    18
                ASC    '$18'
                HEX    19
                ASC    'ADB'
                HEX    1A
                ASC    'AWP'
                HEX    1B
                ASC    'ASP'
                HEX    1C
                ASC    '$1C'
                HEX    1D
                ASC    '$1D'
                HEX    1E
                ASC    '$1E'
                HEX    1F
                ASC    '$1F'
                HEX    20
                ASC    'TDM'
                HEX    21
                ASC    'IPS'
                HEX    22
                ASC    'UCP'
                HEX    23
                ASC    '$23'
                HEX    24
                ASC    '$24'
                HEX    25
                ASC    '$25'
                HEX    26
                ASC    '$26'
                HEX    27
                ASC    '$27'
                HEX    28
                ASC    '$28'
                HEX    29
                ASC    'SDI'
                HEX    2A
                ASC    '8SC'
                HEX    2B
                ASC    '8OB'
                HEX    2C
                ASC    '8IC'
                HEX    2D
                ASC    '8LD'
                HEX    2E
                ASC    'P8C'
                HEX    2F
                ASC    '$2F'
                HEX    30
                ASC    '$30'
                HEX    31
                ASC    '$31'
                HEX    32
                ASC    '$32'
                HEX    33
                ASC    '$33'
                HEX    34
                ASC    '$34'
                HEX    35
                ASC    '$35'
                HEX    36
                ASC    '$36'
                HEX    37
                ASC    '$37'
                HEX    38
                ASC    '$38'
                HEX    39
                ASC    '$39'
                HEX    3A
                ASC    '$3A'
                HEX    3B
                ASC    '$3B'
                HEX    3C
                ASC    '$3C'
                HEX    3D
                ASC    '$3D'
                HEX    3E
                ASC    '$3E'
                HEX    3F
                ASC    '$3F'
                HEX    40
                ASC    'DIC'
                HEX    41
                ASC    'OCR'
                HEX    42
                ASC    'FTD'
                HEX    43
                ASC    'PPD'
                HEX    44
                ASC    '$44'
                HEX    45
                ASC    '$45'
                HEX    46
                ASC    '$46'
                HEX    47
                ASC    '$47'
                HEX    48
                ASC    '$48'
                HEX    49
                ASC    '$49'
                HEX    4A
                ASC    '$4A'
                HEX    4B
                ASC    '$4B'
                HEX    4C
                ASC    '$4C'
                HEX    4D
                ASC    '$4D'
                HEX    4E
                ASC    '$4E'
                HEX    4F
                ASC    '$4F'
                HEX    50
                ASC    'GWP'
                HEX    51
                ASC    'GSS'
                HEX    52
                ASC    'GDB'
                HEX    53
                ASC    'DRW'
                HEX    54
                ASC    'GDP'
                HEX    55
                ASC    'HMD'
                HEX    56
                ASC    'EDU'
                HEX    57
                ASC    'STN'
                HEX    58
                ASC    'HLP'
                HEX    59
                ASC    'COM'
                HEX    5A
                ASC    'CFG'
                HEX    5B
                ASC    'ANM'
                HEX    5C
                ASC    'MUM'
                HEX    5D
                ASC    'ENT'
                HEX    5E
                ASC    'DVU'
                HEX    5F
                ASC    'FIN'
                HEX    60
                ASC    '$60'
                HEX    61
                ASC    '$61'
                HEX    62
                ASC    '$62'
                HEX    63
                ASC    '$63'
                HEX    64
                ASC    '$64'
                HEX    65
                ASC    '$65'
                HEX    66
                ASC    '$66'
                HEX    67
                ASC    '$67'
                HEX    68
                ASC    '$68'
                HEX    69
                ASC    '$69'
                HEX    6A
                ASC    '$6A'
                HEX    6B
                ASC    'BIO'
                HEX    6C
                ASC    '$6C'
                HEX    6D
                ASC    'TDR'
                HEX    6E
                ASC    'PRE'
                HEX    6F
                ASC    'HDV'
                HEX    70
                ASC    '$70'
                HEX    71
                ASC    '$71'
                HEX    72
                ASC    '$72'
                HEX    73
                ASC    '$73'
                HEX    74
                ASC    '$74'
                HEX    75
                ASC    '$75'
                HEX    76
                ASC    '$76'
                HEX    77
                ASC    '$77'
                HEX    78
                ASC    '$78'
                HEX    79
                ASC    '$79'
                HEX    7A
                ASC    '$7A'
                HEX    7B
                ASC    '$7B'
                HEX    7C
                ASC    '$7C'
                HEX    7D
                ASC    '$7D'
                HEX    7E
                ASC    '$7E'
                HEX    7F
                ASC    '$7F'
                HEX    80
                ASC    '$80'
                HEX    81
                ASC    '$81'
                HEX    82
                ASC    '$82'
                HEX    83
                ASC    '$83'
                HEX    84
                ASC    '$84'
                HEX    85
                ASC    '$85'
                HEX    86
                ASC    '$86'
                HEX    87
                ASC    '$87'
                HEX    88
                ASC    '$88'
                HEX    89
                ASC    '$89'
                HEX    8A
                ASC    '$8A'
                HEX    8B
                ASC    '$8B'
                HEX    8C
                ASC    '$8C'
                HEX    8D
                ASC    '$8D'
                HEX    8E
                ASC    '$8E'
                HEX    8F
                ASC    '$8F'
                HEX    90
                ASC    '$90'
                HEX    91
                ASC    '$91'
                HEX    92
                ASC    '$92'
                HEX    93
                ASC    '$93'
                HEX    94
                ASC    '$94'
                HEX    95
                ASC    '$95'
                HEX    96
                ASC    '$96'
                HEX    97
                ASC    '$97'
                HEX    98
                ASC    '$98'
                HEX    99
                ASC    '$99'
                HEX    9A
                ASC    '$9A'
                HEX    9B
                ASC    '$9B'
                HEX    9C
                ASC    '$9C'
                HEX    9D
                ASC    '$9D'
                HEX    9E
                ASC    '$9E'
                HEX    9F
                ASC    '$9F'
                HEX    A0
                ASC    'WP '
                HEX    A1
                ASC    '$A1'
                HEX    A2
                ASC    '$A2'
                HEX    A3
                ASC    '$A3'
                HEX    A4
                ASC    '$A4'
                HEX    A5
                ASC    '$A5'
                HEX    A6
                ASC    '$A6'
                HEX    A7
                ASC    '$A7'
                HEX    A8
                ASC    '$A8'
                HEX    A9
                ASC    '$A9'
                HEX    AA
                ASC    '$AA'
                HEX    AB
                ASC    'GSB'
                HEX    AC
                ASC    'TDF'
                HEX    AD
                ASC    'BDF'
                HEX    AE
                ASC    '$AE'
                HEX    AF
                ASC    '$AF'
                HEX    B0
                ASC    'SRC'
                HEX    B1
                ASC    'OBJ'
                HEX    B2
                ASC    'LIB'
                HEX    B3
                ASC    'S16'
                HEX    B4
                ASC    'RTL'
                HEX    B5
                ASC    'EXE'
                HEX    B6
                ASC    'PIF'
                HEX    B7
                ASC    'TIF'
                HEX    B8
                ASC    'NDA'
                HEX    B9
                ASC    'CDA'
                HEX    BA
                ASC    'TOL'
                HEX    BB
                ASC    'DVR'
                HEX    BC
                ASC    'LDF'
                HEX    BD
                ASC    'FST'
                HEX    BE
                ASC    '$BE'
                HEX    BF
                ASC    'DOC'
                HEX    C0
                ASC    'PNT'
                HEX    C1
                ASC    'PIC'
                HEX    C2
                ASC    'ANI'
                HEX    C3
                ASC    'PAL'
                HEX    C4
                ASC    '$C4'
                HEX    C5
                ASC    'OOG'
                HEX    C6
                ASC    'SCR'
                HEX    C7
                ASC    'CDV'
                HEX    C8
                ASC    'FON'
                HEX    C9
                ASC    'FND'
                HEX    CA
                ASC    'ICN'
                HEX    CB
                ASC    '$CB'
                HEX    CC
                ASC    '$CC'
                HEX    CD
                ASC    '$CD'
                HEX    CE
                ASC    '$CE'
                HEX    CF
                ASC    '$CF'
                HEX    D0
                ASC    '$D0'
                HEX    D1
                ASC    '$D1'
                HEX    D2
                ASC    '$D2'
                HEX    D3
                ASC    '$D3'
                HEX    D4
                ASC    '$D4'
                HEX    D5
                ASC    'MUS'
                HEX    D6
                ASC    'INS'
                HEX    D7
                ASC    'MDI'
                HEX    D8
                ASC    'SND'
                HEX    D9
                ASC    '$D9'
                HEX    DA
                ASC    '$DA'
                HEX    DB
                ASC    'DBM'
                HEX    DC
                ASC    '$DC'
                HEX    DD
                ASC    'DDD'
                HEX    DE
                ASC    '$DE'
                HEX    DF
                ASC    '$DF'
                HEX    E0
                ASC    'LBR'
                HEX    E1
                ASC    '$E1'
                HEX    E2
                ASC    'ATK'
                HEX    E3
                ASC    '$E3'
                HEX    E4
                ASC    '$E4'
                HEX    E5
                ASC    '$E5'
                HEX    E6
                ASC    '$E6'
                HEX    E7
                ASC    '$E7'
                HEX    E8
                ASC    '$E8'
                HEX    E9
                ASC    '$E9'
                HEX    EA
                ASC    '$EA'
                HEX    EB
                ASC    '$EB'
                HEX    EC
                ASC    '$EC'
                HEX    ED
                ASC    '$ED'
                HEX    EE
                ASC    'R16'
                HEX    EF
                ASC    'PAS'
                HEX    F0
                ASC    'CMD'
                HEX    F1
                ASC    '$F1'
                HEX    F2
                ASC    '$F2'
                HEX    F3
                ASC    '$F3'
                HEX    F4
                ASC    '$F4'
                HEX    F5
                ASC    '$F5'
                HEX    F6
                ASC    '$F6'
                HEX    F7
                ASC    '$F7'
                HEX    F8
                ASC    '$F8'
                HEX    F9
                ASC    'OS '
                HEX    FA
                ASC    'INT'
                HEX    FB
                ASC    'IVR'
                HEX    FC
                ASC    'BAS'
                HEX    FD
                ASC    'VAR'
                HEX    FE
                ASC    'REL'
                HEX    FF
                ASC    'SYS'
                HEX    00
                ASC    '---'

numfls          DW     0
blkcnt          DB     0

filetype        DB     0
position        DB     0
FirstTime       DB     0
temp_alt        DW     0                           ; 2 bytes
filenum         DW     0                           ; file number to return
allflag         DB     0
doCase          DB     0
old_close       DB     0

num             DS     10

