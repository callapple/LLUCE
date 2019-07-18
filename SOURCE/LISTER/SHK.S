*=================================================
* SHRINKIT (APPLE)
*=================================================
* FILE FORMAT
*-------------------------------------------------
*
*    Master Header
*         File 1 Header
*              Attribute Section
*              Filename Section
*              Thread Section
*                   Thread 1
*                   .         File Data Is Contained In A Thread
*                   .
*                   Thread N
*         File 2 Header
*              Attribute Section
*              Filename Section
*              Thread Section
*                   Thread 1
*                   .
*                   .
*                   Thread N
*         File 3 Header
*         .
*         .
*         .
* EOF
*
*-------------------------------------------------
* MASTER HEADER
*-------------------------------------------------
*
            DUM       HDRBUF
SHK_ID1     DCI       'Nu'                                     ; Master Signature Spells "NuFile"
            DCI       'Fi'                                     ; In Alternating High And Low ASCII
            DCI       'le'
            DW        0                                        ; CRC Of Bytes 8 - 47 In This Block
SHK_RECS    ADRL      0                                        ; Total Number Of Files In This Archive
SHK_CTIM    DS        3                                        ; Archive Creation Time And Date
SHK_CDAT    DS        5
SHK_MTIM    DS        3                                        ; Time And Date Archive Last Modified
SHK_MDAT    DS        5
SHK_VER     DA        0                                        ; Master Version Number
            ADRL      $E0                                      ; Archive File Type (Should Be $000000E0)
            ADRL      $8002                                    ; Archive Aux Type (Should Be $00008002)
            ADRL      0                                        ; Length Of The Archive
            DS        6                                        ; Reserved
; End Master Header
*
*-------------------------------------------------
* FILE HEADER
*-------------------------------------------------
*
SHK_ID2     DCI       'Nu'                                     ; Header Signature Spells "NuFX" In
            DCI       'FX'                                     ; Alternating High And Low ASCII
            DW        0                                        ; CRC Of Bytes 6 - SHK_ATRB+1
*
*-------------------------------------------------
* ATTRIBUTE SECTION
*-------------------------------------------------
*
SHK_ATRB    DW        0                                        ; Length Of The Attribute Section Of
; Each Header. The Distance From SHK_ID2
; To And Including SHK_FNLN
SHK_FVER    DW        0                                        ; Minimum Version Needed For Extraction
SHK_NTHR    ADRL      0                                        ; The Number Of Threads Following NXFNAM
SHK_OS      DW        0                                        ; Native File System Identifier
*
*  0     File Is An Archived Disk
*  1     ProDOS/SOS
*  2     DOS 3.3
*  3     DOS 3.2
*  4     Apple II Pascal
*  5     Macintosh(Tm) (HFS)
*  6     Macintosh (MFS)
*  7     LISA(Tm) File System
*  8     Apple CP/M
*  9     Reserved, Do Not Use
*  A     MS-DOS
*  B     High-Sierra
*  C     ISO 9660
*  D     AppleShare
*  E-
*  FFFF  Reserved
*
            ASC       '/'                                      ; Native File System Separator
; ProDOS = '/' ($2F)
; HFS    = ':' ($3A)
; MS-DOS = '\' ($5C)
            DB        0                                        ; Sparse File Indicated If = 1
SHK_ACS     ADRL      0
*
* SHK_ACS    31-8     Reserved, Must Be Zero
*             7       Destroy Enabled
*             6       Rename Enabled
*             5       Backup Needed
*            4-3      Reserved, Must Be Zero
*             2       File Is Invisible
*             1       Write Enabled
*             0       Read Enabled
*
SHK_FTYP    ADRL      0                                        ; File Type, Disk = 0
SHK_AUX     ADRL      0                                        ; Extra Type, ProDOS Aux_Type Or HFS
; Creator_Type, Disk: Total Number
; Of Blocks On The Device
            DW        0                                        ; Storage Type, If A Disk This Should
; Contain The Block Size Of The O/S
*
*   1  < 512 Bytes           ProDOS    512
*   2  > 511 Bytes, < 128K   DOS 3.3   256
*   3  > 129K                HFS       524
*   5  Extended File
*  $D  Subdirectory
*
            DS        3                                        ; File Creation Time And Date
            DS        5
