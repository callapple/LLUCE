            LST       OFF
*=================================================
* MacBinary, MacBinary ][
*=================================================
*
            DUM       HDRBUF
            DB        0
MB_FNLEN    DB        0
MB_FNAME    DS        63
MB_FTYPE    ASC       '    '                                     ; Standard Finder Info
MB_CREAT    ASC       '    '
            DB        0
            DB        0                                          ; Used For ID
            DW        0                                          ; Window Vert Pos
            DW        0                                          ; Window Horiz Pos
            DW        0                                          ; Window Info
            DB        0                                          ; Protected In Bit 0
            DB        0                                          ; Used For ID
            ADRL      0                                          ; Data Fork Size
            ADRL      0                                          ; Resource Fork Size
MB_CDATE    ADRL      0                                          ; Creation Date
MB_MDATE    ADRL      0                                          ; Modified Date
            DW        0                                          ; Get Info Length
            DB        0                                          ; Finder Flags
            DS        14                                         ; Reserved
            ADRL      0                                          ; File Size
            DW        0                                          ; Second Header Length
            DB        0                                          ; Uploader Version
            DB        0                                          ; Minimum Uploader Version
            DW        0                                          ; Header CRC
            DW        0                                          ; Computer Type
            DEND

DO_MAC      CPY       #12
            BEQ       :MAC
            JMP       DO_SIT

:MAC        PRINT     'MacBinary Wrapper - Filename: '
; Show Filename
            PSTRING   #$80;MB_FNLEN;MB_FNAME

            JSR       SHOWSTR                                    ; Print Created Date
            DB        Cr,Cr
            DCI       'Created: '
            MACDT     MB_CDATE
            PRINT     'Modified: '
            MACDT     MB_MDATE
            CROUT
            CROUT
            LDX       #3
:TSTPIT     LDA       MB_FTYPE,X
            CMP       :PIT,X
            BNE       :CHKSIT

            DEX
            BPL       :TSTPIT
            BMI       DO_PIT

:CHKSIT     LDX       #3
:TSTSIT     LDA       MB_FTYPE,X
            CMP       :SIT,X
            BNE       :SHOWTYP

            DEX
            BPL       :TSTSIT
            JMP       DO_SIT2

:SHOWTYP    JSR       SHOWSTR
            DB        Cr
            DCI       'Archive Unknown, File Type Is: '
            PSTRING   #$80;#4;MB_FTYPE
            TWOSPACE
            PRINT     'Created By: '
            PSTRING   #$80;#4;MB_CREAT
            RTS

:SIT        ASC       'SIT!'
:PIT        ASC       'PIT '

DO_PIT      JSR       SHOWSTR
            ASC       'This Is A PackIT File.  PackIT Is Not Supported.'
            HEX       0D8D
            RTS

*=================================================
* STUFFIT  (MACINTOSH)
*=================================================
* FILE FORMAT
*-------------------------------------------------
*
*    Master Header
*         File Header 1
*              File 1 Resource Fork
*              File 1 Data Fork
*         File Header 2
*              File 2 Resource Fork
*              File 2 Data Fork
*         .
*         .
*         File Header N
*              File N Resource Fork
*              File N Data Fork
* EOF
*
*-------------------------------------------------
* MASTER HEADER
*-------------------------------------------------
*
            DUM       HDRBUF
SIT_ID1     ASC       'SIT!'                                     ; 00 STUFFIT Archive Signature
SIT_RECS    DW        0                                          ; 04 Number Of Files In Archive
SIT_HLEN    ADRL      0                                          ; 06 Length Of Entire Archive Incl Hdr
            ASC       'rLau'                                     ; 0A Authors Name - R. Lau
SIT_VER     DB        0                                          ; 0E Version Number
            DS        7                                          ; 0F Reserved
; 16
*
*-------------------------------------------------
* FILE HEADER
*-------------------------------------------------
*
SIT_RMTH    DB        0                                          ; 00 Rsrc Fork Compression Method
SIT_DMTH    DB        0                                          ; 01 Data Fork Compression Method
*
* SIT_RMTH  0  PnoComp      Uncompressed
*           1  RleComp      RLE Compression
*           2  LzwComp      LZW Compression, 18K Buffer,
*                             14 Bit Code Size
*           3  HufComp      Huffman Compression
*          16  Encrypted    Bit Set If Encrypted.
*          32  StartFolder  Marks Start Of A New Folder
*          33  EndFolder    Marks End Of The Last Folder Started
*
SIT_FNLN    DB        0                                          ; 02 File Name Length
SIT_FNAM    DS        63                                         ; 03 Filename
SIT_FTYP    ADRL      0                                          ; 42 Filetype
SIT_CRTR    ADRL      0                                          ; 46 File Creator
SIT_FFLG    DW        0                                          ; 4A Finder Flags
            ADRL      0                                          ; 4C Creation Date
SIT_MDAT    ADRL      0                                          ; 50 Modification Date
SIT_ROSZ    ADRL      0                                          ; 54 Uncompressed Resource Fork Length
SIT_DOSZ    ADRL      0                                          ; 58 Uncompressed Data Fork Length
SIT_RNSZ    ADRL      0                                          ; 5C Compressed Resource Fork Length
SIT_DNSZ    ADRL      0                                          ; 60 Compressed Data Fork Length
            DW        0                                          ; 64 Resource Fork CRC
            DW        0                                          ; 66 Data Fork CRC
            DB        0                                          ; 68 Pad Bytes For Encrypted Files,
            DB        0                                          ; 69 Resource And Data Forks
            DS        4                                          ; 6A Reserved
            DW        0                                          ; 6E CRC Of File Header

DIRCNT      DB        0                                          ; Directory level count
DIRPOSN     DS        $10                                        ; NOT PART OF HEADER
            DEND                                                 ; 70

PATHNAME    =         DATABUF
*
*-------------------------------------------------
* POSITIONING IN FILE
*-------------------------------------------------
*
* First File Header = SIT_ID1 + 22
*
* Beginning Of Resource Fork = SIT_DMTH + 112
*
* Beginning Of Data Fork = Beginning Of Resource Fork + SIT_RNSZ
*
* Next File Header = Beginning Of Previous Data Fork + SIT_DNSZ
*       Or
*            = Previous File Header + 112 + SIT_RNSZ + SITCDLN
*
SIT_AOL     ZEROSEEK
            READ      #32;SIT_RMTH                               ; Read In Header
            PRINT     'AOL-'
            JMP       DO_SIT2

DO_SIT      ZEROSEEK
DO_SIT2     READ      #22;SIT_ID1
            PRINT     'StuffIt V'
            DECOUT    $80;BYTE;SIT_VER
            TWOSPACE
            PRINT     'Recs: '
            REVWORD   SIT_RECS
            DECOUT    $80;WORD;SIT_RECS
            PRINT     '  Size: '
            REVLONG   SIT_HLEN
            DECOUT    $80;LONG;SIT_HLEN
            APPLE     1                                          ; Show Header

            LDA       #0                                         ; Put dir level to root
            STA       DIRCNT
            STA       PATHNAME
            LDX       #16
:ZLUP       STA       DIRPOSN,X
            DEX
            BPL       :ZLUP

:SITLOOP    READ      #112;SIT_RMTH                              ; Read In Header
            JSR       :SHOWENT
            BIT       INTOUT
            BMI       :SITDONE

            LDA       DIRCNT                                     ; Are we in a directory?
            BNE       :SKIPCNT                                   ; Yes, don't count records

            LDA       SIT_RECS                                   ; Bump Down File Count
            BNE       :DECREC
            DEC       SIT_RECS+1
:DECREC     DEC       SIT_RECS
            LDA       SIT_RECS                                   ; Count at zero?
            ORA       SIT_RECS+1
            BEQ       :SITDONE                                   ; Yes, exit

:SKIPCNT    LDA       SIT_RMTH                                   ; Get Compression Type
            CMP       #$20                                       ; Directory start?
            BNE       :TSTEDIR                                   ; Nope

            INC       DIRCNT                                     ; Increment directory level
            LDX       PATHNAME
            INX
            LDA       #':'
            STA       PATHNAME+1,X
            TXA
            LDX       DIRCNT
            STA       DIRPOSN,X
            BNE       :SITLOOP

:TSTEDIR    CMP       #$21                                       ; Directory end?
            BNE       :NORMENT                                   ; Nope

            DEC       DIRCNT                                     ; Decrement directory level
            LDX       DIRCNT
            LDA       DIRPOSN,X
            STA       PATHNAME
            BNE       :SITLOOP

:NORMENT    JSR       GET_MARK
            JSR       ADDXAY                                     ; MARK = MARK + COMPRESSED LENGTHS
            DA        SIT_DNSZ
            JSR       SET_POS
            JMP       :SITLOOP

:SITDONE    RTS

:SHOWENT    LDA       SIT_RMTH                                   ; Get Compression Type
            CMP       #$21                                       ; End of subdirectory?
            BEQ       :SITDONE                                   ; Yes, don't show record
            PHA

            M_ACCESS  SIT_FFLG                                   ; Show File Access
; Print File Name
            LDX       DIRCNT
            LDA       DIRPOSN,X
            TAY
            LDX       #0
:MOVENAM    LDA       SIT_FNAM,X
            STA       PATHNAME+1,Y
            INX
            INY
            CPX       SIT_FNLN
            BNE       :MOVENAM

            STY       PATHNAME
            PSTRING   #0;PATHNAME;PATHNAME+1

            PLA                                                  ; Get compression type
            PHA
            CMP       #$20                                       ; Directory start?
            BEQ       :STDIR                                     ; Yes, type is folder

; Show File Type
            PSTRING   #$80;#4;SIT_FTYP
            BRA       :DODATE

:STDIR      PRINT     'FLDR  '
:DODATE     MACDT     SIT_MDAT                                   ; Print Date
            REVLONG   SIT_DOSZ
            REVLONG   SIT_ROSZ

            PLA                                                  ; Get Compression Type
            PHA
            CMP       #$20                                       ; Is it directory start?
            BEQ       :STDIR2                                    ; Yes, Creator is system

; Show Creator
            PSTRING   #$80;#4;SIT_CRTR
            BRA       :DOLENS

:STDIR2     PRINT     'OPSY  '                                   ; Operating system

; Add The Original Lengths
:DOLENS     ADD       LONG;SIT_DOSZ;LONG;SIT_ROSZ;LONG;SIT_DOSZ
; Print Total Entry Length
            DECOUT    8;LONG;SIT_DOSZ
            SPACE
            REVLONG   SIT_DNSZ
            REVLONG   SIT_RNSZ
            PLA                                                  ; Print Compression Type
            BEQ       :USEDATA

            CMP       #$20                                       ; Directory start?
            BNE       :DOMETH                                    ; Nope, type unknown
            LDA       #7                                         ; Show as type FOLDER
            BNE       :METHOK

:USEDATA    LDA       SIT_DMTH
:DOMETH     CMP       #5+1                                       ; Valid method?
            BLT       :METHOK                                    ; Yes

:DOUNK      LDA       #6                                         ; Make it unknown
:METHOK     ASL
            TAY
            LDX       :METHODS,Y
            LDA       :METHODS+1,Y
            JSR       PRINTFMT
; Add Compressed Lengths
            ADD       LONG;SIT_DNSZ;LONG;SIT_RNSZ;LONG;SIT_DNSZ
; Print Compression Percent
            PERCENT   LONG;SIT_DNSZ;LONG;SIT_DOSZ
            CROUT                                                ; Next Line
            RTS

:METHODS    DA        STORE
            DA        RLE
            DA        LZW
            DA        HUFF
            DA        DLX1
            DA        DLX2
            DA        UNK
            DA        FOLDER

