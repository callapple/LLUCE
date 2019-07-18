*=================================================
* LZH  (MS-DOS)
*=================================================
* FILE FORMAT
*-------------------------------------------------
*
*    File Header 1
*         File 1
*    File Header 2
*         File 2
*    .
*    .
*    File Header N
*         File N
* EOF
*
*-------------------------------------------------
* FILE HEADER
*-------------------------------------------------
*
            DUM       HDRBUF
LZH_HSIZ    DB        0                            ; Header Size
            DB        0                            ; Cksum Of Remaining Bytes
LZH_MTHD    ASC       '-Lh0-'                      ; Method
*
* LZH_MTHD  0  Stored     -Lh0-  No Compression Used
*           1  LZW-HUF    -Lh1-  LZW, 4K Buffer
*                                Huffman For Upper 6 Bits Of Pos
*           4  LZW-ARI    -Lz4-  LZW, Arithmetic Encoding
*           5  LZW-ARI    -Lz5-  LZW, Arithmetic Encoding
*
LZH_NSIZ    ADRL      0                            ; Compressed Size
LZH_OSIZ    ADRL      0                            ; Uncompressed Size
LZH_TIME    DW        0                            ; File Time (MSDOS)
LZH_DATE    DW        0                            ; File Date (MSDOS)
LZH_ATRB    DW        0                            ; File Attribute
LZH_FNLN    DB        0                            ; Filename/Path Length
LZH_FNAM    DS        1                            ; Filename/Path (Variable Len)
            DW        0                            ; CRC-16
            DEND
*
*-------------------------------------------------
* POSITIONING IN FILE
*-------------------------------------------------
*
* Beginning Of File Data = Beginning Of Header + LZH_HSIZ
*
* Beginning Of Next File Header = Beginning Of File Data
*                              + LZH_NSIZ
*
DO_LZH      ZEROSEEK
            PRINT     'LZH'
            MSDOS     1                            ; Files Are Packed
:LZHLOOP    BIT       INTOUT
            BMI       :LZHDONE

            READ      #2;LZH_HSIZ                  ; Read In Header Length
            LDY       LZH_HSIZ                     ; Set Length
            BEQ       :LZHDONE

            JSR       DO_READ                      ; Read In Rest Of Header
            DA        LZH_MTHD
            LDA       LZH_MTHD                     ; Check For Valid Header
            CMP       #'-'
            BNE       :LZHDONE

            LDA       LZH_MTHD+1
            CMP       #'l'
            BNE       :LZHDONE

            LDA       LZH_MTHD+2
            CMP       #'h'
            BNE       :LZHDONE

            LDA       LZH_MTHD+3
            AND       #$F0
            CMP       #'0'
            BNE       :LZHDONE

            LDA       LZH_MTHD+4
            CMP       #'-'
            BNE       :LZHDONE

            JSR       :SHOWENT
            JSR       GET_MARK
            JSR       ADDXAY                       ; MARK = MARK + LZH_NSIZ
            DA        LZH_NSIZ
            JSR       SET_POS                      ; Point To Next Record
            JMP       :LZHLOOP                     ; Do Next One

:LZHDONE    RTS

:SHOWENT    M_ACCESS  LZH_ATRB                     ; Show File Access
; Print File Name
            PSTRING   #0;LZH_FNLN;LZH_FNAM
            MDATE     LZH_DATE                     ; Print Date
            MTIME     LZH_TIME                     ; Print Time
; Print Entry Size
            DECOUT    8;LONG;LZH_OSIZ
            TWOSPACE
            LDA       LZH_MTHD+3                   ; Print Packing Method
            AND       #$F
            CMP       #5+1                         ; Valid format?
            BLT       :METHOK                      ; Yes

            LDA       #6                           ; Make it unknown
:METHOK     ASL
            TAY
            LDX       :METHODS,Y
            LDA       :METHODS+1,Y
            JSR       PRINTFMT
; Print Packing Percentage
            PERCENT   LONG;LZH_NSIZ;LONG;LZH_OSIZ
            CROUT                                  ; Next Line
            RTS

:METHODS    DA        STORE
            DA        HUFF
            DA        UNK
            DA        UNK
            DA        LZWARI
            DA        LZWARI