SHK_MATM    DS        3                                        ; Time And Date File Last Modified
SHK_MADT    DS        5
            DS        3                                        ; Time And Date File Archived
            DS        5
            DA        0                                        ; Filename Length
; If Filename Length Is 0,
; Filename Is In Thread Class 3
; Length Of FST Option List
; Only If NuFX Version Is 1 Or Greater
*
* A GS/OS Option_List Is Formatted As Follows:
* This List Is Present Only In NuFX Versions >0
*
*        DA    0          ; Option List Buffer Size (>45)
*        DA    0          ; Bytes Of Info Returned By GS/OS
*        DA    0          ; File System ID Word For FST
*        DS    46         ; Bytes Returned By FST
*
*        DW    0          ; Filename Length
*
*-------------------------------------------------
* THREAD SECTION
*-------------------------------------------------
*
SHK_TCLS    DW        0                                        ; Describes The Class Of The Thread
*              0            CLS_MSG
*              1            CLS_CNTRL
*              2            CLS_DATA
*              3            CLS_FNAME
*
SHK_TFMT    DW        0                                        ; Format Of The Data Within The Thread
*              0            Uncompressed
*              1            Huffman SQueezed (SQ/USQ)
*              2            Dynamic LZW Type 1
*              3            Dynamic LZW Type 2
*              4            Unix 12 bit compression
*              5            Unix 16 bit compression
*              .            RESERVED, Contact The Author
*             FFFF
*
SHK_TKND    DW        0                                        ; Describes Data In Thread
*
* SHK_TCLS     SHK_TKND     THREAD CONTAINS:
*-------------------------------------------------
* CLS_MSG      0            ASCII Text
*              1            Comment
*                           All Others Undefined
*
* CLS_CNTRL    0            Create Directory
*                           All Others Undefined
*
* CLS_DATA     0            Data_Fork Of File
*              1            Disk Image
*              2            Resource_Fork Of File
*                           All Others Undefined
*
* CLS_FNAME    0            Record Filename
*
            DS        2                                        ; Reserved
SHK_TFNL                                                       ; Length Of Filename
SHK_TCML                                                       ; Length Of Comment
SHK_TEOF    ADRL      0                                        ; Length Of The Uncompressed Thread
                                                               ; Space Allocated For Filename
                                                               ; Space Allocated For Comment
SHK_TCEF    ADRL      0                                        ; Length Of The Compressed Thread
            DEND
*
*-------------------------------------------------
* FILENAME SECTION
*-------------------------------------------------
*
            DUM       DATABUF
SHK_FNAM    DS        1                                        ; Filename, Partial Pathname Or Disk
            DEND                                               ; Volume Name. Names Ported Across
; Systems May Have Illegal Characters
; Or Characteristics.
*
*-------------------------------------------------
* POSITIONING IN FILE
*-------------------------------------------------
*
* Start Of The Thread List = (Beginning Of Header)
*                            + SHK_ATRB + SHK_FNLN
*
* End Of The Thread List = (Beginning Of Header)
*                          + SHK_ATRB + SHK_FNLN
*                          + (16 * NCNUMTHR)
*
* Start Of A Data_Thread = (Beginning Of Header)
*                          + SHK_ATRB + SHK_FNLN
*                          + (16 * NCNUMTHR)
*                          + (THRCMPEOF Of All Threads In The
*                           Thread List Which Are Not Data Prior
*                           To Finding A CLS_DATA = 0000)
*
* Start Of A Resource_Thread = (Beginning Of Header)
*                          + SHK_ATRB + SHK_FNLN
*                          + (16 * SHK_NTHR)
*                          + (THRCMPEOF Of All The Threads In
*                            The Thread List Which Are Not
*                            Resources Prior To Finding A
*                            CLS_DATA = 0002)
*
* Next Record = (Beginning Of Header) + SHK_ATRB + SHK_FNLN +
*               (16 * SHK_NTHR) + (THRCMPEOF Of Each Thread)
*
*-------------------------------------------------
*
DO_SHK      ZEROSEEK                                           ; Reset To Archive Start
DO_SHK2     READ      #48;SHK_ID1                              ; Read In Master Header
            LDX       #5                                       ; Check For Valid Header
