*=================================================
* ZIP  (MS-DOS)
*=================================================
* FILE FORMAT
*-------------------------------------------------
*
*         Local File Header 1
*                   File 1 Extra Field
*                   File 1 Comment
*              File Data 1
*         Local File Header 2
*                   File 2 Extra Field
*                   File 2 Comment
*              File Data 2
*         .
*         .
*         .
*         Local File Header N
*                   File N Extra Field
*                   File N Comment
*              File Data N
*    Central Directory
*              Central Extra Field
*              Central Comment
*         End Of Central Directory
*                   End Comment
* EOF
*
*-------------------------------------------------
* LOCAL FILE HEADER
*-------------------------------------------------
*
            DUM       HDRBUF
ZIP_L_ID    ASC       'PK'                         ; 0  ZIP Header Signature
            HEX       0304                         ; 2  Local File Header Signature
            DW        0                            ; 4  Version Needed To Extract
            DW        0                            ; 6  General Purpose Bit Flag
*
*  0     If Set, File Is Encrypted
*  1     If File Imploded And This Bit Is Set, 8K
*          Sliding Dictionary Was Used.
*        If Clear, 4K Sliding Dictionary Was Used.
*  2     If File Imploded And This Bit Is Set, 3
*          3 Shannon-Fano Trees Were Used.
*          If Clear, 2 Shannon-Fano Trees Were Used.
* 3-4    Unused
* 5-7    Used Internaly By ZIP
*
            DW        0                            ; 8  Compression Method
*
*  0  Stored     No Compression Used
*  1  Shrunk     LZW, 8K Buffer
*                  9-13 Bits With Partial Clearing
*  2  Reduced-1  Probalistic Compression,
*                  L(X) = Lower 7 Bits
*  3  Reduced-2  Probalistic Compression
*                  L(X) = Lower 6 Bits
*  4  Reduced-3  Probalistic Compression,
*                  L(X) = Lower 5 Bits
*  5  Reduced-4  Probalistic Compression,
*                  L(X) = Lower 4 Bits
*  6  Imploded   2 Shanno-Fano Trees,
*                  4K Sliding Dictionary
*  7  Imploded   3 Shanno-Fano Trees,
*                  4K Sliding Dictionary
*  8  Imploded   2 Shanno-Fano Trees,
*                  8K Sliding Dictionary
*  9  Imploded   3 Shanno-Fano Trees,
*                  8K Sliding Dictionary
*
            DW        0                            ; 10 Last Mod File Time (MS-DOS)
            DW        0                            ; 12 Last Mod File Date (MS-DOS)
            ADRL      0                            ; 14 CRC-32
ZIP_LNSZ    ADRL      0                            ; 18 Compressed Size
            ADRL      0                            ; 22 Uncompressed Size
ZIP_LFLN    DW        0                            ; 26 Filename Length
ZIP_LXLN    DW        0                            ; 28 Extra Field Length
            DS        1                            ; Filename
            DS        1                            ; Extra Field
*
*-------------------------------------------------
* CENTRAL DIRECTORY STRUCTURE
*-------------------------------------------------
*
ZIP_C_ID    ASC       'PK'                         ; 0  ZIP Header Signature
            HEX       0102                         ; 2  Central File Header Signature
            DB        0                            ; 4  Version Made By
            DB        0                            ; 5  Host Operating System
*
*   0  MS-DOS And OS/2 (FAT)
*   1  Amiga
*   2  VMS
*   3  Unix
*   4  VM/CMS
*   5  Atari ST
*   6  OS/2 1.2 Extended File Sys
*   7  Macintosh
*   8  Thru
* 255  Unused
*
            DB        0                            ; 6  Version Needed To Extract
            DB        0                            ; 7  O/S Of Version Needed For Extraction
            DW        0                            ; 8  General Purpose Bit Flag
