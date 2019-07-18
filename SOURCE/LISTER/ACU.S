*=================================================
* ACU  (APPLE)
*=================================================
* FILE FORMAT
*-------------------------------------------------
*
*  Archive Header
*      File1 Header
*          Resource Fork Of File1
*          Data Fork Of File1
*              .
*              .
*      Filen Header
*          Resource Fork Of Filen
*          Data Fork Of Filen
*
*-------------------------------------------------
* Master Header
*-------------------------------------------------
*
            DUM       HDRBUF
ACU_RECS    DA        0                                          ; * Records In Archive
ACU_OS      DA        0                                          ; * Files Operating System
*
* ACU_OS    0  ProDOS Or SOS
*           1  DOS 3.3
*           2  Reserved
*           3  DOS 3.2 Or DOS 3.1
*           4  Apple II Pascal
*           5  Macintosh MFS
*           6  Macintosh HFS
*           7  Macintosh XL
*           8  Apple CP/M
*           9  Reserved
*           A  MS-DOS
*           B  High Sierra (CD-ROM)
*           C  ISO 9660 (CD-ROM)
*           D  AppleShare
*
            ASC       'fZink'                                    ; * ACU ID String
ACU_VER     DB        0                                          ; * ACU Version Number
ACU_HLEN    DA        0                                          ;   ACU Header Length
            DS        8                                          ; Reserved
; Total Length Of 20 Bytes
*
*-------------------------------------------------
* File Header
*-------------------------------------------------
*
ACU_RCMP    DB        0                                          ; * Resource Fork Compression Method
            DB        0                                          ;   Data Fork Compression Method
*
* ACUFxCMP     0     Stored
*              1
*              2
*              3     Huffman
*
            DA        0                                          ;   Resource Fork CRC-16
            DA        0                                          ;   Data Fork CRC-16
            ADRL      0                                          ;   Resource Fork Blocks Used
            ADRL      0                                          ;   Data Fork Blocks Used
ACU_RSIZ    ADRL      0                                          ; * Resource Fork Compressed Size
ACU_DSIZ    ADRL      0                                          ; * Data Fork Compressed Size
ACU_ACS     DA        0                                          ; * File Access Flags
ACU_FTYP    DA        0                                          ; * File Type
ACU_AUX     ADRL      0                                          ; * File Aux Type
            DA        0                                          ;   Reserved
            DA        0                                          ;   File Storage Type
ACU_REOF    ADRL      0                                          ; * Resource Fork Uncompressed Size
ACU_DEOF    ADRL      0                                          ; * Data Fork Uncompressed Size
ACU_MDAT    DA        0                                          ; * File Modified Date, P8 Format
ACU_MTIM    DA        0                                          ; * File Modified Time, P8 Format
            DA        0                                          ;   File Create Date, P8 Format
            DA        0                                          ;   File Create Time, P8 Format
ACU_FNLN    DA        0                                          ; * Length Of File Name
            DA        0                                          ;   CRC Of Header
ACU_FNAM    DS        1                                          ; * Filename
            DEND
*
*-------------------------------------------------
* POSITIONING IN FILE
*-------------------------------------------------
*
* First File Header = Beginning Of File + 20
*
* Beginning Of File Data = Beginning Of File Header
*                          + 54 + ACU_FNLN
*
* Next File Header      = Beginning Of File Header
*                          + 54 + ACU_FNLN
*                          + ACU_RSIZ + ACU_DSIZ
*       Or
*                       = Beginning Of File Data
*                          + ACU_RSIZ + ACU_DSIZ
*
*=================================================
*
*AppleLink Conversion Utility, Version: Xxxx
*
*OS, X Records
*
DO_ACU      ZEROSEEK
DO_ACU2     PRINT     'AppleLink Conversion Utility, V'
            DECOUT    $80;0;ACU_VER
            CROUT
            CROUT
            LDA       ACU_OS
            JSR       ZINKOS
            PRINT     ', '
            DECOUT    $80;1;ACU_RECS
            PRINT     ' Records'                                 ; Print number of records
            APPLE     1                                          ; Show List Header
            READ      #20;ACU_FNAM                               ; Skip Master Header
            GETMARK   LASTMARK                                   ; Get Starting Mark
:ACULOOP    READ      #54;ACU_RCMP                               ; Read In Header
            READ      ACU_FNLN;ACU_FNAM                          ; Read in filename
            P_ACCESS  ACU_ACS                                    ; Print File Access Flag
            PSTRING   0;ACU_FNLN;ACU_FNAM                        ; Print File Name
            FILETYPE  ACU_FTYP                                   ; Print File Type
            PDATE     ACU_MDAT                                   ; Print Prodos Date
            PTIME     ACU_MTIM                                   ; Print Prodos Time
            AUXTYPE   ACU_AUX                                    ; Print Aux Type
; Add Uncompressed EOF's
            ADD       LONG;ACU_REOF;LONG;ACU_DEOF;LONG;RDEOF
            DECOUT    8;3;RDEOF                                  ; Print File Size
            TWOSPACE
            LDX       #0
            LDA       ACU_DSIZ
            ORA       ACU_DSIZ+1
            ORA       ACU_DSIZ+2
            ORA       ACU_DSIZ+3
            BEQ       :USEFORK

            INX
:USEFORK    LDA       ACU_RCMP,X                                 ; Print The Format
            CMP       #3+1                                       ; Valid format?
            BLT       :FMTOK                                     ; Yes
            LDA       #1                                         ; Make it unknown
:FMTOK      ASL
            TAY
            LDX       :FORMATS,Y
            LDA       :FORMATS+1,Y
            JSR       PRINTFMT
; Add Compressed EOF's
            ADD       LADR;ACU_RSIZ;LADR;ACU_DSIZ;LADR;RDSIZ
; Print Compression Percent
            PERCENT   LADR;RDSIZ;LADR;RDEOF
            CROUT
            BIT       INTOUT
            BMI       :ACUDONE

            LDA       ACU_RECS
            BNE       :DECREC
            DEC       ACU_RECS+1
:DECREC     DEC       ACU_RECS
            LDA       ACU_RECS
            ORA       ACU_RECS+1
            BEQ       :ACUDONE

; Add In Header Length
            ADD       LADR;LASTMARK;WORD;ACU_HLEN;LADR;LASTMARK
; Add In Filename Length
            ADD       LADR;LASTMARK;WORD;ACU_FNLN;LADR;LASTMARK
; Add In Compressed EOF's
            ADD       LADR;LASTMARK;LADR;RDSIZ;LADR;LASTMARK
            PUTMARK   LASTMARK
            JMP       :ACULOOP

:ACUDONE    RTS

:FORMATS    DA        STORE
            DA        UNK
            DA        UNK
            DA        HUFF