:SIGLOOP    LDA       HDRBUF,X
            CMP       :M_SIG,X
            BNE       :SIGERR
            DEX
            BPL       :SIGLOOP
            BMI       :SIGOK

:SIGERR     JSR       SHOWSTR                                  ; Invalid Header
            ASC       '[Error]...Not A NuFX Archive.'8D
            RTS

:SIGOK      JSR       :CPYRECN                                 ; Copy Over Record Number
            PRINT     'ShrinkIt V'
            DECOUT    $80;WORD;SHK_VER
            PRINT     ': Create: '
            GDATE     SHK_CDAT
            GTIME     SHK_CTIM
            PRINT     'Mod: '
            GDATE     SHK_MDAT
            GTIME     SHK_MTIM
            PRINT     'Rec: '
            DECOUT    $80;LONG;SHK_RECS
            APPLE     1                                        ; Compression used
            LDA       #0                                       ; Flag First Pass
            STA       PASSNO
            STA       COMMENTS                                 ; Flag No Comments
            GETMARK   STRTMARK                                 ; Save Starting Mark
            JSR       :LLOOP                                   ; Show File List
            BCC       :COMMENT
            JMP       :BADFILE                                 ; Error, No Comments

:COMMENT    BIT       COMMENTS                                 ; Any Comments To Show?
            BPL       :SHKQUIT

            PUTMARK   STRTMARK                                 ; Reset Mark To Start
            JSR       :CPYRECN                                 ; Reset Number Of Records
            DEC       PASSNO                                   ; Flag Pass 2
            JSR       SHOWSTR
            DB        Cr,Cr
            ASC       'Comments:'0D8D
:LLOOP      BIT       PASSNO                                   ; Which Pass?
            BPL       :PASS1                                   ; Pass 1, Show List

            JSR       :SHOWCOM                                 ; Show Comments
            JMP       :PASS2                                   ; Next Entry

:PASS1      JSR       :SHOWENT                                 ; Show The Entry
            BCS       :BADQUIT
:PASS2      BIT       INTOUT                                   ; Interrupted?
            BMI       :SHKQUIT                                 ; Yes

            LDA       CUR_REC                                  ; Count Down Records
            BNE       :DEC1
            DEC       CUR_REC+1
:DEC1       DEC       CUR_REC
            LDA       CUR_REC
            ORA       CUR_REC+1
            BEQ       :SHKQUIT                                 ; Finished

            JSR       :SETETHR                                 ; Set Mark To Next Header
            JSR       ADDXAY                                   ; Add In Thread Sizes
            DA        TCOMPR
            JSR       ADDXAY                                   ; Add In Other Comp Sizes
            DA        OCOMPR
            JSR       SET_POS                                  ; Set Mark
            JMP       :LLOOP                                   ; Loop Back

:BADQUIT    JSR       SHOWSTR
            DB        Cr,Cr,Cr
            ASC       'ERROR: File Corrupted.'8D
:SHKQUIT    CLC
            RTS

:BADFILE    SEC
            RTS

*=================================================
* Show Record File Information
*=================================================

:SHOWENT    JSR       :THRDATA                                 ; Read In Thread Data
            JSR       :GET_FN
            P_ACCESS  SHK_ACS                                  ; Show File's Access
; Print The File Name
            PSTRING   0;SHK_FNAM;SHK_FNAM+1

            BIT       SHK_DSK                                  ; Is It A Disk?
            BPL       :TFILE                                   ; Nope, File

            PRINT     'Disk  '
            JMP       :DODATE

:TFILE      FILETYPE  SHK_FTYP                                 ; Show File Type
:DODATE     GDATE     SHK_MADT                                 ; Print Date
            GTIME     SHK_MATM                                 ; Print Time
            BIT       SHK_DSK
            BPL       :NOTDISK

            LSR       SHK_AUX+1                                ; Divide Auxtype By 2 For
            ROR       SHK_AUX                                  ; Disk Storage
; Print Disk Size
            DECOUT    $80;WORD;SHK_AUX
            PRINT     'k  '
            JMP       :SIZE

:NOTDISK    AUXTYPE   SHK_AUX                                  ; Show Aux Type
; Print Uncompressed Size
:SIZE       DECOUT    8;LONG;TUCOMPR
            TWOSPACE
            LDA       SHK_TFMT+1
            BEQ       :THROK