*
*  0     If Set, File Is Encrypted
*  1     If File Imploded And This Bit Is Set, 8K
*            Sliding Dictionary Was Used.
*        If Clear, 4K Sliding Dictionary Was Used.
*  2     If File Imploded And This Bit Is Set, 3
*            Shannon-Fano Trees Were Used. If Clear, 2
*            Shannon-Fano Trees Were Used.
* 3-4    Unused
* 5-7    Used Internaly By ZIP
*
ZIP_CMTH    DW        0                            ; 10 Compression Method
*
* ZIP_CMTH  0  Stored     No Compression Used
*           1  Shrunk     LZW, 8K Buffer
*                           9-13 Bits With Partial Clearing
*           2  Reduced-1  Probalistic Compression,
*                           L(X) = Lower 7 Bits
*           3  Reduced-2  Probalistic Compression
*                           L(X) = Lower 6 Bits
*           4  Reduced-3  Probalistic Compression,
*                           L(X) = Lower 5 Bits
*           5  Reduced-4  Probalistic Compression,
*                           L(X) = Lower 4 Bits
*           6  Imploded   2 Shanno-Fano Trees,
*                           4K Sliding Dictionary
*           7  Imploded   3 Shanno-Fano Trees,
*                           4K Sliding Dictionary
*           8  Imploded   2 Shanno-Fano Trees,
*                           8K Sliding Dictionary
*           9  Imploded   3 Shanno-Fano Trees,
*                           8K Sliding Dictionary
*
ZIP_CTIM    DW        0                            ; 12 Last Mod File Time (MS-DOS)
ZIP_CDAT    DW        0                            ; 14 Last Mod File Date (MS-DOS)
            ADRL      0                            ; 16 CRC-32
ZIP_CNSZ    ADRL      0                            ; 20 Compressed Size
ZIP_COSZ    ADRL      0                            ; 24 Uncompressed Size
ZIP_CFLN    DW        0                            ; 28 Filename Length
ZIP_CXLN    DW        0                            ; 30 Extra Field Length
ZIP_CCLN    DW        0                            ; 32 File Comment Length
            DW        0                            ; 34 Disk Number Start
            DW        0                            ; 36 Internal File Attributes
                                                   ; If = 1, File Is Apparently An
;         ASCII Or Text File
; If = 0, File Apparently Contains
;         Binary Data
; 1-7     Unused In Version 1.0.
*
ZIP_CXTN    ADRL      0                            ; 38 External File Attributes, Host
; System Dependent
            ADRL      0                            ; 42 Relative Offset Of Local Header
; From The Start Of The First Disk
; On Which This File Appears
            DS        1                            ; Filename Or Path - Should Not
; Contain A Drive Or Device Letter,
; Or A Leading Slash. All Slashes
; Should Be Forward Slashes '/'
            DS        1                            ; Extra Field
            DS        1                            ; File Comment
*
*-------------------------------------------------
* END OF CENTRAL DIR STRUCTURE
*-------------------------------------------------
*
ZIP_E_ID    ASC       'PK'                         ; ZIP Header Signature
            HEX       0506                         ; End Of Central Dir Signature
            DW        0                            ; Number Of This Disk
            DW        0                            ; Number Of Disk With Start Central Dir
            DW        0                            ; Total Number Of Entries In Central Dir
; On This Disk
ZIP_EENT    DW        0                            ; Total Number Entries In Central Dir
            ADRL      0                            ; Size Of The Central Directory
            ADRL      0                            ; Offset Of Start Of Central Directory
; With Respect To The Starting Disk
; Number
            DW        0                            ; Zipfile Comment Length
            DS        1                            ; Zipfile Comment
            DEND
*
*-------------------------------------------------
* EXTRA FIELD
*-------------------------------------------------
*
            DUM       DATABUF
ZIP_EXID    DW        0                            ; 0-31 Reserved By PKWARE
            DW        0
            DS        1                            ; Specific Data For Individual
            DEND                                   ; Files. Data Field Should Begin
; With A S/W Specific Unique ID
*-------------------------------------------------
* MS-DOS Attribute Flags:
*
* Bit 7: Not Used
*     6: Not Used
*     5: File Not Archived
*     4: Subdirectory File
*     3: Volume Label
*     2: System File
*     1: Hidden File
*     0: File Is Read-Only
*-------------------------------------------------
* POSITIONING IN FILE
*-------------------------------------------------
*
* First File Header = Beginning Of File
*
* Begining Of Data  = Beginning Of Header +
*                       ZIP_LFLN + ZIP_LXLN + 30
*
* Next File Header = Begining Data + ZIP_LNSZ
*       Or
*                  = Previous File Header + ZIP_LNSZ +
*                       ZIP_LFLN + ZIP_LXLN + 30
*
DO_ZIP      ZEROSEEK
            LDA       #0
            STA       LASTMARK
            STA       LASTMARK+1
            STA       LASTMARK+2
:FNDCENT    READ      #30;ZIP_L_ID                 ; Read In A Header
            LDA       ZIP_L_ID+2                   ; Is It A Local File Header?
            CMP       #3
            BNE       :CONT                        ; Nope

            LDA       ZIP_L_ID+3
            CMP       #4
:CONT       BNE       :FINDEND                     ; Nope

            LDX       LASTMARK
            LDA       LASTMARK+1
            LDY       LASTMARK+2
            JSR       ADDXAY                       ; MARK = MARK + ZIP_LNSZ
            DA        ZIP_LNSZ
            JSR       ADDXAY2                      ; MARK = MARK + ZIP_LFLN
            DA        ZIP_LFLN
            JSR       ADDXAY2                      ; MARK = MARK + ZIP_LXLN
            DA        ZIP_LXLN
            JSR       ADDXAY2                      ; Add Local Header Length
            DA        :30
            PUTMARK   LASTMARK                     ; Point To Next Header
            JMP       :FNDCENT

:30         DA        30

:FINDEND    LDX       LASTMARK                     ; Point Back To Last Header
            LDA       LASTMARK+1
            LDY       LASTMARK+2
            STX       CENTMRK                      ; Save Start Of Central Header
            STA       CENTMRK+1
            STY       CENTMRK+2
            JSR       SET_POS
:SRCHEND    READ      #46;ZIP_C_ID                 ; Read Central Header
            LDA       ZIP_C_ID+2                   ; Is It Central Header?
            CMP       #1
            BNE       :CONT2                       ; Nope

            LDA       ZIP_C_ID+3
            CMP       #2
:CONT2      BNE       :DO_END                      ; Nope

            LDX       LASTMARK
            LDA       LASTMARK+1
            LDY       LASTMARK+2
            JSR       ADDXAY2                      ; MARK = MARK + ZIP_CFLN
            DA        ZIP_CFLN
            JSR       ADDXAY2                      ; MARK = MARK + ZIP_CXLN
            DA        ZIP_CXLN
            JSR       ADDXAY2                      ; MARK = MARK + ZIP_CCLN
            DA        ZIP_CCLN
            JSR       ADDXAY2
            DA        :46
            PUTMARK   LASTMARK                     ; Point To Next Header
            JMP       :SRCHEND

:46         DA        46

:DO_END     PUTMARK   LASTMARK                     ; Point Back To Last Header

            READ      #33;ZIP_E_ID                 ; Should Be End Header Now finally
            PRINT     'ZIP  -  Records: '
            DECOUT    $80;WORD;ZIP_EENT
            MSDOS     1                            ; Print List Header
            LDX       CENTMRK                      ; Set Mark Back To Central
            LDA       CENTMRK+1
            LDY       CENTMRK+2
            STX       LASTMARK
            STA       LASTMARK+1
            STY       LASTMARK+2
            JSR       SET_POS
:ZIPLOOP    READ      #46;ZIP_C_ID                 ; Read In A Header
            LDA       ZIP_C_ID+2                   ; Is It Central Header?
            CMP       #1
            BNE       :ZIPDONE

            LDA       ZIP_C_ID+3
            CMP       #2
            BEQ       :ZIP_DO

:ZIPDONE    RTS

:ZIP_DO     CLC                                    ; LENGTH = ZIP_CFLN + ZIP_CXLN
            LDA       ZIP_CFLN
            ADC       ZIP_CXLN
            CLC
            ADC       ZIP_CCLN
            TAY                                    ; Read In Filename +
            JSR       DO_READ
            DA        ZIP_EXID
            M_ACCESS  ZIP_CXTN                     ; Show File's Access
; Print File Name
            PSTRING   #0;ZIP_CFLN;ZIP_EXID
            MDATE     ZIP_CDAT                     ; Print Date
            MTIME     ZIP_CTIM                     ; Print Time
; Print Uncompressed Size
            DECOUT    8;LONG;ZIP_COSZ
            TWOSPACE
            LDA       ZIP_CMTH                     ; Print Compression Method
            CMP       #9+1                         ; Valid method?
            BLT       :METHOK                      ; Yes

            LDA       #10                          ; Make it unknown
:METHOK     ASL
            TAY
            LDX       :METHODS,Y
            LDA       :METHODS+1,Y
            JSR       PRINTFMT
; Print Compression Percentage
            PERCENT   LONG;ZIP_CNSZ;LONG;ZIP_COSZ
            CROUT                                  ; Next Line
            BIT       INTOUT
            BMI       :DONE2

            SEC
            LDA       ZIP_EENT
            BNE       :DECE
            DEC       ZIP_EENT+1
:DECE       DEC       ZIP_EENT
            LDA       ZIP_EENT
            ORA       ZIP_EENT+1
            BEQ       :DONE2

            JMP       :ZIPLOOP

:DONE2      RTS

:METHODS    DA        STORE
            DA        SHRUNK
            DA        REDUCE
            DA        REDUCE
            DA        REDUCE
            DA        REDUCE
            DA        IMPLODE
            DA        IMPLODE
            DA        IMPLODE
            DA        IMPLODE
            DA        UNK