:UNKFMT     LDX       #<UNK                                    ; Method Unknown
            LDA       #>UNK
            BNE       :DO_METH

:THROK      LDA       SHK_TFMT                                 ; Print Pack Method
            CMP       #5+1                                     ; Supported format?
            BGE       :UNKFMT                                  ; Nope, Unknown

            ASL
            TAY
            LDX       :METHODS,Y
            LDA       :METHODS+1,Y
:DO_METH    JSR       PRINTFMT
            JSR       :DECTHRD
; Print Compression %
            PERCENT   LONG;TCOMPR;LONG;TUCOMPR
            CROUT                                              ; Finish Line
:NOCOMM     JMP       :GO_THRD                                 ; Reset To End Of Threads

*=================================================
* Show Comment Thread
*=================================================

:SHOWCOM    JSR       :THRDATA                                 ; Read In Thread Data
            LDA       SHK_NCML                                 ; Any Comment To Show?
            ORA       SHK_NCML+1
            BEQ       :NOCOMM                                  ; Nope..

            JSR       :GET_FN
; Print The File Name
            PSTRING   #$80;SHK_FNAM;SHK_FNAM+1
            CROUT                                              ; Skip A Line
            CROUT
            JSR       :SETETHR
            JSR       ADDXAY                                   ; Add In Comment Offset
            DA        COMOFFS
            JSR       SET_POS                                  ; Set Mark
:COMLUP     READ      #1;SHK_FNAM                              ; Read In Comment Character
            LDA       SHK_FNAM                                 ; Print Character
            JSR       COUT
            LDA       SHK_NCML                                 ; Decrement Comment Byte
            BNE       :DECCOM                                  ; Count
            DEC       SHK_NCML+1
:DECCOM     DEC       SHK_NCML
            LDA       SHK_NCML                                 ; If Zero, Finished
            ORA       SHK_NCML+1
            BNE       :COMLUP

            CROUT
            CROUT
            RTS

:SETTHRD    LDA       SHK_NTHR                                 ; Copy Number Of Threads
            STA       TCOUNT                                   ; To Counter
            LDA       SHK_NTHR+1
            STA       TCOUNT+1
            RTS

:DECTHRD    LDA       TCOUNT                                   ; Count Down Thread Records
            BNE       :DEC2
            DEC       TCOUNT+1
:DEC2       DEC       TCOUNT
:CHKTHRD    LDA       TCOUNT
            ORA       TCOUNT+1
            RTS

*-------------------------------------------------
* List Data

:M_SIG      DCI       'Nu'                                     ; Spells The Word 'NuFile'
            DCI       'Fi'                                     ; In Alternating Ascii For
            DCI       'le'                                     ; Uniqueness

:F_SIG      DCI       'Nu'
            DCI       'FX'

*-------------------------------------------------
* READ16 -- Read 16 Bytes Of A Thread_Record Into
*           Thread Buffer

:READ16     READ      #16;SHK_TCLS                             ; Read In Thread Record
            RTS

:GO_THRD    PUTMARK   THRMARK                                  ; Reset To Start Of Threads
            RTS

:CPYRECN    LDA       SHK_RECS                                 ; Copy Number Of Records
            STA       CUR_REC                                  ; To Counter
            LDA       SHK_RECS+1
            STA       CUR_REC+1
            RTS

:THRDATA    READ      #8;SHK_ID2                               ; First Read Initial 8 Bytes
            LDA       SHK_ATRB
            SEC
            SBC       #8                                       ; (Read SHK_ATRB-8) Bytes
            TAY
            JSR       DO_READ                                  ; Then Read Rest Of HEADER
            DA        SHK_FVER
            LDX       #3
:TESTID     LDA       SHK_ID2,X
            CMP       :F_SIG,X
            BEQ       :GOODFIL
            PLA
            PLA
            JMP       :BADFILE

:GOODFIL    DEX
            BPL       :TESTID

            LDA       #0                                       ; Zero Filename
            STA       SHK_FNAM
            LDX       SHK_ATRB                                 ; Get And Read Filename
            LDA       SHK_ID2-2,X                              ; Any Filename Here?
            BEQ       :NNAME                                   ; No

            TAY
            STY       SHK_FNAM                                 ; Yes, Get The Filename
            JSR       DO_READ
            DA        SHK_FNAM+1
:NNAME      LDA       #0
            STA       SHK_DSK                                  ; Clear Disk Flag
            LDA       SHK_OS                                   ; Get OS.
            BEQ       :SETDISK                                 ; If Zero, It's A Disk

            LDA       SHK_FTYP                                 ; Check File Type
            BNE       :NODISK                                  ; If Not Zero, Not A Disk

            LDA       SHK_AUX+2                                ; If AuxType > 65536
            ORA       SHK_AUX+3
            BNE       :NODISK                                  ; Not A Disk

            LDA       SHK_AUX                                  ; If AuxType <> 1600
            CMP       #<1600
            BNE       :CHK280                                  ; Check For 280 Blocks
            LDA       SHK_AUX+1
            CMP       #>1600
            BNE       :NODISK
            BEQ       :SETDISK

:CHK280     CMP       #<280                                    ; If AuxType <> 280
            BNE       :NODISK                                  ; Not A Disk
            LDA       SHK_AUX+1
            CMP       #>280
            BNE       :NODISK

:SETDISK    DEC       SHK_DSK                                  ; Flag As Disk
:NODISK     GETMARK   THRMARK                                  ; Get Start Of Threads
            LDX       #11                                      ; Zero Old Sizes
            LDA       #0
:0TSIZE     STA       TCOMPR,X
            DEX
            BPL       :0TSIZE

            JSR       :SETTHRD                                 ; Read All Thread Records
:TLOOP1     JSR       :READ16                                  ; To Get All Sizes
            LDA       SHK_TCLS
            BEQ       :MSGTHRD

            CMP       #3                                       ; Filename Thread?
            BEQ       :DOFN                                    ; Yes

            CMP       #2                                       ; Data Thread?
            BNE       :ADDOTHR                                 ; Nope

; Add Uncompressed Sizes
            ADD       LONG;TUCOMPR;LONG;SHK_TEOF;LONG;TUCOMPR
; Add Compressed Sizes
            ADD       LONG;TCOMPR;LONG;SHK_TCEF;LONG;TCOMPR
            JMP       :TLOOP1E

:MSGTHRD    LDA       SHK_TKND                                 ; Comment Is Kind 1
            CMP       #1
            BNE       :ADDOTHR

            LDA       SHK_TCML                                 ; Save Comment Length
            STA       SHK_NCML
            LDA       SHK_TCML+1
            STA       SHK_NCML+1
            ORA       SHK_NCML                                 ; Any Comment Here?
            BEQ       :ADDOTHR                                 ; Nope

* Add previous lengths to get offset
* from end of threads to comment

            ADD       LADR;OCOMPR;LADR;TCOMPR;LADR;COMOFFS
            LDA       #$80
            STA       COMMENTS
            JMP       :ADDOTHR

:DOFN       LDA       SHK_TFNL                                 ; Save Filename Length
            STA       SHK_NFNL

* All previous lengths to get offset
* from end of threads to filename

            ADD       LADR;OCOMPR;LADR;TCOMPR;LADR;FNAMOFFS

; Add In Any Other Sizes
:ADDOTHR    ADD       LADR;OCOMPR;LADR;SHK_TCEF;LADR;OCOMPR
:TLOOP1E    JSR       :DECTHRD
            BEQ       :ENDTHRD
            JMP       :TLOOP1

:ENDTHRD    GETMARK   ENDTHRD                                  ; Get End Of Thread Records
            RTS                                                ; Location

:GET_FN     LDY       SHK_FNAM                                 ; Filename There Already?
            BNE       :SNAME                                   ; Yes, Skip Read

            JSR       :SETETHR                                 ; Point To Filename
            JSR       ADDXAY
            DA        FNAMOFFS
            JSR       SET_POS
            LDY       SHK_NFNL                                 ; Read In Filename
            STY       SHK_FNAM
            JSR       DO_READ
            DA        SHK_FNAM+1
:SNAME      RTS

:SETETHR    PUTMARK   ENDTHRD                                  ; Point To End Of Thread records
            JMP       GET_MARK                                 ; Put Position In X, A, Y

*-------------------------------------------------

:METHODS    DA        STORE
            DA        SQU
            DA        TYPE1
            DA        TYPE2
            DA        COMP12
            DA        COMP16

